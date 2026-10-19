# Book 1: Go & Systems Programming Building Blocks (From Memory)

> **Purpose of This Offline Book:**
> When you get stuck writing Go code in Stages `00`–`12` or the Bug Dojo, **do not open Google or ask AI**. Read the exact building block below, close the file, and type the solution from memory in the **Blind Recall Drills** at the bottom.

---

## Chapter 1: Bytes, Hexadecimal, and Endianness (Required for Stages 00, 02, 05, 08)

Bitcoin is a binary protocol. Every hash, integer, and signature is just a slice of bytes (`[]byte`).

### 1.1 Hex String $\leftrightarrow$ Byte Slice (`encoding/hex`)
```go
package main

import (
	"encoding/hex"
	"fmt"
)

func main() {
	// Decode hex string into raw bytes ([]byte)
	rawBytes, err := hex.DecodeString("01000000")
	if err != nil {
		panic(err)
	}

	// Encode raw bytes ([]byte) back into a lowercase hex string
	hexStr := hex.EncodeToString(rawBytes)
	fmt.Println(hexStr) // "01000000"
}
```

### 1.2 Little-Endian vs Big-Endian Integers (`encoding/binary`)
Bitcoin serializes almost all integers (`version`, `vout`, `value`, `locktime`, `nBits`) in **Little-Endian** (least-significant byte first):
- `uint32(1)` in 4-byte **Little-Endian**: `01 00 00 00`
- `uint32(1)` in 4-byte **Big-Endian**: `00 00 00 01`

```go
import "encoding/binary"

// Write uint32 and uint64 in Little-Endian:
var buf4 [4]byte
binary.LittleEndian.PutUint32(buf4[:], 1) // [0x01, 0x00, 0x00, 0x00]

var buf8 [8]byte
binary.LittleEndian.PutUint64(buf8[:], 100_000_000) // 1 BTC in satoshis (8 bytes LE)

// Read uint32 and uint64 from Little-Endian bytes:
v := binary.LittleEndian.Uint32(buf4[:])
sats := binary.LittleEndian.Uint64(buf8[:])
```

### 1.3 Reversing Byte Order (Internal Byte Order vs RPC Display `txid`)
Bitcoin hashes (`txid`, `blockhash`) are 32 bytes internally, but RPCs display them **reversed** (big-endian hex):
```go
func ReverseBytes(b []byte) []byte {
	out := make([]byte, len(b))
	for i := 0; i < len(b); i++ {
		out[i] = b[len(b)-1-i]
	}
	return out
}
```

---

## Chapter 2: Cryptographic Hashing in Go (`crypto/sha256`) (Required for Stages 02, 05, 07, 12)

Bitcoin uses `HASH256(x) = SHA256(SHA256(x))` for block hashes, transaction IDs (`txid`), and Merkle trees, and tagged hashes `SHA256(SHA256(tag) || SHA256(tag) || msg)` for Taproot (BIP340/341).

```go
import "crypto/sha256"

// Single SHA256 (returns [32]byte; use [:] to get []byte)
func SHA256(data []byte) [32]byte {
	return sha256.Sum256(data)
}

// Double SHA256 (Bitcoin HASH256)
func DoubleSHA256(data []byte) [32]byte {
	first := sha256.Sum256(data)
	return sha256.Sum256(first[:])
}

// BIP340 Tagged Hash: SHA256(SHA256(tag) || SHA256(tag) || msg)
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
```

---

## Chapter 3: Buffers, Structs, Methods & Interfaces (`bytes.Buffer`) (Required for Stages 02, 05, 06)

When serializing a Bitcoin transaction or block header from scratch, use `bytes.Buffer` to append fields sequentially without manual index math:

```go
import (
	"bytes"
	"encoding/binary"
)

type OutPoint struct {
	TxID [32]byte // Internal byte order
	Vout uint32
}

func (o OutPoint) Serialize() []byte {
	var buf bytes.Buffer
	buf.Write(o.TxID[:])
	var voutBytes [4]byte
	binary.LittleEndian.PutUint32(voutBytes[:], o.Vout)
	buf.Write(voutBytes[:])
	return buf.Bytes()
}
```

