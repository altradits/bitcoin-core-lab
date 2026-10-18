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

func TestGenerateLaptopMainnetConfigSafety(t *testing.T) {
	cfg := GenerateLaptopMainnetConfig()
	if !strings.Contains(cfg, "prune=5500") {
		t.Fatalf("expected laptop mainnet config to include prune=5500 so it fits on a standard SSD")
	}
	if !strings.Contains(cfg, "rpcallowip=127.0.0.1") {
		t.Fatalf("expected localhost-only RPC binding")
	}
}
