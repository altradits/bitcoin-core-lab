// REFERENCE SOLUTION (spoiler). Open only after `./lab.sh check 07` passes on your
// own code, or after 3 honest attempts. Your working file is ../psbt_descriptors.go.
//
// Verified against bitcoin/bitcoin 29.x (f490f5562d) and master (e75b76b12c).
package psbtlab

import (
	"bytes"
	"encoding/base64"
	"encoding/binary"
	"errors"
	"fmt"
	"strconv"
	"strings"
)

// ===========================================================================
// PART A — Descriptor checksums (BIP380)
// ===========================================================================

const descInputCharset = "0123456789()[],'/*abcdefgh@:$%{}" +
	"IJKLMNOPQRSTUVWXYZ&+-.;<=>?!^_|~" +
	"ijklmnopqrstuvwxyzABCDEFGH`#\"\\ "

const descChecksumCharset = "qpzry9x8gf2tvdw0s3jn54khce6mua7l"

func descPolyMod(c uint64, val int) uint64 {
	c0 := uint8(c >> 35)
	c = ((c & 0x7ffffffff) << 5) ^ uint64(val)
	if c0&1 != 0 {
		c ^= 0xf5dee51989
	}
	if c0&2 != 0 {
		c ^= 0xa9fdca3312
	}
	if c0&4 != 0 {
		c ^= 0x1bab10e32d
	}
	if c0&8 != 0 {
		c ^= 0x3706b1677a
	}
	if c0&16 != 0 {
		c ^= 0x644d626ffd
	}
	return c
}

func DescriptorChecksum(desc string) (string, error) {
	c := uint64(1)
	cls, clscount := 0, 0
	for i := 0; i < len(desc); i++ {
		pos := strings.IndexByte(descInputCharset, desc[i])
		if pos < 0 {
			return "", errors.New("Invalid characters in payload")
		}
		c = descPolyMod(c, pos&31)
		cls = cls*3 + (pos >> 5)
		clscount++
		if clscount == 3 {
			c = descPolyMod(c, cls)
			cls, clscount = 0, 0
		}
	}
	if clscount > 0 {
		c = descPolyMod(c, cls)
	}
	for j := 0; j < 8; j++ {
		c = descPolyMod(c, 0)
	}
	c ^= 1
	out := make([]byte, 8)
	for j := 0; j < 8; j++ {
		out[j] = descChecksumCharset[(c>>(5*(7-j)))&31]
	}
	return string(out), nil
}

func AddChecksum(desc string) (string, error) {
	sum, err := DescriptorChecksum(desc)
	if err != nil {
		return "", err
	}
	return desc + "#" + sum, nil
}

func CheckDescriptorChecksum(s string, requireChecksum bool) (string, error) {
	parts := strings.Split(s, "#")
	if len(parts) > 2 {
		return "", errors.New("Multiple '#' symbols")
	}
	if len(parts) == 1 && requireChecksum {
		return "", errors.New("Missing checksum")
	}
	if len(parts) == 2 && len(parts[1]) != 8 {
		return "", fmt.Errorf("Expected 8 character checksum, not %d characters", len(parts[1]))
	}
	sum, err := DescriptorChecksum(parts[0])
	if err != nil {
		return "", err
	}
	if len(parts) == 2 && parts[1] != sum {
		return "", fmt.Errorf("Provided checksum '%s' does not match computed checksum '%s'", parts[1], sum)
	}
	return parts[0], nil
}

// ===========================================================================
// PART B — BIP32 derivation paths
// ===========================================================================

const HardenedBit uint32 = 0x80000000

func ParseKeyPath(path string) ([]uint32, error) {
	if path == "" {
		return nil, errors.New("empty path")
	}
	elems := strings.Split(path, "/")
	if elems[0] == "m" {
		elems = elems[1:]
	}
	out := make([]uint32, 0, len(elems))
	for _, e := range elems {
		hardened := false
		if strings.HasSuffix(e, "'") || strings.HasSuffix(e, "h") {
			hardened = true
			e = e[:len(e)-1]
		}
		if e == "" || strings.Trim(e, "0123456789") != "" {
			return nil, fmt.Errorf("Key path value '%s' is not a valid uint32", e)
		}
		v, err := strconv.ParseUint(e, 10, 32)
		if err != nil {
			return nil, fmt.Errorf("Key path value '%s' is not a valid uint32", e)
		}
		if v > 0x7fffffff {
			return nil, fmt.Errorf("Key path value %d is out of range", v)
		}
		n := uint32(v)
		if hardened {
			n |= HardenedBit
		}
		out = append(out, n)
	}
	return out, nil
}

