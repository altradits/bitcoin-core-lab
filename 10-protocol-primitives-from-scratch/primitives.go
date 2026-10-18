package primitives

import (
	"bytes"
	"crypto/sha256"
	"encoding/binary"
	"encoding/hex"
	"errors"
	"fmt"
	"math/big"
)

// ============================================================================
// LESSON 1: Double-SHA256 (SHA256d), Byte-Order Reversal & BIP340 Tagged Hashes
// Upstream C++: src/crypto/sha256.cpp & src/uint256.h
// ============================================================================

// Hash256 computes Satoshi's double-SHA256: SHA256(SHA256(data)).
// Used for block headers, txids, wtxids, and Merkle tree nodes.
func Hash256(data []byte) [32]byte {
	first := sha256.Sum256(data)
	return sha256.Sum256(first[:])
}

// ReverseBytes32 converts between internal little-endian byte order and human-readable
// big-endian hex display order (used for txids and block hashes in RPC output).
func ReverseBytes32(b [32]byte) [32]byte {
	var out [32]byte
	for i := 0; i < 32; i++ {
		out[i] = b[31-i]
	}
	return out
}

// TaggedHash implements BIP340 domain-separated hashing:
// SHA256(SHA256(tag) || SHA256(tag) || msg)
// Used in Taproot (BIP341 "TapLeaf", "TapBranch", "TapTweak") and Schnorr ("BIP0340/challenge").
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

// ============================================================================
// LESSON 2: Bitcoin Wire Serialization — CompactSize (VarInt) Encoder/Decoder
// Upstream C++: src/serialize.h -> WriteCompactSize() / ReadCompactSize()
// ============================================================================
//
// Why does Bitcoin use CompactSize?
// Every vector in the Bitcoin P2P and transaction wire format (number of inputs,
// number of outputs, script length, witness stack count) is prefixed with a
// variable-length integer to save block space:
//   - 0x00 .. 0xfc (0..252)        -> 1 byte:  [val]
//   - 0xfd .. 0xffff (253..65535)  -> 3 bytes: 0xfd + uint16_le
//   - 0x10000 .. 0xffffffff        -> 5 bytes: 0xfe + uint32_le
//   - 0x100000000 .. uint64_max    -> 9 bytes: 0xff + uint64_le
// CONSENSUS RULE: CompactSize MUST be minimally encoded (e.g., encoding 100 as 0xfd6400 is rejected!).
func EncodeCompactSize(n uint64) []byte {
	if n < 253 {
		return []byte{byte(n)}
	} else if n <= 0xFFFF {
		buf := make([]byte, 3)
		buf[0] = 0xfd
		binary.LittleEndian.PutUint16(buf[1:], uint16(n))
		return buf
	} else if n <= 0xFFFFFFFF {
		buf := make([]byte, 5)
		buf[0] = 0xfe
		binary.LittleEndian.PutUint32(buf[1:], uint32(n))
		return buf
	}
	buf := make([]byte, 9)
	buf[0] = 0xff
	binary.LittleEndian.PutUint64(buf[1:], n)
	return buf
}

func DecodeCompactSize(r *bytes.Reader) (uint64, error) {
	first, err := r.ReadByte()
	if err != nil {
		return 0, err
	}
	switch first {
	case 0xfd:
		var v uint16
		if err := binary.Read(r, binary.LittleEndian, &v); err != nil {
			return 0, err
		}
		if v < 253 {
			return 0, errors.New("non-canonical CompactSize (value < 253 encoded with 0xfd)")
		}
		return uint64(v), nil
	case 0xfe:
		var v uint32
		if err := binary.Read(r, binary.LittleEndian, &v); err != nil {
			return 0, err
		}
		if v <= 0xFFFF {
			return 0, errors.New("non-canonical CompactSize (value <= 0xffff encoded with 0xfe)")
		}
		return uint64(v), nil
	case 0xff:
		var v uint64
		if err := binary.Read(r, binary.LittleEndian, &v); err != nil {
			return 0, err
		}
		if v <= 0xFFFFFFFF {
			return 0, errors.New("non-canonical CompactSize (value <= 0xffffffff encoded with 0xff)")
		}
		return v, nil
	default:
		return uint64(first), nil
	}
}

