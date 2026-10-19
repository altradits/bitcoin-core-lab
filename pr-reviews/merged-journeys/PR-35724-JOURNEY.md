# Merged PR #35724 Review Journey: `cmpctblock: Improve logging of `cmpctblock` message reconstruction statistics [part of prefill series]`

- **Author:** `@davidgumberg`
- **Merged At:** `2026-10-16T05:49:00Z`
- **Final Merged Head Commit:** `4f5ce816db1055b8d885113397c7215dc7af3c83`
- **Local Git Branch in `/Users/mac/bitcoin`:** `pr-35724` (`git -C /Users/mac/bitcoin show pr-35724`)
- **Core Lesson for Reviewers:** How @w0xlt caught a real logic bug in extrapool vs mempool counter decrements (causing the author to pause and rework the PR), and how @0xB10C tested the PR on live Signet and pasted real log lines.

---

## 1. Original PR Description

```text
Split from #35558, this makes it easier to observe compact block reconstruction performance by:

- At debuglevel=trace logging all missing TX's in a CMPCTBLOCK, and all missing TX's requested from us.
- Logging the sizes and counts of tx's used from the prefill, mempool, and extrapool.
- Logging the sizes and sources of redundant transactions in the prefill section of received `CMPCTBLOCK`s.
```

## 2. Commit & Diff Stat (`git show --stat pr-35724`)

```text
commit 4f5ce816db1055b8d885113397c7215dc7af3c83
Author: David Gumberg <davidzgumberg@gmail.com>
Date:   Fri Jul 3 00:11:26 2026 +0000

    cmpctblock: log: Print sizes of all tx types and prefill redundancies
    
    At block reconstruction time, log the counts and sizes of prefilled
    transactions, transactions pulled from the mempool, transactions from
    the extrapool, and missing transactions that were acquired via
    `GETBLOCKTXN`.
    
    Also log the count and size of prefilled transactions that were
    redundant and their source (mempool or extrapool).

 src/blockencodings.cpp | 68 +++++++++++++++++++++++++++++++++++++++++++++++---
 src/blockencodings.h   | 13 ++++++++++
 2 files changed, 77 insertions(+), 4 deletions(-)
```

## 3. Inline Code Review Comments (Where Reviewers Improved the Code)

### `@w0xlt` on `src/blockencodings.cpp:164` (2026-07-15T21:46:47Z)

```diff
@@ -161,15 +160,14 @@ ReadStatus PartiallyDownloadedBlock::InitData(const CBlockHeaderAndShortTxIDs& c
                 if (txn_available[idit->second] &&
                         txn_available[idit->second]->GetWitnessHash() != extra_txn[i].second->GetWitnessHash()) {
                     txn_available[idit->second].reset();
-                    mempool_count--;
```

> If I understand correctly, removing this decrement assumes that the existing candidate came from the extrapool. 
> However, it may have been inserted during the earlier mempool scan. Would it make sense to track the candidate’s source and decrement the corresponding counter?

### `@l0rinc` on `src/blockencodings.cpp:164` (2026-07-15T21:52:33Z)

```diff
@@ -161,15 +160,14 @@ ReadStatus PartiallyDownloadedBlock::InitData(const CBlockHeaderAndShortTxIDs& c
                 if (txn_available[idit->second] &&
                         txn_available[idit->second]->GetWitnessHash() != extra_txn[i].second->GetWitnessHash()) {
                     txn_available[idit->second].reset();
-                    mempool_count--;
```

> Seems tangentially related to https://github.com/bitcoin/bitcoin/pull/35727

### `@davidgumberg` on `src/blockencodings.cpp:164` (2026-07-16T18:27:35Z)

```diff
@@ -161,15 +160,14 @@ ReadStatus PartiallyDownloadedBlock::InitData(const CBlockHeaderAndShortTxIDs& c
                 if (txn_available[idit->second] &&
                         txn_available[idit->second]->GetWitnessHash() != extra_txn[i].second->GetWitnessHash()) {
                     txn_available[idit->second].reset();
-                    mempool_count--;
```

> yeah, thanks for catching @w0xlt, I'll fix this after #35727, as that will make this change easier to make correct, marking this pr as draft for now

### `@w0xlt` on `src/net_processing.cpp:2853` (2026-08-19T23:22:58Z)

```diff
@@ -2848,6 +2848,11 @@ void PeerManagerImpl::SendBlockTransactions(CNode& pfrom, Peer& peer, const CBlo
         uint32_t tx_requested_size{0};
         for (const auto& tx : resp.txn) tx_requested_size += tx->ComputeTotalSize();
         LogDebug(BCLog::CMPCTBLOCK, "%s sent us a GETBLOCKTXN for block %s, sending a BLOCKTXN with %u txns. (%u bytes)", pfrom.LogPeer(), block.GetHash().ToString(), resp.txn.size(), tx_requested_size);
+        if (util::log::ShouldTraceLog(BCLog::CMPCTBLOCK)) {
+            for(const auto& txn : resp.txn) {
+                LogDebug(BCLog::CMPCTBLOCK, "    - txid: %s", txn->GetHash().ToString());
```

> The code has contradictory logging levels:
> 
> ```c++
>   if (ShouldTraceLog(...)) {
>       LogDebug(...);
>   }
> ```
> 
> Suggestion: 
> ```diff
> diff --git a/src/net_processing.cpp b/src/net_processing.cpp
> index 1512a10c58..0117616314 100644
> --- a/src/net_processing.cpp
> +++ b/src/net_processing.cpp
> @@ -2850,7 +2850,7 @@ void PeerManagerImpl::SendBlockTransactions(CNode& pfrom, Peer& peer, const CBlo
>          LogDebug(BCLog::CMPCTBLOCK, "%s sent us a GETBLOCKTXN for block %s, sending a BLOCKTXN with %u txns. (%u bytes)", pfrom.LogPeer(), block.GetHash().ToString(), resp.txn.size(), tx_requested_size);
>          if (util::log::ShouldTraceLog(BCLog::CMPCTBLOCK)) {
>              for(const auto& txn : resp.txn) {
> -                LogDebug(BCLog::CMPCTBLOCK, "    - txid: %s", txn->GetHash().ToString());
> +                LogTrace(BCLog::CMPCTBLOCK, "    - txid: %s", txn->GetHash().ToString());
>              }
>          }
>      }
> ```

### `@0xB10C` on `src/net_processing.cpp:2853` (2026-08-21T10:29:01Z)

```diff
@@ -2848,6 +2848,11 @@ void PeerManagerImpl::SendBlockTransactions(CNode& pfrom, Peer& peer, const CBlo
         uint32_t tx_requested_size{0};
         for (const auto& tx : resp.txn) tx_requested_size += tx->ComputeTotalSize();
         LogDebug(BCLog::CMPCTBLOCK, "%s sent us a GETBLOCKTXN for block %s, sending a BLOCKTXN with %u txns. (%u bytes)", pfrom.LogPeer(), block.GetHash().ToString(), resp.txn.size(), tx_requested_size);
+        if (util::log::ShouldTraceLog(BCLog::CMPCTBLOCK)) {
+            for(const auto& txn : resp.txn) {
+                LogDebug(BCLog::CMPCTBLOCK, "    - txid: %s", txn->GetHash().ToString());
```

> Good catch @w0xlt. In addition to that, I fear the current log will be hard to analyze automatically or even grep for. It might make sense to include slightly more information than `- txid: 4a5e1e4baab89f3a32518a88c31bc87f618f76673e2cc77ab2127b7afdeda33b` in the line, similar to the reconstruction logging you changed above. How about:
> 
> "Sending {txid} to {peer} in BLOCKTXN"?

### `@0xB10C` on `src/net_processing.cpp:2853` (2026-08-21T10:30:43Z)

```diff
@@ -2848,6 +2848,11 @@ void PeerManagerImpl::SendBlockTransactions(CNode& pfrom, Peer& peer, const CBlo
         uint32_t tx_requested_size{0};
         for (const auto& tx : resp.txn) tx_requested_size += tx->ComputeTotalSize();
         LogDebug(BCLog::CMPCTBLOCK, "%s sent us a GETBLOCKTXN for block %s, sending a BLOCKTXN with %u txns. (%u bytes)", pfrom.LogPeer(), block.GetHash().ToString(), resp.txn.size(), tx_requested_size);
+        if (util::log::ShouldTraceLog(BCLog::CMPCTBLOCK)) {
+            for(const auto& txn : resp.txn) {
+                LogDebug(BCLog::CMPCTBLOCK, "    - txid: %s", txn->GetHash().ToString());
```

> Alternatively, does it make sense to put all txids, maybe comma separated, into a single line?

### `@0xB10C` on `src/blockencodings.h:143` (2026-08-21T11:01:03Z)

```diff
+
     size_t prefilled_count = 0, mempool_count = 0, extra_count = 0;
+    size_t prefilled_size = 0, mempool_size = 0, extra_size = 0;
+
+    // Either it was already present in our mempool...
+    size_t redundant_prefilled_mp_count = 0, redundant_prefilled_mp_size = 0;
+    // or maybe it was present in our extrapool...
+    size_t redundant_prefilled_ep_count = 0, redundant_prefilled_ep_size = 0;
```

