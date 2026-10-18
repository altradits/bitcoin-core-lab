package main

import (
	"crypto/sha256"
	"encoding/hex"
	"errors"
	"fmt"
	"os/exec"
	"strings"
)

// ============================================================================
// STAGE 12: BITCOIN CORE -> LIGHTNING NETWORK READINESS & BRIDGE ENGINE
// ============================================================================
// Core Truth: "Lightning IS Bitcoin."
// Every Lightning channel open, off-chain payment, HTLC, and channel close is
// 100% built out of standard Bitcoin Core Layer-1 transactions.
// Before touching LND, you must master the 6 Layer-1 Prerequisites below.
// ============================================================================

type L1Prerequisite struct {
	Number           int
	BitcoinCoreSkill string
	LabStage         string
	LightningRole    string
	WhatBreaksIfLost string
}

func RequiredBitcoinSkillsForLightning() []L1Prerequisite {
	return []L1Prerequisite{
		{
			Number:           1,
			BitcoinCoreSkill: "UTXO Conservation & 2-of-2 Multisig (P2WSH / MuSig2)",
			LabStage:         "Stages 01 & 02",
			LightningRole:    "BOLT #3 Funding Transaction (anchors the channel on-chain)",
			WhatBreaksIfLost: "Without 2-of-2 multisig UTXOs, one party could run away with the channel funds.",
		},
		{
			Number:           2,
			BitcoinCoreSkill: "SegWit Transaction Malleability Fix (txid vs wtxid, BIP141)",
			LabStage:         "Stage 02",
			LightningRole:    "Signing Refund/Commitment txs BEFORE the Funding tx is broadcast",
			WhatBreaksIfLost: "If txid could be mutated by a third party, your pre-signed Commitment tx would point to a non-existent txid and your funds would be locked forever!",
		},
		{
			Number:           3,
			BitcoinCoreSkill: "Unbroadcast Signed Transactions & Asymmetric Revocation",
			LabStage:         "Stages 02 & 07",
			LightningRole:    "BOLT #3 Commitment Transactions (instant off-chain balance updates)",
			WhatBreaksIfLost: "You would have to broadcast every payment to bitcoind and wait 10 minutes per block.",
		},
		{
			Number:           4,
			BitcoinCoreSkill: "Relative Timelocks (nSequence BIP68 & OP_CHECKSEQUENCEVERIFY BIP112)",
			LabStage:         "Stage 06",
			LightningRole:    "LN-Penalty (to_self_delay gives Watchtowers/Bob time to punish old state cheats)",
			WhatBreaksIfLost: "A cheating peer could broadcast an old channel state from 2 weeks ago where they had more sats, and spend the money immediately before you could punish them!",
		},
		{
			Number:           5,
			BitcoinCoreSkill: "Hashlocks (OP_SHA256) + Absolute Timelocks (OP_CLTV BIP65)",
			LabStage:         "Stage 06",
			LightningRole:    "BOLT #2/#3/#4 HTLCs (trustless multi-hop routing across nodes)",
			WhatBreaksIfLost: "Intermediate routing nodes could steal your payment on the way to the destination.",
		},
		{
			Number:           6,
			BitcoinCoreSkill: "Mempool Fee Bumping (BIP125 RBF, CPFP & BIP431 TRUC v3 Package Relay)",
			LabStage:         "Stages 03 & 05",
			LightningRole:    "Anchor Outputs & v3 Commitment Tx Fee Bumping during mempool fee spikes",
			WhatBreaksIfLost: "If mempool fees spike to 100 sat/vB, your pre-signed force-close tx gets stuck in the mempool past the HTLC timeout and you lose your funds!",
		},
	}
}

// ChannelState represents the off-chain satoshi balances inside a single Bitcoin Core
// 2-of-2 multisig Funding UTXO between Alice (Local) and Bob (Remote).
type ChannelState struct {
	StateNum        uint64
	CapacitySats    int64
	AliceSats       int64
	BobSats         int64
	RevokedPreimage [32]byte
	IsRevoked       bool
}

// UpdateChannelBalance simulates an instant, 0-on-chain-fee Lightning payment from Alice
// to Bob by creating a new off-chain Commitment state while enforcing Bitcoin Core's
// UTXO conservation invariant (AliceSats + BobSats == CapacitySats) and revoking the old state.
func UpdateChannelBalance(prev *ChannelState, payToBobSats int64, oldStateRevocationSecret [32]byte) (*ChannelState, error) {
	if payToBobSats <= 0 {
		return nil, errors.New("payment amount must be positive satoshis")
	}
	if prev.AliceSats < payToBobSats {
		return nil, errors.New("insufficient local channel balance (outbound liquidity)")
	}
	if prev.AliceSats+prev.BobSats != prev.CapacitySats {
		return nil, errors.New("channel conservation invariant violated")
	}

	// Mark previous commitment state as revoked using the revocation secret!
	prev.RevokedPreimage = oldStateRevocationSecret
	prev.IsRevoked = true

	next := &ChannelState{
		StateNum:     prev.StateNum + 1,
		CapacitySats: prev.CapacitySats,
		AliceSats:    prev.AliceSats - payToBobSats,
		BobSats:      prev.BobSats + payToBobSats,
		IsRevoked:    false,
	}
	return next, nil
}

