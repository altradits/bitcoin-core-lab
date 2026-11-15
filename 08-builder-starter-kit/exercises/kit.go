// Stage 08 — Builder starter kit. YOUR WORKING FILE.
//
// `./lab.sh blank 08` copies this skeleton to ../kit.go. Write every body yourself,
// then `./lab.sh check 08` (= go test ./...). The HTTP shell in ../cmd/kit only
// calls these functions. Standard library only.
// Reference answer: ../solutions/ — only after the tests pass or 3 honest attempts.
package builderkit

import (
	"encoding/json"
	"errors"
	"net/http"
)

var errTODO = errors.New("TODO: not implemented yet")

const (
	SatsPerBTC   int64 = 100_000_000             // COIN, src/consensus/amount.h
	MaxMoneySats int64 = 21_000_000 * SatsPerBTC // MAX_MONEY, src/consensus/amount.h
)

// ---------------------------------------------------------------- amounts
// Core: AmountFromValue (src/rpc/util.cpp), ValueFromAmount (declared in src/core_io.h),
//       ParseFixedPoint (src/util/strencodings.cpp). Never use float64 for money.

// FormatBTC prints sats as "<whole>.<8 digits>", e.g. 50000 -> "0.00050000".
// Error if sats < 0 or sats > MaxMoneySats.
func FormatBTC(sats int64) (string, error) {
	// TODO
	return "", errTODO
}

// ParseBTC parses a plain decimal BTC string into sats with INTEGER math only.
// Accept: digits, optionally "." followed by 1..8 digits ("0.1", "21000000").
// Reject: empty, sign (+/-), exponent, hex, spaces, ".5", "1.", >8 decimals,
// more than one ".", anything above MaxMoneySats.
// (This is a stricter subset of Core's ParseFixedPoint, which also accepts exponents.)
func ParseBTC(s string) (int64, error) {
	// TODO
	return 0, errTODO
}

// ---------------------------------------------------------------- dust
// Core: GetDustThreshold / IsDust in src/policy/policy.cpp, CFeeRate::GetFee in
// src/policy/feerate.cpp, CScript::IsWitnessProgram / IsUnspendable in src/script/script.{h,cpp}.

// DustThreshold mirrors GetDustThreshold(txout, dustRelayFee):
//   - unspendable (first byte OP_RETURN 0x6a, or script > 10000 bytes) -> 0
//   - size = serialized CTxOut size = 8 + CompactSize(len) + len
//   - witness program (IsWitnessProgram: 4..42 bytes, first byte OP_0 or OP_1..OP_16,
//     second byte == len-2): size += 32 + 4 + 1 + 107/4 + 4   (integer division)
//     otherwise:                                   size += 32 + 4 + 1 + 107 + 4
//   - return GetFee(size) = ceil(size * rate / 1000); if that is 0 and rate > 0, return 1.
//
// rate is in sat/kvB (default DUST_RELAY_TX_FEE = 3000).
func DustThreshold(scriptPubKey []byte, dustRelayFeeSatPerKvB int64) int64 {
	// TODO
	return -1
}

// IsDust: valueSats < DustThreshold(...).
func IsDust(valueSats int64, scriptPubKey []byte, dustRelayFeeSatPerKvB int64) bool {
	// TODO
	return false
}

// ---------------------------------------------------------------- OP_RETURN
// Core: MAX_OP_RETURN_RELAY in src/policy/policy.h — 83 on 29.x, but master changed it
// (read it yourself: `git -C ~/bitcoin grep MAX_OP_RETURN_RELAY master -- src/policy/policy.h`).

// BuildOPReturnScript returns OP_RETURN (0x6a) followed by ONE push of data using the
// smallest push: no push for empty data; length byte for 1..75; OP_PUSHDATA1 (0x4c)
// for 76..255; OP_PUSHDATA2 (0x4d, little-endian uint16) for 256..65535.
// Error if the whole script is longer than maxScriptBytes, or data > 65535 bytes.
func BuildOPReturnScript(data []byte, maxScriptBytes int) ([]byte, error) {
	// TODO
	return nil, errTODO
}

// ---------------------------------------------------------------- BIP21
// Spec: bips/bip-0021.mediawiki (offline copy in ~/bitcoin-references/bips/).

// BuildBIP21 returns "bitcoin:<address>[?amount=..][&label=..][&message=..]".
//   - omit amount when sats == 0; error when sats < 0 or > MaxMoneySats
//   - percent-encode label/message per RFC 3986: space -> %20 (NOT '+'), & -> %26, = -> %3D
//   - no '?' at all when there are no parameters
//   - error if address is empty or contains any of ?&=# or space
func BuildBIP21(address string, sats int64, label, message string) (string, error) {
	// TODO
	return "", errTODO
}

// BIP21 is a parsed payment URI.
type BIP21 struct {
	Address string
	Sats    int64
	Label   string
	Message string
}

// ParseBIP21 parses a BIP21 URI.
//   - scheme "bitcoin:" is case-insensitive; address required
//   - amount parsed with ParseBTC; label/message percent-decoded
//   - unknown parameters are IGNORED, but unknown "req-" parameters make the URI invalid
//   - the same parameter twice is an error
func ParseBIP21(uri string) (BIP21, error) {
	// TODO
	return BIP21{}, errTODO
}

// ---------------------------------------------------------------- JSON-RPC
// Core: src/httprpc.cpp (auth, HTTP status codes), src/rpc/request.cpp (cookie, JSON-RPC),
//       doc/JSON-RPC-interface.md

// ParseCookie splits the .cookie file contents "<user>:<password>" at the FIRST ':'
// (ignore one trailing newline). Error if no ':' or either part is empty.
func ParseCookie(contents string) (user, pass string, err error) {
	// TODO
	return "", "", errTODO
}

// RPCClient talks to bitcoind. HTTP nil means http.DefaultClient.
type RPCClient struct {
	BaseURL string
	User    string
	Pass    string
	HTTP    *http.Client
}

// RPCError is the JSON-RPC "error" object, e.g. {"code":-32601,"message":"Method not found"}.
type RPCError struct {
	Code    int
	Message string
}

func (e *RPCError) Error() string {
	// TODO: include both the code and the message
	return "TODO"
}

// Endpoint returns BaseURL (trailing '/' trimmed) + "/" for node RPCs, or
// + "/wallet/<url.PathEscape(wallet)>" for wallet RPCs.
func (c *RPCClient) Endpoint(wallet string) string {
	// TODO
	return ""
}

// Call POSTs {"jsonrpc":"1.0","id":...,"method":method,"params":[...]} with Basic auth.
//   - params must be a JSON ARRAY, also when empty (never null)
//   - HTTP 401 -> an error whose text contains "unauthorized"
//   - bitcoind may answer HTTP 404/500 WITH a JSON error body: decode it anyway
//     and return it as *RPCError (callers use errors.As)
//   - cap how much of the body you read
//
// Returns the raw "result" JSON.
func (c *RPCClient) Call(wallet, method string, params ...any) (json.RawMessage, error) {
	// TODO
	return nil, errTODO
}
