package main

import (
	"bytes"
	"encoding/base64"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"net/http"
	"os"
	"path/filepath"
	"strings"
)

// PSBTMagicBytes represents the mandatory BIP174 header "psbt\xff" (0x70736274ff).
var PSBTMagicBytes = []byte{0x70, 0x73, 0x62, 0x74, 0xff}

// ValidateBIP174Header verifies that a base64-encoded string is a valid BIP174 PSBT
// beginning with the 5-byte magic header 0x70736274ff ("psbt\xff" -> "cHNidP8").
func ValidateBIP174Header(psbtBase64 string) ([]byte, error) {
	raw, err := base64.StdEncoding.DecodeString(strings.TrimSpace(psbtBase64))
	if err != nil {
		return nil, fmt.Errorf("invalid base64 encoding: %w", err)
	}
	if len(raw) < len(PSBTMagicBytes) || !bytes.Equal(raw[:5], PSBTMagicBytes) {
		return nil, errors.New("missing BIP174 magic header (0x70736274ff)")
	}
	return raw, nil
}

// ValidateSatsOutput enforces Bitcoin Core's P2WPKH dust limit (294 sats for SegWit v0, 546 sats conservative)
// and consensus MAX_MONEY (21,000,000 BTC = 2,100,000,000,000,000 sats).
func ValidateSatsOutput(sats int64) error {
	const DustLimitSats = 546
	const MaxMoneySats = 21_000_000 * 100_000_000
	if sats < DustLimitSats {
		return fmt.Errorf("output %d sats is below dust threshold (%d sats)", sats, DustLimitSats)
	}
	if sats > MaxMoneySats {
		return fmt.Errorf("output %d sats exceeds consensus MAX_MONEY (%d sats)", sats, MaxMoneySats)
	}
	return nil
}

