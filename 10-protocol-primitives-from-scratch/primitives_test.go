package primitives

// Outcome checker for Stage 10. These tests are the spec: do not edit them to
// make them pass. Every vector below is either taken from a BIP, from
// bitcoin/bitcoin's own unit tests (file named next to the vector), or from
// mainnet data you can re-check with `bitcoin-cli getblockheader` / `getblock`.

import (
	"bytes"
	"crypto/sha256"
	"encoding/binary"
	"encoding/hex"
	"math/big"
	"strings"
	"testing"
)

func mustHex(t *testing.T, s string) []byte {
	t.Helper()
	b, err := hex.DecodeString(s)
	if err != nil {
		t.Fatalf("bad hex in test: %v", err)
	}
	return b
}

func displayHash(t *testing.T, s string) [32]byte {
	t.Helper()
	b := mustHex(t, s)
	var h [32]byte
	for i := 0; i < 32; i++ {
		h[i] = b[31-i]
	}
	return h
}

// ---------------------------------------------------------------- Lesson 1

func TestLesson1_Hash256AndByteOrder(t *testing.T) {
	// SHA256d("") — easy to recompute with: printf '' | openssl dgst -sha256 -binary | openssl dgst -sha256
	got := Hash256(nil)
	if hex.EncodeToString(got[:]) != "5df6e0e2761359d30a8275058e299fcc0381534545f55cf43e41983f5d4c9456" {
		t.Fatalf("Hash256(\"\") wrong: %x", got)
	}

	in := []byte{1, 2, 3, 4}
	out := ReverseBytes(in)
	if !bytes.Equal(out, []byte{4, 3, 2, 1}) {
		t.Fatalf("ReverseBytes wrong: %x", out)
	}
	if !bytes.Equal(in, []byte{1, 2, 3, 4}) {
		t.Fatalf("ReverseBytes must not mutate its input (reviewer catch: aliasing bug)")
	}
	if len(ReverseBytes(nil)) != 0 {
		t.Fatalf("ReverseBytes(nil) must return an empty slice")
	}

	const genesis = "000000000019d6689c085ae165831e934ff763ae46a2a6c172b3f1b60a8ce26f"
	h, err := HashFromDisplayHex(genesis)
	if err != nil {
		t.Fatalf("HashFromDisplayHex: %v", err)
	}
	if h[0] != 0x6f || h[31] != 0x00 {
		t.Fatalf("internal byte order must be the REVERSE of display order; got first byte %02x", h[0])
	}
	if HashToDisplayHex(h) != genesis {
		t.Fatalf("display round trip failed")
	}
	if _, err := HashFromDisplayHex(genesis[:62]); err == nil {
		t.Fatalf("expected error for 31-byte hash")
	}
	if _, err := HashFromDisplayHex(strings.Repeat("zz", 32)); err == nil {
		t.Fatalf("expected error for non-hex input")
	}
}

func TestLesson1_TaggedHashBIP340(t *testing.T) {
	msg := []byte("kisumu")
	tag := sha256.Sum256([]byte("BIP0340/challenge"))
	want := sha256.Sum256(append(append(append([]byte{}, tag[:]...), tag[:]...), msg...))
	got := TaggedHash("BIP0340/challenge", msg)
	if got != want {
		t.Fatalf("TaggedHash != SHA256(SHA256(tag)||SHA256(tag)||msg)")
	}
	if TaggedHash("TapLeaf", msg) == TaggedHash("TapBranch", msg) {
		t.Fatalf("different tags must give different hashes (domain separation)")
	}
	plain := sha256.Sum256(append([]byte("BIP0340/challenge"), msg...))
	if got == plain {
		t.Fatalf("TaggedHash must not be SHA256(tag||msg)")
	}
}

// ---------------------------------------------------------------- Lesson 2

