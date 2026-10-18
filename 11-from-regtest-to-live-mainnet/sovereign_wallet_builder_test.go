package main

import (
	"strings"
	"testing"
)

func TestAllBitcoinNetworksGraduationLadder(t *testing.T) {
	nets := AllBitcoinNetworks()
	if len(nets) != 4 {
		t.Fatalf("expected 4 Bitcoin networks, got %d", len(nets))
	}
	if nets[0].Bech32HRP != "bcrt1" {
		t.Fatalf("expected regtest prefix bcrt1, got %s", nets[0].Bech32HRP)
	}
	if nets[1].CLIFlag != "-signet" || nets[1].Bech32HRP != "tb1" {
		t.Fatalf("expected signet flag -signet and prefix tb1")
	}
	if nets[3].Bech32HRP != "bc1" || nets[3].DefaultPort != 8333 {
		t.Fatalf("expected mainnet prefix bc1 and port 8333")
	}
}

func TestGenerateLaptopMainnetConfigM1Safety(t *testing.T) {
	cfg := GenerateLaptopMainnetConfig()
	if !strings.Contains(cfg, "prune=5500") {
		t.Fatalf("expected M1 MacBook Air config to include prune=5500 for 68 GB free SSD")
	}
	if !strings.Contains(cfg, "dbcache=1024") || !strings.Contains(cfg, "par=4") {
		t.Fatalf("expected M1 MacBook Air config to include dbcache=1024 and par=4")
	}
	if !strings.Contains(cfg, "walletrbf=1") {
		t.Fatalf("expected walletrbf=1 for fee minimization and instant bumpfee acceleration")
	}
}

func TestEstimateTxVBytesFeeMinimization(t *testing.T) {
	legacy := EstimateTxVBytes("legacy", 1, 2)
	segwit := EstimateTxVBytes("bc1q", 1, 2)
	if legacy != 226 {
		t.Fatalf("expected 1-in 2-out legacy P2PKH to be 226 vB, got %d", legacy)
	}
	if segwit != 141 {
		t.Fatalf("expected 1-in 2-out native SegWit P2WPKH to be 141 vB, got %d", segwit)
	}
	if segwit >= legacy {
		t.Fatalf("SegWit must be smaller in vBytes than legacy")
	}
}
