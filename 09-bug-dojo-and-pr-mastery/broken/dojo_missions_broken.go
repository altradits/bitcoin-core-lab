package dojo

import (
	"crypto/hmac"
	"crypto/sha512"
	"errors"
)

const (
	COIN                 int64 = 100_000_000
	MAX_MONEY            int64 = 21_000_000 * COIN
	WITNESS_SCALE_FACTOR int64 = 4
	BYTES_PER_SIGOP      int64 = 20
)

type OutPoint struct {
	Txid string
	Vout uint32
}

type TxOut struct {
	Value        int64
	ScriptPubKey string
}

type Transaction struct {
	Vin  []OutPoint
	Vout []TxOut
}

// ============================================================================
// MISSION 1 (BROKEN): Vulnerable to CVE-2010-5139 (int64 overflow) & CVE-2018-17144 (duplicate inputs)
// Fix inside dojo_missions.go and run: ./lab.sh dojo check 1
// ============================================================================
func CheckTransactionConsensus(tx Transaction) error {
	if len(tx.Vin) == 0 {
		return errors.New("bad-txns-vin-empty")
	}
	if len(tx.Vout) == 0 {
		return errors.New("bad-txns-vout-empty")
	}
	// BUG 1: Sums outputs before checking individual txout.Value <= MAX_MONEY (overflows int64!)
	var nValueOut int64 = 0
	for _, txout := range tx.Vout {
		nValueOut += txout.Value
	}
	if nValueOut > MAX_MONEY {
		return errors.New("bad-txns-txouttotal-toolarge")
	}
	// BUG 2: Missing duplicate input check (CVE-2018-17144)!
	return nil
}

// ============================================================================
// MISSION 2 (BROKEN): Missing BIP32 16..64 byte seed length check (Upstream PR #35320)
// Fix inside dojo_missions.go and run: ./lab.sh dojo check 2
// ============================================================================
func DeriveBIP32MasterKey(seed []byte) (masterKey [32]byte, chainCode [32]byte, err error) {
	// BUG: Accepts weak seeds (< 16 bytes) and oversized seeds (> 64 bytes)!
	mac := hmac.New(sha512.New, []byte("Bitcoin seed"))
	mac.Write(seed)
	sum := mac.Sum(nil)
	copy(masterKey[:], sum[:32])
	copy(chainCode[:], sum[32:64])
	return masterKey, chainCode, nil
}

// ============================================================================
// MISSION 3 (BROKEN): Ignores sigOpCost when computing mempool vsize (Upstream PR #32800)
// Fix inside dojo_missions.go and run: ./lab.sh dojo check 3
// ============================================================================
func ComputeMempoolVsizes(txWeight int64, sigOpCost int64) (vsizeBIP141 int64, vsizeAdjusted int64) {
	vsizeBIP141 = (txWeight + WITNESS_SCALE_FACTOR - 1) / WITNESS_SCALE_FACTOR
	// BUG: Returns vsizeBIP141 for vsizeAdjusted instead of max(txWeight, sigOpCost * BYTES_PER_SIGOP)!
	return vsizeBIP141, vsizeBIP141
}

// ============================================================================
// MISSION 4 (BROKEN): Only checks replacementFee > originalFee (Vulnerable to RBF DoS!)
// Fix inside dojo_missions.go and run: ./lab.sh dojo check 4
// ============================================================================
func ValidateBIP125Replacement(originalFee, originalVsize, replacementFee, replacementVsize, incrementalRelayFeePerVB int64) error {
	// BUG: Allows +1 sat free relay bandwidth DoS and feerate downgrades!
	if replacementFee <= originalFee {
		return errors.New("rejecting replacement: less fees")
	}
	return nil
}

// ============================================================================
// MISSION 5 (BROKEN): Fails to validate existing PSBT partial signatures (Upstream PR #33014)
// Fix inside dojo_missions.go and run: ./lab.sh dojo check 5
// ============================================================================
type PartialSig struct {
	PubKeyHex string
	SigBytes  []byte
	Valid     bool
}

func ProcessPSBTPartialSignatures(existing []PartialSig, newSig PartialSig) ([]PartialSig, error) {
	// BUG: Blindly appends without validating existing or new DER signature length (9..73) and Valid flag!
	return append(existing, newSig), nil
}