func TestLesson2_CompactSizeExactBytes(t *testing.T) {
	cases := []struct {
		n   uint64
		hex string
	}{
		{0, "00"},
		{252, "fc"},
		{253, "fdfd00"},
		{0x1234, "fd3412"}, // little-endian!
		{0xffff, "fdffff"},
		{0x10000, "fe00000100"},
		{0xffffffff, "feffffffff"},
		{0x100000000, "ff0000000001000000"},
		{0xffffffffffffffff, "ffffffffffffffffff"},
	}
	for _, c := range cases {
		enc := EncodeCompactSize(c.n)
		if hex.EncodeToString(enc) != c.hex {
			t.Errorf("EncodeCompactSize(%d) = %x, want %s", c.n, enc, c.hex)
			continue
		}
		dec, err := DecodeCompactSize(bytes.NewReader(enc), false)
		if err != nil || dec != c.n {
			t.Errorf("DecodeCompactSize(%s) = %d, %v; want %d", c.hex, dec, err, c.n)
		}
	}
}

func TestLesson2_CompactSizeRejectsBadInput(t *testing.T) {
	// A valid one first, so an always-error stub cannot pass this test.
	if v, err := DecodeCompactSize(bytes.NewReader([]byte{0xfd, 0xfd, 0x00}), true); err != nil || v != 253 {
		t.Fatalf("expected 253, got %d (%v)", v, err)
	}
	bad := map[string]string{
		"fdfc00":             "253-prefix carrying 252 (non-canonical)",
		"feffff0000":         "254-prefix carrying 0xffff (non-canonical)",
		"ffffffffff00000000": "255-prefix carrying 0xffffffff (non-canonical)",
		"":                   "empty input",
		"fd01":               "truncated 3-byte form",
		"fe010000":           "truncated 5-byte form",
	}
	for h, why := range bad {
		if _, err := DecodeCompactSize(bytes.NewReader(mustHex(t, h)), false); err == nil {
			t.Errorf("expected error for %q (%s)", h, why)
		}
	}
	// MAX_SIZE range check (src/serialize.h): 0x02000001 is a canonical encoding but too large
	// for a vector length.
	tooBig := EncodeCompactSize(MaxSize + 1)
	if _, err := DecodeCompactSize(bytes.NewReader(tooBig), true); err == nil {
		t.Errorf("expected 'size too large' with rangeCheck=true")
	}
	if v, err := DecodeCompactSize(bytes.NewReader(tooBig), false); err != nil || v != MaxSize+1 {
		t.Errorf("rangeCheck=false must accept MAX_SIZE+1, got %d (%v)", v, err)
	}
}

// ---------------------------------------------------------------- Lesson 3

// Genesis coinbase transaction (legacy serialization). txid 4a5e1e4b...
const genesisCoinbaseHex = "01000000010000000000000000000000000000000000000000000000000000000000000000ffffffff4d04ffff001d0104455468652054696d65732030332f4a616e2f32303039204368616e63656c6c6f72206f6e206272696e6b206f66207365636f6e64206261696c6f757420666f722062616e6b73ffffffff0100f2052a01000000434104678afdb0fe5548271967f1a67130b7105cd6a828e03909a67962e0ea1f61deb649f6bc3f4cef38c4f35504e51ec112de5c384df7ba0b8d578a4c702b6bf11d5fac00000000"

func TestLesson3_ParseLegacyTx(t *testing.T) {
	s, err := ParseTxSummary(mustHex(t, genesisCoinbaseHex))
	if err != nil {
		t.Fatalf("ParseTxSummary: %v", err)
	}
	if s.Version != 1 || s.NumInputs != 1 || s.NumOutputs != 1 || s.LockTime != 0 || s.HasWitness {
		t.Fatalf("unexpected summary: %+v", s)
	}
	if len(s.OutValues) != 1 || s.OutValues[0] != 50*100_000_000 {
		t.Fatalf("expected one 50 BTC output, got %v", s.OutValues)
	}
	if HashToDisplayHex(s.TxID) != "4a5e1e4baab89f3a32518a88c31bc87f618f76673e2cc77ab2127b7afdeda33b" {
		t.Fatalf("wrong txid %s", HashToDisplayHex(s.TxID))
	}
	if s.WTxID != s.TxID {
		t.Fatalf("for a non-witness tx, wtxid must equal txid")
	}
}

