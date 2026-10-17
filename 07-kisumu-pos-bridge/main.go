package main

import (
	"bytes"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"math"
	"net/http"
	"net/url"
	"os"
	"path/filepath"
	"strconv"
	"strings"
	"sync"
)

const SatsPerBTC = 100_000_000

// DarajaSTKCallback models the Safaricom M-Pesa Express (STK Push) webhook payload.
type DarajaSTKCallback struct {
	MerchantRequestID string  `json:"MerchantRequestID"`
	CheckoutRequestID string  `json:"CheckoutRequestID"`
	ResultCode        int     `json:"ResultCode"`
	ResultDesc        string  `json:"ResultDesc"`
	AmountKES         float64 `json:"AmountKES"`
	MpesaReceipt      string  `json:"MpesaReceiptNumber"`
	PhoneNumber       string  `json:"PhoneNumber"`
}

// SettlementRecord tracks an idempotent KES -> Sats settlement.
type SettlementRecord struct {
	CheckoutRequestID string  `json:"checkout_request_id"`
	MpesaReceipt      string  `json:"mpesa_receipt"`
	AmountKES         float64 `json:"amount_kes"`
	AmountSats        int64   `json:"amount_sats"`
	AmountBTC         string  `json:"amount_btc"`
	RecipientAddress  string  `json:"recipient_address"`
	BIP21URI          string  `json:"bip21_uri"`
	TxID              string  `json:"txid"`
	IdempotencyHash   string  `json:"idempotency_hash"`
}

// BridgeEngine manages idempotent M-Pesa -> Bitcoin Core regtest settlement.
type BridgeEngine struct {
	mu          sync.Mutex
	RateKESBTC  float64
	RPCURL      string
	RPCUser     string
	RPCPass     string
	settledByID map[string]SettlementRecord
}

func NewBridgeEngine(rateKESBTC float64, rpcURL, rpcUser, rpcPass string) *BridgeEngine {
	return &BridgeEngine{
		RateKESBTC:  rateKESBTC,
		RPCURL:      rpcURL,
		RPCUser:     rpcUser,
		RPCPass:     rpcPass,
		settledByID: make(map[string]SettlementRecord),
	}
}

// KESToSats converts a Kenyan Shilling amount to satoshis at the configured BTC/KES rate.
func (b *BridgeEngine) KESToSats(kes float64) (int64, string, error) {
	if kes <= 0 || b.RateKESBTC <= 0 {
		return 0, "", errors.New("amount and rate must be positive")
	}
	btc := kes / b.RateKESBTC
	sats := int64(math.Round(btc * SatsPerBTC))
	if sats < 546 {
		return 0, "", fmt.Errorf("calculated output %d sats is below P2WPKH dust threshold (546 sats)", sats)
	}
	btcStr := fmt.Sprintf("%.8f", float64(sats)/SatsPerBTC)
	return sats, btcStr, nil
}

// BuildBIP21URI constructs a standards-compliant BIP21 unified payment URI.
func BuildBIP21URI(address, amountBTC, label, message string) string {
	q := url.Values{}
	q.Set("amount", amountBTC)
	if label != "" {
		q.Set("label", label)
	}
	if message != "" {
		q.Set("message", message)
	}
	return fmt.Sprintf("bitcoin:%s?%s", address, q.Encode())
}

// IdempotencyKey computes a deterministic SHA-256 digest over CheckoutRequestID and MpesaReceiptNumber.
func IdempotencyKey(cb DarajaSTKCallback) string {
	raw := fmt.Sprintf("%s:%s:%.2f", cb.CheckoutRequestID, cb.MpesaReceipt, cb.AmountKES)
	sum := sha256.Sum256([]byte(raw))
	return hex.EncodeToString(sum[:])
}

// ProcessCallback validates a Daraja STK callback, prevents replay/double-payouts, and settles on-chain.
func (b *BridgeEngine) ProcessCallback(cb DarajaSTKCallback, settleFn func(addr, amountBTC string) (string, error), newAddrFn func(label string) (string, error)) (SettlementRecord, bool, error) {
	b.mu.Lock()
	defer b.mu.Unlock()

	if cb.ResultCode != 0 {
		return SettlementRecord{}, false, fmt.Errorf("stk push failed with ResultCode=%d (%s)", cb.ResultCode, cb.ResultDesc)
	}
	if cb.CheckoutRequestID == "" || cb.MpesaReceipt == "" {
		return SettlementRecord{}, false, errors.New("missing CheckoutRequestID or MpesaReceiptNumber")
	}

	if existing, ok := b.settledByID[cb.CheckoutRequestID]; ok {
		return existing, true, nil // Replay detected: return existing settlement without re-broadcasting
	}

	sats, btcStr, err := b.KESToSats(cb.AmountKES)
	if err != nil {
		return SettlementRecord{}, false, err
	}

	addr, err := newAddrFn("kisumu_pos_" + cb.MpesaReceipt)
	if err != nil {
		return SettlementRecord{}, false, err
	}

	txid, err := settleFn(addr, btcStr)
	if err != nil {
		return SettlementRecord{}, false, err
	}

	rec := SettlementRecord{
		CheckoutRequestID: cb.CheckoutRequestID,
		MpesaReceipt:      cb.MpesaReceipt,
		AmountKES:         cb.AmountKES,
		AmountSats:        sats,
		AmountBTC:         btcStr,
		RecipientAddress:  addr,
		BIP21URI:          BuildBIP21URI(addr, btcStr, "Kisumu POS", "M-Pesa "+cb.MpesaReceipt),
		TxID:              txid,
		IdempotencyHash:   IdempotencyKey(cb),
	}
	b.settledByID[cb.CheckoutRequestID] = rec
	return rec, false, nil
}

