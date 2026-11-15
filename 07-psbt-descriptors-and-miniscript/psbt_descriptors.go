// Stage 07 — Descriptors, BIP32 paths and PSBT parsing. YOUR WORKING FILE.
//
// `./lab.sh blank 07` copies this skeleton to ../psbt_descriptors.go. Write every
// body yourself, then `./lab.sh check 07` (or `go test ./...` in the stage dir).
// Standard library only. Paths below are in the bitcoin/bitcoin repo and exist on
// both 29.x (f490f5562d) and master (e75b76b12c).
// Reference answer: ../solutions/ — only after the tests pass or 3 honest attempts.
package psbtlab

import "errors"

var errTODO = errors.New("TODO: not implemented yet")

// ===========================================================================
// PART A — Descriptor checksums (BIP380)
// Core: PolyMod, DescriptorChecksum, CheckChecksum in src/script/descriptor.cpp
// ===========================================================================

// DescriptorChecksum returns the 8-character checksum of desc (without '#').
// Algorithm (copy the charsets and generator constants from Core yourself):
//   - INPUT_CHARSET has 96 symbols in 3 groups of 32. For each char at position pos:
//     feed (pos & 31) to PolyMod; accumulate cls = cls*3 + (pos >> 5); every 3
//     chars feed cls and reset it. After the loop feed any leftover cls.
//   - Feed 8 zeros, XOR with 1, and read 8 groups of 5 bits (most significant first)
//     through CHECKSUM_CHARSET ("qpzry9x8gf2tvdw0s3jn54khce6mua7l").
//
// Error: any character not in INPUT_CHARSET -> "Invalid characters in payload".
func DescriptorChecksum(desc string) (string, error) {
	// TODO
	return "", errTODO
}

// AddChecksum returns desc + "#" + checksum (Core: AddChecksum).
func AddChecksum(desc string) (string, error) {
	// TODO
	return "", errTODO
}

// CheckDescriptorChecksum mirrors CheckChecksum and returns the descriptor
// WITHOUT its "#checksum". Errors use Core's wording:
//
//	more than one '#'                    -> "Multiple '#' symbols"
//	no '#' and requireChecksum           -> "Missing checksum"
//	checksum length != 8                 -> "Expected 8 character checksum, not N characters"
//	bad payload character                -> "Invalid characters in payload"
//	mismatch -> "Provided checksum 'X' does not match computed checksum 'Y'"
func CheckDescriptorChecksum(s string, requireChecksum bool) (string, error) {
	// TODO
	return "", errTODO
}

// ===========================================================================
// PART B — BIP32 derivation paths
// Core: ParseKeyPathNum / ParseKeyPath in src/script/descriptor.cpp,
//       FormatHDKeypath / WriteHDKeypath in src/util/bip32.cpp
// ===========================================================================

// HardenedBit marks a hardened child index (BIP32: i >= 2^31).
const HardenedBit uint32 = 0x80000000

// ParseKeyPath parses "m/84h/1'/0h/0/5" or a descriptor origin path "84h/0h/0h".
//   - An optional leading "m" element is allowed only as the FIRST element.
//   - Each element: decimal digits, optionally ONE trailing ' or h (hardened).
//   - Value must fit uint32 AND be <= 0x7fffffff, then OR in HardenedBit if hardened.
//
// Errors: empty string, empty element ("m/0/"), signs/spaces/letters, two markers,
// value > 0x7fffffff ("Key path value N is out of range").
func ParseKeyPath(path string) ([]uint32, error) {
	// TODO
	return nil, errTODO
}

// FormatKeyPath writes "m" followed by "/N" per element, appending "h" for
// hardened elements (Core's default, apostrophe=false).
func FormatKeyPath(path []uint32) string {
	// TODO
	return ""
}