// buildSegwitTx returns (full serialization, stripped serialization).
func buildSegwitTx(witnessItems [][]byte) ([]byte, []byte) {
	ver := []byte{2, 0, 0, 0}
	var vin []byte
	vin = append(vin, 1)                                 // 1 input
	vin = append(vin, bytes.Repeat([]byte{0xab}, 32)...) // prevout hash
	vin = append(vin, 0, 0, 0, 0)                        // prevout index
	vin = append(vin, 0)                                 // empty scriptSig
	vin = append(vin, 0xfd, 0xff, 0xff, 0xff)            // nSequence
	var vout []byte
	vout = append(vout, 1)
	val := make([]byte, 8)
	binary.LittleEndian.PutUint64(val, 12345)
	vout = append(vout, val...)
	vout = append(vout, 22, 0x00, 0x14)
	vout = append(vout, bytes.Repeat([]byte{0x11}, 20)...)
	lock := []byte{0x65, 0, 0, 0} // 101
	var wit []byte
	wit = append(wit, byte(len(witnessItems)))
	for _, it := range witnessItems {
		wit = append(wit, byte(len(it)))
		wit = append(wit, it...)
	}
	full := append(append(append(append(append(append([]byte{}, ver...), 0x00, 0x01), vin...), vout...), wit...), lock...)
	stripped := append(append(append(append([]byte{}, ver...), vin...), vout...), lock...)
	return full, stripped
}

func TestLesson3_ParseSegwitTxTxidVsWtxid(t *testing.T) {
	full, stripped := buildSegwitTx([][]byte{bytes.Repeat([]byte{0x30}, 71), bytes.Repeat([]byte{0x02}, 33)})
	s, err := ParseTxSummary(full)
	if err != nil {
		t.Fatalf("ParseTxSummary(segwit): %v", err)
	}
	if !s.HasWitness || s.Version != 2 || s.NumInputs != 1 || s.NumOutputs != 1 || s.LockTime != 101 {
		t.Fatalf("unexpected summary: %+v", s)
	}
	if s.TxID != Hash256(stripped) {
		t.Fatalf("txid must be Hash256 of the serialization WITHOUT marker, flag and witness (BIP141)")
	}
	if s.WTxID != Hash256(full) {
		t.Fatalf("wtxid must be Hash256 of the full serialization")
	}
	if s.TxID == s.WTxID {
		t.Fatalf("txid and wtxid must differ for a tx with witness data")
	}

	// The same stripped bytes parse as a legacy tx with the same txid.
	s2, err := ParseTxSummary(stripped)
	if err != nil || s2.TxID != s.TxID || s2.HasWitness {
		t.Fatalf("stripped form must parse with identical txid; err=%v", err)
	}
}

func TestLesson3_ParseTxRejectsMalformed(t *testing.T) {
	if _, err := ParseTxSummary(mustHex(t, genesisCoinbaseHex)); err != nil {
		t.Fatalf("valid tx rejected: %v", err)
	}
	// Witness flag set but every witness stack empty -> "Superfluous witness record".
	superfluous, _ := buildSegwitTx(nil)
	if _, err := ParseTxSummary(superfluous); err == nil {
		t.Errorf("expected 'Superfluous witness record' error")
	}
	// Unknown flag value 0x02 -> "Unknown transaction optional data".
	full, _ := buildSegwitTx([][]byte{{1}})
	unknown := append([]byte{}, full...)
	unknown[5] = 0x02
	if _, err := ParseTxSummary(unknown); err == nil {
		t.Errorf("expected 'Unknown transaction optional data' error for flag 0x02")
	}
	raw := mustHex(t, genesisCoinbaseHex)
	if _, err := ParseTxSummary(raw[:len(raw)-1]); err == nil {
		t.Errorf("expected error for truncated tx")
	}
	if _, err := ParseTxSummary(append(append([]byte{}, raw...), 0x00)); err == nil {
		t.Errorf("expected error for trailing garbage")
	}
	// Input count claims 2^25 inputs with no data: must fail fast without allocating gigabytes.
	huge := append([]byte{1, 0, 0, 0}, EncodeCompactSize(MaxSize)...)
	if _, err := ParseTxSummary(huge); err == nil {
		t.Errorf("expected error for absurd input count")
	}
}