// EvaluateBroadcastedCommitment simulates what happens on Bitcoin Core when one party
// broadcasts a Commitment Transaction on-chain:
//   - If they broadcast a REVOKED old state, Bob uses the Revocation Secret before to_self_delay
//     (OP_CSV) expires to sweep 100% of the channel capacity (Justice Transaction)!
//   - If they broadcast the LATEST unrevoked state, Alice must wait to_self_delay blocks (OP_CSV)
//     while Bob gets his sats immediately.
func EvaluateBroadcastedCommitment(state *ChannelState, currentBlockHeight int, broadcastHeight int, toSelfDelayCSV int) (alicePayout int64, bobPayout int64, outcome string) {
	if state.IsRevoked {
		if currentBlockHeight-broadcastHeight < toSelfDelayCSV {
			// Bob spots the breached old commitment in bitcoind and broadcasts the Justice Tx!
			return 0, state.CapacitySats, "JUSTICE_PENALTY_APPLIED: Alice broadcasted revoked state; Bob swept 100% of channel via revocation key before OP_CSV expired!"
		}
		return state.AliceSats, state.BobSats, "BREACH_MISSED: Bob was offline longer than to_self_delay blocks!"
	}
	if currentBlockHeight-broadcastHeight < toSelfDelayCSV {
		return 0, state.BobSats, fmt.Sprintf("TIMELOCK_ACTIVE: Bob's %d sats are spendable immediately; Alice's %d sats are locked by OP_CSV for %d more blocks.",
			state.BobSats, state.AliceSats, toSelfDelayCSV-(currentBlockHeight-broadcastHeight))
	}
	return state.AliceSats, state.BobSats, "FORCE_CLOSE_MATURED: OP_CSV timelock expired; both Alice and Bob have swept their exact channel balances on-chain."
}

func runBitcoinCLI(args ...string) (string, error) {
	cmdArgs := append([]string{"-regtest"}, args...)
	out, err := exec.Command("bitcoin-cli", cmdArgs...).CombinedOutput()
	if err != nil {
		return "", fmt.Errorf("%v: %s", err, strings.TrimSpace(string(out)))
	}
	return strings.TrimSpace(string(out)), nil
}

func main() {
	fmt.Println("======================================================================")
	fmt.Println("⚡ STAGE 12: BITCOIN CORE -> LIGHTNING READINESS GATE & L1/L2 BRIDGE")
	fmt.Println("======================================================================")

	fmt.Println("\n[1] THE 6 BITCOIN CORE SKILLS YOU MUST HAVE BEFORE LIGHTNING:")
	for _, p := range RequiredBitcoinSkillsForLightning() {
		fmt.Printf("  %d. %-66s [%s]\n     • In Lightning : %s\n     • Why Required : %s\n",
			p.Number, p.BitcoinCoreSkill, p.LabStage, p.LightningRole, p.WhatBreaksIfLost)
	}

	fmt.Println("\n[2] SIMULATING A LIGHTNING CHANNEL ON TOP OF BITCOIN CORE:")
	// 1. Open a 1,000,000 sat (0.01 BTC) channel funded by Alice
	state0 := &ChannelState{
		StateNum:     0,
		CapacitySats: 1_000_000,
		AliceSats:    1_000_000,
		BobSats:      0,
	}
	fmt.Printf("  • Channel Opened (State #0, 1 on-chain tx)  : Alice = %d sats | Bob = %d sats\n", state0.AliceSats, state0.BobSats)

	// 2. Alice pays Bob 250,000 sats off-chain (0 on-chain transactions!)
	revSecret0 := sha256.Sum256([]byte("alice_state_0_revocation_secret"))
	state1, _ := UpdateChannelBalance(state0, 250_000, revSecret0)
	fmt.Printf("  • Off-Chain Payment #1 (State #1, 0 L1 txs) : Alice = %d sats | Bob = %d sats (State #0 Revoked!)\n", state1.AliceSats, state1.BobSats)

	// 3. Alice pays Bob another 150,000 sats off-chain
	revSecret1 := sha256.Sum256([]byte("alice_state_1_revocation_secret"))
	state2, _ := UpdateChannelBalance(state1, 150_000, revSecret1)
	fmt.Printf("  • Off-Chain Payment #2 (State #2, 0 L1 txs) : Alice = %d sats | Bob = %d sats (State #1 Revoked!)\n", state2.AliceSats, state2.BobSats)

	// 4. What if Alice tries to cheat by broadcasting Old State #0 (where she had 1,000,000 sats) to bitcoind?
	_, bobSweep, msg := EvaluateBroadcastedCommitment(state0, 325, 324, 144)
	fmt.Printf("  • Cheat Attempt on bitcoind (State #0)      : %s (Bob gets %d sats, revKey=%s...)\n",
		msg, bobSweep, hex.EncodeToString(state0.RevokedPreimage[:6]))

	// 5. Honest settlement of latest State #2 after OP_CSV (144 blocks)
	aliceFinal, bobFinal, honestMsg := EvaluateBroadcastedCommitment(state2, 470, 324, 144)
	fmt.Printf("  • Honest Settlement on bitcoind (State #2)  : %s (Alice=%d, Bob=%d)\n",
		honestMsg, aliceFinal, bobFinal)

	// 6. Verify live bitcoind connection that LND uses under the hood
	if height, err := runBitcoinCLI("getblockcount"); err == nil {
		fmt.Printf("\n[3] LIVE BITCOIND <-> LND RPC BRIDGE VERIFIED (Current L1 Block Height: #%s)\n", height)
	}
	fmt.Println("======================================================================")
}
