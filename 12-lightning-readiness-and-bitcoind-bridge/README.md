# Stage 12: The Bitcoin-to-Lightning Readiness Gate & How `lnd` Interacts With `bitcoind`

> *"Lightning is not a separate cryptocurrency and it is not magic. Every Lightning channel, off-chain balance update, HTLC payment, and penalty transaction is 100% a standard Bitcoin Core transaction. Once you master the 6 Layer-1 Bitcoin Core building blocks below, you already understand 90% of Lightning."*

---

## Part 1: Your 6-Point Readiness Checklist Before Venturing Into Lightning

Do **not** touch `lnd` (`v0.21.3-beta`, installed at `/Users/mac/bin/lnd`) until you can check off all **6 Bitcoin Core Layer-1 Prerequisites** below. Every single one of them is already built and verified in this repository:

| # | Required Bitcoin Core Skill | Where You Master It | How Lightning Uses It | What Breaks in Lightning Without It |
| :-: | :--- | :--- | :--- | :--- |
| **1** | **UTXO Conservation & 2-of-2 Multisig (`P2WSH` / `MuSig2`)** | [`01-node-foundations`](../01-node-foundations/) & [`02-raw-tx-and-mempool`](../02-raw-tx-and-mempool/) | **BOLT #3 Funding Transaction:** Opening a Lightning channel simply locks satoshis into a single 2-of-2 multisig UTXO on `bitcoind`. | Without 2-of-2 multisig, your channel partner could steal your funds unilaterally. |
| **2** | **SegWit Transaction Malleability Fix (`txid` vs `wtxid`, BIP141)** | [`02-raw-tx-and-mempool`](../02-raw-tx-and-mempool/) | **Pre-Signed Refund/Commitment Transactions:** Before Alice broadcasts the Funding Tx, Alice and Bob sign Commitment Txs spending that Funding Tx's `txid`. | Before SegWit (2017), anyone could tweak signature bytes in `scriptSig` to change the Funding `txid`, invalidating your Commitment Tx and locking your money forever! |
| **3** | **Unbroadcast Signed Transactions & Asymmetric Revocation** | [`02-raw-tx-and-mempool`](../02-raw-tx-and-mempool/) & [`07-psbt-descriptors-and-miniscript`](../07-psbt-descriptors-and-miniscript/) | **BOLT #3 Off-Chain State Updates:** Paying on Lightning means signing a *new* Bitcoin transaction off-chain and giving your peer the **Revocation Secret** for the old transaction. | Every payment would require a 10-minute on-chain block and an on-chain miner fee. |
| **4** | **Relative Timelocks (`nSequence` BIP68 & `OP_CHECKSEQUENCEVERIFY` BIP112)** | [`06-lightning-htlc-state-machine`](../06-lightning-htlc-state-machine/) | **LN-Penalty (`to_self_delay`):** Forces the broadcaster of a Commitment Tx to wait `N` blocks (e.g., 144 blocks) before spending their own output. | If Alice broadcasted an old state from last week where she had more sats, she could spend the money immediately before Bob could punish her! |
| **5** | **Hashlocks (`OP_SHA256`) + Absolute Timelocks (`OP_CLTV` BIP65)** | [`06-lightning-htlc-state-machine`](../06-lightning-htlc-state-machine/) & [`10-protocol-primitives-from-scratch`](../10-protocol-primitives-from-scratch/) | **BOLT #2/#3/#4 HTLC Multi-Hop Routing:** Allows Alice to pay Carol through Bob (`SHA256(Preimage) == PaymentHash`) without trusting Bob. | Routing nodes in the middle of a payment path could take your sats and disappear. |
| **6** | **Mempool Fee Bumping (`BIP125 RBF`, `CPFP`, & `BIP431 TRUC v3 Package Relay`)** | [`03-rbf-and-cpfp`](../03-rbf-and-cpfp/) & [`05-truc-package-relay-review`](../05-truc-package-relay-review/) | **Anchor Outputs & Ephemeral Anchors (`submitpackage`):** Bumps the fee of a pre-signed Commitment Tx at broadcast time when the mempool is congested. | If on-chain fees spike to `100 sat/vB`, a force-close or HTLC claim tx gets stuck in the mempool past its block deadline and funds are stolen! |

---

## Part 2: How Lightning Actually Works (In 4 Simple Steps)