// ---------------------------------------------------------------- Lesson 4

const genesisHeaderHex = "01000000" +
	"0000000000000000000000000000000000000000000000000000000000000000" +
	"3ba3edfd7a7b12b27ac72c3e67768f617fc81bc3888a51323a9fb8aa4b1e5e4a" +
	"29ab5f49" + "ffff001d" + "1dac2b7c"

func TestLesson4_GenesisProofOfWork(t *testing.T) {
	hdr := mustHex(t, genesisHeaderHex)
	h, ok, err := VerifyBlockHeaderPoW(hdr, MainnetPowLimit())
	if err != nil {
		t.Fatal(err)
	}
	if h != "000000000019d6689c085ae165831e934ff763ae46a2a6c172b3f1b60a8ce26f" || !ok {
		t.Fatalf("genesis: got hash %s ok=%v", h, ok)
	}
	// Change the nonce: hash no longer meets the target.
	bad := append([]byte{}, hdr...)
	bad[79] ^= 0x01
	if _, ok, _ := VerifyBlockHeaderPoW(bad, MainnetPowLimit()); ok {
		t.Fatalf("modified nonce must fail PoW")
	}
	// nBits with the sign bit set (negative target) must be rejected (DeriveTarget).
	neg := append([]byte{}, hdr...)
	binary.LittleEndian.PutUint32(neg[72:76], 0x1d80ffff)
	if _, ok, _ := VerifyBlockHeaderPoW(neg, MainnetPowLimit()); ok {
		t.Fatalf("negative compact target must be rejected")
	}
	// Target easier than powLimit must be rejected even if the hash would meet it.
	easy := append([]byte{}, hdr...)
	binary.LittleEndian.PutUint32(easy[72:76], 0x2100ffff)
	if _, ok, _ := VerifyBlockHeaderPoW(easy, MainnetPowLimit()); ok {
		t.Fatalf("target above powLimit must be rejected")
	}
	if _, _, err := VerifyBlockHeaderPoW(hdr[:79], MainnetPowLimit()); err == nil {
		t.Fatalf("79-byte header must be an error")
	}
}

func TestLesson4_CompactRoundTripAndFlags(t *testing.T) {
	tgt, neg, ovf := CompactToTarget(0x1d00ffff)
	if neg || ovf || TargetToCompact(tgt) != 0x1d00ffff {
		t.Fatalf("0x1d00ffff should decode cleanly and round-trip")
	}
	want, _ := new(big.Int).SetString("00000000ffff0000000000000000000000000000000000000000000000000000", 16)
	if tgt.Cmp(want) != 0 {
		t.Fatalf("0x1d00ffff target wrong: %x", tgt)
	}
	// Vectors from src/test/arith_uint256_tests.cpp (SetCompact / GetCompact).
	cases := []struct {
		in       uint32
		wantHex  string
		back     uint32
		negative bool
	}{
		{0x01003456, "0", 0, false},
		{0x01123456, "12", 0x01120000, false},
		{0x02123456, "1234", 0x02123400, false},
		{0x02008000, "80", 0x02008000, false}, // GetCompact never sets the 0x00800000 sign bit
		{0x05009234, "92340000", 0x05009234, false},
		{0x04923456, "12345600", 0x04923456, true},
		{0x20123456, "1234560000000000000000000000000000000000000000000000000000000000", 0x20123456, false},
	}
	for _, c := range cases {
		got, n, _ := CompactToTarget(c.in)
		w, _ := new(big.Int).SetString(c.wantHex, 16)
		if got.Cmp(w) != 0 || n != c.negative {
			t.Errorf("CompactToTarget(%08x) = %x neg=%v, want %s neg=%v", c.in, got, n, c.wantHex, c.negative)
		}
		if !c.negative && TargetToCompact(got) != c.back {
			t.Errorf("TargetToCompact(%x) = %08x, want %08x", got, TargetToCompact(got), c.back)
		}
	}
	if _, _, ovf := CompactToTarget(0xff123456); !ovf {
		t.Errorf("0xff123456 must set overflow")
	}
}

