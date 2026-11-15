// REFERENCE SOLUTION (spoiler). Open only after `./lab.sh check 10` passes on your own
// code, or after 3 honest attempts. Your working file is ../primitives.go.
//
// Verified against bitcoin/bitcoin at commit f490f5562d (29.x branch).
package primitives

import (
	"bytes"
	"crypto/sha256"
	"encoding/binary"
	"encoding/hex"
	"errors"
	"fmt"
	"math/big"
	"strings"
)

// ===========================================================================
// LESSON 1 — Hashing and byte order
// ===========================================================================

// Hash256 returns SHA256(SHA256(data)).
func Hash256(data []byte) [32]byte {
	first := sha256.Sum256(data)
	return sha256.Sum256(first[:])
}

// ReverseBytes returns a NEW slice with the bytes of b in reverse order.
// It must not modify b.
func ReverseBytes(b []byte) []byte {
	out := make([]byte, len(b))
	for i := range b {
		out[i] = b[len(b)-1-i]
	}
	return out
}

// HashToDisplayHex converts an internal-order hash to the hex string shown by RPC.
func HashToDisplayHex(h [32]byte) string {
	return hex.EncodeToString(ReverseBytes(h[:]))
}

// HashFromDisplayHex parses an RPC-style (display order) hash into internal order.
func HashFromDisplayHex(s string) ([32]byte, error) {
	var out [32]byte
	if len(s) != 64 {
		return out, fmt.Errorf("hash hex must be 64 characters, got %d", len(s))
	}
	raw, err := hex.DecodeString(s)
	if err != nil {
		return out, err
	}
	copy(out[:], ReverseBytes(raw))
	return out, nil
}

// TaggedHash implements BIP340: SHA256(SHA256(tag) || SHA256(tag) || msg).
func TaggedHash(tag string, msg []byte) [32]byte {
	tagHash := sha256.Sum256([]byte(tag))
	h := sha256.New()
	h.Write(tagHash[:])
	h.Write(tagHash[:])
	h.Write(msg)
	var out [32]byte
	copy(out[:], h.Sum(nil))
	return out
}

// ===========================================================================
// LESSON 2 — CompactSize
// ===========================================================================

// MaxSize mirrors MAX_SIZE in src/serialize.h.
const MaxSize uint64 = 0x02000000

var (
	ErrNonCanonical = errors.New("non-canonical ReadCompactSize()")
	ErrSizeTooLarge = errors.New("ReadCompactSize(): size too large")
)

func EncodeCompactSize(n uint64) []byte {
	switch {
	case n < 253:
		return []byte{byte(n)}
	case n <= 0xffff:
		buf := make([]byte, 3)
		buf[0] = 0xfd
		binary.LittleEndian.PutUint16(buf[1:], uint16(n))
		return buf
	case n <= 0xffffffff:
		buf := make([]byte, 5)
		buf[0] = 0xfe
		binary.LittleEndian.PutUint32(buf[1:], uint32(n))
		return buf
	default:
		buf := make([]byte, 9)
		buf[0] = 0xff
		binary.LittleEndian.PutUint64(buf[1:], n)
		return buf
	}
}

func DecodeCompactSize(r *bytes.Reader, rangeCheck bool) (uint64, error) {
	first, err := r.ReadByte()
	if err != nil {
		return 0, err
	}
	var n uint64
	switch first {
	case 0xfd:
		var buf [2]byte
		if _, err := ioReadFull(r, buf[:]); err != nil {
			return 0, err
		}
		n = uint64(binary.LittleEndian.Uint16(buf[:]))
		if n < 253 {
			return 0, ErrNonCanonical
		}
	case 0xfe:
		var buf [4]byte
		if _, err := ioReadFull(r, buf[:]); err != nil {
			return 0, err
		}
		n = uint64(binary.LittleEndian.Uint32(buf[:]))
		if n < 0x10000 {
			return 0, ErrNonCanonical
		}
	case 0xff:
		var buf [8]byte
		if _, err := ioReadFull(r, buf[:]); err != nil {
			return 0, err
		}
		n = binary.LittleEndian.Uint64(buf[:])
		if n < 0x100000000 {
			return 0, ErrNonCanonical
		}
	default:
		n = uint64(first)
	}
	if rangeCheck && n > MaxSize {
		return 0, ErrSizeTooLarge
	}
	return n, nil
}

