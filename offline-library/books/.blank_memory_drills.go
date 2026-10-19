package books

import (
	"crypto/sha256"
	"encoding/binary"
	"encoding/hex"
	"fmt"
)

var (
	_ = sha256.Sum256
	_ = binary.LittleEndian
	_ = hex.EncodeToString
	_ = fmt.Errorf
)

const MaxMoney int64 = 21_000_000 * 100_000_000

type OutPoint struct {
	TxID [32]byte
	Vout uint32
}

// Drill 1 (Book 1, Ch 1): Encode uint64 satoshis as 8-byte Little-Endian hex string.
func EncodeSatoshisLEHex(sats uint64) string {
	// TODO: Write from memory! (If stuck, run: ./lab.sh book 1)
	return ""
}

// Drill 2 (Book 1, Ch 1-2): Compute DoubleSHA256(rawTx), reverse the 32 bytes, and return display txid hex.
func ComputeDisplayTxID(rawTx []byte) string {
	// TODO: Write from memory! (If stuck, run: ./lab.sh book 1)
	return ""
}

// Drill 3 (Book 1, Ch 1): Encode uint64 using Bitcoin's CompactSize VarInt rules.
func WriteCompactSize(v uint64) []byte {
	// TODO: Write from memory! (<0xfd -> 1B, <=0xffff -> 0xfd+2B LE, <=0xffffffff -> 0xfe+4B LE, else 0xff+8B LE)
	return nil
}

// Drill 4 (Book 1, Ch 2 & Book 3, Ch 2): Compute BIP340 TaggedHash(tag, msg) = SHA256(SHA256(tag) || SHA256(tag) || msg).
func BIP340TaggedHash(tag string, msg []byte) [32]byte {
	// TODO: Write from memory! (If stuck, run: ./lab.sh book 1)
	return [32]byte{}
}

// Drill 5 (Book 1, Ch 4 & Book 4, Ch 4): Overflow-safe output summation (defeats CVE-2010-5139).
func SafeSumOutputs(outputs []int64) (int64, error) {
	// TODO: Write from memory! (If stuck, run: ./lab.sh book 1)
	return 0, fmt.Errorf("not implemented yet")
}

// Drill 6 (Book 4, Ch 2): Compute SegWit Transaction Weight and Virtual Size (vbytes = ceil(weight / 4)).
func CalcWeightAndVBytes(nonWitnessBytes, witnessBytes int) (weight int, vbytes int) {
	// TODO: Write from memory! (If stuck, run: ./lab.sh book 4)
	return 0, 0
}

// Drill 7 (Book 4, Ch 3): Check if BIP68 relative locktime is active (txVersion >= 2 and bit 31 is 0).
func IsBIP68Active(txVersion int32, nSequence uint32) bool {
	// TODO: Write from memory! (If stuck, run: ./lab.sh book 4)
	return false
}

// Drill 8 (Book 4, Ch 4): Detect duplicate transaction inputs (defeats CVE-2018-17144).
func HasDuplicateInputs(inputs []OutPoint) bool {
	// TODO: Write from memory! (If stuck, run: ./lab.sh book 4)
	return false
}