func TestLesson4_RetargetMatchesCorePowTests(t *testing.T) {
	limit := MainnetPowLimit()
	// Each vector is copied from src/test/pow_tests.cpp.
	cases := []struct {
		name        string
		bits        uint32
		first, last int64
		want        uint32
	}{
		{"get_next_work", 0x1d00ffff, 1261130161, 1262152739, 0x1d00d86a},
		{"get_next_work_pow_limit", 0x1d00ffff, 1231006505, 1233061996, 0x1d00ffff},
		{"get_next_work_lower_limit_actual", 0x1c05a3f4, 1279008237, 1279297671, 0x1c0168fd},
		{"get_next_work_upper_limit_actual", 0x1c387f6f, 1263163443, 1269211443, 0x1d00e1fd},
	}
	for _, c := range cases {
		if got := CalculateNextWorkRequired(c.bits, c.first, c.last, limit); got != c.want {
			t.Errorf("%s: got %08x want %08x", c.name, got, c.want)
		}
	}
}

// ---------------------------------------------------------------- Lesson 5

func TestLesson5_MerkleRootRealBlock100000(t *testing.T) {
	txids := []string{
		"8c14f0db3df150123e6f3dbbf30f8b955a8249b62ac1d1ff16284aefa3d06d87",
		"fff2525b8931402dd09222c50775608f75787bd2b87e56995a7bdd30f79702c4",
		"6359f0868171b1d194cbee1af2f16ea598ae8fad666d9b012c8ed2b79a236ec4",
		"e9a66845e05d5abc0ad04ec80f774a7e585c6e8db975962d069a522137b80c1d",
	}
	var leaves [][32]byte
	for _, s := range txids {
		leaves = append(leaves, displayHash(t, s))
	}
	root, mutated := ComputeMerkleRoot(leaves)
	if HashToDisplayHex(root) != "f3e94742aca4b5ef85488dc37c06c3282295ffec960994b2c0d5ac2a25a95766" || mutated {
		t.Fatalf("block 100000 merkle root wrong: %s mutated=%v", HashToDisplayHex(root), mutated)
	}
	single, _ := ComputeMerkleRoot(leaves[:1])
	if single != leaves[0] {
		t.Fatalf("a one-tx block's merkle root is the coinbase txid itself")
	}
	if empty, _ := ComputeMerkleRoot(nil); empty != ([32]byte{}) {
		t.Fatalf("empty list must give the all-zero hash (uint256())")
	}
}

func TestLesson5_CVE_2012_2459_DuplicateLeafMutation(t *testing.T) {
	var l [][32]byte
	for i := byte(1); i <= 6; i++ {
		l = append(l, sha256.Sum256([]byte{i}))
	}
	// The exact example drawn in the comment at the top of src/consensus/merkle.cpp.
	orig, m1 := ComputeMerkleRoot(l)
	dup := append(append([][32]byte{}, l...), l[4], l[5])
	same, m2 := ComputeMerkleRoot(dup)
	if orig != same {
		t.Fatalf("[1..6] and [1..6,5,6] must have the SAME root — that is the bug you must detect")
	}
	if m1 {
		t.Fatalf("the honest list must not be flagged mutated")
	}
	if !m2 {
		t.Fatalf("the duplicated list must be flagged mutated (CVE-2012-2459)")
	}
	// Odd count: the internal duplication of the LAST element must NOT be flagged.
	if _, m := ComputeMerkleRoot(l[:3]); m {
		t.Fatalf("odd-length padding is not a mutation")
	}
	// [a,b,c,c] vs [a,b,c]
	r3, _ := ComputeMerkleRoot(l[:3])
	r4, m4 := ComputeMerkleRoot([][32]byte{l[0], l[1], l[2], l[2]})
	if r3 != r4 || !m4 {
		t.Fatalf("[a,b,c,c] must equal [a,b,c] and be flagged mutated")
	}
	// Input must not be modified by the function.
	before := append([][32]byte{}, l[:3]...)
	ComputeMerkleRoot(l[:3])
	for i := range before {
		if before[i] != l[i] {
			t.Fatalf("ComputeMerkleRoot must not modify its input slice")
		}
	}
}