// ===========================================================================
// PART C — BIP174 PSBT version 0
// Core: PartiallySignedTransaction::Unserialize, PSBTInput/PSBTOutput in src/psbt.h,
//       DecodeRawPSBT in src/psbt.cpp, AnalyzePSBT in src/node/psbt.cpp
// ===========================================================================

// PSBTMagic is "psbt" followed by 0xff (PSBT_MAGIC_BYTES in src/psbt.h).
var PSBTMagic = []byte{0x70, 0x73, 0x62, 0x74, 0xff}

// PSBTInput counts what one input map holds.
type PSBTInput struct {
	HasNonWitnessUTXO bool // key type 0x00 (PSBT_IN_NON_WITNESS_UTXO)
	HasWitnessUTXO    bool // 0x01 (PSBT_IN_WITNESS_UTXO)
	PartialSigs       int  // 0x02 (PSBT_IN_PARTIAL_SIG), key = 0x02 || pubkey
	BIP32Derivations  int  // 0x06 (PSBT_IN_BIP32_DERIVATION), key = 0x06 || pubkey
	HasFinalScriptSig bool // 0x07 (PSBT_IN_SCRIPTSIG)
	HasFinalScriptWit bool // 0x08 (PSBT_IN_SCRIPTWITNESS)
	UnknownKeys       int  // any other type: keep (count), do not reject
}

// PSBTOutput counts what one output map holds.
type PSBTOutput struct {
	BIP32Derivations int // 0x02 (PSBT_OUT_BIP32_DERIVATION)
	UnknownKeys      int // any type other than 0x00, 0x01, 0x02
}

// PSBTSummary is the result of ParsePSBT.
type PSBTSummary struct {
	TxVersion  int32
	NumInputs  int
	NumOutputs int
	LockTime   uint32
	Inputs     []PSBTInput
	Outputs    []PSBTOutput
}

// ParsePSBT decodes a base64 PSBT (version 0) and checks its structure.
//
// Format: magic, then a GLOBAL map, then one map per input, then one map per
// output. A map is a list of <CompactSize keylen><key><CompactSize vallen><value>
// ending with a single 0x00 byte (keylen 0 = separator). key[0] is the type.
//
// Must reject (each is a BIP174 invalid test vector or a Core error string):
//   - bad base64; magic missing
//   - a map with no 0x00 separator before the data ends; truncated key/value
//   - the same full key twice in one map ("Duplicate Key")
//   - global type 0x00 key longer than 1 byte; no global type 0x00 at all
//   - unsigned tx (the value of global 0x00) that: has a non-empty scriptSig,
//     is in witness serialization, or does not use exactly all value bytes
//     (parse it as a LEGACY tx: version, vin, vout, locktime — no marker/flag)
//   - fewer input/output maps than the unsigned tx has inputs/outputs
//   - input types 0x00,0x01,0x03,0x04,0x05,0x07,0x08 and output types 0x00,0x01
//     with a key longer than 1 byte
//   - input 0x02/0x06 and output 0x02 keys whose length is not 34 or 66
//     (1 type byte + 33-byte compressed or 65-byte uncompressed pubkey)
//   - any bytes left after the last output map ("extra data after PSBT")
//
// CompactSize must be canonical and <= 0x02000000. Never allocate from an
// untrusted length before checking enough bytes remain.
func ParsePSBT(b64 string) (PSBTSummary, error) {
	// TODO
	return PSBTSummary{}, errTODO
}

// NextRole is a simplified AnalyzePSBT: which BIP174 role must act next?
// Per input:
//
//	final scriptSig or final scriptWitness present -> "extractor"
//	no UTXO (neither 0x00 nor 0x01)                -> "updater"
//	UTXO but zero partial sigs                     -> "signer"
//	otherwise                                      -> "finalizer"
//
// The PSBT's role is the LEAST advanced over all inputs
// (updater < signer < finalizer < extractor). Zero inputs -> "extractor".
// (Core also checks whether the signatures are actually sufficient; we don't.)
func NextRole(s PSBTSummary) string {
	// TODO
	return ""
}