// ============================================================================
// LESSON 3: Proof-of-Work & 80-Byte Block Header Verification (Genesis Block)
// Upstream C++: src/pow.cpp -> CheckProofOfWork() & src/arith_uint256.cpp -> SetCompact()
// ============================================================================
//
// Every Bitcoin block header is exactly 80 bytes:
//   [0..4]   Version (int32 little-endian)
//   [4..36]  PrevBlockHash (32 bytes internal byte order)
//   [36..68] MerkleRoot (32 bytes internal byte order)
//   [68..72] Timestamp (uint32 little-endian)
//   [72..76] Bits / Compact Target (uint32 little-endian, e.g. 0x1d00ffff)
//   [76..80] Nonce (uint32 little-endian)

// CompactBitsToTarget decodes Bitcoin's 32-bit compact "nBits" target representation
// into a 256-bit big.Int threshold:
//   exponent = nBits >> 24
//   mantissa = nBits & 0x007fffff
//   target   = mantissa * 2^(8 * (exponent - 3))
func CompactBitsToTarget(nBits uint32) *big.Int {
	exponent := int(nBits >> 24)
	mantissa := nBits & 0x007fffff
	target := new(big.Int).SetUint64(uint64(mantissa))
	if exponent <= 3 {
		target.Rsh(target, uint(8*(3-exponent)))
	} else {
		target.Lsh(target, uint(8*(exponent-3)))
	}
	return target
}

// VerifyBlockHeaderPoW hashes an 80-byte raw block header and verifies that
// SHA256d(header) <= CompactBitsToTarget(nBits).
func VerifyBlockHeaderPoW(header80 []byte) (blockHashHex string, validPoW bool, err error) {
	if len(header80) != 80 {
		return "", false, fmt.Errorf("block header must be exactly 80 bytes, got %d", len(header80))
	}
	nBits := binary.LittleEndian.Uint32(header80[72:76])
	target := CompactBitsToTarget(nBits)

	rawHash := Hash256(header80)
	displayHash := ReverseBytes32(rawHash)
	hashInt := new(big.Int).SetBytes(displayHash[:])

	return hex.EncodeToString(displayHash[:]), hashInt.Cmp(target) <= 0, nil
}

// CalculateNextWorkRequired implements Satoshi's 2016-block difficulty retargeting algorithm
// in src/pow.cpp:
//   actualTimespan = clamped to [targetTimespan / 4, targetTimespan * 4]
//   newTarget = oldTarget * actualTimespan / targetTimespan
func CalculateNextWorkRequired(oldTarget *big.Int, actualTimespanSec int64) *big.Int {
	const TargetTimespanSec int64 = 14 * 24 * 60 * 60 // 1,209,600 seconds (2 weeks)
	if actualTimespanSec < TargetTimespanSec/4 {
		actualTimespanSec = TargetTimespanSec / 4
	}
	if actualTimespanSec > TargetTimespanSec*4 {
		actualTimespanSec = TargetTimespanSec * 4
	}
	newTarget := new(big.Int).Mul(oldTarget, big.NewInt(actualTimespanSec))
	newTarget.Div(newTarget, big.NewInt(TargetTimespanSec))
	return newTarget
}

