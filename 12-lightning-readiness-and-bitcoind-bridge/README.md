# Stage 12: Lightning Readiness — the Channel State Machine, the `lnd` ↔ `bitcoind` Bridge, and Polar

> Checked: `lnd --help` of your `~/bin/lnd` (v0.21.3-beta) for option names; BOLTs from
> `~/bitcoin-references/bolts/`; ZMQ options in Core's `doc/zmq.md`.
> Note: `--bitcoin.active` appears in older Polar compose files but is not an option in lnd 0.21.

**No-Shortcuts Rule.** You write the channel state machine in Go (`./lab.sh blank|check|solve 12`),
you write `lnd.conf` and the matching `bitcoind` ZMQ settings yourself, and you drive a channel
open → pay → close with `lncli` commands you look up yourself. The old finished program is in
[`solutions/`](./solutions/). Journal: `my-work/12-lightning-readiness-and-bitcoind-bridge/journal.md`.

---

## Objectives

| ID | You can... |
|----|------------|
| C-LN-1 | say what each BOLT (01–11) covers and which Bitcoin Core features each depends on |
| C-LN-3 | model commitment states, revocation and penalty, and the `to_self_delay` race |
| C-LN-4 | explain why anchors, CPFP, package relay and TRUC matter for force-closes |
| C-LN-5 | configure `lnd` against `bitcoind` (RPC + ZMQ) and operate it with `lncli` |
| C-LN-6 | follow a payment from invoice (BOLT 11) through onion routing (BOLT 4) at concept level |

## Prerequisites — the readiness gate
Do not start until you can do each of these without notes (stage where you learned it):
1. Build and decode a 2-of-2 P2WSH output (02, 06).
2. Explain txid vs wtxid and why pre-signed children need malleability-proof parents (02).
3. Use relative (CSV) and absolute (CLTV) timelocks (06).
4. Build hashlock scripts and spend both HTLC paths (06).
5. Fee-bump with RBF and CPFP; submit a TRUC package (03, 05).
6. Read `bitcoind` logs and RPC output during sync (11).

Estimated time: 12 hours. **8 GB RAM rule:** Docker + Polar with 5 nodes uses ~3.5 GB. Stop your
native `bitcoind` and any C++ build while Polar runs; quit Docker afterwards.

---

## Theory

### 1. A channel is a Bitcoin UTXO
Funding: a 2-of-2 P2WSH (or Taproot for newer channel types) output. Each state is a pair of
**commitment transactions** (one per side) spending it. Moving to a new state = signing new
commitments **and revoking the old ones** by handing over the old per-commitment secret
(`revoke_and_ack`, BOLT 2). The broadcaster's own output (`to_local`) is CSV-delayed by
`to_self_delay`, so the counterparty has time to punish a revoked broadcast with the revocation key.

### 2. HTLCs in flight
Every pending payment adds an HTLC output (BOLT 3). Offered/received scripts combine a hashlock,
an absolute timeout (`cltv_expiry`) and the revocation path; second-stage HTLC-success/timeout
transactions add the CSV delay. Routing nodes must claim on-chain before `cltv_expiry` — this is
where mempool policy (Stages 03, 05, 18) decides whether funds are safe.

### 3. The bridge (`lnd` with `--bitcoin.node=bitcoind`)
- **RPC** (`bitcoind.rpchost`, cookie or user/pass): block and tx lookups, fee estimation
  (`estimatesmartfee`), broadcasting (`sendrawtransaction`).
- **ZMQ** (`bitcoind.zmqpubrawblock`, `bitcoind.zmqpubrawtx` in lnd; `zmqpubrawblock`,
  `zmqpubrawtx` in `bitcoin.conf`): push notifications of new blocks and txs. Alternatively
  `bitcoind.rpcpolling`.
- Whether your lnd version submits packages with `submitpackage` for anchor/TRUC channels:
  **UNVERIFIED** — check lnd's release notes before you claim it in a talk.

### 4. BOLT map (read in this order)
BOLT 3 (tx formats) → BOLT 2 (channel lifecycle) → BOLT 5 (on-chain handling) → BOLT 11
(invoices) → BOLT 4 (onion routing) → BOLT 7 (gossip) → BOLT 8 (transport) → BOLT 1, 9, 10, 12.

---

## Exercises

| # | Worksheet | Checker |
|---|-----------|---------|
| 1 | Go: write `UpdateChannelBalance` and `EvaluateBroadcastedCommitment` from their specs in `lightning_readiness.go` | `./lab.sh check 12` |
| 2 | [Write `lnd.conf` and the `bitcoind` ZMQ settings yourself](./exercises/01-write-lnd-conf.md) | `./check_lnd_conf.sh` |
| 3 | [Channel lifecycle in Polar, by `lncli` only](./exercises/02-polar-channel-lifecycle.md) | journal + `./check_polar_journal.sh` |
| 4 | [Find the Bitcoin Core in a force-close](./exercises/03-force-close-on-chain.md) | journal (self-check) |

---

## Self-check quiz (answers in [`solutions/quiz_answers.md`](./solutions/quiz_answers.md))
1. What exactly does "revoking" a state hand over, and to whom?
2. Why must `to_local` be CSV-delayed but `to_remote` need not be?
3. Your peer broadcasts a revoked state while you are offline for longer than `to_self_delay`. What happens?
4. Which two ZMQ topics does lnd need, and what would break without them (and without polling)?
5. Why is an HTLC's `cltv_expiry` a mempool-policy problem for routing nodes?
6. Which BOLT defines the invoice format? Which defines the commitment transaction scripts?
7. What is an anchor output and which Core policy features does it rely on?

## Review lens (Core PRs that matter to Lightning)
- Files: `src/policy/truc_policy.cpp`, `src/policy/packages.cpp`, `src/policy/ephemeral_policy.cpp`,
  `src/zmq/` (`zmqpublishnotifier.cpp`), `src/rpc/fees.cpp`, `src/policy/fees/` (master) or
  `src/policy/fees.cpp` (v29).
- Questions: Does this change make it harder or easier to get a time-critical transaction mined
  (pinning, package limits)? Does it change ZMQ message content or ordering that L2 software
  depends on? Is the fee estimator's behaviour under sudden fee spikes affected?

## Proof-of-work output
A BitDevs Kisumu session plan (your own slides/notes) walking through a force-close on regtest
with the real transactions you produced — no copied slides.
