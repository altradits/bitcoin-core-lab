// REFERENCE SOLUTION (spoiler). Open only after `./lab.sh check 08` passes on your
// own code, or after 3 honest attempts. Your working file is ../kit.go.
package builderkit

import (
	"bytes"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"strconv"
	"strings"
)

const (
	SatsPerBTC   int64 = 100_000_000
	MaxMoneySats int64 = 21_000_000 * SatsPerBTC
)

// ---------------------------------------------------------------- amounts

func FormatBTC(sats int64) (string, error) {
	if sats < 0 || sats > MaxMoneySats {
		return "", fmt.Errorf("amount %d out of range [0, MAX_MONEY]", sats)
	}
	return fmt.Sprintf("%d.%08d", sats/SatsPerBTC, sats%SatsPerBTC), nil
}

func ParseBTC(s string) (int64, error) {
	if s == "" {
		return 0, errors.New("empty amount")
	}
	whole, frac, hasDot := strings.Cut(s, ".")
	if whole == "" || strings.Trim(whole, "0123456789") != "" {
		return 0, fmt.Errorf("invalid amount %q", s)
	}
	if hasDot && (frac == "" || len(frac) > 8 || strings.Trim(frac, "0123456789") != "") {
		return 0, fmt.Errorf("invalid amount %q (1-8 decimals)", s)
	}
	if len(whole) > 8 {
		return 0, fmt.Errorf("amount %q exceeds MAX_MONEY", s)
	}
	w, _ := strconv.ParseInt(whole, 10, 64)
	frac = frac + strings.Repeat("0", 8-len(frac))
	f, _ := strconv.ParseInt(frac, 10, 64)
	sats := w*SatsPerBTC + f
	if sats > MaxMoneySats {
		return 0, fmt.Errorf("amount %q exceeds MAX_MONEY", s)
	}
	return sats, nil
}

// ---------------------------------------------------------------- dust

func isWitnessProgram(spk []byte) bool {
	if len(spk) < 4 || len(spk) > 42 {
		return false
	}
	if spk[0] != 0x00 && (spk[0] < 0x51 || spk[0] > 0x60) {
		return false
	}
	return int(spk[1])+2 == len(spk)
}

func compactSizeLen(n int) int {
	switch {
	case n < 253:
		return 1
	case n <= 0xffff:
		return 3
	case n <= 0xffffffff:
		return 5
	}
	return 9
}

func DustThreshold(scriptPubKey []byte, dustRelayFeeSatPerKvB int64) int64 {
	if (len(scriptPubKey) > 0 && scriptPubKey[0] == 0x6a) || len(scriptPubKey) > 10000 {
		return 0
	}
	size := int64(8 + compactSizeLen(len(scriptPubKey)) + len(scriptPubKey))
	if isWitnessProgram(scriptPubKey) {
		size += 32 + 4 + 1 + 107/4 + 4
	} else {
		size += 32 + 4 + 1 + 107 + 4
	}
	fee := (size*dustRelayFeeSatPerKvB + 999) / 1000
	if fee == 0 && dustRelayFeeSatPerKvB > 0 {
		fee = 1
	}
	return fee
}

func IsDust(valueSats int64, scriptPubKey []byte, dustRelayFeeSatPerKvB int64) bool {
	return valueSats < DustThreshold(scriptPubKey, dustRelayFeeSatPerKvB)
}

// ---------------------------------------------------------------- OP_RETURN

func BuildOPReturnScript(data []byte, maxScriptBytes int) ([]byte, error) {
	s := []byte{0x6a}
	switch n := len(data); {
	case n == 0:
	case n <= 75:
		s = append(s, byte(n))
	case n <= 0xff:
		s = append(s, 0x4c, byte(n))
	case n <= 0xffff:
		s = append(s, 0x4d, byte(n), byte(n>>8))
	default:
		return nil, errors.New("data too large")
	}
	s = append(s, data...)
	if len(s) > maxScriptBytes {
		return nil, fmt.Errorf("OP_RETURN script is %d bytes, policy limit is %d", len(s), maxScriptBytes)
	}
	return s, nil
}

// ---------------------------------------------------------------- BIP21

