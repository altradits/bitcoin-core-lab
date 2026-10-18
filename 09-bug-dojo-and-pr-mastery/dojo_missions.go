package dojo

import (
	"crypto/hmac"
	"crypto/sha512"
	"errors"
	"fmt"
)

const (
	COIN                 int64 = 100_000_000
	MAX_MONEY            int64 = 21_000_000 * COIN
	WITNESS_SCALE_FACTOR int64 = 4
	BYTES_PER_SIGOP      int64 = 20 // DEFAULT_BYTES_PER_SIGOP in src/policy/policy.h
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
// MISSION 1: Consensus Shield (CVE-2010-5139 Overflow & CVE-2018-17144 Duplicate Inputs)
// Upstream Reference: src/consensus/tx_check.cpp -> CheckTransaction()
// ============================================================================
//
// SELF-CONTAINED LESSON:
// Why did CVE-2010-5139 happen?
//   An attacker created two outputs of 92,233,720,368.54 BTC (each > MAX_MONEY, near INT64_MAX).
//   When summed naively (total += out.Value), 64-bit signed integer addition overflowed into
//   a NEGATIVE number, bypassing total <= MAX_MONEY!
//   Fix: You MUST check 0 <= out.Value <= MAX_MONEY on EACH output BEFORE adding it to total,
//   AND check 0 <= total <= MAX_MONEY after every addition!
//
// Why did CVE-2018-17144 happen?
//   A transaction listed the exact same OutPoint{Txid, Vout} twice in tx.Vin.
//   Fix: Track seen OutPoints in a map[OutPoint]bool and return "bad-txns-inputs-duplicate"
//   if any input OutPoint appears more than once.
func CheckTransactionConsensus(tx Transaction) error {
	if len(tx.Vin) == 0 {
		return errors.New("bad-txns-vin-empty")
	}
	if len(tx.Vout) == 0 {
		return errors.New("bad-txns-vout-empty")
	}

	// 1. Check each output individually AND cumulative sum (CVE-2010-5139 defense)
	var nValueOut int64 = 0
	for _, txout := range tx.Vout {
		if txout.Value < 0 {
			return errors.New("bad-txns-vout-negative")
		}
		if txout.Value > MAX_MONEY {
			return errors.New("bad-txns-vout-toolarge")
		}
		nValueOut += txout.Value
		if nValueOut < 0 || nValueOut > MAX_MONEY {
			return errors.New("bad-txns-txouttotal-toolarge")
		}
	}

	// 2. Check for duplicate inputs (CVE-2018-17144 defense)
	seenInputs := make(map[OutPoint]bool, len(tx.Vin))
	for _, txin := range tx.Vin {
		if seenInputs[txin] {
			return errors.New("bad-txns-inputs-duplicate")
		}
		seenInputs[txin] = true
	}

	return nil
}

// ============================================================================
// MISSION 2: BIP32 HD Wallet Master Seed Validation (Upstream PR #35320)
// Upstream Reference: src/key.cpp -> CExtKey::SetSeed()
// ============================================================================
//
// SELF-CONTAINED LESSON:
// BIP32 specifies that a master seed fed into HMAC-SHA512("Bitcoin seed", seed)
// MUST be between 128 bits (16 bytes) and 512 bits (64 bytes) inclusive.
// Prior to PR #35320, CExtKey::SetSeed accepted arbitrary seed lengths (even 0 or 4 bytes!),
// risking catastrophic brute-force theft of derived funds.
func DeriveBIP32MasterKey(seed []byte) (masterKey [32]byte, chainCode [32]byte, err error) {
	if len(seed) < 16 || len(seed) > 64 {
		return masterKey, chainCode, fmt.Errorf("invalid BIP32 seed length %d bytes: must be between 16 and 64 bytes (128-512 bits)", len(seed))
	}
	mac := hmac.New(sha512.New, []byte("Bitcoin seed"))
	mac.Write(seed)
	sum := mac.Sum(nil)
	copy(masterKey[:], sum[:32])
	copy(chainCode[:], sum[32:64])
	return masterKey, chainCode, nil
}

// ============================================================================
// MISSION 3: Mempool Sigop-Adjusted Virtual Size (Upstream PR #32800)
// Upstream Reference: src/policy/policy.cpp -> GetVirtualTransactionSize() & src/rpc/mempool.cpp
// ============================================================================
//
// SELF-CONTAINED LESSON:
// Why does Bitcoin Core have TWO virtual sizes in PR #32800 (`vsize_bip141` vs `vsize_adjusted`)?
//   - `vsize_bip141` = ceil(weight / 4). It measures pure byte/witness bandwidth.
//   - However, an attacker could craft a tiny 100-byte transaction containing 50 `OP_CHECKSIG`
//     operations (expensive CPU verification!).
//   - To prevent CPU DoS in the mempool, Bitcoin Core computes:
//       sigop_weight = sigop_cost * BYTES_PER_SIGOP (where BYTES_PER_SIGOP = 20)
//       effective_weight = max(tx_weight, sigop_weight)
//       vsize_adjusted = ceil(effective_weight / 4) = (effective_weight + 3) / 4
func ComputeMempoolVsizes(txWeight int64, sigOpCost int64) (vsizeBIP141 int64, vsizeAdjusted int64) {
	vsizeBIP141 = (txWeight + WITNESS_SCALE_FACTOR - 1) / WITNESS_SCALE_FACTOR
	sigOpWeight := sigOpCost * BYTES_PER_SIGOP
	effectiveWeight := txWeight
	if sigOpWeight > effectiveWeight {
		effectiveWeight = sigOpWeight
	}
	vsizeAdjusted = (effectiveWeight + WITNESS_SCALE_FACTOR - 1) / WITNESS_SCALE_FACTOR
	return vsizeBIP141, vsizeAdjusted
}

// ============================================================================
// MISSION 4: BIP125 RBF DoS Rules (PaysMoreThanConflicts & PaysForRBF)
// Upstream Reference: src/policy/rbf.cpp -> PaysMoreThanConflicts() & PaysForRBF()
// ============================================================================
//
// SELF-CONTAINED LESSON:
// To replace an unconfirmed transaction in the mempool, a replacement transaction must pass:
//   1. Feerate Strictly Higher (PaysMoreThanConflicts):
//      replacementFee * originalVsize > originalFee * replacementVsize
//      (Using cross-multiplication avoids floating-point rounding bugs!)
//   2. Absolute Fee >= Original Fee (Rule #3):
//      replacementFee >= originalFee
//   3. Incremental Relay Bandwidth Fee (Rule #4):
//      (replacementFee - originalFee) >= replacementVsize * incrementalRelayFeePerVB
func ValidateBIP125Replacement(originalFee, originalVsize, replacementFee, replacementVsize, incrementalRelayFeePerVB int64) error {
	// Check 1: Strictly higher feerate (cross-multiplied integer comparison, zero floats!)
	if replacementFee*originalVsize <= originalFee*replacementVsize {
		return errors.New("rejecting replacement: new feerate <= old feerate")
	}
	// Check 2 (Rule #3): Must pay at least as much total fee as the replaced tx
	if replacementFee < originalFee {
		return errors.New("rejecting replacement: less fees than conflicting txs")
	}
	// Check 3 (Rule #4): Additional fee must cover the replacement's own relay bandwidth
	additionalFee := replacementFee - originalFee
	requiredRelayFee := replacementVsize * incrementalRelayFeePerVB
	if additionalFee < requiredRelayFee {
		return fmt.Errorf("rejecting replacement: not enough additional fees to relay (%d < %d)", additionalFee, requiredRelayFee)
	}
	return nil
}

// ============================================================================
// MISSION 5: PSBT Partial Signature Verification (Upstream PR #33014)
// Upstream Reference: src/wallet/rpc/spend.cpp -> descriptorprocesspsbt
// ============================================================================
//
// SELF-CONTAINED LESSON:
// When a coordinator or hardware wallet merges partial signatures in `descriptorprocesspsbt`,
// one of the pre-existing partial signatures in the PSBT might be malformed or invalid.
// Prior to PR #33014, encountering a pre-existing invalid signature during signing/filling
// caused an internal assertion/bug instead of cleanly reporting the signature failure while
// preserving valid signatures.
type PartialSig struct {
	PubKeyHex string
	SigBytes  []byte
	Valid     bool
}

func ProcessPSBTPartialSignatures(existing []PartialSig, newSig PartialSig) ([]PartialSig, error) {
	var validSigs []PartialSig
	for _, sig := range existing {
		// DER ECDSA signature in Bitcoin (BIP66) with SIGHASH byte is between 9 and 73 bytes
		if len(sig.SigBytes) < 9 || len(sig.SigBytes) > 73 || !sig.Valid {
			return nil, fmt.Errorf("psbt contains invalid existing signature for pubkey %s", sig.PubKeyHex)
		}
		validSigs = append(validSigs, sig)
	}
	if len(newSig.SigBytes) < 9 || len(newSig.SigBytes) > 73 || !newSig.Valid {
		return nil, fmt.Errorf("refusing to add invalid new signature for pubkey %s", newSig.PubKeyHex)
	}
	validSigs = append(validSigs, newSig)
	return validSigs, nil
}