func TestLesson5_MerkleBranchSPVProof(t *testing.T) {
	var l [][32]byte
	for i := byte(0); i < 7; i++ {
		l = append(l, sha256.Sum256([]byte{i, 0xee}))
	}
	root, _ := ComputeMerkleRoot(l)
	for idx := range l {
		br, err := MerkleBranch(l, idx)
		if err != nil {
			t.Fatalf("MerkleBranch(%d): %v", idx, err)
		}
		if len(br) != 3 {
			t.Fatalf("7 leaves need a 3-hash branch, got %d", len(br))
		}
		if RootFromBranch(l[idx], br, uint32(idx)) != root {
			t.Fatalf("branch for leaf %d does not lead to the root", idx)
		}
		if idx > 0 && RootFromBranch(l[idx], br, uint32(idx-1)) == root {
			t.Fatalf("wrong index must not verify (left/right order matters)")
		}
	}
	if _, err := MerkleBranch(l, 7); err == nil {
		t.Fatalf("out-of-range index must error")
	}
	if _, err := MerkleBranch(l, -1); err == nil {
		t.Fatalf("negative index must error")
	}
}

// ---------------------------------------------------------------- Lesson 6

func TestLesson6_Bech32AndBech32mStrings(t *testing.T) {
	// BIP173 / BIP350 test vectors.
	valid32 := []string{"A12UEL5L", "a12uel5l", "split1checkupstagehandshakeupstreamerranterredcaperred2y9e3w", "?1ezyfcl"}
	valid32m := []string{"A1LQFN3A", "a1lqfn3a", "abcdef1l7aum6echk45nj3s0wdvt2fg8x9yrzpqzd3ryx",
		"split1checkupstagehandshakeupstreamerranterredcaperredlc445v", "?1v759aa",
		"11llllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllludsr8"}
	for _, s := range valid32 {
		if _, _, enc, err := Bech32Decode(s); err != nil || enc != EncodingBech32 {
			t.Errorf("%s: want Bech32, got enc=%v err=%v", s, enc, err)
		}
	}
	for _, s := range valid32m {
		if _, _, enc, err := Bech32Decode(s); err != nil || enc != EncodingBech32m {
			t.Errorf("%s: want Bech32m, got enc=%v err=%v", s, enc, err)
		}
	}
	invalid := map[string]string{
		"qyrz8wqd2c9m":  "no separator",
		"1qyrz8wqd2c9m": "empty HRP",
		"y1b0jsk6g":     "invalid data character",
		"in1muywd":      "checksum too short",
		"M1VUXWEZ":      "checksum computed with uppercase HRP",
		"a12UEL5L":      "mixed case",
		"an84characterslonghumanreadablepartthatcontainsthetheexcludedcharactersbioandnumber11d6pts4": "over 90 chars",
		"\x201xj0phk": "HRP character out of range",
	}
	for s, why := range invalid {
		if _, _, _, err := Bech32Decode(s); err == nil {
			t.Errorf("%q must be rejected (%s)", s, why)
		}
	}
	// Round trip.
	enc, err := Bech32Encode("abcdef", []byte{31, 30, 29, 28, 27, 26, 25, 24, 23, 22, 21, 20, 19, 18, 17, 16, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0}, EncodingBech32m)
	if err != nil || enc != "abcdef1l7aum6echk45nj3s0wdvt2fg8x9yrzpqzd3ryx" {
		t.Errorf("Bech32Encode round trip wrong: %s (%v)", enc, err)
	}
	if _, err := Bech32Encode("a", []byte{32}, EncodingBech32); err == nil {
		t.Errorf("data values above 31 must be rejected")
	}
}