func ioReadFull(r *bytes.Reader, buf []byte) (int, error) {
	n, err := r.Read(buf)
	if err != nil {
		return n, err
	}
	if n != len(buf) {
		return n, errors.New("unexpected end of data")
	}
	return n, nil
}

// ===========================================================================
// LESSON 3 — Transactions: witness vs non-witness serialization
// ===========================================================================

type TxSummary struct {
	Version    int32
	HasWitness bool
	NumInputs  int
	NumOutputs int
	OutValues  []int64
	LockTime   uint32
	TxID       [32]byte
	WTxID      [32]byte
}

type txReader struct {
	r *bytes.Reader
}

func (t *txReader) bytes(n uint64) ([]byte, error) {
	if n > uint64(t.r.Len()) {
		return nil, errors.New("unexpected end of data")
	}
	buf := make([]byte, n)
	if _, err := ioReadFull(t.r, buf); err != nil {
		return nil, err
	}
	return buf, nil
}

func (t *txReader) compact() (uint64, error) { return DecodeCompactSize(t.r, true) }

func (t *txReader) u32() (uint32, error) {
	b, err := t.bytes(4)
	if err != nil {
		return 0, err
	}
	return binary.LittleEndian.Uint32(b), nil
}

func (t *txReader) inputs() (int, error) {
	n, err := t.compact()
	if err != nil {
		return 0, err
	}
	for i := uint64(0); i < n; i++ {
		if _, err := t.bytes(36); err != nil { // prevout: 32-byte hash + 4-byte index
			return 0, err
		}
		l, err := t.compact()
		if err != nil {
			return 0, err
		}
		if _, err := t.bytes(l); err != nil { // scriptSig
			return 0, err
		}
		if _, err := t.u32(); err != nil { // nSequence
			return 0, err
		}
	}
	return int(n), nil
}

func (t *txReader) outputs() ([]int64, error) {
	n, err := t.compact()
	if err != nil {
		return nil, err
	}
	// Do NOT pre-allocate n entries: n comes from untrusted input (memory DoS).
	var vals []int64
	for i := uint64(0); i < n; i++ {
		b, err := t.bytes(8)
		if err != nil {
			return nil, err
		}
		vals = append(vals, int64(binary.LittleEndian.Uint64(b)))
		l, err := t.compact()
		if err != nil {
			return nil, err
		}
		if _, err := t.bytes(l); err != nil {
			return nil, err
		}
	}
	return vals, nil
}

func (t *txReader) pos(total int) int { return total - t.r.Len() }

