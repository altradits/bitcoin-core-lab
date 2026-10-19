# Merged PR #36447 Review Journey: `test: Misc fixes for pending validation events races`

- **Author:** `@maflcko`
- **Merged At:** `2026-10-07T12:56:49Z`
- **Final Merged Head Commit:** `fa466dea808dedfc281cdff842cbefafae574d8a`
- **Local Git Branch in `/Users/mac/bitcoin`:** `pr-36447` (`git -C /Users/mac/bitcoin show pr-36447`)
- **Core Lesson for Reviewers:** How reviewers (@sedited, @ismaelsadeeq) spotted additional unsynchronized places in the same file (`txindex_tests.cpp`) and suggested moving the event drain into `mineBlock()`, directly improving the PR before merge.

---

## 1. Original PR Description

```text
`TestChain100Setup` enqueues 100 validation events from blocks. Unit tests using that setup and their own validation events may run into non-determinism and even intermittent test failures.

Fix all issues by draining the pending validation events in the ctor.

This can be tested with a diff like:

```diff
diff --git a/src/validationinterface.cpp b/src/validationinterface.cpp
index 128f14a6d5..2ea3ec8d4c 100644
--- a/src/validationinterface.cpp
+++ b/src/validationinterface.cpp
@@ -14,2 +14,3 @@
 #include <primitives/transaction.h>
+#include <random.h>
 #include <util/check.h>
@@ -156,2 +157,4 @@ void ValidationSignals::SyncWithValidationInterfaceQueue()
 
+static FastRandomContext g_rnd{};
+
 // Use a macro instead of a function for conditional logging to prevent
@@ -168,2 +171,3 @@ void ValidationSignals::SyncWithValidationInterfaceQueue()
             LOG_EVENT("%s", local_log_msg);                                                                      \
+            UninterruptibleSleep(1ms * g_rnd.randrange(105));   \
             local_event();                                                                                       \
```

and then running the test `scan_for_wallet_transactions_attach_chain` a few times.

Or master (or the first commit), it should fail with: `error: scan_for_wallet_transactions_attach_chain": check wallet->mapWallet.size() == static_cast<size_t>(NEW_BLOCKS + 1) has failed [7 != 6]`.

(Also included is a commit to move-only the many rescan tests to a separate file)

(Also included is a commit to fix unsafe index shutdowns in tests)
```

## 2. Commit & Diff Stat (`git show --stat pr-36447`)

```text
commit fa466dea808dedfc281cdff842cbefafae574d8a
Author: MarcoFalke <*~=`'#}+{/-|&$^_@721217.xyz>
Date:   Tue Oct 6 18:13:36 2026 +0200

    test: Avoid pending validation events from TestChain100Setup
    
    Drain events in mineBlock and CreateAndProcessBlock by default to avoid
    intermittnet test failures in scan_for_wallet_transactions_attach_chain
    and other tests.

 src/test/util/setup_common.cpp   |  7 +++++--
 src/test/util/setup_common.h     | 13 +++++++------
 src/wallet/test/wallet_tests.cpp |  4 ++--
 3 files changed, 14 insertions(+), 10 deletions(-)
```

## 3. Inline Code Review Comments (Where Reviewers Improved the Code)

### `@ismaelsadeeq` on `src/test/util/setup_common.cpp:436` (2026-10-07T05:38:42Z)

```diff
@@ -431,6 +431,10 @@ TestChain100Setup::TestChain100Setup(
     // Generate a 100-block chain:
     this->mineBlocks(COINBASE_MATURITY);
 
+    // Make the fixture deterministic. Tests requiring validation callbacks
+    // should explicitly create them.
+    if (m_node.validation_signals) m_node.validation_signals->SyncWithValidationInterfaceQueue();
```

> Perhaps it may be better to just drain in mineBlock? That way other callers that will mine a block get the notification emitted for free, without them having to drain themselves?

### `@ismaelsadeeq` on `src/wallet/test/rescan_tests.cpp:574` (2026-10-07T05:40:08Z)

```diff
@@ -569,6 +569,10 @@ BOOST_FIXTURE_TEST_CASE(scan_for_wallet_transactions_attach_chain, TestChain100S
         CreateAndProcessBlock({}, GetScriptForRawPubKey(coinbaseKey.GetPubKey()));
     }
 
+    // Drain BlockConnected callbacks before loading the wallet, so stale
+    // notifications will not update its tip during test checks.
+    m_node.chain->waitForNotifications();
```

> Same comment here: can we move the drain to CreateAndProcessBlock?

### `@maflcko` on `src/test/util/setup_common.cpp:436` (2026-10-07T06:37:41Z)

```diff
@@ -431,6 +431,10 @@ TestChain100Setup::TestChain100Setup(
     // Generate a 100-block chain:
     this->mineBlocks(COINBASE_MATURITY);
 
+    // Make the fixture deterministic. Tests requiring validation callbacks
+    // should explicitly create them.
+    if (m_node.validation_signals) m_node.validation_signals->SyncWithValidationInterfaceQueue();
```

