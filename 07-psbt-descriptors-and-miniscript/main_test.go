package main

import (
	"encoding/base64"
	"os"
	"path/filepath"
	"testing"
)

func TestValidateBIP174Header(t *testing.T) {
	// Valid BIP174 magic bytes: 0x70736274ff ("psbt\xff") followed by global unsigned tx key 0x0100
	validBytes := []byte{0x70, 0x73, 0x62, 0x74, 0xff, 0x01, 0x00}
	encoded := base64.StdEncoding.EncodeToString(validBytes)

	decoded, err := ValidateBIP174Header(encoded)
	if err != nil {
		t.Fatalf("expected valid BIP174 header, got error: %v", err)
	}
	if len(decoded) != len(validBytes) {
		t.Fatalf("unexpected decoded length: %d", len(decoded))
	}

	// Invalid magic header
	badEncoded := base64.StdEncoding.EncodeToString([]byte("not_a_psbt"))
	if _, err := ValidateBIP174Header(badEncoded); err == nil {
		t.Fatalf("expected error for invalid BIP174 magic header")
	}
}

func TestValidateSatsOutputConsensusBounds(t *testing.T) {
	if err := ValidateSatsOutput(100_000); err != nil {
		t.Fatalf("unexpected error for valid satoshi output: %v", err)
	}
	if err := ValidateSatsOutput(200); err == nil {
		t.Fatalf("expected dust rejection for 200 sats (< 546 sats)")
	}
	if err := ValidateSatsOutput(21_000_001 * 100_000_000); err == nil {
		t.Fatalf("expected consensus MAX_MONEY rejection for > 21M BTC")
	}
}

func TestRPCBaseURLDefaultAndOverride(t *testing.T) {
	t.Setenv("BITCOIND_RPC_URL", "")
	if got := rpcBaseURL(); got != "http://127.0.0.1:18443" {
		t.Fatalf("default RPC URL = %q, want default regtest port", got)
	}
	t.Setenv("BITCOIND_RPC_URL", "http://127.0.0.1:28332")
	if got := rpcBaseURL(); got != "http://127.0.0.1:28332" {
		t.Fatalf("override RPC URL = %q, want env value", got)
	}
}

func TestLoadRegtestAuthExplicitCookie(t *testing.T) {
	dir := t.TempDir()
	cookiePath := filepath.Join(dir, ".cookie")
	if err := os.WriteFile(cookiePath, []byte("testuser:testpass"), 0600); err != nil {
		t.Fatal(err)
	}
	t.Setenv("BITCOIN_COOKIE", cookiePath)
	user, pass, err := loadRegtestAuth()
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if user != "testuser" || pass != "testpass" {
		t.Fatalf("got %q:%q, want testuser:testpass", user, pass)
	}
}