// ParseTxSummary mirrors UnserializeTransaction in src/primitives/transaction.h.
func ParseTxSummary(raw []byte) (TxSummary, error) {
	var s TxSummary
	t := &txReader{r: bytes.NewReader(raw)}
	total := len(raw)

	v, err := t.u32()
	if err != nil {
		return s, err
	}
	s.Version = int32(v)

	vinStart := t.pos(total)
	nIn, err := t.inputs()
	if err != nil {
		return s, err
	}
	var flags byte
	var vals []int64
	if nIn == 0 {
		// Either a dummy marker (0x00) or a genuinely empty vin.
		flags, err = t.r.ReadByte()
		if err != nil {
			return s, err
		}
		if flags != 0 {
			vinStart = t.pos(total)
			if nIn, err = t.inputs(); err != nil {
				return s, err
			}
			if vals, err = t.outputs(); err != nil {
				return s, err
			}
		}
	} else {
		if vals, err = t.outputs(); err != nil {
			return s, err
		}
	}
	vinVoutEnd := t.pos(total)

	if flags&1 == 1 {
		flags ^= 1
		anyWitness := false
		for i := 0; i < nIn; i++ {
			items, err := t.compact()
			if err != nil {
				return s, err
			}
			if items > 0 {
				anyWitness = true
			}
			for j := uint64(0); j < items; j++ {
				l, err := t.compact()
				if err != nil {
					return s, err
				}
				if _, err := t.bytes(l); err != nil {
					return s, err
				}
			}
		}
		if !anyWitness {
			return s, errors.New("Superfluous witness record")
		}
		s.HasWitness = true
	}
	if flags != 0 {
		return s, errors.New("Unknown transaction optional data")
	}
	lt, err := t.u32()
	if err != nil {
		return s, err
	}
	if t.r.Len() != 0 {
		return s, errors.New("trailing bytes after transaction")
	}
	s.LockTime = lt
	s.NumInputs = nIn
	s.NumOutputs = len(vals)
	s.OutValues = vals

	// txid commits to the stripped (non-witness) serialization.
	stripped := make([]byte, 0, total)
	stripped = append(stripped, raw[0:4]...)
	stripped = append(stripped, raw[vinStart:vinVoutEnd]...)
	stripped = append(stripped, raw[total-4:]...)
	s.TxID = Hash256(stripped)
	s.WTxID = Hash256(raw)
	return s, nil
}

// ===========================================================================
// LESSON 4 — Proof of work: nBits, targets, retargeting
// ===========================================================================

// CompactToTarget mirrors arith_uint256::SetCompact.
func CompactToTarget(nBits uint32) (target *big.Int, negative bool, overflow bool) {
	size := nBits >> 24
	word := nBits & 0x007fffff
	if size <= 3 {
		word >>= 8 * (3 - size)
		target = new(big.Int).SetUint64(uint64(word))
	} else {
		target = new(big.Int).SetUint64(uint64(word))
		target.Lsh(target, uint(8*(size-3)))
	}
	negative = word != 0 && (nBits&0x00800000) != 0
	overflow = word != 0 && (size > 34 || (word > 0xff && size > 33) || (word > 0xffff && size > 32))
	return target, negative, overflow
}

// TargetToCompact mirrors arith_uint256::GetCompact(false).
func TargetToCompact(target *big.Int) uint32 {
	size := uint32((target.BitLen() + 7) / 8)
	var compact uint32
	if size <= 3 {
		compact = uint32(target.Uint64() << (8 * (3 - size)))
	} else {
		compact = uint32(new(big.Int).Rsh(target, uint(8*(size-3))).Uint64())
	}
	if compact&0x00800000 != 0 {
		compact >>= 8
		size++
	}
	return compact | size<<24
}

// MainnetPowLimit is consensus.powLimit for mainnet (src/kernel/chainparams.cpp).
func MainnetPowLimit() *big.Int {
	v, _ := new(big.Int).SetString("00000000ffffffffffffffffffffffffffffffffffffffffffffffffffffffff", 16)
	return v
}

// VerifyBlockHeaderPoW mirrors CheckProofOfWorkImpl + DeriveTarget in src/pow.cpp.
func VerifyBlockHeaderPoW(header80 []byte, powLimit *big.Int) (string, bool, error) {
	if len(header80) != 80 {
		return "", false, fmt.Errorf("block header must be exactly 80 bytes, got %d", len(header80))
	}
	nBits := binary.LittleEndian.Uint32(header80[72:76])
	h := Hash256(header80)
	display := HashToDisplayHex(h)
	target, neg, ovf := CompactToTarget(nBits)
	if neg || ovf || target.Sign() == 0 || target.Cmp(powLimit) > 0 {
		return display, false, nil
	}
	hashInt := new(big.Int).SetBytes(ReverseBytes(h[:]))
	return display, hashInt.Cmp(target) <= 0, nil
}

// TargetTimespan is nPowTargetTimespan on mainnet (two weeks).
const TargetTimespan int64 = 14 * 24 * 60 * 60

