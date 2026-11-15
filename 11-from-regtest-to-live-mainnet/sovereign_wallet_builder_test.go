package main

import "testing"

func TestAllBitcoinNetworksGraduationLadder(t *testing.T) {
	nets := AllBitcoinNetworks()
	if len(nets) != 4 {
		t.Fatalf("expected 4 networks (regtest, signet, testnet4, mainnet), got %d", len(nets))
	}
	want := []struct {
		flag, hrp string
		p2p, rpc  int
	}{
		{"-regtest", "bcrt1", 18444, 18443},
		{"-signet", "tb1", 38333, 38332},
		{"-testnet4", "tb1", 48333, 48332},
		{"(none)", "bc1", 8333, 8332},
	}
	for i, w := range want {
		n := nets[i]
		if n.CLIFlag != w.flag || n.Bech32HRP != w.hrp || n.DefaultPort != w.p2p || n.RPCPort != w.rpc {
			t.Errorf("network %d: got flag=%q hrp=%q p2p=%d rpc=%d; check chainparams(base).cpp", i, n.CLIFlag, n.Bech32HRP, n.DefaultPort, n.RPCPort)
		}
	}
}

func TestEstimateTxVBytes(t *testing.T) {
	cases := []struct {
		typ      string
		in, out  int
		want     int
	}{
		{"legacy", 1, 2, 226},  // 10 + 148 + 2*34
		{"p2pkh", 2, 1, 340},   // 10 + 2*148 + 34
		{"bc1q", 1, 2, 141},    // ceil(10.5 + 68 + 62)
		{"segwit", 2, 2, 209},  // ceil(10.5 + 136 + 62) = 208.5 -> 209
		{"p2wpkh", 1, 1, 110},  // ceil(10.5 + 68 + 31) = 109.5 -> 110
		{"bc1p", 1, 1, 111},    // ceil(10.5 + 57.5 + 43)
		{"taproot", 5, 2, 384}, // 10.5 + 287.5 + 86 = 384 exactly
		{"unknown", 1, 2, 141}, // falls back to p2wpkh
		{"BC1Q", 1, 2, 141},    // case-insensitive
	}
	for _, c := range cases {
		if got := EstimateTxVBytes(c.typ, c.in, c.out); got != c.want {
			t.Errorf("EstimateTxVBytes(%q,%d,%d) = %d, want %d", c.typ, c.in, c.out, got, c.want)
		}
	}
	if EstimateTxVBytes("bc1q", 1, 2) >= EstimateTxVBytes("legacy", 1, 2) {
		t.Error("segwit must be smaller than legacy")
	}
}
