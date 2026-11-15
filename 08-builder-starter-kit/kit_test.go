package builderkit

// Outcome checker for Stage 08. Do not edit the tests to make them pass.

import (
	"encoding/hex"
	"encoding/json"
	"errors"
	"io"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
)

func h(t *testing.T, s string) []byte {
	t.Helper()
	b, err := hex.DecodeString(s)
	if err != nil {
		t.Fatal(err)
	}
	return b
}

func TestAmounts_FormatAndParse(t *testing.T) {
	ok := map[int64]string{0: "0.00000000", 1: "0.00000001", 50_000: "0.00050000", SatsPerBTC: "1.00000000", MaxMoneySats: "21000000.00000000"}
	for sats, s := range ok {
		got, err := FormatBTC(sats)
		if err != nil || got != s {
			t.Errorf("FormatBTC(%d) = %q (%v), want %q", sats, got, err, s)
		}
		back, err := ParseBTC(s)
		if err != nil || back != sats {
			t.Errorf("ParseBTC(%q) = %d (%v), want %d", s, back, err, sats)
		}
	}
	if v, err := ParseBTC("0.1"); err != nil || v != 10_000_000 {
		t.Errorf("ParseBTC(0.1) = %d (%v): never use float64 for money", v, err)
	}
	if v, err := ParseBTC("21000000"); err != nil || v != MaxMoneySats {
		t.Errorf("ParseBTC(21000000) = %d (%v)", v, err)
	}
	for _, bad := range []int64{-1, MaxMoneySats + 1} {
		if _, err := FormatBTC(bad); err == nil {
			t.Errorf("FormatBTC(%d) must fail", bad)
		}
	}
	for _, bad := range []string{"", "-1", "+1", "1.000000001", "21000000.00000001", "99999999999", ".5", "1.", "1e-8", "0x10", "1,5", " 1", "1.2.3", "NaN"} {
		if v, err := ParseBTC(bad); err == nil {
			t.Errorf("ParseBTC(%q) must fail, got %d", bad, v)
		}
	}
}

func TestDust_MatchesGetDustThreshold(t *testing.T) {
	const rate = 3000 // DUST_RELAY_TX_FEE, sat/kvB (src/policy/policy.h)
	p2pkh := h(t, "76a914"+strings.Repeat("11", 20)+"88ac")
	p2wpkh := h(t, "0014"+strings.Repeat("11", 20))
	p2wsh := h(t, "0020"+strings.Repeat("11", 32))
	p2tr := h(t, "5120"+strings.Repeat("11", 32))
	p2sh := h(t, "a914"+strings.Repeat("11", 20)+"87")
	opret := h(t, "6a0401020304")
	cases := []struct {
		name string
		spk  []byte
		want int64
	}{
		{"p2pkh (comment in policy.cpp: 546)", p2pkh, 546},
		{"p2wpkh (comment in policy.cpp: 294)", p2wpkh, 294},
		{"p2wsh", p2wsh, 330},
		{"p2tr", p2tr, 330},
		{"p2sh", p2sh, 540},
		{"OP_RETURN is unspendable -> 0", opret, 0},
	}
	for _, c := range cases {
		if got := DustThreshold(c.spk, rate); got != c.want {
			t.Errorf("%s: DustThreshold = %d, want %d", c.name, got, c.want)
		}
	}
	if !IsDust(293, p2wpkh, rate) || IsDust(294, p2wpkh, rate) {
		t.Errorf("IsDust boundary: value < threshold is dust, value == threshold is not")
	}
	// Not a witness program: version byte OP_1 but length byte does not match.
	fake := h(t, "5121"+strings.Repeat("11", 32))
	if DustThreshold(fake, rate) == 330 {
		t.Errorf("0x51 0x21 + 32 bytes is NOT a witness program (length byte must equal len-2)")
	}
	// Rounding: Core's GetFee rounds UP (std::ceil).
	if got := DustThreshold(p2wpkh, 1001); got != 99 { // 98 * 1001 / 1000 = 98.098 -> 99
		t.Errorf("fee must be rounded up: got %d want 99", got)
	}
}

func TestOPReturn_PushEncodingAndPolicyLimit(t *testing.T) {
	s, err := BuildOPReturnScript(make([]byte, 32), 83)
	if err != nil || hex.EncodeToString(s[:2]) != "6a20" || len(s) != 34 {
		t.Fatalf("32-byte payload: want 6a20<32 bytes>, got %x (%v)", s, err)
	}
	s, err = BuildOPReturnScript(make([]byte, 80), 83)
	if err != nil || hex.EncodeToString(s[:3]) != "6a4c50" || len(s) != 83 {
		t.Fatalf("80-byte payload needs OP_PUSHDATA1 and fits 29.x's 83-byte MAX_OP_RETURN_RELAY: %x (%v)", s[:3], err)
	}
	if _, err := BuildOPReturnScript(make([]byte, 81), 83); err == nil {
		t.Fatalf("81-byte payload makes an 84-byte script: must exceed an 83-byte limit")
	}
	s, err = BuildOPReturnScript(make([]byte, 300), 100_000)
	if err != nil || hex.EncodeToString(s[:4]) != "6a4d2c01" {
		t.Fatalf("300-byte payload needs OP_PUSHDATA2 little-endian length 2c01: %x (%v)", s[:4], err)
	}
	if s, err := BuildOPReturnScript(nil, 83); err != nil || hex.EncodeToString(s) != "6a" {
		t.Fatalf("empty payload is a bare OP_RETURN: %x (%v)", s, err)
	}
}

