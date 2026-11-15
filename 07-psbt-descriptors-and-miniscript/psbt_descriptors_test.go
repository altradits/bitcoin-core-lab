package psbtlab

// Outcome checker for Stage 07. Vectors come from BIP380, BIP174 and
// src/test/descriptor_tests.cpp. Do not edit the tests to make them pass.

import (
	"encoding/base64"
	"strings"
	"testing"
)

// From src/test/descriptor_tests.cpp (CheckUnparsable error messages name the checksums).
const coreMultiXpub = "sh(multi(2,[00000000/111'/222]xpub6ERApfZwUNrhLCkDtcHTcxd75RbzS1ed54G1LkBUHQVHQKqhMkhgbmJbZRkrgZw4koxb5JaHWkY4ALHY2grBGRjaDMzQLcgJvLJuZZvRcEL,xpub68NZiKmJWnxxS6aaHmn81bvJeTESw724CRDs6HbuccFQN9Ku14VQrADWgqbhhTHBaohPX4CjNLf9fq9MYo6oDaPPLPxSb7gwQN3ih19Zm4Y/0))"

func TestA_DescriptorChecksumVectors(t *testing.T) {
	cases := map[string]string{
		"raw(deadbeef)": "89f8spxm", // BIP380
		coreMultiXpub:   "tjg09x5t", // descriptor_tests.cpp
		strings.Replace(coreMultiXpub, "multi(2,", "multi(3,", 1): "d4x0uxyv",
		"wsh(and_v(vc:andor(pk(03cdabb7f2dce7bfbd8a0b9570c6fd1e712e5d64045e9d6b517b3d5072251dc204),pk_k(032707170c71d8f75e4ca4e3fce870b9409dcaf12b051d3bcadff74747fa7619c0),and_v(v:older(1),pk_k(02aa27e5eb2c185e87cd1dbc3e0efc9cb1175235e0259df1713424941c3cb40402))),after(10)))": "tyzp6a7p",
	}
	for desc, want := range cases {
		got, err := DescriptorChecksum(desc)
		if err != nil || got != want {
			t.Errorf("DescriptorChecksum(%.30s...) = %q (%v), want %q", desc, got, err, want)
		}
	}
	if s, err := AddChecksum("raw(deadbeef)"); err != nil || s != "raw(deadbeef)#89f8spxm" {
		t.Errorf("AddChecksum = %q (%v)", s, err)
	}
	if _, err := DescriptorChecksum("raw(Ü)"); err == nil {
		t.Errorf("non-ASCII payload must be rejected (BIP380: invalid characters in payload)")
	}
}

func TestA_CheckDescriptorChecksum(t *testing.T) {
	if p, err := CheckDescriptorChecksum("raw(deadbeef)#89f8spxm", true); err != nil || p != "raw(deadbeef)" {
		t.Fatalf("valid descriptor rejected: %q %v", p, err)
	}
	if p, err := CheckDescriptorChecksum("raw(deadbeef)", false); err != nil || p != "raw(deadbeef)" {
		t.Fatalf("checksum is optional when requireChecksum=false: %q %v", p, err)
	}
	bad := map[string]string{
		"raw(deadbeef)":           "Missing checksum",
		"raw(deadbeef)#":          "Expected 8 character checksum, not 0 characters",
		"raw(deadbeef)#89f8spxmx": "Expected 8 character checksum, not 9 characters",
		"raw(deadbeef)#89f8spx":   "Expected 8 character checksum, not 7 characters",
		"raw(deedbeef)#89f8spxm":  "does not match computed checksum",
		"raw(deadbeef)##89f8spxm": "Multiple '#' symbols",
		"raw(Ü)#00000000":         "Invalid characters in payload",
	}
	for in, wantSub := range bad {
		_, err := CheckDescriptorChecksum(in, true)
		if err == nil || !strings.Contains(err.Error(), wantSub) {
			t.Errorf("%q: want error containing %q, got %v", in, wantSub, err)
		}
	}
}

func TestB_ParseAndFormatKeyPath(t *testing.T) {
	p, err := ParseKeyPath("m/84h/1'/0h/0/5")
	if err != nil {
		t.Fatalf("ParseKeyPath: %v", err)
	}
	want := []uint32{84 | HardenedBit, 1 | HardenedBit, 0 | HardenedBit, 0, 5}
	if len(p) != len(want) {
		t.Fatalf("got %v want %v", p, want)
	}
	for i := range want {
		if p[i] != want[i] {
			t.Fatalf("element %d: got %#x want %#x", i, p[i], want[i])
		}
	}
	if FormatKeyPath(p) != "m/84h/1h/0h/0/5" {
		t.Fatalf("FormatKeyPath = %q (Core's FormatHDKeypath uses 'h' by default)", FormatKeyPath(p))
	}
	if p2, err := ParseKeyPath("84h/0h/0h"); err != nil || len(p2) != 3 {
		t.Fatalf("descriptor key origins omit the leading m: %v %v", p2, err)
	}
	if p3, err := ParseKeyPath("2147483647h"); err != nil || p3[0] != 0xffffffff {
		t.Fatalf("2^31-1 hardened is the largest valid element: %v %v", p3, err)
	}
	bad := map[string]string{
		"m/2147483648": "out of range (>= 2^31 would collide with the hardened bit)",
		"m/4294967296": "not a uint32",
		"m/-1":         "negative",
		"m/1x":         "garbage suffix",
		"m/1hh":        "double hardened marker",
		"m/0/":         "empty element",
		"m/m/0":        "second m",
		"m/1'h":        "two markers",
		"":             "empty string",
		"m/ 1":         "whitespace",
	}
	for in, why := range bad {
		if _, err := ParseKeyPath(in); err == nil {
			t.Errorf("%q must be rejected (%s)", in, why)
		}
	}
}