type rpcRequest struct {
	JSONRPC string        `json:"jsonrpc"`
	ID      string        `json:"id"`
	Method  string        `json:"method"`
	Params  []interface{} `json:"params"`
}

type rpcResponse struct {
	Result json.RawMessage `json:"result"`
	Error  *struct {
		Code    int    `json:"code"`
		Message string `json:"message"`
	} `json:"error"`
}

func (b *BridgeEngine) callRPC(wallet, method string, params ...interface{}) (json.RawMessage, error) {
	endpoint := b.RPCURL
	if wallet != "" {
		endpoint = fmt.Sprintf("%s/wallet/%s", strings.TrimRight(b.RPCURL, "/"), wallet)
	}
	payload, _ := json.Marshal(rpcRequest{
		JSONRPC: "1.0",
		ID:      "kisumu-pos",
		Method:  method,
		Params:  params,
	})
	req, err := http.NewRequest("POST", endpoint, bytes.NewReader(payload))
	if err != nil {
		return nil, err
	}
	req.Header.Set("Content-Type", "application/json")
	req.SetBasicAuth(b.RPCUser, b.RPCPass)

	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()
	body, _ := io.ReadAll(resp.Body)

	var rpcResp rpcResponse
	if err := json.Unmarshal(body, &rpcResp); err != nil {
		return nil, fmt.Errorf("invalid rpc response: %s", string(body))
	}
	if rpcResp.Error != nil {
		return nil, fmt.Errorf("rpc error %d: %s", rpcResp.Error.Code, rpcResp.Error.Message)
	}
	return rpcResp.Result, nil
}

func loadRegtestAuth() (string, string, error) {
	home, _ := os.UserHomeDir()
	cookieCandidates := []string{
		filepath.Join(home, "Library", "Application Support", "Bitcoin", "regtest", ".cookie"),
		filepath.Join(home, ".bitcoin", "regtest", ".cookie"),
	}
	for _, path := range cookieCandidates {
		if data, err := os.ReadFile(path); err == nil {
			parts := strings.SplitN(strings.TrimSpace(string(data)), ":", 2)
			if len(parts) == 2 {
				return parts[0], parts[1], nil
			}
		}
	}

	confCandidates := []string{
		filepath.Join(home, "Library", "Application Support", "Bitcoin", "bitcoin.conf"),
		filepath.Join(home, ".bitcoin", "bitcoin.conf"),
	}
	for _, path := range confCandidates {
		if data, err := os.ReadFile(path); err == nil {
			var user, pass string
			for _, line := range strings.Split(string(data), "\n") {
				line = strings.TrimSpace(line)
				if strings.HasPrefix(line, "rpcuser=") {
					user = strings.TrimPrefix(line, "rpcuser=")
				} else if strings.HasPrefix(line, "rpcpassword=") {
					pass = strings.TrimPrefix(line, "rpcpassword=")
				}
			}
			if user != "" && pass != "" {
				return user, pass, nil
			}
		}
	}
	return "", "", errors.New("regtest .cookie or bitcoin.conf credentials not found")
}

func main() {
	user, pass, err := loadRegtestAuth()
	if err != nil {
		fmt.Fprintf(os.Stderr, "Failed to load regtest auth: %v\n", err)
		os.Exit(1)
	}

	engine := NewBridgeEngine(11_500_000.0, "http://127.0.0.1:18443", user, pass)

	newAddrFn := func(label string) (string, error) {
		res, err := engine.callRPC("kisumu_merchant", "getnewaddress", label, "bech32")
		if err != nil {
			return "", err
		}
		var addr string
		json.Unmarshal(res, &addr)
		return addr, nil
	}

	settleFn := func(addr, amountBTC string) (string, error) {
		amtFloat, _ := strconv.ParseFloat(amountBTC, 64)
		res, err := engine.callRPC("kisumu_miner", "sendtoaddress", addr, amtFloat)
		if err != nil {
			return "", err
		}
		var txid string
		json.Unmarshal(res, &txid)
		return txid, nil
	}

	cb := DarajaSTKCallback{
		MerchantRequestID: "29115-34620561-1",
		CheckoutRequestID: "ws_CO_17102026210500_KSM001",
		ResultCode:        0,
		ResultDesc:        "The service request is processed successfully.",
		AmountKES:         1150.00, // 1,150 KES at 11.5M KES/BTC = 10,000 sats (0.00010000 BTC)
		MpesaReceipt:      "QJH8KSM901",
		PhoneNumber:       "254712345678",
	}

	rec1, replayed1, err := engine.ProcessCallback(cb, settleFn, newAddrFn)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Settlement failed: %v\n", err)
		os.Exit(1)
	}
	out1, _ := json.MarshalIndent(rec1, "", "  ")
	fmt.Printf("=== First Daraja Webhook Delivery (Replayed=%v) ===\n%s\n", replayed1, string(out1))

	// Simulate duplicate Daraja webhook retry with identical CheckoutRequestID
	rec2, replayed2, err := engine.ProcessCallback(cb, settleFn, newAddrFn)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Replay check failed: %v\n", err)
		os.Exit(1)
	}
	fmt.Printf("=== Duplicate Daraja Webhook Retry (Replayed=%v, Same TxID=%v) ===\n", replayed2, rec1.TxID == rec2.TxID)
}