func FormatKeyPath(path []uint32) string {
	var sb strings.Builder
	sb.WriteString("m")
	for _, p := range path {
		sb.WriteString("/")
		sb.WriteString(strconv.FormatUint(uint64(p&^HardenedBit), 10))
		if p&HardenedBit != 0 {
			sb.WriteString("h")
		}
	}
	return sb.String()
}

// ===========================================================================
// PART C — BIP174 PSBT (version 0) parsing
// ===========================================================================

var PSBTMagic = []byte{0x70, 0x73, 0x62, 0x74, 0xff}

type PSBTInput struct {
	HasNonWitnessUTXO bool
	HasWitnessUTXO    bool
	PartialSigs       int
	BIP32Derivations  int
	HasFinalScriptSig bool
	HasFinalScriptWit bool
	UnknownKeys       int
}

type PSBTOutput struct {
	BIP32Derivations int
	UnknownKeys      int
}

type PSBTSummary struct {
	TxVersion  int32
	NumInputs  int
	NumOutputs int
	LockTime   uint32
	Inputs     []PSBTInput
	Outputs    []PSBTOutput
}

type reader struct{ r *bytes.Reader }

func (rd reader) compact() (uint64, error) {
	b, err := rd.r.ReadByte()
	if err != nil {
		return 0, errors.New("unexpected end of data")
	}
	var n uint64
	switch b {
	case 0xfd:
		buf, err := rd.take(2)
		if err != nil {
			return 0, err
		}
		n = uint64(binary.LittleEndian.Uint16(buf))
		if n < 253 {
			return 0, errors.New("non-canonical ReadCompactSize()")
		}
	case 0xfe:
		buf, err := rd.take(4)
		if err != nil {
			return 0, err
		}
		n = uint64(binary.LittleEndian.Uint32(buf))
		if n < 0x10000 {
			return 0, errors.New("non-canonical ReadCompactSize()")
		}
	case 0xff:
		buf, err := rd.take(8)
		if err != nil {
			return 0, err
		}
		n = binary.LittleEndian.Uint64(buf)
		if n < 0x100000000 {
			return 0, errors.New("non-canonical ReadCompactSize()")
		}
	default:
		n = uint64(b)
	}
	if n > 0x02000000 {
		return 0, errors.New("ReadCompactSize(): size too large")
	}
	return n, nil
}

func (rd reader) take(n uint64) ([]byte, error) {
	if n > uint64(rd.r.Len()) {
		return nil, errors.New("unexpected end of data")
	}
	buf := make([]byte, n)
	_, _ = rd.r.Read(buf)
	return buf, nil
}

type kv struct{ key, value []byte }

// readMap reads key-value pairs until the 0x00 separator.
func readMap(rd reader, where string) ([]kv, error) {
	seen := map[string]bool{}
	var out []kv
	for {
		if rd.r.Len() == 0 {
			return nil, fmt.Errorf("Separator is missing at the end of %s", where)
		}
		klen, err := rd.compact()
		if err != nil {
			return nil, err
		}
		if klen == 0 {
			return out, nil
		}
		key, err := rd.take(klen)
		if err != nil {
			return nil, err
		}
		vlen, err := rd.compact()
		if err != nil {
			return nil, err
		}
		val, err := rd.take(vlen)
		if err != nil {
			return nil, err
		}
		if seen[string(key)] {
			return nil, fmt.Errorf("Duplicate Key in %s", where)
		}
		seen[string(key)] = true
		out = append(out, kv{key, val})
	}
}

func parseUnsignedTx(raw []byte) (version int32, nIn, nOut int, lock uint32, err error) {
	rd := reader{bytes.NewReader(raw)}
	b, err := rd.take(4)
	if err != nil {
		return
	}
	version = int32(binary.LittleEndian.Uint32(b))
	n, err := rd.compact()
	if err != nil {
		return
	}
	for i := uint64(0); i < n; i++ {
		if _, err = rd.take(36); err != nil {
			return
		}
		var l uint64
		if l, err = rd.compact(); err != nil {
			return
		}
		if l != 0 {
			err = errors.New("Unsigned tx does not have empty scriptSigs and scriptWitnesses.")
			return
		}
		if _, err = rd.take(4); err != nil {
			return
		}
	}
	nIn = int(n)
	n, err = rd.compact()
	if err != nil {
		return
	}
	for i := uint64(0); i < n; i++ {
		if _, err = rd.take(8); err != nil {
			return
		}
		var l uint64
		if l, err = rd.compact(); err != nil {
			return
		}
		if _, err = rd.take(l); err != nil {
			return
		}
	}
	nOut = int(n)
	if b, err = rd.take(4); err != nil {
		return
	}
	lock = binary.LittleEndian.Uint32(b)
	if rd.r.Len() != 0 {
		err = errors.New("Size of value was not the stated size")
	}
	return
}

