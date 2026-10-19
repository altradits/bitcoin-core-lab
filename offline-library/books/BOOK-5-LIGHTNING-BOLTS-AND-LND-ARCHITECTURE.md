# Book 5: Lightning Network BOLTs, Off-Chain State & LND Architecture (From Memory)

> **Purpose of This Offline Book:**
> Covers the protocol mechanics required for Stage `12` (`12-lightning-readiness-and-bitcoind-bridge/`), `./lab.sh polar`, and all chapters of _Mastering the Lightning Network_ (`/Users/mac/bitcoin-references/books/mastering-lightning/`).

---

## Chapter 1: How a Lightning Channel Anchors to Bitcoin Core (`BOLT 2` & `BOLT 3`)

A Lightning payment channel is **not** a separate token or sidechain—every single state is a real, valid, signed Bitcoin transaction ready to be broadcast to `bitcoind`:

1. **Funding Transaction (On-Chain):**
   - Spends on-chain UTXOs into a **2-of-2 P2WSH (`bc1q` / `bcrt1q`) or MuSig2 P2TR (`bc1p`)** output requiring both Alice's and Bob's signatures:
     ```text
     2 <pubkey_Alice> <pubkey_Bob> 2 OP_CHECKMULTISIG
     ```
2. **Asymmetric Commitment Transactions (Off-Chain):**
   - **Before** signing the Funding Transaction, Alice and Bob sign **Commitment State #0** (which spends the 2-of-2 funding output back to Alice and Bob).
   - Why **asymmetric**? Because if Alice broadcasts *her* commitment transaction, *her* payout (`to_local`) must be delayed by `to_self_delay` blocks (`OP_CHECKSEQUENCEVERIFY`) so Bob has time to penalize her if she broadcast an old state! Meanwhile, Bob's payout (`to_remote`) is immediately spendable by Bob.

---

## Chapter 2: The `to_local` Script & Justice Transactions (`BOLT 3` & `BOLT 5`)

Memorize the exact Bitcoin Script inside every commitment transaction's `to_local` output:

```text
OP_IF
    # Penalty / Justice Path (Immediate if Alice broadcasts a revoked state!)
    <revocationpubkey>
OP_ELSE
    # Honest Force-Close Path (Alice must wait to_self_delay blocks!)
    <to_self_delay>
    OP_CHECKSEQUENCEVERIFY
    OP_DROP
    <local_delayedpubkey>
OP_ENDIF
OP_CHECKSIG
```

- **When moving from State $N$ to State $N+1$:**
  - Alice and Bob exchange signatures for State $N+1$, and Alice reveals her **per-commitment secret** for State $N$.
  - That secret allows Bob (and only Bob!) to compute the private key for `<revocationpubkey>` of State $N$.
  - If Alice ever broadcasts State $N$ on-chain, Bob's `lnd` node spots the transaction via `bitcoind`'s ZMQ (`hashblock`/`rawtx`), takes the `OP_IF` branch, and sweeps **100% of Alice's channel balance** before her `OP_CSV` timer expires!

---

## Chapter 3: Hash Time-Locked Contracts (HTLCs) & Multi-Hop Routing (`BOLT 2`, `BOLT 3`, `BOLT 4`)

How does Alice pay Carol through Bob (`Alice -> Bob -> Carol`) without trusting Bob?
1. Carol generates a random 32-byte secret **Preimage $R$** and puts its SHA256 hash **$H = \text{SHA256}(R)$** inside a `BOLT 11` invoice (`lnbcrt...`).
2. Alice offers Bob an HTLC paying Bob **if and only if** Bob reveals $R$ before block height $T_2$ (`OP_SHA256 <H> OP_EQUALVERIFY` vs `OP_CHECKLOCKTIMEVERIFY`).
3. Bob offers Carol an HTLC with the **same payment hash $H$**, expiring at block height $T_1 < T_2$ (the timeout delta is `cltv_expiry_delta`).
4. Carol reveals $R$ to Bob to claim her sats $\rightarrow$ Bob now knows $R$ and reveals it to Alice to claim his sats!

---

## Chapter 4: How `lnd` Talks to `bitcoind` (Polar & Production Architecture)

In your Polar networks (`Addis Ababa Bootcamp` and `Bitrust Bootcamp 2026`), every `lnd` container connects to `backend1` (`bitcoind -regtest`) via two channels:
1. **JSON-RPC (`-rpcport=18443`):** `lnd` calls `getblockchaininfo`, `getblock`, `sendrawtransaction`, and `estimatesmartfee`.
2. **ZeroMQ (`-zmqpubrawblock=tcp://0.0.0.0:28334`, `-zmqpubrawtx=tcp://0.0.0.0:28335`):** `bitcoind` pushes real-time block and mempool notifications to `lnd` so `lnd` can detect channel funding confirmations and revoked commitment breaches immediately.

---

## 🧠 Blind Recall Challenges (Close This File & Write From Memory!)

1. **Drill 5.1 (`to_local` Script):** Write out the 9-line `OP_IF ... OP_ELSE ... OP_ENDIF OP_CHECKSIG` script for a Lightning `to_local` output from memory.
2. **Drill 5.2 (CLTV Delta Rule):** If `Alice -> Bob -> Carol` routes an HTLC, must `T_Alice_Bob` be **greater than** or **less than** `T_Bob_Carol`? Explain in one sentence what happens to Bob if they are equal.
3. **Drill 5.3 (Conservation of Channel Sats):** In a 1,000,000-sat channel with a 1,500-sat on-chain commitment fee, if Alice has 600,000 sats and offers a 50,000-sat in-flight HTLC, what is `to_local + to_remote + htlc + fee`?
