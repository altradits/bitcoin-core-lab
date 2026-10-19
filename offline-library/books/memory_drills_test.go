package books

import (
	"bytes"
	"encoding/hex"
	"math"
	"testing"
)

func TestDrill1_EncodeSatoshisLEHex(t *testing.T) {
	got := EncodeSatoshisLEHex(50_0000_0000) // 50 BTC Genesis subsidy
	want := "00f2052a01000000"
	if got != want {
		t.Fatalf("Drill 1 Failed: EncodeSatoshisLEHex(50_0000_0000) = %q, want %q (See ./lab.sh book 1)", got, want)
	}
}

func TestDrill2_ComputeDisplayTxID(t *testing.T) {
	raw := []byte("bitcoin-from-memory")
	got := ComputeDisplayTxID(raw)
	if len(got) != 64 {
		t.Fatalf("Drill 2 Failed: expected 64-char hex txid, got %q (See ./lab.sh book 1)", got)
	}
	// Verify byte reversal against direct DoubleSHA256
	want := "a4a91d3cb7394be615d2fbefc3004bff3e38d9c96561f8d9e5a68e76eab67346"
	if got != want {
		t.Fatalf("Drill 2 Failed: ComputeDisplayTxID = %q, want %q (Did you reverse the 32 bytes? See ./lab.sh book 1)", got, want)
	}
}

func TestDrill3_WriteCompactSize(t *testing.T) {
	cases := []struct {
		v    uint64
		want string
	}{
		{252, "fc"},
		{253, "fdfd00"},
		{65535, "fdffff"},
		{65536, "fe00000100"},
	}
	for _, tc := range cases {
		got := hex.EncodeToString(WriteCompactSize(tc.v))
		if got != tc.want {
			t.Fatalf("Drill 3 Failed: WriteCompactSize(%d) = %q, want %q (See ./lab.sh book 1)", tc.v, got, tc.want)
		}
	}
}

func TestDrill4_BIP340TaggedHash(t *testing.T) {
	got := BIP340TaggedHash("TapSighash", []byte{0x01})
	var zero [32]byte
	if bytes.Equal(got[:], zero[:]) {
		t.Fatalf("Drill 4 Failed: BIP340TaggedHash returned all zeros (See ./lab.sh book 1 & book 3)")
	}
}

func TestDrill5_SafeSumOutputs(t *testing.T) {
	sum, err := SafeSumOutputs([]int64{100_000_000, 200_000_000})
	if err != nil || sum != 300_000_000 {
		t.Fatalf("Drill 5 Failed on valid outputs: sum=%d, err=%v", sum, err)
	}
	// CVE-2010-5139 overflow vector
	if _, err := SafeSumOutputs([]int64{math.MaxInt64, math.MaxInt64}); err == nil {
		t.Fatalf("Drill 5 Failed: allowed CVE-2010-5139 int64 overflow! (See ./lab.sh book 1)")
	}
	if _, err := SafeSumOutputs([]int64{MaxMoney, 1}); err == nil {
		t.Fatalf("Drill 5 Failed: allowed cumulative outputs > MAX_MONEY! (See ./lab.sh book 1)")
	}
}

func TestDrill6_CalcWeightAndVBytes(t *testing.T) {
	w, vb := CalcWeightAndVBytes(100, 109)
	if w != 509 || vb != 128 {
		t.Fatalf("Drill 6 Failed: CalcWeightAndVBytes(100, 109) = (%d, %d), want (509, 128) (See ./lab.sh book 4)", w, vb)
	}
}

func TestDrill7_IsBIP68Active(t *testing.T) {
	if IsBIP68Active(1, 10) {
		t.Fatalf("Drill 7 Failed: BIP68 should NOT be active for txVersion=1 (See ./lab.sh book 4)")
	}
	if !IsBIP68Active(2, 144) {
		t.Fatalf("Drill 7 Failed: BIP68 SHOULD be active for txVersion=2, nSequence=144")
	}
	if IsBIP68Active(2, 0x80000001) {
		t.Fatalf("Drill 7 Failed: BIP68 should be disabled when bit 31 is set")
	}
}

func TestDrill8_HasDuplicateInputs(t *testing.T) {
	op1 := OutPoint{Vout: 0}
	op2 := OutPoint{Vout: 1}
	if HasDuplicateInputs([]OutPoint{op1, op2}) {
		t.Fatalf("Drill 8 Failed: reported false duplicate on distinct inputs")
	}
	if !HasDuplicateInputs([]OutPoint{op1, op2, op1}) {
		t.Fatalf("Drill 8 Failed: missed CVE-2018-17144 duplicate input! (See ./lab.sh book 4)")
	}
}