func isPubkeyKey(k []byte) bool { return len(k) == 34 || len(k) == 66 }

func ParsePSBT(b64 string) (PSBTSummary, error) {
	var s PSBTSummary
	raw, err := base64.StdEncoding.DecodeString(strings.TrimSpace(b64))
	if err != nil {
		return s, fmt.Errorf("invalid base64: %w", err)
	}
	if len(raw) < 5 || !bytes.Equal(raw[:5], PSBTMagic) {
		return s, errors.New("Invalid PSBT magic bytes")
	}
	rd := reader{bytes.NewReader(raw[5:])}

	global, err := readMap(rd, "the global map")
	if err != nil {
		return s, err
	}
	haveTx := false
	for _, e := range global {
		if e.key[0] == 0x00 {
			if len(e.key) != 1 {
				return s, errors.New("Global unsigned tx key is more than one byte type")
			}
			s.TxVersion, s.NumInputs, s.NumOutputs, s.LockTime, err = parseUnsignedTx(e.value)
			if err != nil {
				return s, err
			}
			haveTx = true
		}
	}
	if !haveTx {
		return s, errors.New("No unsigned transaction was provided")
	}

	for i := 0; i < s.NumInputs; i++ {
		m, err := readMap(rd, "an input map")
		if err != nil {
			return s, err
		}
		var in PSBTInput
		for _, e := range m {
			t := e.key[0]
			switch t {
			case 0x00, 0x01, 0x03, 0x04, 0x05, 0x07, 0x08:
				if len(e.key) != 1 {
					return s, fmt.Errorf("input key type 0x%02x is more than one byte", t)
				}
				switch t {
				case 0x00:
					in.HasNonWitnessUTXO = true
				case 0x01:
					in.HasWitnessUTXO = true
				case 0x07:
					in.HasFinalScriptSig = true
				case 0x08:
					in.HasFinalScriptWit = true
				}
			case 0x02:
				if !isPubkeyKey(e.key) {
					return s, errors.New("Size of key was not the expected size for the type partial signature pubkey")
				}
				in.PartialSigs++
			case 0x06:
				if !isPubkeyKey(e.key) {
					return s, errors.New("Size of key was not the expected size for the type BIP32 keypath")
				}
				in.BIP32Derivations++
			default:
				in.UnknownKeys++
			}
		}
		s.Inputs = append(s.Inputs, in)
	}
	for i := 0; i < s.NumOutputs; i++ {
		m, err := readMap(rd, "an output map")
		if err != nil {
			return s, err
		}
		var out PSBTOutput
		for _, e := range m {
			t := e.key[0]
			switch t {
			case 0x00, 0x01:
				if len(e.key) != 1 {
					return s, fmt.Errorf("output key type 0x%02x is more than one byte", t)
				}
			case 0x02:
				if !isPubkeyKey(e.key) {
					return s, errors.New("Size of key was not the expected size for the type BIP32 keypath")
				}
				out.BIP32Derivations++
			default:
				out.UnknownKeys++
			}
		}
		s.Outputs = append(s.Outputs, out)
	}
	if rd.r.Len() != 0 {
		return s, errors.New("extra data after PSBT")
	}
	return s, nil
}

// NextRole is a simplified AnalyzePSBT (src/node/psbt.cpp).
func NextRole(s PSBTSummary) string {
	rank := map[string]int{"updater": 1, "signer": 2, "finalizer": 3, "extractor": 4}
	next := "extractor"
	for _, in := range s.Inputs {
		var r string
		switch {
		case in.HasFinalScriptSig || in.HasFinalScriptWit:
			r = "extractor"
		case !in.HasWitnessUTXO && !in.HasNonWitnessUTXO:
			r = "updater"
		case in.PartialSigs == 0:
			r = "signer"
		default:
			r = "finalizer"
		}
		if rank[r] < rank[next] {
			next = r
		}
	}
	return next
}
