// Stage 10 — Protocol primitives from scratch. YOUR WORKING FILE.
//
// `./lab.sh blank 10` copies this skeleton to ../primitives.go. Write every body
// yourself, then run `./lab.sh check 10` (or `go test ./...` in the stage dir).
// Work lesson by lesson: `go test -run TestLesson2 ./...`.
//
// Rules: standard library only. Read the named Bitcoin Core function before
// you write each one (paths are relative to the bitcoin/bitcoin repo root,
// checked at commit f490f5562d, 29.x). The reference answer is in
// ../solutions/ — open it only after the tests pass or after 3 honest attempts.
package primitives

import (
	"bytes"
	"errors"
	"math/big"
)

var errTODO = errors.New("TODO: not implemented yet")

// ===========================================================================
// LESSON 1 — Hashing and byte order
// Core: src/hash.h (Hash, HashWriter), src/uint256.h (GetHex / FromHex)
// ===========================================================================

// Hash256 returns SHA256(SHA256(data)) — Core's Hash()/HashWriter::GetHash().
// Used for txids, wtxids, block hashes and Merkle nodes.
func Hash256(data []byte) [32]byte {
	// TODO
	return [32]byte{}
}

// ReverseBytes returns a NEW slice holding b in reverse order.
// Edge cases: must NOT modify b (callers keep using it); nil/empty -> empty slice.
func ReverseBytes(b []byte) []byte {
	// TODO
	return nil
}

// HashToDisplayHex turns an internal-order hash (what Hash256 returns, what is
// serialized on the wire) into the hex string RPC prints (byte-reversed).
// Mirrors uint256::GetHex().
func HashToDisplayHex(h [32]byte) string {
	// TODO
	return ""
}

// HashFromDisplayHex is the inverse: parse 64 hex chars as printed by RPC and
// return internal order. Errors: length != 64, non-hex characters.
func HashFromDisplayHex(s string) ([32]byte, error) {
	// TODO
	return [32]byte{}, errTODO
}

// TaggedHash implements BIP340 tagged hashing:
//
//	SHA256( SHA256(tag) || SHA256(tag) || msg )
//
// Core: HashWriter TaggedHash(const std::string& tag) in src/hash.cpp.
func TaggedHash(tag string, msg []byte) [32]byte {
	// TODO
	return [32]byte{}
}

// ===========================================================================
// LESSON 2 — CompactSize
// Core: WriteCompactSize / ReadCompactSize in src/serialize.h
// ===========================================================================

// MaxSize mirrors MAX_SIZE in src/serialize.h (do not change).
const MaxSize uint64 = 0x02000000

var (
	ErrNonCanonical = errors.New("non-canonical ReadCompactSize()")
	ErrSizeTooLarge = errors.New("ReadCompactSize(): size too large")
)

// EncodeCompactSize writes n using the SHORTEST form:
//
//	n < 253          -> [n]
//	n <= 0xffff      -> 0xfd + uint16 little-endian
//	n <= 0xffffffff  -> 0xfe + uint32 little-endian
//	otherwise        -> 0xff + uint64 little-endian
func EncodeCompactSize(n uint64) []byte {
	// TODO
	return nil
}

// DecodeCompactSize reads one CompactSize from r.
// Must return:
//   - an error on empty or truncated input (do not return a partial value);
//   - ErrNonCanonical if a longer form encodes a value the shorter form could
//     hold (0xfd with < 253, 0xfe with < 0x10000, 0xff with < 0x100000000);
//   - ErrSizeTooLarge if rangeCheck && value > MaxSize.
func DecodeCompactSize(r *bytes.Reader, rangeCheck bool) (uint64, error) {
	// TODO
	return 0, errTODO
}

// ===========================================================================
// LESSON 3 — Transactions: witness vs non-witness serialization (BIP141/BIP144)
// Core: UnserializeTransaction in src/primitives/transaction.h
// ===========================================================================

// TxSummary is what ParseTxSummary returns. TxID/WTxID are in INTERNAL order.
type TxSummary struct {
	Version    int32
	HasWitness bool
	NumInputs  int
	NumOutputs int
	OutValues  []int64 // satoshi value of each output, in order
	LockTime   uint32
	TxID       [32]byte
	WTxID      [32]byte
}

