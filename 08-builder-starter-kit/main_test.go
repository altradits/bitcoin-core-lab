package main

import (
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
