# Bitcoin first principles workbook

> *"A purely peer-to-peer version of electronic cash would allow online payments to be sent directly from one party to another without going through a financial institution."*
> — Satoshi Nakamoto, *Bitcoin: A Peer-to-Peer Electronic Cash System* (2008)

This workbook links Satoshi's design to the code you will review. It is a
**repetition companion** to stages 01–07: each drill gives the concept, the goal,
hints and a self-check, never the finished commands
([no-shortcuts rule](./CURRICULUM_CONVENTIONS.md#1-the-no-shortcuts-rule)).
Competency IDs and the schedule are in [CURRICULUM.md](./CURRICULUM.md).

Paths are relative to a Bitcoin Core checkout. Symbols were checked on `master` at `e75b76b12c`.

---

## Part 1: Five invariants to carry into every review

| # | Invariant | Whitepaper | Where to look |
|---|---|---|---|
| 1 | Capped supply and halving | §6 Incentive | `MAX_MONEY` in `src/consensus/amount.h`; `GetBlockSubsidy` in `src/validation.cpp` |
| 2 | Coinbase maturity (100) | §6 | `COINBASE_MATURITY` in `src/consensus/consensus.h`; `Consensus::CheckTxInputs` in `src/consensus/tx_verify.cpp` |
| 3 | Value conservation, implicit fee | §2, §6 | `txfee_aux` and `bad-txns-in-belowout` in `src/consensus/tx_verify.cpp` |
| 4 | Script-based verification | §2 | `EvalScript`, `VerifyScript` in `src/script/interpreter.cpp` |
| 5 | Ordering and incentive-compatible mempool | §3, §5 | `AcceptToMemoryPool` in `src/validation.cpp`; `src/policy/rbf.cpp`; `src/policy/truc_policy.cpp` |

**Exercise:** for each row, open the file yourself, find the symbol with `git grep`, and
write in your journal the line number and one sentence on what would break if that check
were removed.

---

## Part 2: Drills (repeat each until you can do it from memory)

Before any drill: make sure your own built binaries are on your `PATH` and a regtest node
is running. You did this in Stage 13/01; if you can't remember how, that is drill zero.
Keep only one `bitcoind` running (8 GB machine).

### Drill 01: Coinbase maturity *(Stage 01, C-CONS-1)*
- **Concept:** why a coinbase output can't be spent for 100 blocks. (What happens to it in a reorg?)
- **Goal:** mine to an address, try to spend the first coinbase one block too early, then spend it at the boundary.
- <details><summary>Hint 1</summary>Count confirmations, not heights. Which RPC shows them for a UTXO?</details>
- <details><summary>Hint 2</summary>`generatetoaddress`, `listunspent`, then a raw tx (Stage 02 skills). Find the constant with `git grep`.</details>
- **Self-check:** which reject reason do you get, and which function returns it?

### Drill 02: Implicit fees and SegWit weight *(Stage 02, C-TX-1)*
- **Concept:** a transaction has no fee field. Witness bytes are discounted by `WITNESS_SCALE_FACTOR`.
- **Goal:** build a raw tx that would accidentally pay a huge fee, watch the node's guardrail reject it, then fix it with a change output.
- <details><summary>Hint 1</summary>Which RPC argument caps the fee on broadcast?</details>
- <details><summary>Hint 2</summary>`sendrawtransaction help`; the weight formula is base×3 + total.</details>
- **Self-check:** with base 113 bytes and total 222 bytes, compute weight and vsize by hand.

### Drill 03: RBF and CPFP *(Stage 03, C-MEMPOOL-2)*
- **Concept:** a replacement must pay for its own relay bandwidth. A child can pay for its parent.
- **Goal:** make a replacement that fails the incremental-fee rule, then one that passes. Then lift a stuck parent with a child.
- <details><summary>Hint 1</summary>Read `PaysForRBF` in `src/policy/rbf.cpp` and `doc/policy/mempool-replacements.md`.</details>
- <details><summary>Hint 2</summary>`bumpfee` hides the mechanics, so use raw transactions. `getmempoolentry` shows the ancestor/descendant numbers.</details>
- **Self-check:** which rule number stops 1-sat replacement spam?

### Drill 04: Functional tests *(Stage 04, C-PY-1..3)*
- **Goal:** run two upstream mempool tests by name, then write your own two-node test in `my-work/04-functional-test-framework/`.
- <details><summary>Hint 1</summary>`test/functional/README.md` explains the runner and the `--configfile` your direct runs need.</details>
- **Self-check:** what goes wrong without `sync_mempools()` in a two-node relay test?

### Drill 05: TRUC and `submitpackage` *(Stage 05, C-MEMPOOL-3)*
- **Concept:** a 0-fee v3 parent plus a fee-paying v3 child, accepted atomically. Size bounds stop pinning.
- **Goal:** show the 0-fee parent fails alone and the 1P1C package succeeds. Then trigger a TRUC violation with a v2 child.
- <details><summary>Hint 1</summary>Constants live in `src/policy/truc_policy.h`.</details>
- **Self-check:** what are the TRUC child's vsize limit and its constant name?

### Drill 06: HTLC script *(Stage 06, C-LN-2, C-TX-3)*
- **Goal:** fund a P2WSH HTLC. Fail with a wrong preimage, succeed with the right one, and show a premature CSV refund is rejected.
- <details><summary>Hint 1</summary>`OP_IF … OP_SHA256 <H> OP_EQUALVERIFY … OP_ELSE <n> OP_CSV OP_DROP … OP_ENDIF`; the input's `nSequence` matters.</details>
- **Self-check:** which reject reason does a premature CSV spend give?

### Drill 07: Descriptors and PSBT *(Stage 07, C-PSBT-1, C-WALLET-1)*
- **Goal:** a watch-only wallet creates the PSBT, a separate signer wallet signs it, then you finalize and broadcast.
- <details><summary>Hint 1</summary>`createwallet` has a `disable_private_keys` argument. Read `doc/psbt.md`.</details>
- **Self-check:** name each BIP174 role and the RPC that performs it.

---

## Part 3: Weekly review loop (the habit behind every gate)

Bitcoin Core's `CONTRIBUTING.md` says reviewing and testing are "the bottleneck of the
project" and the most effective way to start contributing. That is why the curriculum
starts public reviews in week 4. **What Btrust evaluates** is listed in the
[playbook](./BTRUST_AND_BITDEVS_PLAYBOOK.md). Don't rely on the earlier claim that grant
committees judge "primarily" on reviews; it was unverified and has been removed.

Each week, for one open PR:
1. **Fetch and check out** the PR by number into a local branch (C-GIT-2). *Hint:* GitHub exposes `pull/<N>/head`.
2. **Read the commits one by one** against the merge-base, not just the combined diff.
3. **Build only what you need and run the tests it touches**, with `-j` sized for 8 GB.
4. **Mutation-test:** break the PR's key check and confirm a test fails, then restore it (C-TEST-3).
5. **Write your own review** following CONTRIBUTING.md "Peer Review": `ACK <commit>` (or Concept/Approach ACK, or a reasoned NACK), followed by *what you actually did*. There is deliberately no template here: write it fresh from your journal (`doc/AI_POLICY.md` on master).
6. Log the link in [BTRUST_READINESS_TRACKER.md](./BTRUST_READINESS_TRACKER.md).
