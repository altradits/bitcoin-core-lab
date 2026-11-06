package main

import (
	"os"
	"path/filepath"
	"strings"
	"testing"
)

func TestSatsToBTCAndBIP21(t *testing.T) {
	btc, err := SatsToBTC(50_000)
	if err != nil || btc != "0.00050000" {
		t.Fatalf("expected 0.00050000 BTC, got %s (err=%v)", btc, err)
	}

	// Dust check (< 546 sats)
	if _, err := SatsToBTC(545); err == nil {
		t.Fatalf("expected dust rejection at 545 sats")
	}

	// MAX_MONEY check (> 21,000,000 BTC)
	if _, err := SatsToBTC(MaxMoneySats + 1); err == nil {
		t.Fatalf("expected MAX_MONEY rejection")
	}

	uri, err := BuildBIP21("bcrt1q9k8m86ek5azkjcnds3snf6jnxutqld420yk5pa", 50_000, "Kisumu Peer")
	if err != nil {
		t.Fatalf("unexpected BuildBIP21 error: %v", err)
	}
	if !strings.HasPrefix(uri, "bitcoin:bcrt1q9k8m86ek5azkjcnds3snf6jnxutqld420yk5pa?amount=0.00050000") {
		t.Fatalf("unexpected BIP21 URI format: %s", uri)
	}
}

func TestBuildOPReturnScriptHex(t *testing.T) {
	digest, script := BuildOPReturnScriptHex("Chancellor on brink of second bailout for banks")
	if len(digest) != 64 {
		t.Fatalf("expected 32-byte (64 hex char) SHA-256 digest, got len=%d", len(digest))
	}
	if !strings.HasPrefix(script, "6a20") || len(script) != 68 {
		t.Fatalf("expected OP_RETURN prefix 6a20 + 64 hex chars, got %s", script)
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