// CalculateNextWorkRequired mirrors CalculateNextWorkRequired in src/pow.cpp (no BIP94 rule).
func CalculateNextWorkRequired(lastBits uint32, firstBlockTime, lastBlockTime int64, powLimit *big.Int) uint32 {
	actual := lastBlockTime - firstBlockTime
	if actual < TargetTimespan/4 {
		actual = TargetTimespan / 4
	}
	if actual > TargetTimespan*4 {
		actual = TargetTimespan * 4
	}
	bn, _, _ := CompactToTarget(lastBits)
	bn.Mul(bn, big.NewInt(actual))
	bn.Div(bn, big.NewInt(TargetTimespan))
	if bn.Cmp(powLimit) > 0 {
		bn.Set(powLimit)
	}
	return TargetToCompact(bn)
}

// ===========================================================================
// LESSON 5 — Merkle trees and CVE-2012-2459
// ===========================================================================

func hashPair(a, b [32]byte) [32]byte {
	var buf [64]byte
	copy(buf[:32], a[:])
	copy(buf[32:], b[:])
	return Hash256(buf[:])
}

// ComputeMerkleRoot mirrors ComputeMerkleRoot(hashes, &mutated) in src/consensus/merkle.cpp.
func ComputeMerkleRoot(hashes [][32]byte) (root [32]byte, mutated bool) {
	level := make([][32]byte, len(hashes))
	copy(level, hashes)
	for len(level) > 1 {
		for pos := 0; pos+1 < len(level); pos += 2 {
			if level[pos] == level[pos+1] {
				mutated = true
			}
		}
		if len(level)%2 == 1 {
			level = append(level, level[len(level)-1])
		}
		next := make([][32]byte, len(level)/2)
		for i := range next {
			next[i] = hashPair(level[2*i], level[2*i+1])
		}
		level = next
	}
	if len(level) == 0 {
		return [32]byte{}, mutated
	}
	return level[0], mutated
}

// MerkleBranch returns the sibling hashes from leaf `index` up to the root.
func MerkleBranch(hashes [][32]byte, index int) ([][32]byte, error) {
	if index < 0 || index >= len(hashes) {
		return nil, fmt.Errorf("index %d out of range for %d leaves", index, len(hashes))
	}
	level := make([][32]byte, len(hashes))
	copy(level, hashes)
	var branch [][32]byte
	for len(level) > 1 {
		if len(level)%2 == 1 {
			level = append(level, level[len(level)-1])
		}
		branch = append(branch, level[index^1])
		next := make([][32]byte, len(level)/2)
		for i := range next {
			next[i] = hashPair(level[2*i], level[2*i+1])
		}
		level = next
		index >>= 1
	}
	return branch, nil
}

// RootFromBranch mirrors ComputeMerkleRootFromBranch in src/test/merkle_tests.cpp.
func RootFromBranch(leaf [32]byte, branch [][32]byte, index uint32) [32]byte {
	h := leaf
	for _, sib := range branch {
		if index&1 == 1 {
			h = hashPair(sib, h)
		} else {
			h = hashPair(h, sib)
		}
		index >>= 1
	}
	return h
}

// ===========================================================================
// LESSON 6 — Bech32 / Bech32m and SegWit addresses
// ===========================================================================

type Bech32Encoding int

const (
	EncodingInvalid Bech32Encoding = iota
	EncodingBech32
	EncodingBech32m
)

const bech32Charset = "qpzry9x8gf2tvdw0s3jn54khce6mua7l"

const (
	bech32Const  uint32 = 1
	bech32mConst uint32 = 0x2bc830a3
)

func bech32Polymod(values []byte) uint32 {
	gen := [5]uint32{0x3b6a57b2, 0x26508e6d, 0x1ea119fa, 0x3d4233dd, 0x2a1462b3}
	chk := uint32(1)
	for _, v := range values {
		top := chk >> 25
		chk = (chk&0x1ffffff)<<5 ^ uint32(v)
		for i := 0; i < 5; i++ {
			if (top>>uint(i))&1 == 1 {
				chk ^= gen[i]
			}
		}
	}
	return chk
}

