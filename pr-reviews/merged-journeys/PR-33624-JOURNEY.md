# Merged PR #33624 Review Journey: `test: P2SH sig ops are only counted with `SCRIPT_VERIFY_P2SH``

- **Author:** `@brunoerg`
- **Merged At:** `2025-10-15T08:55:55Z`
- **Final Merged Head Commit:** `3a10d700bc1889b3690097efc935c5a4ba5966bb`
- **Local Git Branch in `/Users/mac/bitcoin`:** `pr-33624` (`git -C /Users/mac/bitcoin show pr-33624`)
- **Core Lesson for Reviewers:** How @instagibbs improved test readability with inline `/*flags=*/0` parameter comments, and how @l0rinc & @janb84 proved the new test actually catches bugs by mutating `src/consensus/tx_verify.cpp` (`1 == 1`) to watch the assertion fail.

---

## 1. Original PR Description

```text
This PR adds a test case for `GetTransactionSigOpCost` to check that P2SH sig ops are only counted when `SCRIPT_VERIFY_P2SH` flag is set. 

Kills the following [mutant](https://corecheck.dev/mutation/src/consensus/tx_verify.cpp#L150):

```diff
diff --git a/src/consensus/tx_verify.cpp b/src/consensus/tx_verify.cpp
index 9d09872597..cc7cdaaf8f 100644
--- a/src/consensus/tx_verify.cpp
+++ b/src/consensus/tx_verify.cpp
@@ -147,7 +147,7 @@ int64_t GetTransactionSigOpCost(const CTransaction& tx, const CCoinsViewCache& i
     if (tx.IsCoinBase())
         return nSigOps;

-    if (flags & SCRIPT_VERIFY_P2SH) {
+    if (1==1) {
         nSigOps += GetP2SHSigOpCount(tx, inputs) * WITNESS_SCALE_FACTOR;
     }
```
```

## 2. Commit & Diff Stat (`git show --stat pr-33624`)

```text
commit 3a10d700bc1889b3690097efc935c5a4ba5966bb
Author: brunoerg <brunoely.gc@gmail.com>
Date:   Tue Oct 14 11:02:38 2025 -0300

    test: P2SH sig ops are only counted with `SCRIPT_VERIFY_P2SH` flag

 src/test/sigopcount_tests.cpp | 3 +++
 1 file changed, 3 insertions(+)
```

## 3. Inline Code Review Comments (Where Reviewers Improved the Code)

### `@instagibbs` on `src/test/sigopcount_tests.cpp:156` (2025-10-14T16:40:30Z)

```diff
@@ -151,6 +151,9 @@ BOOST_AUTO_TEST_CASE(GetTxSigOpCost)
         BuildTxs(spendingTx, coins, creationTx, scriptPubKey, scriptSig, CScriptWitness());
         assert(GetTransactionSigOpCost(CTransaction(spendingTx), coins, flags) == 2 * WITNESS_SCALE_FACTOR);
         assert(VerifyWithFlag(CTransaction(creationTx), spendingTx, flags) == SCRIPT_ERR_CHECKMULTISIGVERIFY);
+
+        // Ignore the SCRIPT_VERIFY_P2SH flag
+        assert(GetTransactionSigOpCost(CTransaction(spendingTx), coins, 0) == 0);
```

> ```suggestion
>         assert(GetTransactionSigOpCost(CTransaction(spendingTx), coins, /*flags=*/0) == 0);
> ```

### `@instagibbs` on `src/test/sigopcount_tests.cpp:155` (2025-10-14T16:41:57Z)

```diff
@@ -151,6 +151,9 @@ BOOST_AUTO_TEST_CASE(GetTxSigOpCost)
         BuildTxs(spendingTx, coins, creationTx, scriptPubKey, scriptSig, CScriptWitness());
         assert(GetTransactionSigOpCost(CTransaction(spendingTx), coins, flags) == 2 * WITNESS_SCALE_FACTOR);
         assert(VerifyWithFlag(CTransaction(creationTx), spendingTx, flags) == SCRIPT_ERR_CHECKMULTISIGVERIFY);
+
+        // Ignore the SCRIPT_VERIFY_P2SH flag
```

> we're not ignoring, we're not setting it
> ```suggestion
>         // P2SH sigops are not counted if we don't set the SCRIPT_VERIFY_P2SH flag
> ```

### `@brunoerg` on `src/test/sigopcount_tests.cpp:155` (2025-10-14T18:40:10Z)

```diff
@@ -151,6 +151,9 @@ BOOST_AUTO_TEST_CASE(GetTxSigOpCost)
         BuildTxs(spendingTx, coins, creationTx, scriptPubKey, scriptSig, CScriptWitness());
         assert(GetTransactionSigOpCost(CTransaction(spendingTx), coins, flags) == 2 * WITNESS_SCALE_FACTOR);
         assert(VerifyWithFlag(CTransaction(creationTx), spendingTx, flags) == SCRIPT_ERR_CHECKMULTISIGVERIFY);
+
+        // Ignore the SCRIPT_VERIFY_P2SH flag
```

> Done.

### `@brunoerg` on `src/test/sigopcount_tests.cpp:156` (2025-10-14T18:40:17Z)

```diff
@@ -151,6 +151,9 @@ BOOST_AUTO_TEST_CASE(GetTxSigOpCost)
         BuildTxs(spendingTx, coins, creationTx, scriptPubKey, scriptSig, CScriptWitness());
         assert(GetTransactionSigOpCost(CTransaction(spendingTx), coins, flags) == 2 * WITNESS_SCALE_FACTOR);
         assert(VerifyWithFlag(CTransaction(creationTx), spendingTx, flags) == SCRIPT_ERR_CHECKMULTISIGVERIFY);
+
+        // Ignore the SCRIPT_VERIFY_P2SH flag
+        assert(GetTransactionSigOpCost(CTransaction(spendingTx), coins, 0) == 0);
```

> Done.

## 4. General Discussion & Maintainer Feedback Thread

### `@maflcko` (2025-10-14T15:51:14Z)

review ACK fd2ce880e09c686c320811a322d00b9318f317ae 📌

<details><summary>Show signature</summary>

Signature:

```
untrusted comment: signature from minisign secret key on empty file; verify via: minisign -Vm "${path_to_any_empty_file}" -P RWTRmVTMeKV5noAMqVlsMugDDCyyTSbA3Re5AkUrhvLVln0tSaFWglOw -x "${path_to_this_whole_four_line_signature_blob}"
RUTRmVTMeKV5npGrKx1nqXCw5zeVHdtdYURB/KlyA/LMFgpNCs+SkW9a8N95d+U4AP1RJMi+krxU1A3Yux4bpwZNLvVBKy0wLgM=
trusted comment: review ACK fd2ce880e09c686c320811a322d00b9318f317ae 📌
a7guwJPj/0LC4GJ0MbGqlb6sKA2KXRIfvwsjinqVvRMBY7d2YgOa1CRK6/m3J6hnBy8ZktVF+ODCSyFZ03sLDQ==
```

</details>

---

### `@brunoerg` (2025-10-14T18:40:40Z)

Force-pushed addressing https://github.com/bitcoin/bitcoin/pull/33624#discussion_r2429811753 and https://github.com/bitcoin/bitcoin/pull/33624#discussion_r2429816763.

---

### `@l0rinc` (2025-10-14T21:22:29Z)

Verified with:
```patch
diff --git a/src/consensus/tx_verify.cpp b/src/consensus/tx_verify.cpp
index 9d09872597..d43bf14b7e 100644
--- a/src/consensus/tx_verify.cpp
+++ b/src/consensus/tx_verify.cpp
@@ -147,7 +147,7 @@ int64_t GetTransactionSigOpCost(const CTransaction& tx, const CCoinsViewCache& i
     if (tx.IsCoinBase())
         return nSigOps;
 
-    if (flags & SCRIPT_VERIFY_P2SH) {
+    if (true) {
         nSigOps += GetP2SHSigOpCount(tx, inputs) * WITNESS_SCALE_FACTOR;
     }
 
diff --git a/src/test/sigopcount_tests.cpp b/src/test/sigopcount_tests.cpp
index 41a4304fe0..30c80533d1 100644
--- a/src/test/sigopcount_tests.cpp
+++ b/src/test/sigopcount_tests.cpp
@@ -153,7 +153,7 @@ BOOST_AUTO_TEST_CASE(GetTxSigOpCost)
         assert(VerifyWithFlag(CTransaction(creationTx), spendingTx, flags) == SCRIPT_ERR_CHECKMULTISIGVERIFY);
 
         // P2SH sigops are not counted if we don't set the SCRIPT_VERIFY_P2SH flag
-        assert(GetTransactionSigOpCost(CTransaction(spendingTx), coins, /*flags=*/0) == 0);
+        // assert(GetTransactionSigOpCost(CTransaction(spendingTx), coins, /*flags=*/0) == 0);
     }
 
     // P2WPKH witness program
```
And the build did indeed pass without the new assert, good find!

Tested ACK 3a10d700bc1889b3690097efc935c5a4ba5966bb

---

### `@maflcko` (2025-10-15T07:54:32Z)

re-lgtm ACK 3a10d700bc1889b3690097efc935c5a4ba5966bb

Only change seems to be a comment/doc.

---

## 5. Formal Reviews & Final `ACK`s

### `@instagibbs` (`APPROVED`)

ACK 3a10d700bc1889b3690097efc935c5a4ba5966bb

---

### `@janb84` (`COMMENTED`)

tested ACK 3a10d700bc1889b3690097efc935c5a4ba5966bb

PR introduces new assert in test that prohibits the `if ( 1 == 1)` mutation / `if(true)`, because the assert will fail in that condition.

- code review ✅
- build & ran tests ✅
- changed code to true to test assert ✅

---