> I was thinking that it could be useful coverage for the unit tests to be async here. But then, I don't know if they have ever found an issue here. Of course, we still need the option to be async, but maybe it is fine to sync by default.
> 
> I'll push that ...

### `@sedited` on `src/test/txindex_tests.cpp:174` (2026-10-07T10:04:08Z)

```diff
@@ -170,8 +171,7 @@ BOOST_FIXTURE_TEST_CASE(txindex_initial_sync, TestChain100Setup)
         LookupTx(txindex, txn.GetHash());
     }
 
-    // shutdown sequence (c.f. Shutdown() in init.cpp)
-    txindex.Stop();
+    StopIndex(txindex, m_node);
```

> What about the other cases of `txindex.Stop()` in this file? I guess most don't produce more blocks, but the last test for example does, so maybe we should also sync there?

### `@maflcko` on `src/test/txindex_tests.cpp:174` (2026-10-07T10:43:46Z)

```diff
@@ -170,8 +171,7 @@ BOOST_FIXTURE_TEST_CASE(txindex_initial_sync, TestChain100Setup)
         LookupTx(txindex, txn.GetHash());
     }
 
-    // shutdown sequence (c.f. Shutdown() in init.cpp)
-    txindex.Stop();
+    StopIndex(txindex, m_node);
```

> ah, I only grepped for the comment. Fixed the others as well now.

## 4. General Discussion & Maintainer Feedback Thread

### `@maflcko` (2026-10-06T20:05:32Z)

Hmm, looks like Ralph Review found another race. To repo:

```diff
diff --git a/src/wallet/test/rescan_tests.cpp b/src/wallet/test/rescan_tests.cpp
index 4c5cf76ced..d838e1fc70 100644
--- a/src/wallet/test/rescan_tests.cpp
+++ b/src/wallet/test/rescan_tests.cpp
@@ -29,2 +29,3 @@
 #include <string>
+#include <thread>
 #include <utility>
@@ -567,4 +568,12 @@ BOOST_FIXTURE_TEST_CASE(scan_for_wallet_transactions_attach_chain, TestChain100S
     constexpr int NEW_BLOCKS{5};
+    const auto delayed_blocks_start = std::chrono::steady_clock::now();
     for (int i = 0; i < NEW_BLOCKS; ++i) {
+        if (i >= 3) {
+            m_node.validation_signals->CallFunctionInValidationInterfaceQueue(
+                [] { std::this_thread::sleep_for(std::chrono::milliseconds{500}); });
+        }
         CreateAndProcessBlock({}, GetScriptForRawPubKey(coinbaseKey.GetPubKey()));
+        if (i < 3) {
+            m_node.validation_signals->SyncWithValidationInterfaceQueue();
+        }
     }
@@ -582,4 +591,9 @@ BOOST_FIXTURE_TEST_CASE(scan_for_wallet_transactions_attach_chain, TestChain100S
     wallet = TestLoadWallet(context);
+    BOOST_TEST_MESSAGE("Wallet load returned " << std::chrono::duration_cast<std::chrono::milliseconds>(std::chrono::steady_clock::now() - delayed_blocks_start).count() << " ms after starting delayed blocks");
+
+    // Allow some delayed callbacks to run before checking the wallet tip.
+    std::this_thread::sleep_for(std::chrono::milliseconds{500});
     {
         LOCK(wallet->cs_wallet);
+        BOOST_TEST_MESSAGE("Assertions at " << std::chrono::duration_cast<std::chrono::milliseconds>(std::chrono::steady_clock::now() - delayed_blocks_start).count() << " ms, wallet height " << wallet->GetLastBlockHeight());
         BOOST_CHECK_EQUAL(wallet->GetLastBlockHeight(), tip_height);
```

Let me push a fix for that as well ...

---

### `@maflcko` (2026-10-06T20:34:55Z)

ok, now the CI is failing because there is another UB race :(

Let's fix that here as well, I guess ...

---

### `@willcl-ark` (2026-10-07T11:27:25Z)

reACK fa466dea808dedfc281cdff842cbefafae574d8a

---

## 5. Formal Reviews & Final `ACK`s

### `@sedited` (`APPROVED`)

ACK 9999557b77224be0f6d079af53fa90042bfd01b9

---

### `@willcl-ark` (`APPROVED`)

ACK 9999557b77224be0f6d079af53fa90042bfd01b9

Nice!

---

### `@ismaelsadeeq` (`APPROVED`)

Code review ACK fa77f27f98211167d9dfeba8933e6866df5fce8b

Minor comments below

---

### `@ismaelsadeeq` (`APPROVED`)

reACK fa10ab5fdbb8ca3fede08dd7c93c7359a5e25433

---

### `@sedited` (`APPROVED`)

ACK fa466dea808dedfc281cdff842cbefafae574d8a

---

### `@StephenChi-hi` (`COMMENTED`)

tACK

I agree, this will sure help to prevent flaky test failures.
built and verified changes, all 862 unit test cases in test_bitcoin passed cleanly.

---