func hrpExpand(hrp string) []byte {
	out := make([]byte, 0, len(hrp)*2+1)
	for i := 0; i < len(hrp); i++ {
		out = append(out, hrp[i]>>5)
	}
	out = append(out, 0)
	for i := 0; i < len(hrp); i++ {
		out = append(out, hrp[i]&31)
	}
	return out
}

func Bech32Encode(hrp string, data []byte, enc Bech32Encoding) (string, error) {
	if enc != EncodingBech32 && enc != EncodingBech32m {
		return "", errors.New("invalid encoding")
	}
	if len(hrp) == 0 {
		return "", errors.New("empty hrp")
	}
	for i := 0; i < len(hrp); i++ {
		c := hrp[i]
		if c < 33 || c > 126 {
			return "", errors.New("hrp character out of range")
		}
		if c >= 'A' && c <= 'Z' {
			return "", errors.New("hrp must be lowercase")
		}
	}
	for _, d := range data {
		if d > 31 {
			return "", errors.New("data value is not 5-bit")
		}
	}
	if len(hrp)+1+len(data)+6 > 90 {
		return "", errors.New("string exceeds 90 characters")
	}
	k := bech32Const
	if enc == EncodingBech32m {
		k = bech32mConst
	}
	values := append(hrpExpand(hrp), data...)
	values = append(values, 0, 0, 0, 0, 0, 0)
	mod := bech32Polymod(values) ^ k
	var sb strings.Builder
	sb.WriteString(hrp)
	sb.WriteByte('1')
	for _, d := range data {
		sb.WriteByte(bech32Charset[d])
	}
	for i := 0; i < 6; i++ {
		sb.WriteByte(bech32Charset[(mod>>uint(5*(5-i)))&31])
	}
	return sb.String(), nil
}

func Bech32Decode(s string) (string, []byte, Bech32Encoding, error) {
	if len(s) > 90 {
		return "", nil, EncodingInvalid, errors.New("string exceeds 90 characters")
	}
	hasLower, hasUpper := false, false
	for i := 0; i < len(s); i++ {
		c := s[i]
		if c < 33 || c > 126 {
			return "", nil, EncodingInvalid, errors.New("character out of range")
		}
		if c >= 'a' && c <= 'z' {
			hasLower = true
		}
		if c >= 'A' && c <= 'Z' {
			hasUpper = true
		}
	}
	if hasLower && hasUpper {
		return "", nil, EncodingInvalid, errors.New("mixed case")
	}
	s = strings.ToLower(s)
	pos := strings.LastIndexByte(s, '1')
	if pos < 1 {
		return "", nil, EncodingInvalid, errors.New("missing separator or empty hrp")
	}
	if pos+7 > len(s) {
		return "", nil, EncodingInvalid, errors.New("checksum too short")
	}
	hrp := s[:pos]
	data := make([]byte, 0, len(s)-pos-1)
	for i := pos + 1; i < len(s); i++ {
		idx := strings.IndexByte(bech32Charset, s[i])
		if idx < 0 {
			return "", nil, EncodingInvalid, errors.New("invalid data character")
		}
		data = append(data, byte(idx))
	}
	var enc Bech32Encoding
	switch bech32Polymod(append(hrpExpand(hrp), data...)) {
	case bech32Const:
		enc = EncodingBech32
	case bech32mConst:
		enc = EncodingBech32m
	default:
		return "", nil, EncodingInvalid, errors.New("invalid checksum")
	}
	return hrp, data[:len(data)-6], enc, nil
}