func TestLesson6_SegwitAddresses(t *testing.T) {
	valid := []struct {
		addr, hrp, spk string
	}{
		{"BC1QW508D6QEJXTDG4Y5R3ZARVARY0C5XW7KV8F3T4", "bc", "0014751e76e8199196d454941c45d1b3a323f1433bd6"},
		{"tb1qrp33g0q5c5txsp9arysrx4k6zdkfs4nce4xj0gdcccefvpysxf3q0sl5k7", "tb", "00201863143c14c5166804bd19203356da136c985678cd4d27a1b8c6329604903262"},
		{"bc1p0xlxvlhemja6c4dqv22uapctqupfhlxm9h8z3k2e72q4k9hcz7vqzk5jj0", "bc", "512079be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798"},
		{"BC1SW50QGDZ25J", "bc", "6002751e"},
		{"bc1zw508d6qejxtdg4y5r3zarvaryvaxxpcs", "bc", "5210751e76e8199196d454941c45d1b3a323"},
	}
	for _, v := range valid {
		ver, prog, err := DecodeSegwitAddress(v.hrp, v.addr)
		if err != nil {
			t.Errorf("%s: %v", v.addr, err)
			continue
		}
		opVer := byte(0)
		if ver > 0 {
			opVer = 0x50 + ver
		}
		spk := append([]byte{opVer, byte(len(prog))}, prog...)
		if hex.EncodeToString(spk) != v.spk {
			t.Errorf("%s: scriptPubKey %x want %s", v.addr, spk, v.spk)
		}
		back, err := EncodeSegwitAddress(v.hrp, ver, prog)
		if err != nil || back != strings.ToLower(v.addr) {
			t.Errorf("%s: re-encode gave %s (%v)", v.addr, back, err)
		}
	}
	invalid := map[string]string{
		"tc1p0xlxvlhemja6c4dqv22uapctqupfhlxm9h8z3k2e72q4k9hcz7vq5zuyut": "wrong HRP",
		"bc1p0xlxvlhemja6c4dqv22uapctqupfhlxm9h8z3k2e72q4k9hcz7vqh2y7hd": "v1 with Bech32 checksum",
		"bc1qw508d6qejxtdg4y5r3zarvary0c5xw7kemeawh":                     "v0 with Bech32m checksum",
		"BC130XLXVLHEMJA6C4DQV22UAPCTQUPFHLXM9H8Z3K2E72Q4K9HCZ7VQ7ZWS8R": "witness version 17",
		"bc1pw5dgrnzv":                         "1-byte program",
		"BC1QR508D6QEJXTDG4Y5R3ZARVARYV98GJ9P": "v0 program of 16 bytes",
		"bc1p0xlxvlhemja6c4dqv22uapctqupfhlxm9h8z3k2e72q4k9hcz7v07qwwzcrf": "more than 4 bits of zero padding",
		"tb1p0xlxvlhemja6c4dqv22uapctqupfhlxm9h8z3k2e72q4k9hcz7vpggkg4j":   "non-zero padding",
		"bc1gmk9yu": "empty data section",
	}
	for a, why := range invalid {
		hrp := "bc"
		if strings.HasPrefix(strings.ToLower(a), "tb") {
			hrp = "tb"
		}
		if _, _, err := DecodeSegwitAddress(hrp, a); err == nil {
			t.Errorf("%s must be rejected (%s)", a, why)
		}
	}
	if _, err := EncodeSegwitAddress("bc", 0, make([]byte, 21)); err == nil {
		t.Errorf("v0 with 21-byte program must not encode")
	}
}

// ---------------------------------------------------------------- Lesson 7