func TestC_BIP174ValidVectors(t *testing.T) {
	for _, v := range bip174Valid {
		if _, err := ParsePSBT(v.b64); err != nil {
			t.Errorf("valid vector %q rejected: %v", v.why, err)
		}
	}
	s, err := ParsePSBT(bip174Valid[1].b64) // P2PKH + P2SH-P2WPKH, first input finalized
	if err != nil {
		t.Fatalf("%v", err)
	}
	if s.NumInputs != 2 || len(s.Inputs) != 2 || s.NumOutputs != 2 || len(s.Outputs) != 2 {
		t.Fatalf("expected 2 inputs / 2 outputs, got %+v", s)
	}
	// BIP174: the Finalizer clears everything except the UTXO and final fields; this
	// vector's finalized input keeps only its final scriptSig.
	if !s.Inputs[0].HasFinalScriptSig || s.Inputs[0].PartialSigs != 0 {
		t.Fatalf("input 0 must be finalized with no partial sigs left: %+v", s.Inputs[0])
	}
	if !s.Inputs[1].HasWitnessUTXO {
		t.Fatalf("input 1 (P2SH-P2WPKH) must carry a witness UTXO: %+v", s.Inputs[1])
	}
	s2, _ := ParsePSBT(bip174Valid[2].b64) // P2SH-P2WSH 2-of-2 with one signature
	if len(s2.Inputs) != 1 || s2.Inputs[0].PartialSigs != 1 || s2.Inputs[0].BIP32Derivations != 2 {
		t.Fatalf("expected 1 partial sig and 2 keypaths, got %+v", s2.Inputs)
	}
	s3, _ := ParsePSBT(bip174Valid[4].b64) // unknown types
	if len(s3.Inputs) != 1 || s3.Inputs[0].UnknownKeys == 0 {
		t.Fatalf("unknown key types must be kept (counted), not rejected: %+v", s3.Inputs)
	}
	s4, _ := ParsePSBT(bip174Valid[5].b64)
	if s4.NumInputs != 0 || s4.NumOutputs != 0 {
		t.Fatalf("0-in/0-out vector parsed wrong: %+v", s4)
	}
}

func TestC_BIP174InvalidVectors(t *testing.T) {
	if _, err := ParsePSBT(bip174Valid[0].b64); err != nil {
		t.Fatalf("sanity: valid vector rejected: %v", err)
	}
	for _, v := range bip174Invalid {
		if _, err := ParsePSBT(v.b64); err == nil {
			t.Errorf("invalid vector accepted: %s", v.why)
		}
	}
	extra := []string{
		base64.StdEncoding.EncodeToString([]byte("not_a_psbt")),
		"cHNidP8", // magic only, no global map
		"%%%not-base64%%%",
		"",
	}
	for _, e := range extra {
		if _, err := ParsePSBT(e); err == nil {
			t.Errorf("%q must be rejected", e)
		}
	}
	// Trailing junk after a valid PSBT: Core's DecodeRawPSBT says "extra data after PSBT".
	raw, _ := base64.StdEncoding.DecodeString(bip174Valid[0].b64)
	junk := base64.StdEncoding.EncodeToString(append(raw, 0x00))
	if _, err := ParsePSBT(junk); err == nil {
		t.Errorf("trailing bytes after the last output map must be rejected")
	}
}

func TestC_NextRoleLikeAnalyzePSBT(t *testing.T) {
	cases := []struct {
		s    PSBTSummary
		want string
	}{
		{PSBTSummary{NumInputs: 1, Inputs: []PSBTInput{{}}}, "updater"},
		{PSBTSummary{NumInputs: 1, Inputs: []PSBTInput{{HasWitnessUTXO: true}}}, "signer"},
		{PSBTSummary{NumInputs: 1, Inputs: []PSBTInput{{HasWitnessUTXO: true, PartialSigs: 1}}}, "finalizer"},
		{PSBTSummary{NumInputs: 1, Inputs: []PSBTInput{{HasWitnessUTXO: true, HasFinalScriptWit: true}}}, "extractor"},
		// The PSBT goes to the role needed by its LEAST advanced input.
		{PSBTSummary{NumInputs: 2, Inputs: []PSBTInput{{HasFinalScriptSig: true}, {HasNonWitnessUTXO: true}}}, "signer"},
		{PSBTSummary{}, "extractor"},
	}
	for i, c := range cases {
		if got := NextRole(c.s); got != c.want {
			t.Errorf("case %d: NextRole = %q, want %q", i, got, c.want)
		}
	}
	s, _ := ParsePSBT(bip174Valid[0].b64)
	if NextRole(s) != "signer" {
		t.Errorf("BIP174 'one P2PKH input' vector has the UTXO but no sigs: want signer, got %q", NextRole(s))
	}
}