// ParseTxSummary parses a raw transaction in legacy OR extended (segwit) form.
//
// Follow Core's algorithm exactly:
//  1. version (int32 LE)
//  2. read vin (CompactSize count, then per input: 32-byte hash, uint32 index,
//     CompactSize-prefixed scriptSig, uint32 nSequence)
//  3. if vin was EMPTY: read one byte `flags`. If flags != 0, read vin again,
//     then vout. (The 0x00 you read as an "empty vin" was the segwit marker.)
//     Otherwise read vout.
//  4. if flags&1: clear that bit, read one witness stack per input
//     (CompactSize item count, then CompactSize-prefixed items). If EVERY stack
//     is empty -> error "Superfluous witness record".
//  5. if any flag bits remain -> error "Unknown transaction optional data".
//  6. nLockTime (uint32 LE). Any bytes left over -> error.
//
// TxID  = Hash256(version || vin || vout || locktime)  (no marker/flag/witness)
// WTxID = Hash256(all bytes)                            (== TxID if no witness)
//
// Reviewer edge cases the tests check: truncation anywhere, trailing bytes,
// unknown flags, and a CompactSize count of 2^25 with no data behind it — you
// must not pre-allocate memory from an untrusted count.
func ParseTxSummary(raw []byte) (TxSummary, error) {
	// TODO
	return TxSummary{}, errTODO
}

// ===========================================================================
// LESSON 4 — Proof of work: nBits, targets, retargeting
// Core: arith_uint256::SetCompact/GetCompact (src/arith_uint256.cpp),
//       DeriveTarget, CheckProofOfWorkImpl, CalculateNextWorkRequired (src/pow.cpp)
// ===========================================================================

// CompactToTarget mirrors SetCompact(nCompact, &fNegative, &fOverflow):
//
//	size = nBits >> 24, word = nBits & 0x007fffff
//	size <= 3: target = word >> 8*(3-size)  (shift the WORD first — see Core)
//	size > 3:  target = word << 8*(size-3)
//	negative = word != 0 && (nBits & 0x00800000) != 0
//	overflow = word != 0 && (size > 34 || (word > 0xff && size > 33) || (word > 0xffff && size > 32))
func CompactToTarget(nBits uint32) (target *big.Int, negative bool, overflow bool) {
	// TODO
	return new(big.Int), false, false
}

// TargetToCompact mirrors GetCompact(false). Remember the rule: if the
// mantissa would have bit 0x00800000 set, shift it right 8 and bump the size,
// so the result is never read back as negative.
func TargetToCompact(target *big.Int) uint32 {
	// TODO
	return 0
}

// MainnetPowLimit returns consensus.powLimit for mainnet
// (see src/kernel/chainparams.cpp, CMainParams). Find the value yourself.
func MainnetPowLimit() *big.Int {
	// TODO
	return new(big.Int)
}

// VerifyBlockHeaderPoW checks an 80-byte header.
// Header layout (all integers little-endian): version[0:4] prevhash[4:36]
// merkleroot[36:68] time[68:72] nBits[72:76] nonce[76:80].
// Returns the display-order block hash hex and whether PoW is valid.
// Invalid (ok=false, err=nil) when DeriveTarget would fail: negative, zero,
// overflow, or target > powLimit; or when hash (as a 256-bit number) > target.
// err != nil only when len(header80) != 80.
func VerifyBlockHeaderPoW(header80 []byte, powLimit *big.Int) (hashHex string, ok bool, err error) {
	// TODO
	return "", false, errTODO
}

// TargetTimespan is nPowTargetTimespan on mainnet (two weeks, in seconds).
const TargetTimespan int64 = 14 * 24 * 60 * 60

// CalculateNextWorkRequired mirrors src/pow.cpp (ignore the BIP94/testnet4 branch
// and fPowNoRetargeting): clamp (last-first) to [TargetTimespan/4, TargetTimespan*4],
// new = old * actual / TargetTimespan, cap at powLimit, return as compact.
func CalculateNextWorkRequired(lastBits uint32, firstBlockTime, lastBlockTime int64, powLimit *big.Int) uint32 {
	// TODO
	return 0
}

// ===========================================================================
// LESSON 5 — Merkle trees and CVE-2012-2459
// Core: ComputeMerkleRoot in src/consensus/merkle.cpp (read the big comment!)
// ===========================================================================

// ComputeMerkleRoot mirrors ComputeMerkleRoot(hashes, &mutated).
// Leaves are INTERNAL-order txids. At each level:
//   - FIRST scan pairs (pos, pos+1) for pos+1 < len: equal pair => mutated = true
//   - THEN, if the level is odd, duplicate the last hash
//   - next level = Hash256(left || right) for each pair
//
// Empty input -> all-zero hash, mutated=false. Must not modify the caller's slice.
func ComputeMerkleRoot(hashes [][32]byte) (root [32]byte, mutated bool) {
	// TODO
	return [32]byte{}, false
}

// MerkleBranch returns the sibling hash at every level for leaf `index`
// (bottom to top) — the data an SPV proof (BIP37 merkleblock) carries.
// Errors: index < 0 or index >= len(hashes).
func MerkleBranch(hashes [][32]byte, index int) ([][32]byte, error) {
	// TODO
	return nil, errTODO
}