func TestLesson7_ScriptNum(t *testing.T) {
	enc := map[int64]string{0: "", 1: "01", -1: "81", 127: "7f", 128: "8000", -128: "8080", 255: "ff00", 256: "0001", -255: "ff80", 32767: "ff7f", 32768: "008000"}
	for v, h := range enc {
		if got := hex.EncodeToString(ScriptNumEncode(v)); got != h {
			t.Errorf("ScriptNumEncode(%d) = %s, want %s", v, got, h)
		}
		back, err := ScriptNumDecode(mustHex(t, h), true, 4)
		if err != nil || back != v {
			t.Errorf("ScriptNumDecode(%s) = %d (%v), want %d", h, back, err, v)
		}
	}
	nonMinimal := []string{"00", "80", "0100", "ff0000"}
	for _, h := range nonMinimal {
		if _, err := ScriptNumDecode(mustHex(t, h), true, 4); err == nil {
			t.Errorf("%s is non-minimal and must be rejected when requireMinimal", h)
		}
	}
	if v, err := ScriptNumDecode(mustHex(t, "0100"), false, 4); err != nil || v != 1 {
		t.Errorf("non-minimal 0100 must decode to 1 when requireMinimal=false, got %d (%v)", v, err)
	}
	if _, err := ScriptNumDecode(mustHex(t, "0000000001"), false, 4); err == nil {
		t.Errorf("5-byte number must overflow nMaxNumSize=4")
	}
	if CastToBool([]byte{0x00, 0x80}) || CastToBool(nil) || !CastToBool([]byte{0x00, 0x01}) || !CastToBool([]byte{0x80, 0x00}) {
		t.Errorf("CastToBool wrong (negative zero 0x..80 is false; 0x8000 is true)")
	}
}

func TestLesson7_EvalHashlockAndArithmetic(t *testing.T) {
	pre := []byte("kisumu_sovereign_secret_preimage")
	h := sha256.Sum256(pre)
	script := append([]byte{byte(len(pre))}, pre...)
	script = append(script, OP_SHA256, 32)
	script = append(script, h[:]...)
	script = append(script, OP_EQUALVERIFY, OP_1)
	st, err := EvalMinimalScript(script)
	if err != nil || len(st) != 1 || !bytes.Equal(st[0], []byte{1}) {
		t.Fatalf("hashlock should leave [01], got %x (%v)", st, err)
	}
	wrong := append([]byte{}, script...)
	wrong[1] ^= 0xff
	if _, err := EvalMinimalScript(wrong); err == nil {
		t.Fatalf("wrong preimage must fail OP_EQUALVERIFY")
	}

	// <2> <3> OP_ADD <5> OP_EQUAL
	st, err = EvalMinimalScript([]byte{0x52, 0x53, OP_ADD, 0x55, OP_EQUAL})
	if err != nil || len(st) != 1 || !CastToBool(st[0]) {
		t.Fatalf("2+3==5 should be true, got %x (%v)", st, err)
	}
	// OP_1NEGATE OP_1 OP_ADD -> 0 (empty vector), then OP_VERIFY must fail.
	if _, err := EvalMinimalScript([]byte{OP_1NEGATE, OP_1, OP_ADD, OP_VERIFY}); err == nil {
		t.Fatalf("-1 + 1 = 0 is false, OP_VERIFY must fail")
	}
	// OP_PUSHDATA1 with 76 bytes.
	big76 := append([]byte{OP_PUSHDATA1, 76}, bytes.Repeat([]byte{7}, 76)...)
	if st, err := EvalMinimalScript(big76); err != nil || len(st) != 1 || len(st[0]) != 76 {
		t.Fatalf("OP_PUSHDATA1 76 bytes failed: %v", err)
	}
	// Malformed / adversarial scripts.
	bad := map[string][]byte{
		"push past end":            {0x05, 1, 2},
		"PUSHDATA1 missing length": {OP_PUSHDATA1},
		"OP_DUP empty stack":       {OP_DUP},
		"OP_ADD one item":          {OP_1, OP_ADD},
		"OP_ADD 5-byte operand":    {0x05, 1, 0, 0, 0, 0, OP_1, OP_ADD},
		"OP_ADD non-minimal":       {0x02, 1, 0, OP_1, OP_ADD},
		"unknown opcode":           {0xff},
	}
	for name, s := range bad {
		if _, err := EvalMinimalScript(s); err == nil {
			t.Errorf("%s: expected error", name)
		}
	}
}