// ConvertBits regroups a bit stream (e.g. 8-bit bytes -> 5-bit groups).
func ConvertBits(data []byte, fromBits, toBits uint, pad bool) ([]byte, error) {
	acc := uint32(0)
	bits := uint(0)
	maxv := uint32(1)<<toBits - 1
	var out []byte
	for _, v := range data {
		if uint32(v)>>fromBits != 0 {
			return nil, errors.New("input value out of range")
		}
		acc = acc<<fromBits | uint32(v)
		bits += fromBits
		for bits >= toBits {
			bits -= toBits
			out = append(out, byte((acc>>bits)&maxv))
		}
	}
	if pad {
		if bits > 0 {
			out = append(out, byte((acc<<(toBits-bits))&maxv))
		}
	} else if bits >= fromBits || (acc<<(toBits-bits))&maxv != 0 {
		return nil, errors.New("invalid padding")
	}
	return out, nil
}

func EncodeSegwitAddress(hrp string, version byte, program []byte) (string, error) {
	if err := checkWitnessProgram(version, program); err != nil {
		return "", err
	}
	enc := EncodingBech32
	if version > 0 {
		enc = EncodingBech32m
	}
	conv, err := ConvertBits(program, 8, 5, true)
	if err != nil {
		return "", err
	}
	return Bech32Encode(hrp, append([]byte{version}, conv...), enc)
}

func DecodeSegwitAddress(expectedHRP, addr string) (byte, []byte, error) {
	hrp, data, enc, err := Bech32Decode(addr)
	if err != nil {
		return 0, nil, err
	}
	if hrp != expectedHRP {
		return 0, nil, fmt.Errorf("wrong hrp %q (expected %q)", hrp, expectedHRP)
	}
	if len(data) == 0 {
		return 0, nil, errors.New("Empty Bech32 data section")
	}
	version := data[0]
	if version > 16 {
		return 0, nil, errors.New("Invalid Bech32 address witness version")
	}
	if version == 0 && enc != EncodingBech32 {
		return 0, nil, errors.New("Version 0 witness address must use Bech32 checksum")
	}
	if version != 0 && enc != EncodingBech32m {
		return 0, nil, errors.New("Version 1+ witness address must use Bech32m checksum")
	}
	prog, err := ConvertBits(data[1:], 5, 8, false)
	if err != nil {
		return 0, nil, err
	}
	if err := checkWitnessProgram(version, prog); err != nil {
		return 0, nil, err
	}
	return version, prog, nil
}

func checkWitnessProgram(version byte, program []byte) error {
	if version > 16 {
		return errors.New("Invalid Bech32 address witness version")
	}
	if len(program) < 2 || len(program) > 40 {
		return fmt.Errorf("Invalid Bech32 address program size (%d bytes)", len(program))
	}
	if version == 0 && len(program) != 20 && len(program) != 32 {
		return fmt.Errorf("Invalid Bech32 v0 address program size (%d bytes), per BIP141", len(program))
	}
	return nil
}

// ===========================================================================
// LESSON 7 — A tiny Script interpreter with CScriptNum
// ===========================================================================

const (
	OP_0           byte = 0x00
	OP_PUSHDATA1   byte = 0x4c
	OP_1NEGATE     byte = 0x4f
	OP_1           byte = 0x51
	OP_16          byte = 0x60
	OP_VERIFY      byte = 0x69
	OP_DUP         byte = 0x76
	OP_EQUAL       byte = 0x87
	OP_EQUALVERIFY byte = 0x88
	OP_ADD         byte = 0x93
	OP_SHA256      byte = 0xa8
)

// ScriptNumEncode mirrors CScriptNum::serialize.
func ScriptNumEncode(v int64) []byte {
	if v == 0 {
		return []byte{}
	}
	neg := v < 0
	var abs uint64
	if neg {
		abs = uint64(-v)
	} else {
		abs = uint64(v)
	}
	var out []byte
	for abs > 0 {
		out = append(out, byte(abs&0xff))
		abs >>= 8
	}
	if out[len(out)-1]&0x80 != 0 {
		if neg {
			out = append(out, 0x80)
		} else {
			out = append(out, 0x00)
		}
	} else if neg {
		out[len(out)-1] |= 0x80
	}
	return out
}

