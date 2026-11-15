# Stage 06: HTLCs — Hand-Assemble the Script, Spend Both Branches, Then Read BOLT 3

> Source checked: `src/script/interpreter.cpp`, `src/consensus/tx_verify.cpp` at `v29.0`
> (`f490f5562d`); BOLT 3 from your offline copy in `/Users/mac/bitcoin-references/bolts/`.

**No-Shortcuts Rule.** You assemble the HTLC script byte by byte on paper, you write the Python
that signs both spending paths, and you read BOLT 3 to see how real Lightning differs from the toy.
The previous all-in-one script is the spoiler in
[`solutions/verify_htlc.py`](./solutions/verify_htlc.py). Journal:
`my-work/06-lightning-htlc-state-machine/journal.md`.

---

## Objectives

| ID | You can... |
|----|------------|
| C-LN-2 | build an HTLC witness script by hand, fund it as P2WSH, and spend it through the preimage path and the timeout path |
| C-TX-3 | explain `nSequence` relative locks (BIP68), `OP_CHECKSEQUENCEVERIFY` (BIP112), `OP_CHECKLOCKTIMEVERIFY` (BIP65), and why BIP113 uses median-time-past |
| C-SCRIPT-2 | build a P2WSH output from a witness script and sign a BIP143 sighash for it |
| C-LN-3 (intro) | read BOLT 3's offered/received HTLC scripts and explain revocation |

## Prerequisites
Stage 02 (serialization, P2WPKH, sighash) and Stage 04 (you can import `test_framework`).
Estimated time: 8 hours.

---

## Theory

### 1. The toy HTLC
```
OP_IF
    OP_SHA256 <H> OP_EQUALVERIFY <merchant_pubkey> OP_CHECKSIG      # pay if you know R with SHA256(R)=H
OP_ELSE
    <delay> OP_CHECKSEQUENCEVERIFY OP_DROP <sender_pubkey> OP_CHECKSIG   # refund after `delay` blocks
OP_ENDIF
```
Witness stacks (bottom → top, last item is the witness script for P2WSH):
- claim: `<sig_merchant> <R> 0x01 <script>`
- refund: `<sig_sender> <empty> <script>` with the input's `nSequence = delay`.

Segwit v0 enforces **MINIMALIF** as policy (and tapscript as consensus): the `OP_IF` argument
must be exactly empty or exactly `0x01` (`SCRIPT_VERIFY_MINIMALIF`, `src/script/interpreter.h`).

### 2. Relative and absolute timelocks
| Mechanism | Field / opcode | Code |
|-----------|----------------|------|
| absolute, tx level | `nLockTime` (+ a non-final `nSequence`) | `IsFinalTx` in `src/consensus/tx_verify.cpp` |
| absolute, script | `OP_CHECKLOCKTIMEVERIFY` (BIP65) | `CheckLockTime` in `src/script/interpreter.cpp` |
| relative, tx level | `nSequence` (BIP68; bit 31 disables, bit 22 = time units of 512 s) | `CalculateSequenceLocks`, `SequenceLocks` |
| relative, script | `OP_CHECKSEQUENCEVERIFY` (BIP112) | `CheckSequence` |

Opcodes only **check** that the tx field is set at least as high; the tx field is what consensus
enforces against the chain. That is why the refund tx itself must carry `nSequence = delay` and
`version >= 2`. Time-based locks use **median-time-past** of the last 11 blocks (BIP113) so miners
cannot game timestamps.

### 3. P2WSH
`scriptPubKey = OP_0 <SHA256(witness_script)>` = `0x00 0x20 <32 bytes>`. The spender reveals
the script in the witness; `VerifyWitnessProgram` checks its SHA256 matches.

### 4. Real Lightning (BOLT 3) differs
- Hash: `OP_HASH160 <RIPEMD160(payment_hash)>` (20 bytes) to save space. `OP_HASH160` computes
  RIPEMD160(SHA256(x)); since `payment_hash = SHA256(preimage)`, hashing the preimage with
  `OP_HASH160` gives RIPEMD160(payment_hash). `OP_SIZE 32 OP_EQUAL` picks the branch by item size.
- Every output has a **revocation** path: if a party broadcasts an old commitment, the other
  claims everything with the revocation key (penalty).
- The timeout uses **absolute** `cltv_expiry`, enforced through a second-stage HTLC-timeout tx
  with `nLockTime`, plus `to_self_delay` CSV on the broadcaster's own funds.
- With anchors, HTLC outputs use `1 OP_CHECKSEQUENCEVERIFY` so they cannot be spent in the same
  block (CPFP carve-out safety).

---

## Exercises

| # | Worksheet | Checker |
|---|-----------|---------|
| 1 | [Assemble the HTLC script by hand](./exercises/01-assemble-the-script.md) | `./check_htlc_script.sh` (offline) |
| 2 | [Fund it and spend both branches with your own Python](./exercises/02-spend-both-branches.md) | `./check_htlc_spends.sh` |
| 3 | [BOLT 3: toy vs real](./exercises/03-bolt3-compare.md) | `./check_bolt3.sh` (offline) |

Copy [`exercises/answers.env.template`](./exercises/answers.env.template) to
`my-work/06-lightning-htlc-state-machine/answers.env`.

---

## Self-check quiz (answers in [`solutions/quiz_answers.md`](./solutions/quiz_answers.md))
1. Write the byte values of `OP_IF`, `OP_ELSE`, `OP_ENDIF`, `OP_SHA256`, `OP_EQUALVERIFY`, `OP_CHECKSIG`, `OP_CHECKSEQUENCEVERIFY`, `OP_DROP`.
2. How is the number 10 pushed in a script? And 144?
3. Why must the refund tx have `version >= 2`?
4. The refund's input has `nSequence = 10`, the funding tx has 3 confirmations. What does `testmempoolaccept` say?
5. Why is a wrong preimage rejected with `mandatory-script-verify-flag-failed`, while an early refund gives `non-BIP68-final`?
6. What does `0x01` in the claim witness do, and what would `0x02` cause?
7. Why does BOLT 3 use `OP_HASH160 <RIPEMD160(payment_hash)>` instead of `OP_SHA256 <payment_hash>`?
8. What stops a Lightning party from broadcasting an old, favourable commitment?

---

## Review lens
- Files: `src/script/interpreter.cpp` (`EvalScript` cases for `OP_CHECKLOCKTIMEVERIFY`,
  `OP_CHECKSEQUENCEVERIFY`; `GenericTransactionSignatureChecker::CheckSequence`/`CheckLockTime`),
  `src/consensus/tx_verify.cpp` (`IsFinalTx`, `CalculateSequenceLocks`, `EvaluateSequenceLocks`),
  `src/validation.cpp` (`CheckSequenceLocksAtTip`).
- Tests: `feature_bip68_sequence.py`, `feature_csv_activation.py`, `feature_cltv.py`,
  `src/test/script_tests.cpp`, `src/test/data/script_tests.json`.
- Invariants: timelocks are monotone (once spendable, always spendable on that chain, except via
  reorg); script checks never depend on wall-clock time; consensus and policy flags stay separated.
- Questions: does the PR change how sequence/locktime fields are interpreted (consensus!)? Is
  there a reorg case where a tx becomes non-final again, and is the mempool cleaned
  (`removeForReorg`)?

## Proof-of-work output
Your own `htlc_spend.py` in `my-work/06-lightning-htlc-state-machine/` and a one-page note
comparing the toy HTLC with BOLT 3. Good material for a BitDevs Kisumu Lightning session.
