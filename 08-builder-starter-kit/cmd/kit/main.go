// The HTTP shell around YOUR kit.go. It only wires your functions to bitcoind; all
// Bitcoin logic (amounts, dust, BIP21, OP_RETURN, the RPC client) is code you write.
//
//	go run ./cmd/kit            # serve on 127.0.0.1:8080 against regtest
//	go run ./cmd/kit -check     # one getblockcount through YOUR RPC client
//
// Env overrides: BITCOIND_RPC_URL, BITCOIN_COOKIE, BUILDER_LISTEN_ADDR.
package main

import (
	"encoding/hex"
	"encoding/json"
	"flag"
	"fmt"
	"log"
	"net/http"
	"os"
	"path/filepath"

	kit "github.com/altradits/bitcoin-core-lab/08-builder-starter-kit"
)

// envOr returns the environment variable key, or def when it is unset.
func envOr(key, def string) string {
	if v := os.Getenv(key); v != "" {
		return v
	}
	return def
}

// cookiePath finds the regtest cookie. BITCOIN_COOKIE wins, for custom datadirs.
func cookiePath() string {
	if explicit := os.Getenv("BITCOIN_COOKIE"); explicit != "" {
		return explicit
	}
	home, _ := os.UserHomeDir()
	for _, p := range []string{
		filepath.Join(home, "Library", "Application Support", "Bitcoin", "regtest", ".cookie"),
		filepath.Join(home, ".bitcoin", "regtest", ".cookie"),
	} {
		if _, err := os.Stat(p); err == nil {
			return p
		}
	}
	return ""
}

func main() {
	check := flag.Bool("check", false, "call getblockcount once and exit")
	wallet := flag.String("wallet", "w07_watch", "watch-only wallet used for invoices")
	flag.Parse()

	p := cookiePath()
	if p == "" {
		log.Fatal("no regtest .cookie found: start YOUR bitcoind -regtest first")
	}
	raw, err := os.ReadFile(p)
	if err != nil {
		log.Fatal(err)
	}
	user, pass, err := kit.ParseCookie(string(raw))
	if err != nil {
		log.Fatal(err)
	}
	rpc := &kit.RPCClient{BaseURL: envOr("BITCOIND_RPC_URL", "http://127.0.0.1:18443"), User: user, Pass: pass}

	if *check {
		res, err := rpc.Call("", "getblockcount")
		if err != nil {
			log.Fatal(err)
		}
		fmt.Println("getblockcount via your client:", string(res))
		return
	}

	mux := http.NewServeMux()
	mux.HandleFunc("POST /api/invoice", func(w http.ResponseWriter, r *http.Request) {
		var req struct {
			AmountBTC string `json:"amount_btc"`
			Label     string `json:"label"`
		}
		if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
			http.Error(w, err.Error(), http.StatusBadRequest)
			return
		}
		sats, err := kit.ParseBTC(req.AmountBTC)
		if err != nil {
			http.Error(w, err.Error(), http.StatusBadRequest)
			return
		}
		res, err := rpc.Call(*wallet, "getnewaddress", req.Label, "bech32")
		if err != nil {
			http.Error(w, err.Error(), http.StatusBadGateway)
			return
		}
		var addr string
		_ = json.Unmarshal(res, &addr)
		uri, err := kit.BuildBIP21(addr, sats, req.Label, "")
		if err != nil {
			http.Error(w, err.Error(), http.StatusBadRequest)
			return
		}
		_ = json.NewEncoder(w).Encode(map[string]any{"address": addr, "sats": sats, "bip21": uri})
	})
	mux.HandleFunc("POST /api/opreturn", func(w http.ResponseWriter, r *http.Request) {
		var req struct {
			Hex string `json:"data_hex"`
		}
		if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
			http.Error(w, err.Error(), http.StatusBadRequest)
			return
		}
		data, err := hex.DecodeString(req.Hex)
		if err != nil {
			http.Error(w, err.Error(), http.StatusBadRequest)
			return
		}
		s, err := kit.BuildOPReturnScript(data, 83) // 29.x MAX_OP_RETURN_RELAY; see README
		if err != nil {
			http.Error(w, err.Error(), http.StatusBadRequest)
			return
		}
		_ = json.NewEncoder(w).Encode(map[string]string{"script_hex": hex.EncodeToString(s)})
	})
	addr := envOr("BUILDER_LISTEN_ADDR", "127.0.0.1:8080")
	log.Printf("listening on http://%s (POST /api/invoice, POST /api/opreturn)", addr)
	log.Fatal(http.ListenAndServe(addr, mux))
}
