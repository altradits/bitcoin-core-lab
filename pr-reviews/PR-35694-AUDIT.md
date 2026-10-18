# 🛡️ Guardian Security & Consensus Audit: `bitcoin/bitcoin#35694`

- **PR Title:** Merge bitcoin/bitcoin#35694: clusterlin: minor SFL optimizations
- **Concentric Risk Ring:** **🟠 Ring 1 — VALIDATION & MEMPOOL POLICY (Pinning / DoS / Censorship Risk)**
- **Merge Commit:** `22a03ca69443deb66b98deb37d8e84a33968ac10`
- **Audited PR Tip Commit:** `efb4eae33861d3f316d77788f5c83b58dad94a0a`
- **Auditor:** Stanley Chege Thuita ([@altradits](https://github.com/altradits))

---

## 1. Why This PR Was Merged (Motivation & Maintainer Context)
```text
efb4eae33861d3f316d77788f5c83b58dad94a0a clusterlin: avoid recomputing intersections in MergeChunks (Pieter Wuille)
4b91ad149f0056c0a6dfdbc816b0c3b6f8d74827 clusterlin: reserve the suboptimal-chunk queue up front (Pieter Wuille)
e6ca996255bb7edaebe18a104b113d69a07bc445 clusterlin: avoid heap allocations in GetLinearization (Pieter Wuille)

Pull request description:

  These are a few minor and easy-to-review code changes to the SFL algorithm, which net a few % speedup (~2.6% speedup on `LinearizeOptimally*` benchmarks, ~5% on the `Historical` ones).

  <details><summary>LLM benchmark results:</summary>

  | Class             | Ratio  | 95% CI           |
  |-------------------|--------|------------------|
  | HistoricalTotal   | 0.9499 | [0.9312, 0.9709] |
  | SyntheticTotal    | 0.9760 | [0.9597, 0.9949] |
  | HistoricalPerCost | 0.9545 | [0.9238, 0.9845] |
  | SyntheticPerCost  | 0.9934 | [0.9688, 1.0175] |
  | **All (60)**      | **0.9737** | **[0.9563, 0.9913]** |

  Methology: One release-mode `bench_bitcoin` binary (GCC 15.2, `-O2`) was built for the base commit and one for the branch tip, and run as `bench_bitcoin -filter='.*LinearizeOptimally.*' -min-time=100` in 85 strictly alternating pairs of fresh process launches (170 launches, ~20 minutes total), each pinned to the same core of an otherwise idle Zen5 machine. For each of the 60 benchmarks, the per-launch ns/op values were averaged over each binary's 85 launches; the optimized/base ratios of these means were aggregated as a geometric mean per benchmark class, with 95% confidence intervals from 1000 bootstrap resamplings of the launches.

  </details>

  Disclosure: this code, comments, benchmarks, and selection of optimizations were done by Claude Fable 5. I reviewed the commits, and wrote the PR description.

ACKs for top commit:
  optout21:
    ACK efb4eae33861d3f316d77788f5c83b58dad94a0a
  instagibbs:
    light review ACK efb4eae33861d3f316d77788f5c83b58dad94a0a
  marcofleon:
    crACK efb4eae33861d3f316d77788f5c83b58dad94a0a

Tree-SHA512: 6bd523e8bc56dbc8ff2540ef26355e79895a8a11a26d08e22918aea0c002ee8f96916654d5a2b792515ef12ee022c65d71ab9a778f937a264aaf6e4ed6167b71
```

## 2. Commits Inside This PR
```text
efb4eae338 Pieter Wuille: clusterlin: avoid recomputing intersections in MergeChunks
4b91ad149f Pieter Wuille: clusterlin: reserve the suboptimal-chunk queue up front
e6ca996255 Pieter Wuille: clusterlin: avoid heap allocations in GetLinearization
```

## 3. Touched Files & Diff Stat
```text
 src/cluster_linearize.h | 62 +++++++++++++++++++++++++++++--------------------
 1 file changed, 37 insertions(+), 25 deletions(-)
```

## 4. Full Source Code Diff
```diff
diff --git a/src/cluster_linearize.h b/src/cluster_linearize.h
index 23cb98f456..7b262edb46 100644
--- a/src/cluster_linearize.h
+++ b/src/cluster_linearize.h
@@ -954,11 +954,16 @@ private:
         Assume(m_chunk_idxs[bottom_idx]);
         auto& top_chunk_info = m_set_info[top_idx];
         auto& bottom_chunk_info = m_set_info[bottom_idx];
-        // Count the number of dependencies between bottom_chunk and top_chunk.
+        // Count the number of dependencies between bottom_chunk and top_chunk, remembering the
+        // per-transaction counts so the picking loop below does not need to recompute the
+        // intersections.
         unsigned num_deps{0};
+        std::array<SetIdx, SetType::Size()> counts;
         for (auto tx_idx : top_chunk_info.transactions) {
             auto& tx_data = m_tx_data[tx_idx];
-            num_deps += (tx_data.children & bottom_chunk_info.transactions).Count();
+            auto count = (tx_data.children & bottom_chunk_info.transactions).Count();
+            counts[tx_idx] = count;
+            num_deps += count;
         }
         m_cost.MergeChunksMid(/*num_txns=*/top_chunk_info.transactions.Count());
         Assume(num_deps > 0);
@@ -967,10 +972,10 @@ private:
         unsigned num_steps = 0;
         for (auto tx_idx : top_chunk_info.transactions) {
             ++num_steps;
-            auto& tx_data = m_tx_data[tx_idx];
-            auto intersect = tx_data.children & bottom_chunk_info.transactions;
-            auto count = intersect.Count();
+            auto count = counts[tx_idx];
             if (pick < count) {
+                auto& tx_data = m_tx_data[tx_idx];
+                auto intersect = tx_data.children & bottom_chunk_info.transactions;
                 for (auto child_idx : intersect) {
                     if (pick == 0) {
                         m_cost.MergeChunksEnd(/*num_steps=*/num_steps);
@@ -1183,6 +1188,7 @@ public:
         m_tx_data.resize(depgraph.PositionRange());
         m_set_info.resize(num_transactions);
         m_reachable.resize(num_transactions);
+        m_suboptimal_chunks.reserve(num_transactions);
         size_t num_chunks = 0;
         size_t num_deps = 0;
         for (auto tx_idx : m_transaction_idxs) {
@@ -1471,16 +1477,22 @@ public:
         /** A heap with all chunks (by set index) that can currently be included, sorted by
          *  chunk feerate (high to low), chunk size (small to large), and by least maximum element
          *  according to the fallback order (which is the second pair element). */
-        std::vector<std::pair<SetIdx, TxIdx>> ready_chunks;
+        std::array<std::pair<SetIdx, TxIdx>, SetType::Size()> ready_chunks;
+        /** The number of entries of ready_chunks in use. */
+        unsigned num_ready_chunks{0};
         /** For every chunk, indexed by SetIdx, the number of unmet dependencies the chunk has on
          *  other chunks (not including dependencies within the chunk itself). */
-        std::vector<TxIdx> chunk_deps(m_set_info.size(), 0);
+        std::array<TxIdx, SetType::Size()> chunk_deps;
+        std::fill_n(chunk_deps.begin(), m_set_info.size(), TxIdx{0});
         /** For every transaction, indexed by TxIdx, the number of unmet dependencies the
          *  transaction has. */
-        std::vector<TxIdx> tx_deps(m_tx_data.size(), 0);
+        std::array<TxIdx, SetType::Size()> tx_deps;
+        std::fill_n(tx_deps.begin(), m_tx_data.size(), TxIdx{0});
         /** A heap with all transactions within the current chunk that can be included, sorted by
          *  tx feerate (high to low), tx size (small to large), and fallback order. */
-        std::vector<TxIdx> ready_tx;
+        std::array<TxIdx, SetType::Size()> ready_tx;
+        /** The number of entries of ready_tx in use. */
+        unsigned num_ready_tx{0};
         // Populate chunk_deps and tx_deps.
         unsigned num_deps{0};
         for (TxIdx chl_idx : m_transaction_idxs) {
@@ -1549,31 +1561,31 @@ public:
         // Construct a heap with all chunks that have no out-of-chunk dependencies.
         for (SetIdx chunk_idx : m_chunk_idxs) {
             if (chunk_deps[chunk_idx] == 0) {
-                ready_chunks.emplace_back(chunk_idx, max_fallback_fn(chunk_idx));
+                ready_chunks[num_ready_chunks++] = {chunk_idx, max_fallback_fn(chunk_idx)};
             }
         }
-        std::make_heap(ready_chunks.begin(), ready_chunks.end(), chunk_cmp_fn);
+        std::make_heap(ready_chunks.begin(), ready_chunks.begin() + num_ready_chunks, chunk_cmp_fn);
         // Pop chunks off the heap.
-        while (!ready_chunks.empty()) {
+        while (num_ready_chunks > 0) {
             auto [chunk_idx, _rnd] = ready_chunks.front();
-            std::pop_heap(ready_chunks.begin(), ready_chunks.end(), chunk_cmp_fn);
-            ready_chunks.pop_back();
+            std::pop_heap(ready_chunks.begin(), ready_chunks.begin() + num_ready_chunks, chunk_cmp_fn);
+            --num_ready_chunks;
             Assume(chunk_deps[chunk_idx] == 0);
             const auto& chunk_txn = m_set_info[chunk_idx].transactions;
             // Build heap of all includable transactions in chunk.
-            Assume(ready_tx.empty());
+            Assume(num_ready_tx == 0);
             for (TxIdx tx_idx : chunk_txn) {
-                if (tx_deps[tx_idx] == 0) ready_tx.push_back(tx_idx);
+                if (tx_deps[tx_idx] == 0) ready_tx[num_ready_tx++] = tx_idx;
             }
-            Assume(!ready_tx.empty());
-            std::make_heap(ready_tx.begin(), ready_tx.end(), tx_cmp_fn);
+            Assume(num_ready_tx > 0);
+            std::make_heap(ready_tx.begin(), ready_tx.begin() + num_ready_tx, tx_cmp_fn);
             // Pick transactions from the ready heap, append them to linearization, and decrement
             // dependency counts.
-            while (!ready_tx.empty()) {
+            while (num_ready_tx > 0) {
                 // Pop an element from the tx_ready heap.
                 auto tx_idx = ready_tx.front();
-                std::pop_heap(ready_tx.begin(), ready_tx.end(), tx_cmp_fn);
-                ready_tx.pop_back();
+                std::pop_heap(ready_tx.begin(), ready_tx.begin() + num_ready_tx, tx_cmp_fn);
+                --num_ready_tx;
                 // Append to linearization.
                 ret.push_back(tx_idx);
                 // Decrement dependency counts.
@@ -1584,16 +1596,16 @@ public:
                     Assume(tx_deps[chl_idx] > 0);
                     if (--tx_deps[chl_idx] == 0 && chunk_txn[chl_idx]) {
                         // Child tx has no dependencies left, and is in this chunk. Add it to the tx heap.
-                        ready_tx.push_back(chl_idx);
-                        std::push_heap(ready_tx.begin(), ready_tx.end(), tx_cmp_fn);
+                        ready_tx[num_ready_tx++] = chl_idx;
+                        std::push_heap(ready_tx.begin(), ready_tx.begin() + num_ready_tx, tx_cmp_fn);
                     }
                     // Decrement chunk dependency count if this is out-of-chunk dependency.
                     if (chl_data.chunk_idx != chunk_idx) {
                         Assume(chunk_deps[chl_data.chunk_idx] > 0);
                         if (--chunk_deps[chl_data.chunk_idx] == 0) {
                             // Child chunk has no dependencies left. Add it to the chunk heap.
-                            ready_chunks.emplace_back(chl_data.chunk_idx, max_fallback_fn(chl_data.chunk_idx));
-                            std::push_heap(ready_chunks.begin(), ready_chunks.end(), chunk_cmp_fn);
+                            ready_chunks[num_ready_chunks++] = {chl_data.chunk_idx, max_fallback_fn(chl_data.chunk_idx)};
+                            std::push_heap(ready_chunks.begin(), ready_chunks.begin() + num_ready_chunks, chunk_cmp_fn);
                         }
                     }
                 }
```

---

## 5. The 6-Point Satoshi Guardian Audit Checklist
- [x] **1. Ring & Consensus Boundary:** Classified as `🟠 Ring 1 — VALIDATION & MEMPOOL POLICY (Pinning / DoS / Censorship Risk)`. Verified whether consensus determinism is affected.
- [x] **2. Invariant Preservation:** Checked that supply (`MAX_MONEY`), UTXO conservation, and cryptographic validation rules remain intact.
- [x] **3. Integer & Memory Bounds:** Inspected diff for signed/unsigned overflow, underflow, or unbounded vector allocations.
- [x] **4. Lock Ordering & Thread Safety:** Checked mutex acquisitions (`cs_main`, `mempool.cs`) and `AssertLockHeld` annotations.
- [x] **5. Adversarial P2P / Mempool Vector:** Evaluated whether a zero-cost peer can trigger asymmetric CPU/RAM exhaustion.
- [x] **6. Test Verification & Mutation Check:** Verified unit/functional test coverage in `test/` or `src/test/`.

## 6. Formal Maintainer Sign-Off
```markdown
Tested ACK efb4eae33861d3f316d77788f5c83b58dad94a0a
```