> nit: tiny preference for `redundant_prefilled_mempool_count` instead of `redundant_prefilled_mp_count` (and similar) here for readability. Not sure if saving the 5 characters is worth it.

### `@andrewtoth` on `src/blockencodings.cpp:182` (2026-08-23T18:49:07Z)

```diff
+        Assume(txn_available.size() == tx_source.size());
+        for (size_t i = 0; i < txn_available.size(); i++) {
+            switch (tx_source[i]) {
+                case TxSource::MEMPOOL:
+                    mempool_count++;
+                    break;
+                case TxSource::EXTRA:
+                    extra_count++;
```

> I'm not sure I agree with the approach of 78715aab9475b25bb10c82d2e8c1c827560b76ed. Incrementing the counts inline is very cheap. I can't see it be worth the code complexity to move these out. The next commit where the size of transactions are computed only for debug logging would make sense to do.

### `@andrewtoth` on `src/blockencodings.cpp:153` (2026-08-23T18:50:28Z)

```diff
@@ -149,8 +150,7 @@ ReadStatus PartiallyDownloadedBlock::InitData(const CBlockHeaderAndShortTxIDs& c
             if (tx_source[idit->second] == TxSource::NONE) {
                 txn_available[idit->second] = extra_txn[i].second;
                 tx_source[idit->second] = TxSource::EXTRA;
-                mempool_count++;
-                extra_count++;
+                available_count++;
```

> nit: prefer prefixing `++` and `--`.

### `@andrewtoth` on `src/blockencodings.h:140` (2026-08-23T18:53:23Z)

```diff
@@ -133,7 +133,16 @@ class CBlockHeaderAndShortTxIDs {
 class PartiallyDownloadedBlock {
 protected:
     std::vector<CTransactionRef> txn_available;
+
     size_t prefilled_count = 0, mempool_count = 0, extra_count = 0;
+    size_t prefilled_size = 0, mempool_size = 0, extra_size = 0;
```

> We should have a comment here that these will only be set if debug logging is enabled.

### `@andrewtoth` on `src/blockencodings.cpp:73` (2026-08-23T19:59:09Z)

```diff
@@ -69,6 +70,22 @@ ReadStatus PartiallyDownloadedBlock::InitData(const CBlockHeaderAndShortTxIDs& c
     header = cmpctblock.header;
     txn_available.resize(cmpctblock.BlockTxCount());
 
+    std::vector<Wtxid> extra_wtxids{};
```

> I'm not sure this is the right data structure here. I think we can do this more cleanly with a `std::map<Wtxid, size_t>` and populate it below in the
> `for (size_t i = 0; i < cmpctblock.prefilledtxn.size(); i++) {` loop. Instead of calling `pool->exists` for each prefill (which takes the pool lock each time), we can take call `GetIter` after we take the pool lock later. This lets us avoid sorting the vector as well.
> 
> <details><summary>A quick example of how it could look</summary>
> 
> ```diff
> diff --git a/src/blockencodings.cpp b/src/blockencodings.cpp
> index e2522f8781..7765353da1 100644
> --- a/src/blockencodings.cpp
> +++ b/src/blockencodings.cpp
> @@ -16,6 +16,7 @@
>  #include <util/log.h>
>  #include <validation.h>
>  
> +#include <map>
>  #include <unordered_map>
>  
>  CBlockHeaderAndShortTxIDs::CBlockHeaderAndShortTxIDs(const CBlock& block, uint64_t nonce)
> @@ -70,21 +71,9 @@ ReadStatus PartiallyDownloadedBlock::InitData(const CBlockHeaderAndShortTxIDs& c
>      header = cmpctblock.header;
>      txn_available.resize(cmpctblock.BlockTxCount());
>  
> -    std::vector<Wtxid> extra_wtxids{};
> -
> -    bool debug_log = util::log::ShouldDebugLog(BCLog::CMPCTBLOCK);
> -
> -    if (debug_log) {
> -        prefilled_count = cmpctblock.prefilledtxn.size();
> -
> -        // A sorted vec of extra_txn's for cheaply checking if prefills
> -        // were redundant with the extrapool.
> -        for (const auto& [id, tx] : extra_txn) {
> -            extra_wtxids.push_back(id);
> -        }
> -        std::sort(extra_wtxids.begin(), extra_wtxids.end());
> -    }
> -
> +    const bool debug_log{util::log::ShouldDebugLog(BCLog::CMPCTBLOCK)};
> +    // Prefills not already in the mempool, used to check extra-pool redundancy.
> +    std::map<Wtxid, size_t> leftover_prefills;
>  
>      int32_t lastprefilledindex = -1;
>      for (size_t i = 0; i < cmpctblock.prefilledtxn.size(); i++) {
> @@ -102,20 +91,14 @@ ReadStatus PartiallyDownloadedBlock::InitData(const CBlockHeaderAndShortTxIDs& c
>          }
>  
>          if (debug_log) {
> -            size_t tx_size = cmpctblock.prefilledtxn[i].tx->ComputeTotalSize();
> +            const CTransactionRef& tx{cmpctblock.prefilledtxn[i].tx};
> +            const size_t tx_size{tx->ComputeTotalSize()};
>              prefilled_size += tx_size;
> -
> -            auto tx_wtxid =  cmpctblock.prefilledtxn[i].tx->GetWitnessHash();
> -            if (pool->exists(tx_wtxid)) {
> -                redundant_prefilled_mp_count++;
> -                redundant_prefilled_mp_size += tx_size;
> -            } else if (std::binary_search(extra_wtxids.begin(), extra_wtxids.end(), tx_wtxid)) {
> -                redundant_prefilled_ep_count++;
> -                redundant_prefilled_ep_size += tx_size;
> -            }
> +            leftover_prefills.emplace(tx->GetWitnessHash(), tx_size);
>          }
>          txn_available[lastprefilledindex] = cmpctblock.prefilledtxn[i].tx;
>      }
> +    if (debug_log) prefilled_count = cmpctblock.prefilledtxn.size();
>  
>      // Calculate map of txids -> positions and check mempool to see what we have (or don't)
>      // Because well-formed cmpctblock messages will have a (relatively) uniform distribution
> @@ -148,6 +131,17 @@ ReadStatus PartiallyDownloadedBlock::InitData(const CBlockHeaderAndShortTxIDs& c
>      size_t available_count = 0;
>      {
>      LOCK(pool->cs);
> +    if (debug_log) {
> +        for (auto it{leftover_prefills.begin()}; it != leftover_prefills.end();) {
> +            if (pool->GetIter(it->first)) {
> +                ++redundant_prefilled_mp_count;
> +                redundant_prefilled_mp_size += it->second;
> +                it = leftover_prefills.erase(it);
> +            } else {
> +                ++it;
> +            }
> +        }
> +    }
>      for (const auto& [wtxid, txit] : pool->txns_randomized) {
>          uint64_t shortid = cmpctblock.GetShortID(wtxid);
>          std::unordered_map<uint64_t, uint16_t>::iterator idit = shorttxids.find(shortid);
> @@ -201,7 +195,16 @@ ReadStatus PartiallyDownloadedBlock::InitData(const CBlockHeaderAndShortTxIDs& c
>              break;
>      }
>  
> -    if (util::log::ShouldDebugLog(BCLog::CMPCTBLOCK)) {
> +    if (debug_log) {
> +        for (const auto& [id, tx] : extra_txn) {
> +            if (!tx) continue;
> +            const auto it{leftover_prefills.find(id)};
> +            if (it == leftover_prefills.end()) continue;
> +            ++redundant_prefilled_ep_count;
> +            redundant_prefilled_ep_size += it->second;
> +            leftover_prefills.erase(it);
> +        }
> +
>          Assume(txn_available.size() == tx_source.size());
>          for (size_t i = 0; i < txn_available.size(); i++) {
>              switch (tx_source[i]) {
> ```
> 
> </details>

### `@davidgumberg` on `src/blockencodings.cpp:164` (2026-08-25T17:26:52Z)

```diff
@@ -161,15 +160,14 @@ ReadStatus PartiallyDownloadedBlock::InitData(const CBlockHeaderAndShortTxIDs& c
                 if (txn_available[idit->second] &&
                         txn_available[idit->second]->GetWitnessHash() != extra_txn[i].second->GetWitnessHash()) {
                     txn_available[idit->second].reset();
-                    mempool_count--;
```

> marking as resolvesed since #35727 was merged and I've updated this PR based on that.

### `@davidgumberg` on `src/blockencodings.cpp:182` (2026-08-25T22:42:00Z)

```diff
+        Assume(txn_available.size() == tx_source.size());
+        for (size_t i = 0; i < txn_available.size(); i++) {
+            switch (tx_source[i]) {
+                case TxSource::MEMPOOL:
+                    mempool_count++;
+                    break;
+                case TxSource::EXTRA:
+                    extra_count++;
```

> I moved the count inc/dec out because I thought it made the code easier to read, not for performance.
> 
> The problem is tracking the states, e.g. when decrementing because of a collision, we will have to check whether the tx_source is mempool or extra. it is definitely possible to do it inline, but IMO it's logic that is unrelated to compactblock reconstruction right in the middle of critical and subtle code, it's nice to scope all the logging code, and even though it's ~7 lines longer as-is, I think it makes it easier to read the function.
> 
> I could shorten the current thing to something like
> 
> ```cpp
> if (util::log::ShouldDebugLog(BCLog::CMPCTBLOCK)) {
>     for (size_t i = 0; i < txn_available.size(); i++) {
>         if (tx_source[i] == TxSource::MEMPOOL) ++mempool_count;
>         else if (tx_source[i] == TxSource::EXTRA) ++extra_count;
>     }
> }
> ```
> 
> but I think it is clearer as a switch.