// RootFromBranch mirrors ComputeMerkleRootFromBranch in src/test/merkle_tests.cpp:
// for each sibling: if index&1 the sibling is on the LEFT, else on the RIGHT; index >>= 1.
func RootFromBranch(leaf [32]byte, branch [][32]byte, index uint32) [32]byte {
	// TODO
	return [32]byte{}
}

// ===========================================================================
// LESSON 6 — Bech32 (BIP173) / Bech32m (BIP350) and SegWit addresses
// Core: src/bech32.cpp (Encode/Decode), src/key_io.cpp (DecodeDestination)
// ===========================================================================

type Bech32Encoding int

const (
	EncodingInvalid Bech32Encoding = iota
	EncodingBech32                 // checksum constant 1
	EncodingBech32m                // checksum constant 0x2bc830a3
)

// Bech32Encode builds hrp + "1" + data chars + 6 checksum chars.
// data holds 5-bit values (0..31). Errors: enc not Bech32/Bech32m, empty hrp,
// hrp char outside 33..126 or uppercase, any data value > 31, total length > 90.
func Bech32Encode(hrp string, data []byte, enc Bech32Encoding) (string, error) {
	// TODO
	return "", errTODO
}

// Bech32Decode parses a Bech32 or Bech32m string and reports which checksum matched.
// Returns the lowercase hrp and the 5-bit data WITHOUT the 6 checksum values.
// Errors: length > 90, char outside 33..126, mixed case, no '1' separator or
// empty hrp (use the LAST '1'), fewer than 6 data chars, char not in charset,
// checksum matching neither constant.
func Bech32Decode(s string) (hrp string, data []byte, enc Bech32Encoding, err error) {
	// TODO
	return "", nil, EncodingInvalid, errTODO
}

// ConvertBits regroups bits (8->5 to encode, 5->8 to decode).
// With pad=true, leftover bits are zero-padded into one final group.
// With pad=false (decoding), leftover bits >= fromBits, or any non-zero
// leftover bit, is "invalid padding" (see BIP173 reference code).
// Any input value >= 2^fromBits is an error.
func ConvertBits(data []byte, fromBits, toBits uint, pad bool) ([]byte, error) {
	// TODO
	return nil, errTODO
}

// EncodeSegwitAddress: version 0 uses Bech32, versions 1..16 use Bech32m.
// Program rules: 2..40 bytes; version 0 must be exactly 20 or 32 bytes.
func EncodeSegwitAddress(hrp string, version byte, program []byte) (string, error) {
	// TODO
	return "", errTODO
}

// DecodeSegwitAddress checks, in order: decodes; hrp == expectedHRP; data not
// empty; version <= 16; v0 => Bech32, v1+ => Bech32m (the exact errors in
// key_io.cpp); 5->8 conversion without padding; program length rules above.
func DecodeSegwitAddress(expectedHRP, addr string) (version byte, program []byte, err error) {
	// TODO
	return 0, nil, errTODO
}

// ===========================================================================
// LESSON 7 — A tiny Script interpreter with CScriptNum
// Core: class CScriptNum in src/script/script.h, CastToBool and EvalScript in
//       src/script/interpreter.cpp
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

// ScriptNumEncode mirrors CScriptNum::serialize: little-endian magnitude, sign
// in the top bit of the LAST byte; add an extra 0x00/0x80 byte if the top bit
// is already used. 0 encodes as an EMPTY slice.
func ScriptNumEncode(v int64) []byte {
	// TODO
	return nil
}

// ScriptNumDecode mirrors CScriptNum(vch, fRequireMinimal, nMaxNumSize):
//
//	len(b) > maxLen -> "script number overflow"
//	requireMinimal and last byte & 0x7f == 0 and (len<=1 or second-to-last
//	byte has no 0x80 bit) -> "non-minimally encoded script number"
func ScriptNumDecode(b []byte, requireMinimal bool, maxLen int) (int64, error) {
	// TODO
	return 0, errTODO
}

// CastToBool: false for empty, all-zero, or "negative zero" (zeros then a final 0x80).
func CastToBool(b []byte) bool {
	// TODO
	return false
}

// EvalMinimalScript runs a script on an empty stack and returns the final stack.
// Support exactly: OP_0, direct pushes 0x01..0x4b, OP_PUSHDATA1, OP_1NEGATE,
// OP_1..OP_16, OP_VERIFY, OP_DUP, OP_SHA256, OP_EQUAL, OP_EQUALVERIFY, OP_ADD
// (operands decoded with requireMinimal=true, maxLen=4, as with SCRIPT_VERIFY_MINIMALDATA).
// Errors: push past end of script, too few stack items, failed VERIFY/EQUALVERIFY,
// bad ScriptNum, any other opcode. Pushed items must be COPIES of script bytes.
func EvalMinimalScript(script []byte) ([][]byte, error) {
	// TODO
	return nil, errTODO
}