---

## Chapter 4: Overflow-Safe Integer Math in Go (Required for Bug Dojo Mission 1 & Stage 09)

In 64-bit Go, `int64` ranges from `-9,223,372,036,854,775,808` to `+9,223,372,036,854,775,807`.
If an attacker passes a massive output value near `math.MaxInt64`, adding two outputs (`total += outValue`) wraps around into a **negative number**!
Always check bounds **before** adding:

```go
const MaxMoney int64 = 21_000_000 * 100_000_000 // 2,100,000,000,000,000 sats

func MoneyRange(sats int64) bool {
	return sats >= 0 && sats <= MaxMoney
}

func SafeSumOutputs(outputs []int64) (int64, error) {
	var total int64
	for _, v := range outputs {
		if !MoneyRange(v) {
			return 0, fmt.Errorf("output value out of range: %d", v)
		}
		if total+v > MaxMoney { // Safe because both total <= MaxMoney and v <= MaxMoney (2*MaxMoney << MaxInt64)
			return 0, fmt.Errorf("cumulative output value exceeds MAX_MONEY")
		}
		total += v
	}
	return total, nil
}
```

---

## Chapter 5: Writing Table-Driven Go Tests (`testing`) (Required for All Stages)

Every Bitcoin builder verifies their code with deterministic unit tests (`go test -v ./...`):

```go
package main

import "testing"

func TestMoneyRange(t *testing.T) {
	tests := []struct {
		name string
		sats int64
		want bool
	}{
		{"zero sats is valid", 0, true},
		{"1 BTC is valid", 100_000_000, true},
		{"MAX_MONEY is valid", 21_000_000 * 100_000_000, true},
		{"negative sats is invalid", -1, false},
		{"MAX_MONEY + 1 is invalid", 21_000_000*100_000_000 + 1, false},
	}

	for _, tc := range tests {
		t.Run(tc.name, func(t *testing.T) {
			got := MoneyRange(tc.sats)
			if got != tc.want {
				t.Errorf("MoneyRange(%d) = %v; want %v", tc.sats, got, tc.want)
			}
		})
	}
}
```

---

## 🧠 Blind Recall Challenges (Close This File & Write From Memory!)

Do not copy-paste. Open a scratch file (`scratch_drill.go`) and write each function **100% from memory** until `go test` passes without looking at the notes:

1. **Drill 1.1 (Endianness):** Write a function `EncodeSatoshisLE(sats uint64) [8]byte` that encodes `50_0000_0000` satoshis (50 BTC) into 8 Little-Endian bytes and returns the hex string `"00f2052a01000000"`.
2. **Drill 1.2 (Byte Reversal):** Write `TxIDFromRawTx(rawTx []byte) string` that computes `DoubleSHA256(rawTx)`, reverses the 32 bytes, and returns the 64-character hex `txid`.
3. **Drill 1.3 (CompactSize VarInt):** Write `WriteCompactSize(v uint64) []byte` following Bitcoin's CompactSize rules:
   - `< 0xfd` $\rightarrow$ 1 byte (`uint8(v)`)
   - `<= 0xffff` $\rightarrow$ `0xfd` followed by 2-byte Little-Endian `uint16(v)`
   - `<= 0xffffffff` $\rightarrow$ `0xfe` followed by 4-byte Little-Endian `uint32(v)`
   - `> 0xffffffff` $\rightarrow$ `0xff` followed by 8-byte Little-Endian `uint64(v)`
4. **Drill 1.4 (Tagged Hash):** Write `TapSighash(msg []byte) [32]byte` that computes `TaggedHash("TapSighash", msg)` from memory.
5. **Drill 1.5 (Overflow Guard):** Without looking at Chapter 4, write `CheckOutputValue(outputs []int64) error` that defeats the `CVE-2010-5139` 184-Billion BTC overflow exploit.