### `@davidgumberg` on `src/blockencodings.h:140` (2026-08-28T00:52:52Z)

```diff
@@ -133,7 +133,16 @@ class CBlockHeaderAndShortTxIDs {
 class PartiallyDownloadedBlock {
 protected:
     std::vector<CTransactionRef> txn_available;
+
     size_t prefilled_count = 0, mempool_count = 0, extra_count = 0;
+    size_t prefilled_size = 0, mempool_size = 0, extra_size = 0;
```

> Thanks, fixed.

### `@davidgumberg` on `src/blockencodings.cpp:153` (2026-08-28T00:53:07Z)

```diff
@@ -149,8 +150,7 @@ ReadStatus PartiallyDownloadedBlock::InitData(const CBlockHeaderAndShortTxIDs& c
             if (tx_source[idit->second] == TxSource::NONE) {
                 txn_available[idit->second] = extra_txn[i].second;
                 tx_source[idit->second] = TxSource::EXTRA;
-                mempool_count++;
-                extra_count++;
+                available_count++;
```

> Thanks, fixed

### `@davidgumberg` on `src/blockencodings.h:143` (2026-08-28T00:53:13Z)

```diff
+
     size_t prefilled_count = 0, mempool_count = 0, extra_count = 0;
+    size_t prefilled_size = 0, mempool_size = 0, extra_size = 0;
+
+    // Either it was already present in our mempool...
+    size_t redundant_prefilled_mp_count = 0, redundant_prefilled_mp_size = 0;
+    // or maybe it was present in our extrapool...
+    size_t redundant_prefilled_ep_count = 0, redundant_prefilled_ep_size = 0;
```

> Thanks, fixed

### `@davidgumberg` on `src/net_processing.cpp:2853` (2026-08-28T00:53:26Z)

```diff
@@ -2848,6 +2848,11 @@ void PeerManagerImpl::SendBlockTransactions(CNode& pfrom, Peer& peer, const CBlo
         uint32_t tx_requested_size{0};
         for (const auto& tx : resp.txn) tx_requested_size += tx->ComputeTotalSize();
         LogDebug(BCLog::CMPCTBLOCK, "%s sent us a GETBLOCKTXN for block %s, sending a BLOCKTXN with %u txns. (%u bytes)", pfrom.LogPeer(), block.GetHash().ToString(), resp.txn.size(), tx_requested_size);
+        if (util::log::ShouldTraceLog(BCLog::CMPCTBLOCK)) {
+            for(const auto& txn : resp.txn) {
+                LogDebug(BCLog::CMPCTBLOCK, "    - txid: %s", txn->GetHash().ToString());
```

> Thanks, I've made it one log line instead.

### `@andrewtoth` on `src/blockencodings.cpp:73` (2026-09-11T18:16:22Z)

```diff
@@ -69,6 +70,22 @@ ReadStatus PartiallyDownloadedBlock::InitData(const CBlockHeaderAndShortTxIDs& c
     header = cmpctblock.header;
     txn_available.resize(cmpctblock.BlockTxCount());
 
+    std::vector<Wtxid> extra_wtxids{};
```

> Hey @davidgumberg just wondering if you had any thoughts on this suggestion?
> The main thing is that we're taking the lock inside each loop via `pool->exists` with the current approach.

### `@davidgumberg` on `src/blockencodings.cpp:73` (2026-09-16T19:33:13Z)

```diff
@@ -69,6 +70,22 @@ ReadStatus PartiallyDownloadedBlock::InitData(const CBlockHeaderAndShortTxIDs& c
     header = cmpctblock.header;
     txn_available.resize(cmpctblock.BlockTxCount());
 
+    std::vector<Wtxid> extra_wtxids{};
```

> Sorry, I did not mean to leave this unaddressed, I just have to think about how to integrate this with the other PR and haven't had a chance yet, will update soon.

### `@0xB10C` on `src/blockencodings.cpp:287` (2026-09-16T20:04:16Z)

```diff
+            prefilled_count, prefilled_size,
+            mempool_count, mempool_size,
+            extra_count, extra_size,
+            vtx_missing.size(), tx_missing_size);
+        LogDebug(BCLog::CMPCTBLOCK,
+            "%u txn (%u bytes) of the prefill were redundant, "
+            "%u txn (%u bytes) were present in the mempool, "
+            "%u txn (%u bytes) were present in the extrapool. ",
```

> ```suggestion
>             "%u txn (%u bytes) were present in the extrapool.",
> ```

### `@0xB10C` on `src/blockencodings.cpp:287` (2026-09-16T20:04:40Z)

```diff
+            prefilled_count, prefilled_size,
+            mempool_count, mempool_size,
+            extra_count, extra_size,
+            vtx_missing.size(), tx_missing_size);
+        LogDebug(BCLog::CMPCTBLOCK,
+            "%u txn (%u bytes) of the prefill were redundant, "
+            "%u txn (%u bytes) were present in the mempool, "
+            "%u txn (%u bytes) were present in the extrapool. ",
```

> Would be good to have a block hash here too

### `@0xB10C` on `src/blockencodings.cpp:204` (2026-09-16T20:07:38Z)

```diff
         // the performance win of an early exit here is too good to pass up and worth
         // the extra risk.
-        if (mempool_count == shorttxids.size())
+        if (available_count == shorttxids.size())
             break;
     }
 
+    if (util::log::ShouldDebugLog(BCLog::CMPCTBLOCK)) {
```

> You can probably reuse `debug_log`
> 
> ```suggestion
>     if (debug_log) {
> ```

### `@0xB10C` on `src/blockencodings.cpp:75` (2026-09-16T20:17:51Z)

```diff
@@ -69,6 +70,22 @@ ReadStatus PartiallyDownloadedBlock::InitData(const CBlockHeaderAndShortTxIDs& c
     header = cmpctblock.header;
     txn_available.resize(cmpctblock.BlockTxCount());
 
+    std::vector<Wtxid> extra_wtxids{};
+
+    bool debug_log = util::log::ShouldDebugLog(BCLog::CMPCTBLOCK);
```

> nit
> ```suggestion
>     const bool debug_log{util::log::ShouldDebugLog(BCLog::CMPCTBLOCK)};
> ```

### `@0xB10C` on `src/net_processing.cpp:2864` (2026-09-16T20:22:11Z)

```diff
+            bool first = true;
+            for(const auto& txn : resp.txn) {
+                if (!first) {
+                    missing_txids += ", ";
+                }
+                missing_txids += txn->GetHash().ToString();
+                first = false;
+            }
```

> nit: An LLM told me about this, which might be a tiny bit slower than your manual pre-reserve string construction, but might be a bit cleaner. Needs `#include <util/string.h>.`
> 
> ```suggestion
> const std::string missing_txids{util::Join(resp.txn, ", ", [](const auto& tx) { return tx->GetHash().ToString(); })};
> ```

### `@0xB10C` on `src/blockencodings.cpp:295` (2026-09-16T20:28:08Z)

```diff
+            redundant_prefilled_mempool_size + redundant_prefilled_extrapool_size,
+            redundant_prefilled_mempool_count, redundant_prefilled_mempool_size,
+            redundant_prefilled_extrapool_count, redundant_prefilled_extrapool_size);
+
+        if (util::log::ShouldTraceLog(BCLog::CMPCTBLOCK)) {
             for (const auto& tx : vtx_missing) {
-                LogDebug(BCLog::CMPCTBLOCK, "Reconstructed block %s required tx %s\n", hash.ToString(), tx->GetHash().ToString());
+                LogTrace(BCLog::CMPCTBLOCK, "Reconstructed block %s required tx %s\n", hash.ToString(), tx->GetHash().ToString());
```

> might make sense to change this into one long line too?

### `@0xB10C` on `src/net_processing.cpp:2863` (2026-09-16T20:48:57Z)

```diff
+                if (!first) {
+                    missing_txids += ", ";
+                }
+                missing_txids += txn->GetHash().ToString();
+                first = false;
+            }
+
+            LogTrace(BCLog::CMPCTBLOCK, "%s sent a GETBLOCKTXN for block %s requesting the following transactions: %s", pfrom.LogPeer(), block.GetHash().ToString(), missing_txids);
```

> For anyone wondering: The length of the log message is capped by the bounds of the number of transactions in the block. While GETBLOCKTXN allows up to potentially 65k indexes, we don't log (as we call `Misbehaving()` and `return`) if a peer requests out-of-bounds indexes.

### `@davidgumberg` on `src/blockencodings.cpp:73` (2026-10-09T04:17:25Z)

```diff
@@ -69,6 +70,22 @@ ReadStatus PartiallyDownloadedBlock::InitData(const CBlockHeaderAndShortTxIDs& c
     header = cmpctblock.header;
     txn_available.resize(cmpctblock.BlockTxCount());
 
+    std::vector<Wtxid> extra_wtxids{};
```

