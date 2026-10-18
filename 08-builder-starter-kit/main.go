package main

import (
	"bytes"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"log"
	"net/http"
	"net/url"
	"os"
	"path/filepath"
	"strings"
)

const (
	SatsPerBTC    = 100_000_000
	DustLimitSats = 546
	MaxMoneySats  = 21_000_000 * SatsPerBTC
)

// BitcoinRPC connects directly to bitcoind JSON-RPC using stdlib net/http.
type BitcoinRPC struct {
	BaseURL string
	User    string
	Pass    string
}

type rpcReq struct {
	JSONRPC string        `json:"jsonrpc"`
	ID      string        `json:"id"`
	Method  string        `json:"method"`
	Params  []interface{} `json:"params"`
}

type rpcResp struct {
	Result json.RawMessage `json:"result"`
	Error  *struct {
		Code    int    `json:"code"`
		Message string `json:"message"`
	} `json:"error"`
}

func (r *BitcoinRPC) Call(wallet, method string, params ...interface{}) (json.RawMessage, error) {
	endpoint := r.BaseURL
	if wallet != "" {
		endpoint = fmt.Sprintf("%s/wallet/%s", strings.TrimRight(r.BaseURL, "/"), wallet)
	}
	if params == nil {
		params = []interface{}{}
	}
	bodyBytes, _ := json.Marshal(rpcReq{
		JSONRPC: "1.0",
		ID:      "sovereign-kit",
		Method:  method,
		Params:  params,
	})
	req, err := http.NewRequest("POST", endpoint, bytes.NewReader(bodyBytes))
	if err != nil {
		return nil, err
	}
	req.Header.Set("Content-Type", "application/json")
	req.SetBasicAuth(r.User, r.Pass)

	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()
	raw, _ := io.ReadAll(resp.Body)

	var parsed rpcResp
	if err := json.Unmarshal(raw, &parsed); err != nil {
		return nil, fmt.Errorf("invalid rpc response: %s", string(raw))
	}
	if parsed.Error != nil {
		return nil, fmt.Errorf("rpc error %d: %s", parsed.Error.Code, parsed.Error.Message)
	}
	return parsed.Result, nil
}

// SatsToBTC converts integer satoshis into an 8-decimal BTC string and enforces consensus/policy bounds.
func SatsToBTC(sats int64) (string, error) {
	if sats < DustLimitSats {
		return "", fmt.Errorf("amount %d sats is below dust limit (%d sats)", sats, DustLimitSats)
	}
	if sats > MaxMoneySats {
		return "", fmt.Errorf("amount %d sats exceeds MAX_MONEY (%d sats)", sats, MaxMoneySats)
	}
	whole := sats / SatsPerBTC
	rem := sats % SatsPerBTC
	return fmt.Sprintf("%d.%08d", whole, rem), nil
}

// BuildBIP21 creates a standards-compliant BIP21 URI (bitcoin:<address>?amount=<btc>&label=<label>).
func BuildBIP21(address string, sats int64, label string) (string, error) {
	if !strings.HasPrefix(address, "bc1") && !strings.HasPrefix(address, "tb1") && !strings.HasPrefix(address, "bcrt1") {
		return "", errors.New("address must be a valid Bech32/Bech32m SegWit address (bc1/tb1/bcrt1)")
	}
	btcStr, err := SatsToBTC(sats)
	if err != nil {
		return "", err
	}
	q := url.Values{}
	q.Set("amount", btcStr)
	if label != "" {
		q.Set("label", label)
	}
	return fmt.Sprintf("bitcoin:%s?%s", address, q.Encode()), nil
}