// ScriptNumDecode mirrors the CScriptNum(vch, fRequireMinimal, nMaxNumSize) constructor.
func ScriptNumDecode(b []byte, requireMinimal bool, maxLen int) (int64, error) {
	if len(b) > maxLen {
		return 0, errors.New("script number overflow")
	}
	if requireMinimal && len(b) > 0 {
		if b[len(b)-1]&0x7f == 0 {
			if len(b) <= 1 || b[len(b)-2]&0x80 == 0 {
				return 0, errors.New("non-minimally encoded script number")
			}
		}
	}
	if len(b) == 0 {
		return 0, nil
	}
	var result int64
	for i, c := range b {
		result |= int64(c) << (8 * uint(i))
	}
	if b[len(b)-1]&0x80 != 0 {
		return -(result & ^(int64(0x80) << (8 * uint(len(b)-1)))), nil
	}
	return result, nil
}

// CastToBool mirrors CastToBool in src/script/interpreter.cpp.
func CastToBool(b []byte) bool {
	for i, c := range b {
		if c != 0 {
			if i == len(b)-1 && c == 0x80 {
				return false
			}
			return true
		}
	}
	return false
}

func EvalMinimalScript(script []byte) ([][]byte, error) {
	var stack [][]byte
	pop := func() []byte {
		top := stack[len(stack)-1]
		stack = stack[:len(stack)-1]
		return top
	}
	for i := 0; i < len(script); {
		op := script[i]
		i++
		switch {
		case op == OP_0:
			stack = append(stack, []byte{})
		case op >= 0x01 && op <= 0x4b:
			n := int(op)
			if i+n > len(script) {
				return nil, errors.New("push past end of script")
			}
			stack = append(stack, append([]byte{}, script[i:i+n]...))
			i += n
		case op == OP_PUSHDATA1:
			if i >= len(script) {
				return nil, errors.New("push past end of script")
			}
			n := int(script[i])
			i++
			if i+n > len(script) {
				return nil, errors.New("push past end of script")
			}
			stack = append(stack, append([]byte{}, script[i:i+n]...))
			i += n
		case op == OP_1NEGATE:
			stack = append(stack, ScriptNumEncode(-1))
		case op >= OP_1 && op <= OP_16:
			stack = append(stack, ScriptNumEncode(int64(op-OP_1+1)))
		case op == OP_VERIFY:
			if len(stack) < 1 {
				return nil, errors.New("invalid stack operation")
			}
			if !CastToBool(pop()) {
				return nil, errors.New("SCRIPT_ERR_VERIFY")
			}
		case op == OP_DUP:
			if len(stack) < 1 {
				return nil, errors.New("invalid stack operation")
			}
			stack = append(stack, append([]byte{}, stack[len(stack)-1]...))
		case op == OP_SHA256:
			if len(stack) < 1 {
				return nil, errors.New("invalid stack operation")
			}
			sum := sha256.Sum256(pop())
			stack = append(stack, sum[:])
		case op == OP_EQUAL || op == OP_EQUALVERIFY:
			if len(stack) < 2 {
				return nil, errors.New("invalid stack operation")
			}
			b := pop()
			a := pop()
			eq := bytes.Equal(a, b)
			if op == OP_EQUALVERIFY {
				if !eq {
					return nil, errors.New("SCRIPT_ERR_EQUALVERIFY")
				}
			} else if eq {
				stack = append(stack, []byte{1})
			} else {
				stack = append(stack, []byte{})
			}
		case op == OP_ADD:
			if len(stack) < 2 {
				return nil, errors.New("invalid stack operation")
			}
			b, err := ScriptNumDecode(pop(), true, 4)
			if err != nil {
				return nil, err
			}
			a, err := ScriptNumDecode(pop(), true, 4)
			if err != nil {
				return nil, err
			}
			stack = append(stack, ScriptNumEncode(a+b))
		default:
			return nil, fmt.Errorf("unsupported opcode 0x%02x", op)
		}
	}
	return stack, nil
}
