package books

import (
	"crypto/sha256"
	"encoding/binary"
	"encoding/hex"
	"fmt"
)

const MaxMoney int64 = 21_000_000 * 100_000_000

type OutPoint struct {
	TxID [32]byte
	Vout uint32
}

// Drill 1 (Book 1, Ch 1): Encode uint64 satoshis as 8-byte Little-Endian hex string.
func EncodeSatoshisLEHex(sats uint64) string {
	var buf [8]byte
	binary.LittleEndian.PutUint64(buf[:], sats)
	return hex.EncodeToString(buf[:])
}

// Drill 2 (Book 1, Ch 1-2): Compute DoubleSHA256(rawTx), reverse the 32 bytes, and return display txid hex.
func ComputeDisplayTxID(rawTx []byte) string {
	first := sha256.Sum256(rawTx)
	second := sha256.Sum256(first[:])
	var rev [32]byte
	for i := 0; i < 32; i++ {
		rev[i] = second[31-i]
	}
	return hex.EncodeToString(rev[:])
}

// Drill 3 (Book 1, Ch 1): Encode uint64 using Bitcoin's CompactSize VarInt rules.
func WriteCompactSize(v uint64) []byte {
	if v < 0xfd {
		return []byte{uint8(v)}
	}
	if v <= 0xffff {
		out := make([]byte, 3)
		out[0] = 0xfd
		binary.LittleEndian.PutUint16(out[1:], uint16(v))
		return out
	}
	if v <= 0xffffffff {
		out := make([]byte, 5)
		out[0] = 0xfe
		binary.LittleEndian.PutUint32(out[1:], uint32(v))
		return out
	}
	out := make([]byte, 9)
	out[0] = 0xff
	binary.LittleEndian.PutUint64(out[1:], v)
	return out
}

// Drill 4 (Book 1, Ch 2 & Book 3, Ch 2): Compute BIP340 TaggedHash(tag, msg) = SHA256(SHA256(tag) || SHA256(tag) || msg).
func BIP340TaggedHash(tag string, msg []byte) [32]byte {
	tagHash := sha256.Sum256([]byte(tag))
	h := sha256.New()
	h.Write(tagHash[:])
	h.Write(tagHash[:])
	h.Write(msg)
	var out [32]byte
	copy(out[:], h.Sum(nil))
	return out
}

// Drill 5 (Book 1, Ch 4 & Book 4, Ch 4): Overflow-safe output summation (defeats CVE-2010-5139).
func SafeSumOutputs(outputs []int64) (int64, error) {
	var total int64
	for _, v := range outputs {
		if v < 0 || v > MaxMoney {
			return 0, fmt.Errorf("output value out of range: %d", v)
		}
		if total+v > MaxMoney {
			return 0, fmt.Errorf("cumulative output value exceeds MAX_MONEY")
		}
		total += v
	}
	return total, nil
}

// Drill 6 (Book 4, Ch 2): Compute SegWit Transaction Weight and Virtual Size (vbytes = ceil(weight / 4)).
func CalcWeightAndVBytes(nonWitnessBytes, witnessBytes int) (weight int, vbytes int) {
	weight = nonWitnessBytes*4 + witnessBytes
	vbytes = (weight + 3) / 4
	return weight, vbytes
}

// Drill 7 (Book 4, Ch 3): Check if BIP68 relative locktime is active (txVersion >= 2 and bit 31 is 0).
func IsBIP68Active(txVersion int32, nSequence uint32) bool {
	if txVersion < 2 {
		return false
	}
	return (nSequence & (uint32(1) << 31)) == 0
}

// Drill 8 (Book 4, Ch 4): Detect duplicate transaction inputs (defeats CVE-2018-17144).
func HasDuplicateInputs(inputs []OutPoint) bool {
	seen := make(map[OutPoint]struct{}, len(inputs))
	for _, in := range inputs {
		if _, exists := seen[in]; exists {
			return true
		}
		seen[in] = struct{}{}
	}
	return false
}