// BuildOPReturnScriptHex constructs a provably unspendable OP_RETURN (0x6a) scriptPubKey
// committing to the 32-byte SHA-256 digest of arbitrary data (6a20 + 32-byte hash).
func BuildOPReturnScriptHex(message string) (digestHex string, scriptHex string) {
	sum := sha256.Sum256([]byte(message))
	digestHex = hex.EncodeToString(sum[:])
	// 0x6a = OP_RETURN, 0x20 = push 32 bytes
	scriptHex = "6a20" + digestHex
	return digestHex, scriptHex
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

func NewServerMux(rpc *BitcoinRPC) *http.ServeMux {
	mux := http.NewServeMux()

	// 1. Node & Mempool Telemetry Endpoint
	mux.HandleFunc("GET /api/node", func(w http.ResponseWriter, r *http.Request) {
		chainInfo, err := rpc.Call("", "getblockchaininfo")
		if err != nil {
			http.Error(w, err.Error(), http.StatusBadGateway)
			return
		}
		mempoolInfo, err := rpc.Call("", "getmempoolinfo")
		if err != nil {
			http.Error(w, err.Error(), http.StatusBadGateway)
			return
		}
		w.Header().Set("Content-Type", "application/json")
		fmt.Fprintf(w, `{"chain":%s,"mempool":%s}`, string(chainInfo), string(mempoolInfo))
	})

	// 2. Sovereign Satoshi Invoice Generator (Watch-Only BIP84 Address + BIP21 URI)
	mux.HandleFunc("POST /api/invoice", func(w http.ResponseWriter, r *http.Request) {
		var req struct {
			AmountSats int64  `json:"amount_sats"`
			Label      string `json:"label"`
		}
		if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
			http.Error(w, err.Error(), http.StatusBadRequest)
			return
		}
		addrRes, err := rpc.Call("sovereign_watch_only", "getnewaddress", req.Label, "bech32")
		if err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}
		var addr string
		json.Unmarshal(addrRes, &addr)

		uri, err := BuildBIP21(addr, req.AmountSats, req.Label)
		if err != nil {
			http.Error(w, err.Error(), http.StatusBadRequest)
			return
		}
		btcStr, _ := SatsToBTC(req.AmountSats)
		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(map[string]interface{}{
			"address":     addr,
			"amount_sats": req.AmountSats,
			"amount_btc":  btcStr,
			"bip21_uri":   uri,
			"watch_only":  true,
		})
	})

	// 3. OP_RETURN Timestamp Notarization Endpoint
	mux.HandleFunc("POST /api/notarize", func(w http.ResponseWriter, r *http.Request) {
		var req struct {
			DocumentText string `json:"document_text"`
		}
		if err := json.NewDecoder(r.Body).Decode(&req); err != nil || req.DocumentText == "" {
			http.Error(w, "document_text is required", http.StatusBadRequest)
			return
		}
		digestHex, scriptHex := BuildOPReturnScriptHex(req.DocumentText)

		// Create funded PSBT with OP_RETURN data output {"data": digestHex}
		psbtRes, err := rpc.Call("kisumu_miner", "walletcreatefundedpsbt",
			[]interface{}{},
			[]map[string]interface{}{{"data": digestHex}},
		)
		if err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}
		var created struct {
			PSBT string `json:"psbt"`
		}
		json.Unmarshal(psbtRes, &created)

		signedRes, err := rpc.Call("kisumu_miner", "walletprocesspsbt", created.PSBT)
		if err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}
		var signed struct {
			PSBT string `json:"psbt"`
		}
		json.Unmarshal(signedRes, &signed)

		finalRes, err := rpc.Call("", "finalizepsbt", signed.PSBT)
		if err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}
		var finalized struct {
			Hex string `json:"hex"`
		}
		json.Unmarshal(finalRes, &finalized)

		txidRes, err := rpc.Call("", "sendrawtransaction", finalized.Hex)
		if err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}
		var txid string
		json.Unmarshal(txidRes, &txid)

		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(map[string]string{
			"document_sha256": digestHex,
			"op_return_hex":   scriptHex,
			"txid":            txid,
		})
	})

	return mux
}

func main() {
	user, pass, err := loadRegtestAuth()
	if err != nil {
		log.Fatalf("Failed to load regtest credentials: %v", err)
	}
	rpc := &BitcoinRPC{BaseURL: "http://127.0.0.1:18443", User: user, Pass: pass}

	if len(os.Args) > 1 && os.Args[1] == "--demo" {
		// Run end-to-end self-test against live bitcoind -regtest
		digest, scriptHex := BuildOPReturnScriptHex("BitDevs Kisumu Sovereign Block Timestamp #001")
		fmt.Printf("1. Computed OP_RETURN Commitment:\n   SHA256: %s\n   Script: %s\n", digest, scriptHex)

		addrRes, err := rpc.Call("sovereign_watch_only", "getnewaddress", "builder_demo", "bech32")
		if err != nil {
			log.Fatalf("getnewaddress failed: %v", err)
		}
		var addr string
		json.Unmarshal(addrRes, &addr)
		uri, err := BuildBIP21(addr, 50_000, "Sovereign Builder Demo")
		if err != nil {
			log.Fatalf("BuildBIP21 failed: %v", err)
		}
		fmt.Printf("2. Generated Watch-Only BIP21 Invoice (50,000 sats):\n   %s\n", uri)
		return
	}

	addr := "127.0.0.1:8080"
	fmt.Printf("⚡ Sovereign Bitcoin Builder Server listening on http://%s\n", addr)
	log.Fatal(http.ListenAndServe(addr, NewServerMux(rpc)))
}