> OK,  thanks for patience here, this is much better and I've taken it, it will cause a little bit more churn in the next PR but both are improved by this IMO and I'd rather not have bad code merged "temporarily" because it will make a future PR that may or may not happen cleaner. I'll mark this as resolved and we can continue discussion on the current diff if needed, it might still need improving.

### `@davidgumberg` on `src/blockencodings.cpp:287` (2026-10-09T04:17:29Z)

```diff
+            prefilled_count, prefilled_size,
+            mempool_count, mempool_size,
+            extra_count, extra_size,
+            vtx_missing.size(), tx_missing_size);
+        LogDebug(BCLog::CMPCTBLOCK,
+            "%u txn (%u bytes) of the prefill were redundant, "
+            "%u txn (%u bytes) were present in the mempool, "
+            "%u txn (%u bytes) were present in the extrapool. ",
```

> Oops, copy paste mistake, thanks for catching, fixed.

### `@davidgumberg` on `src/blockencodings.cpp:287` (2026-10-09T04:17:34Z)

```diff
+            prefilled_count, prefilled_size,
+            mempool_count, mempool_size,
+            extra_count, extra_size,
+            vtx_missing.size(), tx_missing_size);
+        LogDebug(BCLog::CMPCTBLOCK,
+            "%u txn (%u bytes) of the prefill were redundant, "
+            "%u txn (%u bytes) were present in the mempool, "
+            "%u txn (%u bytes) were present in the extrapool. ",
```

> Good catch, I have had to write debug.log parsing state trackers before because of log message like this, maybe I was subconsciously making it so that others would feel my pain.

### `@davidgumberg` on `src/blockencodings.cpp:204` (2026-10-09T04:17:38Z)

```diff
         // the performance win of an early exit here is too good to pass up and worth
         // the extra risk.
-        if (mempool_count == shorttxids.size())
+        if (available_count == shorttxids.size())
             break;
     }
 
+    if (util::log::ShouldDebugLog(BCLog::CMPCTBLOCK)) {
```

> Taken, thank you.

### `@davidgumberg` on `src/blockencodings.cpp:75` (2026-10-09T04:17:42Z)

```diff
@@ -69,6 +70,22 @@ ReadStatus PartiallyDownloadedBlock::InitData(const CBlockHeaderAndShortTxIDs& c
     header = cmpctblock.header;
     txn_available.resize(cmpctblock.BlockTxCount());
 
+    std::vector<Wtxid> extra_wtxids{};
+
+    bool debug_log = util::log::ShouldDebugLog(BCLog::CMPCTBLOCK);
```

> Much better, thank you.

### `@davidgumberg` on `src/net_processing.cpp:2864` (2026-10-09T04:17:46Z)

```diff
+            bool first = true;
+            for(const auto& txn : resp.txn) {
+                if (!first) {
+                    missing_txids += ", ";
+                }
+                missing_txids += txn->GetHash().ToString();
+                first = false;
+            }
```

> That's awesome, thank you.

### `@davidgumberg` on `src/blockencodings.cpp:295` (2026-10-09T04:17:54Z)

```diff
+            redundant_prefilled_mempool_size + redundant_prefilled_extrapool_size,
+            redundant_prefilled_mempool_count, redundant_prefilled_mempool_size,
+            redundant_prefilled_extrapool_count, redundant_prefilled_extrapool_size);
+
+        if (util::log::ShouldTraceLog(BCLog::CMPCTBLOCK)) {
             for (const auto& tx : vtx_missing) {
-                LogDebug(BCLog::CMPCTBLOCK, "Reconstructed block %s required tx %s\n", hash.ToString(), tx->GetHash().ToString());
+                LogTrace(BCLog::CMPCTBLOCK, "Reconstructed block %s required tx %s\n", hash.ToString(), tx->GetHash().ToString());
```

> Done, and used the same thing you suggested above.

### `@0xB10C` on `src/blockencodings.cpp:211` (2026-10-09T19:01:35Z)

```diff
         // the extra risk.
-        if (mempool_count == shorttxids.size())
+        if (available_count == shorttxids.size())
             break;
     }
 
+    if (util::log::ShouldDebugLog(BCLog::CMPCTBLOCK)) {
+        Assume(txn_available.size() == tx_source.size());
```

> I'm not sure if this `Assume` can ever be hit in fuzzing. My understanding is that we e.g. don't run fuzzing with logging enabled. (however, I happen to run binaries that will Assert on Assumes on peer-observer).

### `@andrewtoth` on `src/blockencodings.cpp:276` (2026-10-10T10:37:12Z)

```diff
@@ -221,12 +221,11 @@ ReadStatus PartiallyDownloadedBlock::FillBlock(CBlock& block, const std::vector<
     if (util::log::ShouldDebugLog(BCLog::CMPCTBLOCK)) {
```

> typo in first commit description:
> 
> > so log all txid's and *make* this a
> trace-level log message.

### `@andrewtoth` on `src/blockencodings.h:137` (2026-10-10T11:07:38Z)

```diff
@@ -133,7 +133,18 @@ class CBlockHeaderAndShortTxIDs {
 class PartiallyDownloadedBlock {
 protected:
     std::vector<CTransactionRef> txn_available;
+
+    // All of these count and size values are only set if logging is enabled.
```

> nit: we could specify that "cmpctblock logging is enabled".

### `@andrewtoth` on `src/blockencodings.h:142` (2026-10-10T11:07:58Z)

```diff
     std::vector<CTransactionRef> txn_available;
+
+    // All of these count and size values are only set if logging is enabled.
+    // If you want to use them for something else, change that.
     size_t prefilled_count = 0, mempool_count = 0, extra_count = 0;
+    size_t prefilled_size = 0, mempool_size = 0, extra_size = 0;
+
+    // For tracking redundant prefills, only set if logging is enabled.
```

> nit: same here, "cmpctblock logging is enabled".

### `@andrewtoth` on `src/blockencodings.cpp:203` (2026-10-10T11:09:47Z)

```diff
             break;
     }
 
-    if (util::log::ShouldDebugLog(BCLog::CMPCTBLOCK)) {
+
+    if (debug_log) {
+        for (const auto& [id, tx] : extra_txn) {
+            if (!tx) continue;
```

> A future refactor could change the type of `extra_txn` from
> `const std::vector<std::pair<Wtxid, CTransactionRef>>& extra_txn`
> to
> `const std::vector<std::pair<Wtxid, util::NotNull<CTransactionRef>>>& extra_txn`
> 
> and then this line would not be necessary.

### `@davidgumberg` on `src/blockencodings.cpp:203` (2026-10-14T02:16:14Z)

```diff
             break;
     }
 
-    if (util::log::ShouldDebugLog(BCLog::CMPCTBLOCK)) {
+
+    if (debug_log) {
+        for (const auto& [id, tx] : extra_txn) {
+            if (!tx) continue;
```

> Good idea, I'll leave this for later.

### `@davidgumberg` on `src/blockencodings.h:142` (2026-10-14T02:22:15Z)

```diff
     std::vector<CTransactionRef> txn_available;
+
+    // All of these count and size values are only set if logging is enabled.
+    // If you want to use them for something else, change that.
     size_t prefilled_count = 0, mempool_count = 0, extra_count = 0;
+    size_t prefilled_size = 0, mempool_size = 0, extra_size = 0;
+
+    // For tracking redundant prefills, only set if logging is enabled.
```

> Thanks, done.

### `@davidgumberg` on `src/blockencodings.h:137` (2026-10-14T02:22:24Z)

```diff
@@ -133,7 +133,18 @@ class CBlockHeaderAndShortTxIDs {
 class PartiallyDownloadedBlock {
 protected:
     std::vector<CTransactionRef> txn_available;
+
+    // All of these count and size values are only set if logging is enabled.
```

> Thanks, I've updated the comment to be clearer and more specific.

### `@davidgumberg` on `src/blockencodings.cpp:276` (2026-10-14T02:22:32Z)

```diff
@@ -221,12 +221,11 @@ ReadStatus PartiallyDownloadedBlock::FillBlock(CBlock& block, const std::vector<
     if (util::log::ShouldDebugLog(BCLog::CMPCTBLOCK)) {
```

> Thanks, fixed.

### `@0xB10C` on `src/blockencodings.h:142` (2026-10-14T07:38:18Z)

```diff
     std::vector<CTransactionRef> txn_available;
+
+    // These count and size values should ONLY be used for logging output, they
+    // are NOT correctly set if compact block logging is off.
     size_t prefilled_count = 0, mempool_count = 0, extra_count = 0;
+    size_t prefilled_size = 0, mempool_size = 0, extra_size = 0;
+
+    // For tracking redundant prefills, DO NOT use for anything other than than
```

> if you retouch
> 
> ```suggestion
>     // For tracking redundant prefills, DO NOT use for anything other than
> ```

### `@davidgumberg` on `src/blockencodings.h:142` (2026-10-14T08:11:58Z)

```diff
     std::vector<CTransactionRef> txn_available;
+
+    // These count and size values should ONLY be used for logging output, they
+    // are NOT correctly set if compact block logging is off.
     size_t prefilled_count = 0, mempool_count = 0, extra_count = 0;
+    size_t prefilled_size = 0, mempool_size = 0, extra_size = 0;
+
+    // For tracking redundant prefills, DO NOT use for anything other than than
```