Run `./lab.sh practice 12` to see [`lightning_readiness.go`](file:///Users/mac/bitcoin-core-lab/12-lightning-readiness-and-bitcoind-bridge/lightning_readiness.go) execute this exact state machine:

```
+-----------------------------------------------------------------------------+
| LAYER 1 (BITCOIN CORE - bitcoind):                                          |
|   [Funding Tx (Broadcast on L1)] ---> Creates 1_000_000 sat 2-of-2 UTXO     |
|                                              |                              |
| - - - - - - - - - - - - - - - - - - - - - - -|- - - - - - - - - - - - - - - |
| LAYER 2 (LIGHTNING - lnd, OFF-CHAIN):        v                              |
|   State #0 (Revoked): Alice = 1,000,000 | Bob =         0 (Not broadcast!)  |
|   State #1 (Revoked): Alice =   750,000 | Bob =   250,000 (Not broadcast!)  |
|   State #2 (Latest) : Alice =   600,000 | Bob =   400,000 (Held in RAM/DB)  |
| - - - - - - - - - - - - - - - - - - - - - - -|- - - - - - - - - - - - - - - |
| LAYER 1 SETTLEMENT (BITCOIN CORE - bitcoind):v                              |
|   [Closing Tx (Broadcast on L1)] ---> Alice: 600k sats | Bob: 400k sats     |
+-----------------------------------------------------------------------------+
```

1. **Step 1 — Open Channel (1 On-Chain Transaction on `bitcoind`):**
   Alice locks `1,000,000 sats` into a 2-of-2 multisig output controlled by `Alice_PubKey + Bob_PubKey`. `bitcoind` mines this Funding Transaction into a block.
2. **Step 2 — Instant Off-Chain Payments (0 On-Chain Transactions!):**
   - In **State #0**, Alice has `1,000,000 sats` and Bob has `0 sats`.
   - To pay Bob `250,000 sats` in 10 milliseconds, Alice and Bob sign **Commitment Transaction #1** (`Alice: 750,000`, `Bob: 250,000`) and Alice hands Bob the **Revocation Preimage** for State #0.
   - Neither Alice nor Bob sends this transaction to `bitcoind`! They keep it in their local `lnd` database (`channel.db`), knowing they *could* broadcast it to `bitcoind` at any moment.
3. **Step 3 — What If Someone Tries to Cheat? (`OP_CHECKSEQUENCEVERIFY` + Justice Tx):**
   - Suppose Alice tries to cheat by broadcasting old **State #0** (where she had `1,000,000 sats`) to `bitcoind`.
   - Because Alice's output in State #0 is locked by **Stage 06's `OP_CHECKSEQUENCEVERIFY`** for `to_self_delay` blocks (e.g., 144 blocks), Alice cannot spend her `1,000,000 sats` right away!
   - Meanwhile, Bob's `bitcoind` node notifies Bob's `lnd` daemon that State #0 just entered a block. Bob uses Alice's **State #0 Revocation Preimage** to immediately broadcast a **Justice (Penalty) Transaction** to `bitcoind`, sweeping **100% of the `1,000,000 sats`** to Bob!
4. **Step 4 — Channel Close (1 On-Chain Transaction on `bitcoind`):**
   - **Cooperative Close (Best & Cheapest):** Alice and Bob agree to close the channel and sign a clean 1-input, 2-output transaction with **no timelocks**, paying low fees (`bc1q...` / `bc1p...`) directly to their wallets on `bitcoind`.
   - **Force Close (Unilateral):** If Bob goes offline forever, Alice broadcasts the latest **State #2** Commitment Transaction to `bitcoind`, waits `144 blocks` (`OP_CSV`), and sweeps her `600,000 sats`.

---

## Part 3: How `lnd` Talks to `bitcoind` (The 5 Exact Bridge Calls)

A Lightning node (`lnd`) **cannot function without a Bitcoin node (`bitcoind`)**. Why? Because `lnd` does not validate blocks or hold the UTXO set—it relies on `bitcoind` as its **Eyes and Hands on Layer 1**:

| # | `bitcoind` RPC / Notification | Why `lnd` Calls It on `bitcoind` |
| :-: | :--- | :--- |
| **1** | **`getblockchaininfo` / `getblockhash` / `getblock`** | **Watching for Funding & Breaches:** `lnd` scans every new block mined on `bitcoind` to confirm when a Funding Tx reaches 3–6 confirmations, or to detect if a peer broadcasted a revoked old Commitment Tx! |
| **2** | **`estimatesmartfee`** | **Dynamic Channel Fee Sizing:** `lnd` asks `bitcoind` for current `sat/vB` feerates to set the fee on Commitment Transactions, Cooperative Closes, and Sweep transactions. |
| **3** | **`sendrawtransaction`** | **Broadcasting to Layer 1:** When opening a channel, force-closing, sweeping an HTLC timeout, or punishing a cheater, `lnd` constructs the raw hex transaction and calls `sendrawtransaction` on `bitcoind`. |
| **4** | **`submitpackage` (`BIP431 TRUC v3` & `1P1C`)** | **Next-Gen Package Fee Bumping (Stage 05):** Modern Lightning commitment transactions use `submitpackage` on `bitcoind` so a 0-fee Commitment Tx (`parent`) and a high-fee Anchor CPFP (`child`) enter the mempool atomically! |
| **5** | **`ZMQ` (`-zmqpubrawblock`, `-zmqpubrawtx`) / RPC Polling** | **Real-Time Wakeup:** `bitcoind` pushes newly arrived blocks and transactions to `lnd` in milliseconds so `lnd` can react immediately to HTLC preimages on-chain. |

---

## Part 4: Your Guided Offline BOLT Study Order (`./lab.sh bolt <num>`)

All Lightning specifications (`BOLTs`) are already stored offline on your Mac in `/Users/mac/bitcoin-references/bolts/`. Read them in this exact order using `./lab.sh`:

1. **`./lab.sh bolt 3` (BOLT #3: Bitcoin Transaction and Script Formats)** — *Start here!* You will immediately recognize `OP_CHECKSEQUENCEVERIFY`, `OP_SHA256`, `OP_CHECKLOCKTIMEVERIFY`, and SegWit witness scripts from **Stage 02** and **Stage 06**!
2. **`./lab.sh bolt 2` (BOLT #2: Peer Protocol for Channel Management)** — How `open_channel`, `funding_created`, `funding_signed`, `commitment_signed`, and `revoke_and_ack` messages work.
3. **`./lab.sh bolt 11` (BOLT #11: Invoice Protocol for Lightning Payments)** — How `lnbc...` invoices encode the `payment_hash` (`H`), amount in millisatoshis (`msat`), expiry, and node signature.
4. **`./lab.sh bolt 4` (BOLT #4: Onion Routing Protocol)** — How Sphinx onion packets hide who is paying whom across multiple Lightning hops.