// ============================================================================
// LESSON 4: Merkle Tree Engine (ComputeMerkleRoot & CVE-2012-2459 Understanding)
// Upstream C++: src/consensus/merkle.cpp -> ComputeMerkleRoot()
// ============================================================================
//
// Given a slice of 32-byte internal-order transaction hashes, ComputeMerkleRoot
// pairs adjacent hashes (h_left || h_right) and computes Hash256(h_left || h_right).
// If a level has an odd number of hashes, the final hash is duplicated before hashing.
func ComputeMerkleRoot(txHashes [][32]byte) ([32]byte, error) {
	if len(txHashes) == 0 {
		return [32]byte{}, errors.New("cannot compute Merkle root of empty tx list")
	}
	level := make([][32]byte, len(txHashes))
	copy(level, txHashes)

	for len(level) > 1 {
		if len(level)%2 == 1 {
			level = append(level, level[len(level)-1])
		}
		nextLevel := make([][32]byte, len(level)/2)
		for i := 0; i < len(level); i += 2 {
			var combined [64]byte
			copy(combined[:32], level[i][:])
			copy(combined[32:], level[i+1][:])
			nextLevel[i/2] = Hash256(combined[:])
		}
		level = nextLevel
	}
	return level[0], nil
}

// ============================================================================
// LESSON 5: Stack-Based Bitcoin Script Virtual Machine (Mini EvalScript)
// Upstream C++: src/script/interpreter.cpp -> EvalScript()
// ============================================================================

const (
	OP_0           byte = 0x00
	OP_1           byte = 0x51
	OP_DUP         byte = 0x76
	OP_EQUAL       byte = 0x87
	OP_EQUALVERIFY byte = 0x88
	OP_SHA256      byte = 0xa8
)

// EvalMinimalScript executes a subset of Bitcoin Script opcodes on a stack of byte slices:
//   - Data pushes: length byte 0x01..0x4b (1..75 bytes) pushes the next N bytes onto the stack
//   - OP_DUP (0x76): duplicates the top stack item
//   - OP_SHA256 (0xa8): replaces the top stack item with its 32-byte SHA-256 digest
//   - OP_EQUAL (0x87): pops two items, pushes 0x01 if equal, or empty slice []byte{} if unequal
//   - OP_EQUALVERIFY (0x88): runs OP_EQUAL and immediately fails script execution if unequal
func EvalMinimalScript(script []byte) ([][]byte, error) {
	var stack [][]byte
	i := 0
	for i < len(script) {
		op := script[i]
		i++
		switch {
		case op == OP_0:
			stack = append(stack, []byte{})
		case op == OP_1:
			stack = append(stack, []byte{1})
		case op >= 0x01 && op <= 0x4b:
			n := int(op)
			if i+n > len(script) {
				return nil, errors.New("script push exceeds script bounds")
			}
			data := make([]byte, n)
			copy(data, script[i:i+n])
			stack = append(stack, data)
			i += n
		case op == OP_DUP:
			if len(stack) < 1 {
				return nil, errors.New("OP_DUP on empty stack")
			}
			top := stack[len(stack)-1]
			dup := make([]byte, len(top))
			copy(dup, top)
			stack = append(stack, dup)
		case op == OP_SHA256:
			if len(stack) < 1 {
				return nil, errors.New("OP_SHA256 on empty stack")
			}
			top := stack[len(stack)-1]
			sum := sha256.Sum256(top)
			stack[len(stack)-1] = sum[:]
		case op == OP_EQUAL, op == OP_EQUALVERIFY:
			if len(stack) < 2 {
				return nil, errors.New("OP_EQUAL requires 2 stack elements")
			}
			a := stack[len(stack)-2]
			b := stack[len(stack)-1]
			stack = stack[:len(stack)-2]
			eq := bytes.Equal(a, b)
			if op == OP_EQUALVERIFY {
				if !eq {
					return nil, errors.New("SCRIPT_ERR_EQUALVERIFY: top two stack items not equal")
				}
			} else {
				if eq {
					stack = append(stack, []byte{1})
				} else {
					stack = append(stack, []byte{})
				}
			}
		default:
			return nil, fmt.Errorf("unsupported opcode 0x%02x", op)
		}
	}
	return stack, nil
}
