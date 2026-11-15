# 🛡️ Guardian Security & Consensus Audit: `bitcoin/bitcoin#35664`

> **Study notes, auto-generated (lab.sh pr-audit).** The diff and metadata below were collected by a
> script; the risk ring was assigned automatically and may be wrong. Sections 5–6 are blank for you
> to complete after your own review. See [`README.md`](./README.md) for known issues.

- **PR Title:** Merge bitcoin/bitcoin#35664: test: add CLTV and CHECK(MULTI)SIGVERIFY failure-path vectors to script_tests.json
- **Concentric Risk Ring:** **🟢 Ring 3 — Wallet / RPC / Build / Tests**
- **Merge Commit:** `774d11c58f221294950f05ac4d249e19583e4b7b`
- **Audited PR Tip Commit:** `c4068cf37b6674417c77ce1f295b51dd49a57e81`
- **Auditor:** Stanley Chege Thuita ([@altradits](https://github.com/altradits))

---

## 1. Why This PR Was Merged (Motivation & Maintainer Context)
```text
c4068cf37b6674417c77ce1f295b51dd49a57e81 test: add negative zero CSV failure script test vector (azuchi)
37edf0e2338e4ae811ec224bf27d143ffbee25e6 test: add CHECKLOCKTIMEVERIFY failure-path script test vectors (azuchi)
a86a96d17b37a30ba0664cda01ef42d2d8e16a15 test: add CHECKSIGVERIFY/CHECKMULTISIGVERIFY failure script test vectors (azuchi)

Pull request description:

  While reviewing spec coverage of `src/test/data/script_tests.json` against the script interpreter, I found two gaps that are testable within this file's harness but were never covered:

   **1. `OP_CHECKSIGVERIFY` / `OP_CHECKMULTISIGVERIFY` failure paths**

   `OP_CHECKSIGVERIFY` never appears anywhere in the file, and no vector expects  the `CHECKSIGVERIFY` or `CHECKMULTISIGVERIFY` script errors, so the VERIFY tail of both opcodes (interpreter.cpp, `case OP_CHECKSIGVERIFY`) is untested  here. This commit adds static vectors that fail the signature check with an  empty signature and a valid pubkey, so each opcode returns its opcode-specific error code. The success paths require real signatures and remain covered by the auto-generated tests and functional tests.

   **2. `CHECKLOCKTIMEVERIFY` (BIP65) failure paths**

  `SCRIPT_VERIFY_CHECKLOCKTIMEVERIFY` is never set by any vector:  `CHECKLOCKTIMEVERIFY` only appears as an unflagged NOP, so none of the BIP65  semantics are exercised, while the equivalent CHECKSEQUENCEVERIFY section has existed since #7994. This commit adds a section mirroring the CSV tests, covering every failure path reachable in this harness:

  - empty stack → `INVALID_STACK_OPERATION`
  - negative operand → `NEGATIVE_LOCKTIME`
  - negative zero (`0x80`), evaluated as 0 by `CScriptNum` → `UNSATISFIED_LOCKTIME` rather than `NEGATIVE_LOCKTIME`
  - non-minimal encoding under MINIMALDATA → `SCRIPTNUM`
  - final input nSequence (lock time requirement itself satisfied) → `UNSATISFIED_LOCKTIME`
  - operand greater than the tx nLockTime → `UNSATISFIED_LOCKTIME`
  - height/time type mismatch → `UNSATISFIED_LOCKTIME`
  - 5-byte operand (2^32) accepted by the parser, then failing the type check → `UNSATISFIED_LOCKTIME`

  Unlike CSV (where an operand with bit 31 set makes the opcode pass without  calling `CheckSequence`), the CLTV success path cannot be expressed in this  file, because the test harness spends with nLockTime=0 and a final nSequence;  it is covered by `tx_valid.json` and functional tests instead. A comment in  the JSON notes this.

  **3. Negative zero vector for the existing `CHECKSEQUENCEVERIFY` section**

  Following review feedback, the third commit adds the same negative-zero vector to the existing CSV section: the footgun is identical there (a re-implementation treating any operand with the sign bit set as negative would return `NEGATIVE_LOCKTIME` instead of reaching `CheckSequence`), and it keeps the two sections mirrored.

ACKs for top commit:
  achow101:
    ACK c4068cf37b6674417c77ce1f295b51dd49a57e81
  sedited:
    ACK c4068cf37b6674417c77ce1f295b51dd49a57e81

Tree-SHA512: e7baa9d96b0faec1115c7afb97aa2a8ac17a93d44637cd3e58ab91240b198b6d21c84a29129b586ff760f8f4ca8b1988c652b8f5ebd6ebaa0ffae6615c9aec5d
```

## 2. Commits Inside This PR
```text
c4068cf37b azuchi: test: add negative zero CSV failure script test vector
37edf0e233 azuchi: test: add CHECKLOCKTIMEVERIFY failure-path script test vectors
a86a96d17b azuchi: test: add CHECKSIGVERIFY/CHECKMULTISIGVERIFY failure script test vectors
```

## 3. Touched Files & Diff Stat
```text
 src/test/data/script_tests.json | 18 ++++++++++++++++++
 1 file changed, 18 insertions(+)
```

## 4. Full Source Code Diff
```diff
diff --git a/src/test/data/script_tests.json b/src/test/data/script_tests.json
index 25581c4d64..b88c641547 100644
--- a/src/test/data/script_tests.json
+++ b/src/test/data/script_tests.json
@@ -2569,9 +2569,27 @@
     "P2SH(P2WSH) CHECKMULTISIG with second key uncompressed and signing with the second key"
 ],
 
+["CHECKSIGVERIFY and CHECKMULTISIGVERIFY failure tests"],
+["0", "0x21 0x02865c40293a680cb9c020e7b1e106d8c1916d3cef99aa431a56d253e69256dac0 CHECKSIGVERIFY 1", "P2SH,STRICTENC", "CHECKSIGVERIFY", "CHECKSIGVERIFY fails with its own error code when the signature check fails"],
+["0 0", "1 0x21 0x02865c40293a680cb9c020e7b1e106d8c1916d3cef99aa431a56d253e69256dac0 1 CHECKMULTISIGVERIFY 1", "P2SH,STRICTENC", "CHECKMULTISIGVERIFY", "CHECKMULTISIGVERIFY fails with its own error code when the signature check fails"],
+
+["CHECKLOCKTIMEVERIFY tests"],
+["All tests below can only exercise failure paths: the spending transaction in these tests"],
+["has nLockTime 0 and a final nSequence, so CheckLockTime never succeeds."],
+["", "CHECKLOCKTIMEVERIFY", "CHECKLOCKTIMEVERIFY", "INVALID_STACK_OPERATION", "CLTV automatically fails on an empty stack"],
+["-1", "CHECKLOCKTIMEVERIFY", "CHECKLOCKTIMEVERIFY", "NEGATIVE_LOCKTIME", "CLTV automatically fails if stack top is negative"],
+["0x0180", "CHECKLOCKTIMEVERIFY", "CHECKLOCKTIMEVERIFY", "UNSATISFIED_LOCKTIME", "Negative zero is treated as 0, so CLTV fails with UNSATISFIED_LOCKTIME rather than NEGATIVE_LOCKTIME"],
+["0x0100", "CHECKLOCKTIMEVERIFY", "CHECKLOCKTIMEVERIFY,MINIMALDATA", "SCRIPTNUM", "CLTV use is non-standard if stack top is not minimally encoded"],
+["0", "CHECKLOCKTIMEVERIFY", "CHECKLOCKTIMEVERIFY", "UNSATISFIED_LOCKTIME", "CLTV fails if the input's nSequence is final, even when the lock time requirement is met"],
+["499999999", "CHECKLOCKTIMEVERIFY", "CHECKLOCKTIMEVERIFY", "UNSATISFIED_LOCKTIME", "CLTV fails if the stack operand (height) is greater than the tx nLockTime"],
+["500000000", "CHECKLOCKTIMEVERIFY", "CHECKLOCKTIMEVERIFY", "UNSATISFIED_LOCKTIME", "CLTV fails if the operand is time-based while the tx nLockTime is height-based"],
+["0x050000000001", "CHECKLOCKTIMEVERIFY", "CHECKLOCKTIMEVERIFY", "UNSATISFIED_LOCKTIME",
+ "CLTV accepts a 5-byte operand (2^32), but it is time-based while the tx nLockTime is height-based"],
+
 ["CHECKSEQUENCEVERIFY tests"],
 ["", "CHECKSEQUENCEVERIFY", "CHECKSEQUENCEVERIFY", "INVALID_STACK_OPERATION", "CSV automatically fails on an empty stack"],
 ["-1", "CHECKSEQUENCEVERIFY", "CHECKSEQUENCEVERIFY", "NEGATIVE_LOCKTIME", "CSV automatically fails if stack top is negative"],
+["0x0180", "CHECKSEQUENCEVERIFY", "CHECKSEQUENCEVERIFY", "UNSATISFIED_LOCKTIME", "Negative zero is treated as 0, so CSV fails with UNSATISFIED_LOCKTIME rather than NEGATIVE_LOCKTIME"],
 ["0x0100", "CHECKSEQUENCEVERIFY", "CHECKSEQUENCEVERIFY,MINIMALDATA", "SCRIPTNUM", "CSV fails if stack top is not minimally encoded"],
 ["0", "CHECKSEQUENCEVERIFY", "CHECKSEQUENCEVERIFY", "UNSATISFIED_LOCKTIME", "CSV fails if stack top bit 1 << 31 is set and the tx version < 2"],
 ["0x050000000001", "CHECKSEQUENCEVERIFY", "CHECKSEQUENCEVERIFY", "UNSATISFIED_LOCKTIME",
```

---

## 5. Review checklist (YOURS to tick — nothing below was checked for you)
- [ ] **1. Risk area:** Which subsystem and invariant does this PR touch? Is any consensus behaviour affected? (Decide yourself; the ring label above was assigned by a script.)
- [ ] **2. Invariants:** Which invariants must hold (supply, UTXO conservation, policy limits, determinism)? How did you check them?
- [ ] **3. Bounds:** Integer overflow/underflow, unbounded containers or loops reachable by a peer or RPC caller?
- [ ] **4. Locking:** Which mutexes are taken; do the annotations (`EXCLUSIVE_LOCKS_REQUIRED`, `GUARDED_BY`) still hold?
- [ ] **5. Adversarial input:** Can an untrusted peer or caller make the node do expensive work?
- [ ] **6. Tests:** Do the PR's tests fail without the change (mutation)? What did you run, on which commit?

## 6. Your conclusion (fill in from YOUR OWN testing; never post text you did not write)
- Commit I reviewed: `________`
- What I built and ran (exact commands): ________
- What I tested manually beyond the PR's tests: ________
- Questions / concerns for the author: ________
- My conclusion (Concept/Approach/Code review, or none yet): ________

> Bitcoin Core's `doc/AI_POLICY.md` (master) and `CONTRIBUTING.md` expect review comments to be your
> own work. This file is study material, not a comment to paste.
