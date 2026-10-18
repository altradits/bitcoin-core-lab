package dojo

import (
	"math"
	"strings"
	"testing"
)

func TestMission1_ConsensusShield_CVE2010_And_CVE2018(t *testing.T) {
	// 1. Valid transaction must pass
	validTx := Transaction{
		Vin:  []OutPoint{{Txid: "abc", Vout: 0}},
		Vout: []TxOut{{Value: 50 * COIN, ScriptPubKey: "0014..."}},
	}
	if err := CheckTransactionConsensus(validTx); err != nil {
		t.Fatalf("expected valid tx to pass, got: %v", err)
	}

	// 2. CVE-2010-5139 Exploit: Two massive outputs that overflow int64 if added before range check
	overflowTx := Transaction{
		Vin: []OutPoint{{Txid: "abc", Vout: 0}},
		Vout: []TxOut{
			{Value: math.MaxInt64 - 100, ScriptPubKey: "0014..."},
			{Value: 200, ScriptPubKey: "0014..."},
		},
	}
	if err := CheckTransactionConsensus(overflowTx); err == nil {
		t.Fatalf("CVE-2010-5139 VULNERABILITY: int64 output overflow was not caught!")
	}

	// 3. Cumulative output > MAX_MONEY (each output is 15M BTC <= 21M BTC, but sum is 30M BTC > 21M BTC)
	sumExceedsMaxMoneyTx := Transaction{
		Vin: []OutPoint{{Txid: "abc", Vout: 0}},
		Vout: []TxOut{
			{Value: 15_000_000 * COIN, ScriptPubKey: "0014..."},
			{Value: 15_000_000 * COIN, ScriptPubKey: "0014..."},
		},
	}
	err := CheckTransactionConsensus(sumExceedsMaxMoneyTx)
	if err == nil || !strings.Contains(err.Error(), "bad-txns-txouttotal-toolarge") {
		t.Fatalf("expected bad-txns-txouttotal-toolarge, got: %v", err)
	}

	// 4. CVE-2018-17144 Exploit: Duplicate input spending the same UTXO twice in one tx
	dupInputTx := Transaction{
		Vin: []OutPoint{
			{Txid: "93328feb", Vout: 0},
			{Txid: "93328feb", Vout: 0}, // Duplicate!
		},
		Vout: []TxOut{{Value: 10 * COIN, ScriptPubKey: "0014..."}},
	}
	err = CheckTransactionConsensus(dupInputTx)
	if err == nil || !strings.Contains(err.Error(), "bad-txns-inputs-duplicate") {
		t.Fatalf("CVE-2018-17144 VULNERABILITY: duplicate input was not rejected! got: %v", err)
	}
}

func TestMission2_PR35320_BIP32SeedLengthValidation(t *testing.T) {
	// Weak 8-byte seed (< 16 bytes) must be rejected per BIP32 & PR #35320
	if _, _, err := DeriveBIP32MasterKey([]byte("weakseed")); err == nil {
		t.Fatalf("PR #35320 VULNERABILITY: accepted weak 8-byte seed (< 128 bits)!")
	}

	// Oversized 65-byte seed (> 64 bytes) must be rejected
	if _, _, err := DeriveBIP32MasterKey(make([]byte, 65)); err == nil {
		t.Fatalf("PR #35320 VULNERABILITY: accepted 65-byte seed (> 512 bits)!")
	}

	// Valid 32-byte (256-bit) seed must succeed
	if _, _, err := DeriveBIP32MasterKey(make([]byte, 32)); err != nil {
		t.Fatalf("expected valid 32-byte seed to succeed, got: %v", err)
	}
}

func TestMission3_PR32800_SigopAdjustedVsize(t *testing.T) {
	// Case A: Standard 1-input 2-output P2WPKH tx (weight = 561 WU, sigOpCost = 1)
	// sigOpWeight = 1 * 20 = 20 WU < 561 WU -> both vsizes are ceil(561/4) = 141 vB
	vBIP141, vAdj := ComputeMempoolVsizes(561, 1)
	if vBIP141 != 141 || vAdj != 141 {
		t.Fatalf("expected (141, 141), got (%d, %d)", vBIP141, vAdj)
	}

	// Case B: Sigop-heavy transaction (txWeight = 400 WU -> 100 vB, but sigOpCost = 80 -> sigOpWeight = 1600 WU)
	// vsizeBIP141 = 100 vB, but vsizeAdjusted = 1600 / 4 = 400 vB!
	vBIP141, vAdj = ComputeMempoolVsizes(400, 80)
	if vBIP141 != 100 || vAdj != 400 {
		t.Fatalf("PR #32800 FAILURE: expected vsize_bip141=100 and vsize_adjusted=400, got (%d, %d)", vBIP141, vAdj)
	}
}

func TestMission4_BIP125_RBF_DoSProtection(t *testing.T) {
	// Original tx: 200 sats fee, 141 vB
	// Bad replacement 1: Pays +50 sats (250 sats total) for 141 vB at 1 sat/vB relay fee -> fails Rule #4 (50 < 141)
	if err := ValidateBIP125Replacement(200, 141, 250, 141, 1); err == nil {
		t.Fatalf("BIP125 Rule #4 VULNERABILITY: allowed +50 sat replacement for 141 vB tx!")
	}

	// Bad replacement 2: Pays higher absolute fee (1000 -> 1200 sats), but is much larger (100 vB -> 200 vB),
	// lowering the feerate from 10 sat/vB to 6 sat/vB -> fails PaysMoreThanConflicts!
	if err := ValidateBIP125Replacement(1000, 100, 1200, 200, 1); err == nil {
		t.Fatalf("PaysMoreThanConflicts VULNERABILITY: allowed feerate downgrade (10 sat/vB -> 6 sat/vB)!")
	}

	// Valid replacement: 200 sats -> 5000 sats on 141 vB
	if err := ValidateBIP125Replacement(200, 141, 5000, 141, 1); err != nil {
		t.Fatalf("expected valid RBF replacement to pass, got: %v", err)
	}
}

func TestMission5_PR33014_PSBTInvalidSignatureHandling(t *testing.T) {
	corruptedExisting := []PartialSig{
		{PubKeyHex: "02aaaa", SigBytes: []byte{0x30, 0x01}, Valid: false}, // Truncated/corrupted DER sig
	}
	goodNew := PartialSig{
		PubKeyHex: "03bbbb",
		SigBytes:  make([]byte, 71),
		Valid:     true,
	}
	if _, err := ProcessPSBTPartialSignatures(corruptedExisting, goodNew); err == nil {
		t.Fatalf("PR #33014 VULNERABILITY: failed to detect corrupted existing partial signature in PSBT!")
	}

	validExisting := []PartialSig{
		{PubKeyHex: "02aaaa", SigBytes: make([]byte, 71), Valid: true},
	}
	merged, err := ProcessPSBTPartialSignatures(validExisting, goodNew)
	if err != nil || len(merged) != 2 {
		t.Fatalf("expected 2 valid merged PSBT signatures, got len=%d err=%v", len(merged), err)
	}
}