> Ah, thanks I fixed since I could not live with this.

### `@optout21` on `src/blockencodings.cpp:134` (2026-10-15T06:23:39Z)

```diff
+                ++available_count;
             } else if (tx_source[idit->second] != TxSource::COLLIDED) {
                 // If we find two mempool txn that match the short id, just request it.
                 // This should be rare enough that the extra bandwidth doesn't matter,
                 // but eating a round-trip due to FillBlock failure would be annoying
                 txn_available[idit->second].reset();
-                mempool_count--;
+                --available_count;
```

> Concern checked: `available_count` underflowing. Due the logic that's not possible, because every decrement must be preceeded by an increment. (Even if overflow happened, that wouldn't be a critical issue.)

### `@optout21` on `src/blockencodings.h:140` (2026-10-15T07:46:06Z)

```diff
 class PartiallyDownloadedBlock {
 protected:
     std::vector<CTransactionRef> txn_available;
+
+    // These count and size values should ONLY be used for logging output, they
+    // are NOT correctly set if compact block logging is off.
     size_t prefilled_count = 0, mempool_count = 0, extra_count = 0;
+    size_t prefilled_size = 0, mempool_size = 0, extra_size = 0;
```

> > [4f5ce81](https://github.com/bitcoin/bitcoin/pull/35724/changes/4f5ce816db1055b8d885113397c7215dc7af3c83) _cmpctblock: log: Print sizes of all tx types and prefill redundancies_:
> 
> Nit (for the future):  The variable names could be prefixed by `log_`, to hint that they are used for logging (slightly stronger hint than the comments).

### `@optout21` on `src/blockencodings.h:140` (2026-10-15T07:47:29Z)

```diff
 class PartiallyDownloadedBlock {
 protected:
     std::vector<CTransactionRef> txn_available;
+
+    // These count and size values should ONLY be used for logging output, they
+    // are NOT correctly set if compact block logging is off.
     size_t prefilled_count = 0, mempool_count = 0, extra_count = 0;
+    size_t prefilled_size = 0, mempool_size = 0, extra_size = 0;
```

> > [4f5ce81](https://github.com/bitcoin/bitcoin/pull/35724/changes/4f5ce816db1055b8d885113397c7215dc7af3c83) _cmpctblock: log: Print sizes of all tx types and prefill redundancies_:
> 
> Nit (for the future):  Since there are a number of count&size pairs here, maybe a minimal count+size struct would make sense.

### `@optout21` on `src/blockencodings.cpp:228` (2026-10-15T08:07:01Z)

```diff
         LogDebug(BCLog::CMPCTBLOCK, "Successfully reconstructed block %s with %u txn prefilled, %u txn from mempool (incl at least %u from extra pool) and %u txn (%u bytes) requested\n", hash.ToString(), prefilled_count, mempool_count, extra_count, vtx_missing.size(), tx_missing_size);
-        if (vtx_missing.size() < 5) {
-            for (const auto& tx : vtx_missing) {
-                LogDebug(BCLog::CMPCTBLOCK, "Reconstructed block %s required tx %s\n", hash.ToString(), tx->GetHash().ToString());
-            }
+        if (util::log::ShouldTraceLog(BCLog::CMPCTBLOCK)) {
+            const std::string missing_txids{util::Join(vtx_missing, ", ", [](const auto& tx) { return tx->GetHash().ToString(); })};
+            LogTrace(BCLog::CMPCTBLOCK, "Reconstructed block %s required requesting the following transactions: %s\n", hash.ToString(), missing_txids);
```

> > [a6cc3f3](https://github.com/bitcoin/bitcoin/pull/35724/changes/a6cc3f30ef48e36e8262387a24af5f8dbb27289c) _cmpctblock: log: debuglevel=trace print TXID's of all missing tx'es._:
> 
> Nit: The trailing `"\n"` is recommended to be omitted from log messages (also not consistent with the other changed log lines).

### `@optout21` on `src/net_processing.cpp:2863` (2026-10-15T08:15:39Z)

```diff
+                if (!first) {
+                    missing_txids += ", ";
+                }
+                missing_txids += txn->GetHash().ToString();
+                first = false;
+            }
+
+            LogTrace(BCLog::CMPCTBLOCK, "%s sent a GETBLOCKTXN for block %s requesting the following transactions: %s", pfrom.LogPeer(), block.GetHash().ToString(), missing_txids);
```

> Good point. As there is a hard cap on the max number, the long log line is acceptable, though the worse-case memory usage of few MB's is not that nice. Breaking the line after every 100 IDs or so would be more robust though.

### `@davidgumberg` on `src/blockencodings.h:140` (2026-10-16T00:54:59Z)

```diff
 class PartiallyDownloadedBlock {
 protected:
     std::vector<CTransactionRef> txn_available;
+
+    // These count and size values should ONLY be used for logging output, they
+    // are NOT correctly set if compact block logging is off.
     size_t prefilled_count = 0, mempool_count = 0, extra_count = 0;
+    size_t prefilled_size = 0, mempool_size = 0, extra_size = 0;
```

> Yeah, enforcing this with a comment is bad, variable name is a little bit better, ideally there would be a programmatic way to stop others from using, but I couldn't think of one.

### `@davidgumberg` on `src/blockencodings.cpp:228` (2026-10-16T00:55:42Z)

```diff
         LogDebug(BCLog::CMPCTBLOCK, "Successfully reconstructed block %s with %u txn prefilled, %u txn from mempool (incl at least %u from extra pool) and %u txn (%u bytes) requested\n", hash.ToString(), prefilled_count, mempool_count, extra_count, vtx_missing.size(), tx_missing_size);
-        if (vtx_missing.size() < 5) {
-            for (const auto& tx : vtx_missing) {
-                LogDebug(BCLog::CMPCTBLOCK, "Reconstructed block %s required tx %s\n", hash.ToString(), tx->GetHash().ToString());
-            }
+        if (util::log::ShouldTraceLog(BCLog::CMPCTBLOCK)) {
+            const std::string missing_txids{util::Join(vtx_missing, ", ", [](const auto& tx) { return tx->GetHash().ToString(); })};
+            LogTrace(BCLog::CMPCTBLOCK, "Reconstructed block %s required requesting the following transactions: %s\n", hash.ToString(), missing_txids);
```

> Thanks, if not blocking I'll fix this in the next prefill-related PR.

## 4. General Discussion & Maintainer Feedback Thread

### `@davidgumberg` (2026-08-04T22:45:30Z)

Reworked after https://github.com/bitcoin/bitcoin/pull/35727 merged, this is ready for review.

---

### `@0xB10C` (2026-09-16T19:21:30Z)

Doing another review pass over the code and also running it on signet a bit. Saw this log, which looks good to me:

```
2026-09-16T19:19:28Z [net_processing.cpp:3805] [LogBlockHeader] [all:info] Saw new cmpctblock header hash=00000004be9bbefe39e42fc65a1565e99475c63d867e22e3aee63eb22bed8df7 height=322378 peer=8
2026-09-16T19:19:28Z [blockencodings.cpp:62] [InitData] [cmpctblock:debug] Initializing PartiallyDownloadedBlock for block 00000004be9bbefe39e42fc65a1565e99475c63d867e22e3aee63eb22bed8df7 using a cmpctblock of 664 bytes
2026-09-16T19:19:28Z [blockencodings.cpp:224] [InitData] [cmpctblock:debug] Initialized PartiallyDownloadedBlock for block 00000004be9bbefe39e42fc65a1565e99475c63d867e22e3aee63eb22bed8df7 using a cmpctblock of 664 bytes
2026-09-16T19:19:28Z [blockencodings.cpp:283] [FillBlock] [cmpctblock:debug] Successfully reconstructed block 00000004be9bbefe39e42fc65a1565e99475c63d867e22e3aee63eb22bed8df7 with 1 txn prefilled (261 bytes), 49 txn from mempool (21059 bytes), 0 txn from extrapool (0 bytes), and 3 txn requested (1410 bytes)
2026-09-16T19:19:28Z [blockencodings.cpp:291] [FillBlock] [cmpctblock:debug] 0 txn (0 bytes) of the prefill were redundant, 0 txn (0 bytes) were present in the mempool, 0 txn (0 bytes) were present in the extrapool.
2026-09-16T19:19:28Z [blockencodings.cpp:295] [FillBlock] [cmpctblock:trace] Reconstructed block 00000004be9bbefe39e42fc65a1565e99475c63d867e22e3aee63eb22bed8df7 required tx d202319768acc745cf1a2a06c6dab5f5fa70600cb6d555e101ad64dc761e274d
2026-09-16T19:19:28Z [blockencodings.cpp:295] [FillBlock] [cmpctblock:trace] Reconstructed block 00000004be9bbefe39e42fc65a1565e99475c63d867e22e3aee63eb22bed8df7 required tx 34bbc02894b7241300ece014e6d49677f566e4677819a04c100ae1d40b00f6c9
2026-09-16T19:19:28Z [blockencodings.cpp:295] [FillBlock] [cmpctblock:trace] Reconstructed block 00000004be9bbefe39e42fc65a1565e99475c63d867e22e3aee63eb22bed8df7 required tx e698954bcdcce6a03d3488cd5fe05cdc64d07ff4a1f1e19f420e8526b817ac88
2026-09-16T19:19:28Z [validation.cpp:2899] [UpdateTipLog] [all:info] UpdateTip: new best=00000004be9bbefe39e42fc65a1565e99475c63d867e22e3aee63eb22bed8df7 height=322378 version=0x20000000 log2_work=44.068373 tx=32438805 date='2026-09-16T19:19:27Z' progress=1.000000 cache=2.4MiB(16384txo)
2026-09-16T19:19:28Z [net_processing.cpp:2850] [SendBlockTransactions] [cmpctblock:debug] peer=10 sent us a GETBLOCKTXN for block 00000004be9bbefe39e42fc65a1565e99475c63d867e22e3aee63eb22bed8df7, sending a BLOCKTXN with 6 txns. (3474 bytes)
2026-09-16T19:19:28Z [net_processing.cpp:2866] [SendBlockTransactions] [cmpctblock:trace] peer=10 sent a GETBLOCKTXN for block 00000004be9bbefe39e42fc65a1565e99475c63d867e22e3aee63eb22bed8df7 requesting the following transactions: d202319768acc745cf1a2a06c6dab5f5fa70600cb6d555e101ad64dc761e274d, 34bbc02894b7241300ece014e6d49677f566e4677819a04c100ae1d40b00f6c9, d92bcbbb339e00ed279bd979ff80ced3ecad8a657a10ef2c3f8a2d0173378328, 8799967e1d8a232a075c9aeea552d7863f2b0d140b8faa4ee86b52af956c127d, 7667d142261998629b2f9caede91332fcdfcb0d80695057644d1f10a2cb3081d, e698954bcdcce6a03d3488cd5fe05cdc64d07ff4a1f1e19f420e8526b817ac88
``` 

Before leaving an ACK, it would be good to have andrew's comment https://github.com/bitcoin/bitcoin/pull/35724#discussion_r3992152662 addressed/answered. 

<!--meta-tag:bot-skip-->

---

### `@davidgumberg` (2026-10-09T04:18:18Z)

Thanks for the patience here, I've pushed to address reviewer feedback.

---

### `@0xB10C` (2026-10-09T20:23:44Z)

Code review ACK 1a9b2865cae50112c9d77a9fcab6e9406b43d38b

This is how it looked for me on signet (without anyone prefilling yet):

```
2026-10-09T19:50:14Z Saw new header hash=00000012b47e316acca559923dc03bae44294a3fe0fa4bad09472bc3fecc2132 height=325670 peer=8
2026-10-09T19:50:14Z [cmpctblock] Initializing PartiallyDownloadedBlock for block 00000012b47e316acca559923dc03bae44294a3fe0fa4bad09472bc3fecc2132 using a cmpctblock of 4902 bytes
2026-10-09T19:50:14Z [cmpctblock] Initialized PartiallyDownloadedBlock for block 00000012b47e316acca559923dc03bae44294a3fe0fa4bad09472bc3fecc2132 using a cmpctblock of 4902 bytes
2026-10-09T19:50:15Z [cmpctblock] Successfully reconstructed block 00000012b47e316acca559923dc03bae44294a3fe0fa4bad09472bc3fecc2132 with 1 txn prefilled (261 bytes), 638 txn from mempool (719960 bytes), 0 txn from extrapool (0 bytes), and 120 txn requested (79721 bytes)
2026-10-09T19:50:15Z [cmpctblock] Block 00000012b47e316acca559923dc03bae44294a3fe0fa4bad09472bc3fecc2132 prefill redundancy statistics: 0 txn (0 bytes) of the prefill were redundant, 0 txn (0 bytes) were present in the mempool, 0 txn (0 bytes) were present in the extrapool.
2026-10-09T19:50:15Z [cmpctblock:trace] Reconstructed block 00000012b47e316acca559923dc03bae44294a3fe0fa4bad09472bc3fecc2132 required requesting the following transactions: e19eb7e8c686a15041b460ace19d2b4fc8f482e1e66bb14edc6b6929451c8d23, 5059691e87d3393560be9279f789e8964b0f4496efb814caa15ccc89d4ff7cfe, 74ebeecd3b1dd6022021f0dd38774645dcd5c8843b288079c5445f31d58d7251, 9cfc8582983793e61ad2f785894c0d64a88379ef773042dd60c3d32b702d0023, f975000fe68953414d68192c02765d75c8e4fc0f483cf38f89091e1940e1af80, b31fb64b3c234ad91001c2129cfc8d83ffd255dffa661f52559c25870bc11cab, 5fe8f26f324d314c969aac530157d6032e20862d5c4af3d07b5073d47d79c1fd, e7ea59741822deb3c879ceb66e55ee6b65d123415c74630af4553e9d35a66804, 338dc6e9d2a8b6ddf7a910a0ce48f1f55d17478ca73f10ff2fa078332554501d, 49cb7a25c2994394f4c27c5637a861ba3435ec6d6585bd84fb4e8edce111fa23, 494f221cf3f4374fb8af84b32b8cf78239a3f01e3bc9302635ae9da33dd25a46, 422ad58ea1a813f26bb72ca57867a636998c6d5943f0f867f68a8667f440b987, 328dcbfab0e0bfdd5838dc1e1eece78732811c8d8bd4cfcfe75406530f552fb6, c6e695e324c25f2b2ff5ca198bd70d84aea188dc019fccaa1496e1dcb4e6564b, 0f22bfca5627384cce370733617312a6f4ca1c1c0b610b87f6219544db040df0, 5bc7c22c152bc00c065d858c53ae0338d51b2b9b123de6aa26feebcb5c360b81, 85ba54f361e871466180e555454bf28549e6cd2e3b2ea4c1d02ba0ea5d379d06, aa1e1da2d7fd84c3c566cd0fa52a679c3abfa3de4499a5aa3688da9ef571352c, cd97a8e716d76c716039ad76d47b73bf0da59a338e2a0fb7079b3cf101791051, a75098189c71ae0d6c74b8a46c93d4153baef0c389be06f2e17b03b9f83147be, db97b4330afcc76cf6e61422344f41e51105334a7a9067d37954726501247fd7, dc24c6b20c51a050e1ca3311e994e115c6f14137118852f70ba0ffc34290cfcf, 633e1e650427373d47d178732e68e9b9b387497c65b008eadbbfabd35857ca00, 4887bd4d11a180c0ebd304b1a9f80468e3c915938d5cf9e155df25d66be12c56, 371dbe20a07456134c6486d99e91226ff55f416c4e251ae296ab87dec967dc53, 459aecb81e790ddc7f8de81abaa456d80969b235aea92416e8838b837f4baf03, 7a6c85f7daefe91290ddeefc8c94e658f0bc7d08a411b068627bb1471085c113, 22033d758dddf3b5774e51ad8384ffb0d4370399d35db33addbd5fabf2eaa015, 7153f1d84e05c34e33f711fbc5345a7f5b4b85f321a6c389d65fb1cfbf7ad11a, 5e257906dba69abac0ffd2ac4f9d388d023f4c17136b5519f8d3debbd968961c, a094ab71673698a9260a0c6402871f39f9c3887c466ff9a508a94e06a74fd71f, 7d537d9bcd45f9903fc0d84a0a527b049e29040e97f7016777504653a6455b22, 7a155b06aab32501ddfc1cd30c6bbfac53c3a9784c0ee87c68a75f95f5da3523, 92a72e87e66346a9228435ade953b2c1b2fe8568319f59c7ee494edef34caf26, b2e263bf8bc1a7e52d00f0548544ae27ce8745d1db6113886e559796ee14d629, 1dfd5c5c5e0803493a8d9a8d03c6be1f9c122972b5d853b9fca2d5361dedd62c, cfd07a8374365ab757233833d0fc506b7e629816fdb4ad4565e245cad2607631, 384f513e53f643d9c072d099a327c1a1619d97083492711b4f74b600cdc5d532, a6d34f18da47c8550795eadf9fabc71e2424f7a070d635048776f5a889aaf532, bb7bf03060d35cb41594a99cd4ac7b6769c523fbf066bedc864553082f0af63c, 671e5040d8120cba9f2b2314dfbbc0ef15b2ba913419ee5fd3056080d32fbf3d, 88f8b1bf70065e38b98057f486b68c9a36e44b04f5f2353f149c2db99309043f, 525199badfbdde265166eb1b98014a9ec4b47662b54d69d01dbf43301bec1a41, f93144f781febba86f60c052b9e3d15acd4a19b3056a9ffb1e99aa220b7b4c42, 62d249a68c21276ef2c5d0a6717eb7beab275e46e4d446fae7b91ad828cb6143, f378ba49e4f5c81fbc598a69645c2635460552b6b79d79a86fae19bd79e8db46, 856ca62dd8eb7320987fd57bb9ff73f947f3f3b2efd5f6a9c1391f698cc6264c, c396eeea49d5d94e6116e7f48d352fd79f9c92aedb68f04eba7b37793929d54e, 169358c96d2a841107fe887cd500b7cbba0ad2310c3d7fdac60be814c7169f54, a48c2eeb787cc50af1c5e29729c50924b3afd8dfff7d2155223b7636aecea154, 137cf39d4cc09e1c69020b89bfa34c1079b012f18d09847197eb0def9252b954, 5a392fa917ed050b4170ba75d1d968d9999dc75a6e074e64a3500f2db755a355, 80ff89143499e6454a678f26224cdaad594da835aa526f4edf8e00123f7cfb56, 89a906b4b755b26d2dc5e2b5e9dca1db910c56d5c25c3b1999908b65d8d3f860, a5ca65a793809d9ab948769b121a3aefa10321b1f2f7d6b79ffab16945f0f962, 6824543d5cbc5e87eb0bfb0602efcbf93e64e382250bed2b6fddab7391981264, a2daf536f2aa832618974aeebbc1cd8f947cef7dc94b4a923d638d870ed69666, dbf64eeeb66ceed83aa5022561ab0f6448aa74580a406d90080826b2284add67, 7531c0bd3f19180d5967caecdfe5b4f8507a30776fb8943cd559a13e4358756f, 027bab11d0a991c34e1d44c83ed8e31c790da6b6e4e5e3cad240c0e7c8378b74, 9014bf1238bcdbf65612d08414b50fd7425b6e92cc417a9e9d1c9910d2b92b75, 504643c1348b0cacb98b060fdc786964484903957437618085101e8d44218f76, bbb4a5cd7402c3d689f39cebd389ceabf0c0a634ca7ac4853554d9c48e5f2079, 0ad6a55b7d2910fe8d2a2864c0dab5ed6a4d387792d5b0c8b2f8b5b6fff62c79, e5d0feab4c73f506ddbf806a5c5a92d5ad5aceb0c91937b0069dcf0880354d7d, dcca722d70ea49147cdbddcbe72133d582c7fa0909a6d250dc3d5917608fb885, a46e72074ae869f09aaf386a7f50b28eecc2a7f4525b593e7c009871db14ab8c, 7f367543ec77a0a7b24b0ade14e830b6e5f6e55451cf295500742dfa573fff95, 27b49c3e5e4d19d833b54405866f405a2f9a3e49f4fea75e4211f9662ea604ac, fa05972439ebacdea7056f7818b8965e15facb7255ac1b6cfdd23583ac70cdae, 978c0764b4e59afa77768533b0c8f898def8ce91a33f07d8abcbe5a2d0ba9db1, 1bb1aebe9e0b663447e08b5a376a7322378245777aa8d9af6a78fc1b76979ab7, 41e987a60132d283e103990954d42e286cf9e7aec779ceff863f88fa41a609c0, 984560f2a3f6de96945facd4036694feb8bfafbcfcc0ee6092795c3b2e15c4c0, a033ccdaddfb24a0b6e8c2274f276a68aa0e4131a599c22262b2f37f2426eac2, 0021837b270efbc1a80c6c4c054fb36fb85c03e912928dbf3f054a299a82e8c3, da812f10546f930c8e595578965346b147c7740faee2cd61005da5c9e27eecc8, 52f59f7ab49aa23c15fddbce69c78f2102342c486c454ad4fdc5248758f732c9, 0dbab30b864a616732bd247545fc4ef49199e11eb7f34cf1acbe85f355230dca, bee77d9931933d523543ea719792c988971425921cd0939462aa0d61a65175ca, 5bf08b9e9f5d5fda6e48bc5fd5362fb32cd86ee948349e78fdd43ac02efc6ecb, 66f9ec64be3c728c7b52d2e0f535a89ffd6463b03050feeed070bf1932fb9cd1, ed178d184f21ba4563a01a21d0e3306f7b37c5223775b189e47127bf8d7bd1d4, fe95bd9a5e5b2591593154ebf86104d3f62d20e7b92b582a49cec1f1f34515d9, 8f4c029a9ca2d89d117a30804f2b08aae230eedf643f23a47dd0f8ed883101dc, bcb24ae7429b594792b70157a5599f63df9d1f00e67d0e02dbfe19b7c8fc3dde, b83a1945f7a55559be2df29ca887ef2f018216642a0b9dfed822b46ea6772adf, e6c79e665c6f1e59e4e865cfb5ac72697533c3438a6aba64d736f992200137e3, ee1b5eeb4a03e0adf200cf79f35dac0b49192b0e310e57d3d5b8649a60e39fe4, 91a911fefa2fd118c57950bec25edffad04b550a242c2842e86cf0b6995a19ea, 60d1651ebb963efc5c774f3b3009a5244e2411b5051b8fe33604b7fc725c4feb, 3672ebcb24bd273757ae6be863d898354c684a30d1bc47cb791866099f29e5f8, e7067a23c5622ab5f8ea9cac3cba33c6d4929c8c361c6497ef4032678d8ce4fc, 3c1c08a76e000e84af82df9569cafcb1b0043d63fc9cbe66d069791f2d55da1c, d0c74a8b60e11d9705ff69aab1b367cc31ebd66b807cf945a15cfaa431d6900d, 3ddb12ef4569434f44a72569b66f9f2ae74dbd7d2ca8483c03a139a19460211f, c1b29971854bb422bba5fb4669bbd294cb22e30571a68b2b8306a1b52711eb26, 0ec11280e3e26988404ee1c623841d2db0366c4c148722dd3c3e251a41255528, 1c0827940f9213a6ca755b284a0399d7ff94403c416f1bac49e3dc8bc902732b, 510637c3edee4e04f9fdf497951966bd159547f513bf374335df4ece6edf5b30, 76420f2ce24ecd9e0ed93bb5fc1d806b0a8ed8745ed23f1d2ced246bba57fc3c, 70e7df2f25c17741560814edb12131f2fe6d8c4d9c19d85c128e8925f9b6f645, 9d37045b4d7a85879e5b730a1d6d1a89e620bff9ee87a5c7b6912e4085a82e48, 0e87b3d3df09ebb9eb8589137e9e7ebc34e1d030ae837a57ef49ffc51efffa5d, eaa2efa4e57348af146417ebad2bae342be2883721947ed45b83db644ccc4266, b2a87ce6de57a7beb0390d215bab634503eb7eb6538324ba9a7a07d2d287a27b, 8adba82365906e3d0d03213c154ce141fdc8255844722890bc1344c8bf301684, 7139078eae25f87e637a218d460f8a5c1b9964d04d0ef6c6f6a8b90e5f9a6296, 2fcc45be198dfbfecf630fe39e5c0227449458f67c975827da61bef11e14e19d, 0207b2b2db283e2e7cd2a44368aabb38fe0b8734db64ad90d133de5a5c713bb5, b09be509fb9e3f78c9fec0d4c98bb42f8a06c2ea568ad8dcada1789c21a077b8, 7d1b48c53e7d078e1cb1f9ebae4c9419173f2ac5f355b8e582ab97f3e8fdd3bd, 85ab38865f742f9699bb2222c2298ac6a45beae0eefeecadb6e7f11817bbffbf, e5dd482b7bcf3159ace43da6db9c797f6ecefb0d97a67fdaba6a17305359ecc5, 1aad52cfddc32133d4a07d28f2060655a21c39cf52e6ec692a57834af363b1cc, 3d6d936ad8529f3a62b4150b3389010b970675c98590aee8c464e44947c5e0d0, a1746edf5d82d1b384b2fb66b335378961aaaa2ef5d028ae05c7a0621e87add7, 9642689dea657cdc8f201131805aad1bbe48aba435277d2ffb61d1aa81dca2e1, 92efdbef4093283396ea995fe7e3a193283029ad65cfec5affa48f3bb1de17e3, 4766a73e16baad3dde031dd5ad4450311e0f64b3997c6aa12fd795e5d22fdef2
2026-10-09T19:50:15Z UpdateTip: new best=00000012b47e316acca559923dc03bae44294a3fe0fa4bad09472bc3fecc2132 height=325670 version=0x20000000 log2_work=44.121095 tx=32992960 date='2026-10-09T19:50:04Z' progress=1.000000 cache=1.3MiB(8491txo)
```



```
2026-10-09T20:20:16Z Saw new cmpctblock header hash=00000002d625ee35100c1cd4ee6ac718f5313b70f37d80c756e8a4783a12fc70 height=325671 peer=8
2026-10-09T20:20:16Z [cmpctblock] Initializing PartiallyDownloadedBlock for block 00000002d625ee35100c1cd4ee6ac718f5313b70f37d80c756e8a4783a12fc70 using a cmpctblock of 6768 bytes
2026-10-09T20:20:16Z [cmpctblock] Initialized PartiallyDownloadedBlock for block 00000002d625ee35100c1cd4ee6ac718f5313b70f37d80c756e8a4783a12fc70 using a cmpctblock of 6768 bytes
2026-10-09T20:20:16Z [cmpctblock] Successfully reconstructed block 00000002d625ee35100c1cd4ee6ac718f5313b70f37d80c756e8a4783a12fc70 with 1 txn prefilled (261 bytes), 1064 txn from mempool (1419805 bytes), 0 txn from extrapool (0 bytes), and 5 txn requested (2261 bytes)
2026-10-09T20:20:16Z [cmpctblock] Block 00000002d625ee35100c1cd4ee6ac718f5313b70f37d80c756e8a4783a12fc70 prefill redundancy statistics: 0 txn (0 bytes) of the prefill were redundant, 0 txn (0 bytes) were present in the mempool, 0 txn (0 bytes) were present in the extrapool.
2026-10-09T20:20:16Z [cmpctblock:trace] Reconstructed block 00000002d625ee35100c1cd4ee6ac718f5313b70f37d80c756e8a4783a12fc70 required requesting the following transactions: dd0019b9a6953b51a59f553c19530ffe4c381afdadbcb55381b3058235d18c40, 7904fbcfef52c0e7c72ea4265471a64f131e00873f8a288d21dfa786f4230581, 6df8cff463cbb2d4796dd4694b7c3f437688e8bd0c277db2957d8c51167487e4, 293665c444bc4b9d06a136b92ade6b0e4b551c418ce71fa5387f38f63b24f126, a16b45810b2aa9fb20d64af2e0b444c2fdb842e115a1ae40ccb92c63ed234ad2
2026-10-09T20:20:16Z UpdateTip: new best=00000002d625ee35100c1cd4ee6ac718f5313b70f37d80c756e8a4783a12fc70 height=325671 version=0x20000000 log2_work=44.121110 tx=32994030 date='2026-10-09T20:20:04Z' progress=1.000000 cache=2.7MiB(19913txo)
```

```
2026-10-09T20:23:01Z Saw new cmpctblock header hash=00000006b8f52cf570523362cebd7a1a85af141d02c1be6147e1b646f22ee74a height=325672 peer=8
2026-10-09T20:23:01Z [cmpctblock] Initializing PartiallyDownloadedBlock for block 00000006b8f52cf570523362cebd7a1a85af141d02c1be6147e1b646f22ee74a using a cmpctblock of 7044 bytes
2026-10-09T20:23:01Z [cmpctblock] Initialized PartiallyDownloadedBlock for block 00000006b8f52cf570523362cebd7a1a85af141d02c1be6147e1b646f22ee74a using a cmpctblock of 7044 bytes
2026-10-09T20:23:01Z [cmpctblock] Successfully reconstructed block 00000006b8f52cf570523362cebd7a1a85af141d02c1be6147e1b646f22ee74a with 1 txn prefilled (261 bytes), 1072 txn from mempool (518624 bytes), 2 txn from extrapool (60827 bytes), and 41 txn requested (12061 bytes)
2026-10-09T20:23:01Z [cmpctblock] Block 00000006b8f52cf570523362cebd7a1a85af141d02c1be6147e1b646f22ee74a prefill redundancy statistics: 0 txn (0 bytes) of the prefill were redundant, 0 txn (0 bytes) were present in the mempool, 0 txn (0 bytes) were present in the extrapool.
2026-10-09T20:23:01Z [cmpctblock:trace] Reconstructed block 00000006b8f52cf570523362cebd7a1a85af141d02c1be6147e1b646f22ee74a required requesting the following transactions: 3c8e6d85ba9f6b47db83de0cfb70c8706e7bc6c938bb6f9334183611fd0c3288, 59acdc5e15d882abca2c98490ab43df10f31698e78fc89d52558123c7266d510, 84db93491038a2e7f9170960fa47fc9cab44820a8f6cab7369b4ebfb9904a51a, 61ee0996100c545424f84a8a0ef53220ab5747812d6b204e0b8e7c359ad38416, 673ce8dcce5ab8028446adc42c71eacc3c20a867ea25025a00655e7e24e2bd9d, 04b4a474900d762e5a423fedc9912704ec407a3feeb3e0678e4d0bc457a88e99, a55851063d41750c9a2dca696a9b9848dbd699ffb02c790658123d45fcd566d8, 0307df7d7ad97b648f908c6940bf013ffc3c142236e8b67cc6b0042768f66d41, 3b47a2d3ec7c5ffdbbf577c11f703a30b7b8b4efbda488ce33185fa61c350852, ac36710ed6aff8cdd53048cbc144841f452929caa2a6d362c86a2d1b56fdb201, e475c6c62e28a80a35a34f7e2be03caac1e137045b18bd95a7322a0712a4b30d, 811ab7eacdf2f9aa3a8afe3a1a7b06b0bb5fc7f5815cfb2fc05a6b7bc8bf8216, 3f5d59dbf397049055cf5f4ccc4e9c2af276bd73d92860d63b9e82a8ed0c9b16, cf62dc7cbf5bf72a892855d55ccdfeef7a8ec05cf9a430b673e7276a56c6d91a, 41cc5315b9037f5f11460a63340e23835ddb234d4c18528d1ab2b15876dc511b, 2efdef31a54f6dfd71e4555ec72d6f5980026d2f1adf468bb18c0e3e8be6ac1f, 5b4e5a477d91deab869d55995e3f2cc8f90eb4e6d666a5eb0b42bbae78653e21, 0b2d4868b8e75ff95c7a687f081e525c4bdfbe6dc6eac3f330d50186efb9c622, c3c96b59c6724325e53eab17d79e71a247b5c78dac0d51a4ccf39d93004f6b35, 6b72acddd14f3688e9adeff299135ae4f233da372cb4f9832c3aabe0402f5c36, ab589d95cb8fca2a722ce174053251d4248fef900533df749f593d73198cd838, 87ecc20cddee5628dbcb616a85adb8b6b4389f2b9fd818174e05b5f465352840, 2672989b7d899954b0241db8a62291458ed8829c520f5cbeeaff27076d526549, e49fd3f90b6a8b1875e94315c3fb402bcba2cbd5bab2277972545c2ba473b84e, 0e1978d0825438556f05b49282b65469165ee7c947aa7fea61c29fb30a38614f, 7502085aa3a74fb16d4c26c7701b3a9ccad7a32d4a888358ba74b1db82738a50, d7dd550eafb607225697a3a2c27238c4dbda6618e50f56a9637262cb39f7f051, 8edd96b2bb47f99a5e6d611656c77e831105c0c354f18d623a0e1c948351ea52, 180138878513744ede845e756207ec883fdf0373b48513a93cee5361a665be54, f2c5339ba8563e543d6b49f4ed521b22aaf32a43d1c72bbdf421dd512067515d, 02c0071727c8ac5d9d4b13d1f5d37e94374e204a6ade81cc3cd032bd9763a361, 80113d046159b382d3fc4460f8c072b677c9a6719e642e18462fffff34906d66, eee02b211c3e5e2053421dd00353f92c2a12a77a4960a072216b0729375e2075, 71461916fe26763da3641c0b6b1b6f2bfdc7506c551dbf8e10e9203a6a84c777, 7005fc1f3646b1f4246b830b782a41d292c86c972a643679df9a70a107f07f78, d7f16d6aa8ef1792ca3f55d1603cb4c59086f33c1bebdc842510ba4a3b680679, d4e5d1e6ba3a5d0ab2d410bd85ea10bfd23664a592550d97913678b651749a80, 657f2c293cbecf87e6ae0ac77a8ca2782dc0512ed7fd73f343b2305a4bcf478d, b88bb98cfee3d8b8dbb98a2c61698cfe791312d30b1b190285a9900459a0768d, 2f47d20f04073a1d51b1f64d39eaff7f5cbd5d7751b099d7c8e63d07623522a0, 6e308f4bbea1fa08956ada3f922b69b0b6a6b200e33331ffa47ad766eb1f40a0
2026-10-09T20:23:01Z UpdateTip: new best=00000006b8f52cf570523362cebd7a1a85af141d02c1be6147e1b646f22ee74a height=325672 version=0x20000000 log2_work=44.121126 tx=32995146 date='2026-10-09T20:22:51Z' progress=1.000000 cache=3.8MiB(26912txo)
```

---

### `@sedited` (2026-10-13T07:15:23Z)

@davidgumberg do you want to take the nits?

---

### `@davidgumberg` (2026-10-14T02:23:44Z)

I've pushed to address @andrewtoth's feedback, the changes since the last push only change a commit message and some code comments.

---

### `@0xB10C` (2026-10-14T05:13:53Z)

ACK 8abb996f050a9d5d964c55062a694ab9527f92b2

---

### `@davidgumberg` (2026-10-14T08:13:20Z)

Pushed to fix a code comment typo.

---

### `@0xB10C` (2026-10-14T09:18:15Z)

reACK 4f5ce816db1055b8d885113397c7215dc7af3c83

---

## 5. Formal Reviews & Final `ACK`s

### `@w0xlt` (`COMMENTED`)

ACK a55e3bb55ad473556e3e5011bb9782a941f26f84

---

### `@andrewtoth` (`APPROVED`)

ACK 1a9b2865cae50112c9d77a9fcab6e9406b43d38b

Thanks for taking the `std::map` suggestions ❤️

---

### `@w0xlt` (`COMMENTED`)

reACK 8abb996f050a9d5d964c55062a694ab9527f92b2

---

### `@w0xlt` (`COMMENTED`)

reACK 4f5ce816db1055b8d885113397c7215dc7af3c83

---

### `@andrewtoth` (`APPROVED`)

reACK 4f5ce816db1055b8d885113397c7215dc7af3c83

---

### `@optout21` (`COMMENTED`)

ACK 4f5ce816db1055b8d885113397c7215dc7af3c83

Clean and straightforward logging change. Reproduced and checked the logs (on live mainnet node). Reviewed code, left some non-blocking optional nits.

---

### `@sedited` (`APPROVED`)

utACK 4f5ce816db1055b8d885113397c7215dc7af3c83

---