func TestBIP21_BuildAndParse(t *testing.T) {
	const addr = "bcrt1q9k8m86ek5azkjcnds3snf6jnxutqld420yk5pa"
	uri, err := BuildBIP21(addr, 50_000, "Kisumu Peer", "")
	if err != nil {
		t.Fatal(err)
	}
	if uri != "bitcoin:"+addr+"?amount=0.00050000&label=Kisumu%20Peer" {
		t.Fatalf("got %s (spaces must be %%20, not '+': BIP21 uses RFC 3986)", uri)
	}
	if u, _ := BuildBIP21(addr, 0, "", ""); u != "bitcoin:"+addr {
		t.Fatalf("no params -> no '?': got %s", u)
	}
	if u, _ := BuildBIP21(addr, 1, "a&b=c", ""); !strings.Contains(u, "label=a%26b%3Dc") {
		t.Fatalf("& and = inside a label must be escaped: %s", u)
	}
	p, err := ParseBIP21("BITCOIN:" + addr + "?amount=20.3&label=Luke%20Jr&message=Donation")
	if err != nil || p.Address != addr || p.Sats != 2_030_000_000 || p.Label != "Luke Jr" || p.Message != "Donation" {
		t.Fatalf("ParseBIP21: %+v %v", p, err)
	}
	if _, err := ParseBIP21("bitcoin:" + addr + "?req-somethingyoudontunderstand=50&req-somethingelse=x"); err == nil {
		t.Errorf("unknown req- parameter must make the URI invalid (BIP21)")
	}
	if p, err := ParseBIP21("bitcoin:" + addr + "?somethingyoudontunderstand=50"); err != nil || p.Address != addr {
		t.Errorf("unknown optional parameters must be ignored: %v", err)
	}
	for _, bad := range []string{"bitcoin:" + addr + "?amount=1&amount=2", "bitcoin:" + addr + "?amount=-1", "bitcoin:?amount=1", "litecoin:" + addr, "bitcoin:" + addr + "?amount=0.000000001"} {
		if _, err := ParseBIP21(bad); err == nil {
			t.Errorf("%q must be rejected", bad)
		}
	}
	if _, err := BuildBIP21("bad?addr", 1, "", ""); err == nil {
		t.Errorf("address containing '?' must be rejected")
	}
}

func TestRPC_CookieAndClient(t *testing.T) {
	u, p, err := ParseCookie("__cookie__:abc:def\n")
	if err != nil || u != "__cookie__" || p != "abc:def" {
		t.Fatalf("split at the FIRST colon only: %q %q %v", u, p, err)
	}
	for _, bad := range []string{"", "nocolon", ":pw", "user:"} {
		if _, _, err := ParseCookie(bad); err == nil {
			t.Errorf("ParseCookie(%q) must fail", bad)
		}
	}

	var gotPath, gotUser, gotPass string
	var gotBody map[string]any
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		gotPath = r.URL.EscapedPath()
		gotUser, gotPass, _ = r.BasicAuth()
		b, _ := io.ReadAll(r.Body)
		_ = json.Unmarshal(b, &gotBody)
		if gotPass != "secret" {
			w.WriteHeader(http.StatusUnauthorized) // bitcoind sends 401 with an empty body
			return
		}
		switch gotBody["method"] {
		case "getblockcount":
			io.WriteString(w, `{"result":101,"error":null,"id":"lab"}`)
		default:
			w.WriteHeader(http.StatusNotFound) // bitcoind uses HTTP 404 for "method not found"
			io.WriteString(w, `{"result":null,"error":{"code":-32601,"message":"Method not found"},"id":"lab"}`)
		}
	}))
	defer srv.Close()

	c := &RPCClient{BaseURL: srv.URL, User: "__cookie__", Pass: "secret"}
	res, err := c.Call("my wallet/1", "getblockcount")
	if err != nil || string(res) != "101" {
		t.Fatalf("Call: %s %v", res, err)
	}
	if gotPath != "/wallet/my%20wallet%2F1" {
		t.Errorf("wallet name must be path-escaped: got %s", gotPath)
	}
	if gotUser != "__cookie__" {
		t.Errorf("basic auth user not sent")
	}
	if params, ok := gotBody["params"].([]any); !ok || len(params) != 0 {
		t.Errorf("params must be an empty JSON array, not null: %v", gotBody["params"])
	}
	if c.Endpoint("") != srv.URL+"/" {
		t.Errorf("Endpoint(\"\") = %s", c.Endpoint(""))
	}

	_, err = c.Call("", "nosuchmethod")
	var rpcErr *RPCError
	if !errors.As(err, &rpcErr) || rpcErr.Code != -32601 {
		t.Errorf("HTTP 404 with a JSON error body must surface as *RPCError code -32601, got %v", err)
	}
	bad := &RPCClient{BaseURL: srv.URL, User: "x", Pass: "wrong"}
	if _, err := bad.Call("", "getblockcount"); err == nil || !strings.Contains(strings.ToLower(err.Error()), "unauthorized") {
		t.Errorf("401 must produce an 'unauthorized' error, got %v", err)
	}
}