type RPCClient struct {
	BaseURL string
	User    string
	Pass    string
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

func (c *RPCClient) Call(wallet, method string, params ...interface{}) (json.RawMessage, error) {
	endpoint := c.BaseURL
	if wallet != "" {
		endpoint = fmt.Sprintf("%s/wallet/%s", strings.TrimRight(c.BaseURL, "/"), wallet)
	}
	if params == nil {
		params = []interface{}{}
	}
	payload, _ := json.Marshal(rpcRequest{
		JSONRPC: "1.0",
		ID:      "bip174-psbt",
		Method:  method,
		Params:  params,
	})
	req, err := http.NewRequest("POST", endpoint, bytes.NewReader(payload))
	if err != nil {
		return nil, err
	}
	req.Header.Set("Content-Type", "application/json")
	req.SetBasicAuth(c.User, c.Pass)

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

func ensureWallet(client *RPCClient, name string, disablePrivateKeys bool) {
	_, err := client.Call("", "createwallet", name, disablePrivateKeys, false, "", false, true)
	if err != nil {
		_, _ = client.Call("", "loadwallet", name)
	}
}

func main() {
	user, pass, err := loadRegtestAuth()
	if err != nil {
		fmt.Fprintf(os.Stderr, "Failed to load regtest auth: %v\n", err)
		os.Exit(1)
	}
	client := &RPCClient{BaseURL: "http://127.0.0.1:18443", User: user, Pass: pass}

	const signerWallet = "sovereign_cold_signer"
	const watchWallet = "sovereign_watch_only"

	// 1. Create Cold Signer (has private keys) & Watch-Only Coordinator (disable_private_keys=true)
	ensureWallet(client, signerWallet, false)
	ensureWallet(client, watchWallet, true)

	// 2. Export public BIP84 descriptors from Cold Signer and import into Watch-Only Coordinator
	descRes, err := client.Call(signerWallet, "listdescriptors", false)
	if err != nil {
		panic(err)
	}
	var descList struct {
		Descriptors []struct {
			Desc      string `json:"desc"`
			Timestamp any    `json:"timestamp"`
			Active    bool   `json:"active"`
			Internal  bool   `json:"internal"`
		} `json:"descriptors"`
	}
	json.Unmarshal(descRes, &descList)

	var importPayload []map[string]interface{}
	var externalWpkhDesc string
	for _, d := range descList.Descriptors {
		if strings.HasPrefix(d.Desc, "wpkh(") {
			if !d.Internal {
				externalWpkhDesc = d.Desc
			}
			importPayload = append(importPayload, map[string]interface{}{
				"desc":      d.Desc,
				"timestamp": "now",
				"active":    true,
				"internal":  d.Internal,
			})
		}
	}
	_, err = client.Call(watchWallet, "importdescriptors", importPayload)
	if err != nil {
		panic(err)
	}
	fmt.Printf("1. Exported & Imported Public BIP84 Descriptor:\n   %s\n", externalWpkhDesc)

	// 3. Derive receiving address from the Watch-Only wallet (zero private keys!) and fund it
	addrRes, err := client.Call(watchWallet, "getnewaddress", "cold_vault", "bech32")
	if err != nil {
		panic(err)
	}
	var vaultAddr string
	json.Unmarshal(addrRes, &vaultAddr)
	fmt.Printf("2. Watch-Only Derived Vault Address: %s\n", vaultAddr)

	fundRes, err := client.Call("kisumu_miner", "sendtoaddress", vaultAddr, 0.5)
	if err != nil {
		panic(err)
	}
	var fundTxid string
	json.Unmarshal(fundRes, &fundTxid)

	minerAddrRes, _ := client.Call("kisumu_miner", "getnewaddress")
	var minerAddr string
	json.Unmarshal(minerAddrRes, &minerAddr)
	_, _ = client.Call("", "generatetoaddress", 1, minerAddr)
	fmt.Printf("3. Funded Vault UTXO (0.50000000 BTC) in TXID: %s\n", fundTxid)

	// 4. Watch-Only Wallet constructs an UNSIGNED BIP174 PSBT spending from the Vault
	destRes, _ := client.Call("kisumu_merchant", "getnewaddress", "sovereign_settlement", "bech32")
	var destAddr string
	json.Unmarshal(destRes, &destAddr)

	psbtRes, err := client.Call(watchWallet, "walletcreatefundedpsbt",
		[]interface{}{},
		[]map[string]interface{}{{destAddr: 0.25}},
		0,
		map[string]interface{}{"includeWatching": true},
		true,
	)
	if err != nil {
		panic(err)
	}
	var createdPSBT struct {
		PSBT string  `json:"psbt"`
		Fee  float64 `json:"fee"`
	}
	json.Unmarshal(psbtRes, &createdPSBT)

	rawPSBT, err := ValidateBIP174Header(createdPSBT.PSBT)
	if err != nil {
		panic(err)
	}
	fmt.Printf("4. Watch-Only Created Unsigned BIP174 PSBT (%d bytes, Fee=%.8f BTC):\n   Prefix: %s...\n",
		len(rawPSBT), createdPSBT.Fee, createdPSBT.PSBT[:48])

	// 5. Cold Signer signs the PSBT across the airgap (walletprocesspsbt)
	signedRes, err := client.Call(signerWallet, "walletprocesspsbt", createdPSBT.PSBT)
	if err != nil {
		panic(err)
	}
	var signedPSBT struct {
		PSBT     string `json:"psbt"`
		Complete bool   `json:"complete"`
	}
	json.Unmarshal(signedRes, &signedPSBT)
	fmt.Printf("5. Cold Signer Processed PSBT (Complete=%v)\n", signedPSBT.Complete)

	// 6. Finalize PSBT & Broadcast raw transaction to bitcoind mempool
	finalRes, err := client.Call("", "finalizepsbt", signedPSBT.PSBT)
	if err != nil {
		panic(err)
	}
	var finalized struct {
		Hex      string `json:"hex"`
		Complete bool   `json:"complete"`
	}
	json.Unmarshal(finalRes, &finalized)

	txidRes, err := client.Call("", "sendrawtransaction", finalized.Hex)
	if err != nil {
		panic(err)
	}
	var spendTxid string
	json.Unmarshal(txidRes, &spendTxid)
	_, _ = client.Call("", "generatetoaddress", 1, minerAddr)
	fmt.Printf("6. Finalized & Broadcasted Sovereign Settlement TXID: %s\n", spendTxid)
}
