package main

import (
	"crypto/sha256"
	"os"
	"strings"
	"testing"
)

func TestRequiredBitcoinSkillsForLightningCompleteness(t *testing.T) {
	skills := RequiredBitcoinSkillsForLightning()
	if len(skills) != 6 {
		t.Fatalf("expected 6 foundational Bitcoin Core prerequisites for Lightning, got %d", len(skills))
	}
}

func TestChannelBalanceConservationAndRevocationPenalty(t *testing.T) {
	s0 := &ChannelState{
		StateNum:     0,
		CapacitySats: 1_000_000,
		AliceSats:    1_000_000,
		BobSats:      0,
	}

	if _, err := UpdateChannelBalance(s0, 2_000_000, [32]byte{}); err == nil {
		t.Fatalf("expected payment exceeding outbound liquidity to fail")
	}

	secret0 := sha256.Sum256([]byte("revoke_state_0"))
	s1, err := UpdateChannelBalance(s0, 400_000, secret0)
	if err != nil {
		t.Fatal(err)
	}
	if !s0.IsRevoked {
		t.Fatalf("expected previous state s0 to be marked revoked")
	}
	if s1.AliceSats != 600_000 || s1.BobSats != 400_000 {
		t.Fatalf("expected 600k/400k split, got %d/%d", s1.AliceSats, s1.BobSats)
	}

	aliceOut, bobOut, outcome := EvaluateBroadcastedCommitment(s0, 105, 100, 144)
	if aliceOut != 0 || bobOut != 1_000_000 || !strings.Contains(outcome, "JUSTICE_PENALTY_APPLIED") {
		t.Fatalf("expected Bob to sweep 100%% of channel via revocation penalty, got alice=%d bob=%d (%s)", aliceOut, bobOut, outcome)
	}

	aliceEarly, bobEarly, earlyOutcome := EvaluateBroadcastedCommitment(s1, 110, 100, 144)
	if aliceEarly != 0 || bobEarly != 400_000 || !strings.Contains(earlyOutcome, "TIMELOCK_ACTIVE") {
		t.Fatalf("expected Alice's to_local output to be locked by OP_CSV before 144 blocks")
	}

	aliceMatured, bobMatured, _ := EvaluateBroadcastedCommitment(s1, 250, 100, 144)
	if aliceMatured != 600_000 || bobMatured != 400_000 {
		t.Fatalf("expected 600k/400k after OP_CSV maturity, got %d/%d", aliceMatured, bobMatured)
	}
}

func TestInspectLocalPolarNetworksIfPresent(t *testing.T) {
	if _, err := os.Stat("/Users/mac/.polar/networks/networks.json"); err == nil {
		nets, err := InspectLocalPolarNetworks("/Users/mac/.polar")
		if err != nil {
			t.Fatalf("failed to parse ~/.polar/networks/networks.json: %v", err)
		}
		if len(nets) < 1 {
			t.Fatalf("expected at least 1 configured Polar network")
		}
	}
}