func BuildBIP21(address string, sats int64, label, message string) (string, error) {
	if address == "" || strings.ContainsAny(address, "?&=# ") {
		return "", errors.New("invalid address")
	}
	var params []string
	if sats > 0 {
		amt, err := FormatBTC(sats)
		if err != nil {
			return "", err
		}
		params = append(params, "amount="+amt)
	} else if sats < 0 {
		return "", errors.New("negative amount")
	}
	if label != "" {
		params = append(params, "label="+escapeParam(label))
	}
	if message != "" {
		params = append(params, "message="+escapeParam(message))
	}
	uri := "bitcoin:" + address
	if len(params) > 0 {
		uri += "?" + strings.Join(params, "&")
	}
	return uri, nil
}

// escapeParam percent-encodes per RFC 3986: QueryEscape, but space is %20, not '+'.
func escapeParam(s string) string {
	return strings.ReplaceAll(url.QueryEscape(s), "+", "%20")
}

type BIP21 struct {
	Address string
	Sats    int64
	Label   string
	Message string
}

func ParseBIP21(uri string) (BIP21, error) {
	var out BIP21
	if len(uri) < 8 || !strings.EqualFold(uri[:8], "bitcoin:") {
		return out, errors.New("missing bitcoin: scheme")
	}
	rest := uri[8:]
	addr, query, _ := strings.Cut(rest, "?")
	if addr == "" {
		return out, errors.New("missing address")
	}
	out.Address = addr
	seen := map[string]bool{}
	if query != "" {
		for _, kvs := range strings.Split(query, "&") {
			k, v, _ := strings.Cut(kvs, "=")
			if seen[k] {
				return out, fmt.Errorf("duplicate parameter %q", k)
			}
			seen[k] = true
			dv, err := url.PathUnescape(v)
			if err != nil {
				return out, err
			}
			switch {
			case k == "amount":
				sats, err := ParseBTC(dv)
				if err != nil {
					return out, err
				}
				out.Sats = sats
			case k == "label":
				out.Label = dv
			case k == "message":
				out.Message = dv
			case strings.HasPrefix(k, "req-"):
				return out, fmt.Errorf("unsupported required parameter %q", k)
			}
		}
	}
	return out, nil
}

// ---------------------------------------------------------------- JSON-RPC

func ParseCookie(contents string) (user, pass string, err error) {
	line := strings.TrimRight(contents, "\r\n")
	user, pass, ok := strings.Cut(line, ":")
	if !ok || user == "" || pass == "" {
		return "", "", errors.New("malformed cookie: want <user>:<password>")
	}
	return user, pass, nil
}

type RPCClient struct {
	BaseURL string
	User    string
	Pass    string
	HTTP    *http.Client
}

type RPCError struct {
	Code    int
	Message string
}

func (e *RPCError) Error() string { return fmt.Sprintf("rpc error %d: %s", e.Code, e.Message) }

func (c *RPCClient) Endpoint(wallet string) string {
	base := strings.TrimRight(c.BaseURL, "/")
	if wallet == "" {
		return base + "/"
	}
	return base + "/wallet/" + url.PathEscape(wallet)
}

func (c *RPCClient) Call(wallet, method string, params ...any) (json.RawMessage, error) {
	if params == nil {
		params = []any{}
	}
	body, err := json.Marshal(map[string]any{"jsonrpc": "1.0", "id": "lab", "method": method, "params": params})
	if err != nil {
		return nil, err
	}
	req, err := http.NewRequest(http.MethodPost, c.Endpoint(wallet), bytes.NewReader(body))
	if err != nil {
		return nil, err
	}
	req.Header.Set("Content-Type", "application/json")
	req.SetBasicAuth(c.User, c.Pass)
	hc := c.HTTP
	if hc == nil {
		hc = http.DefaultClient
	}
	resp, err := hc.Do(req)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()
	if resp.StatusCode == http.StatusUnauthorized {
		return nil, errors.New("unauthorized: check rpc credentials / cookie")
	}
	raw, err := io.ReadAll(io.LimitReader(resp.Body, 32<<20))
	if err != nil {
		return nil, err
	}
	var parsed struct {
		Result json.RawMessage `json:"result"`
		Error  *RPCError       `json:"error"`
	}
	if err := json.Unmarshal(raw, &parsed); err != nil {
		return nil, fmt.Errorf("HTTP %d, non-JSON body: %.200s", resp.StatusCode, raw)
	}
	if parsed.Error != nil {
		return nil, parsed.Error
	}
	return parsed.Result, nil
}
