# 🛡️ Guardian Security & Consensus Audit: `bitcoin/bitcoin#34628`

- **PR Title:** Merge bitcoin/bitcoin#34628: p2p: Replace per-peer transaction rate-limiting with global rate limits
- **Concentric Risk Ring:** **🟠 Ring 1 — VALIDATION & MEMPOOL POLICY (Pinning / DoS / Censorship Risk)**
- **Merge Commit:** `b33a7fcd7bd896da7175a28802bac9ca53fa238d`
- **Audited PR Tip Commit:** `349c72ee00a06581aa8cddaced6377c49a81d511`
- **Auditor:** Stanley Chege Thuita ([@altradits](https://github.com/altradits))

---

## 1. Why This PR Was Merged (Motivation & Maintainer Context)
```text
349c72ee00a06581aa8cddaced6377c49a81d511 net_processing: Drop unnecessary txid arg from InitiateTxBroadcastToAll (Anthony Towns)
12b0dc33c4af6fc0eb48ae4265c6c050c4d122d7 doc: Add release note for -txsendrate etc (Anthony Towns)
5cde66341a66c37454a4b516016243060cdc8f56 tests: basic functional test for tx rate limiting (Anthony Towns)
4842903ac122c8683a810a1b5da4cc230580fe90 rpc: report -txsendrate and bucket info via getnetworkinfo (Anthony Towns)
74a47a5207135a7a481cb36edfa64907a5d66563 init: add -txsendrate configuration parameter (Anthony Towns)
6307bd034bfb07e45139e80b6177686c02b74d91 net_processing: Provide a 30bpm heartbeat log while inv backlog is in use (Anthony Towns)
df31ee57aaf5d27dc740553f600fe948bcae3e61 net_processing: add a global delay queue for sending txs (Anthony Towns)
7927650e56d2cebc26983b332eec35944f29971a util/tokenbucket.h: Provide a generic TokenBucket class (Anthony Towns)
749bb447f819428d4836c9f205d5212283fa3eac txmempool: Drop CompareMiningScoreWithTopology (Anthony Towns)
e1b7490fbc91c9a119d659461fa426810000f0ae net_processing: Replace CompareInvMempoolOrder (Anthony Towns)
6cfc65d2103e9fd09deea833011bf0d80136f4b1 txmempool: Add ExtractBestByMiningScoreWithTopology (Anthony Towns)
026f70e05f96f5795c888ed69ba9128169ec5b7f net_processing: Remove per-peer rate-limiting (Anthony Towns)
46c8c471dcf55f0e631cd4281d2413a63e7b3775 net_processing: bump last_inv_sequence for bip35 messages explicitly (Anthony Towns)

Pull request description:

  Per-peer `m_tx_inventory_to_send` queues have CPU and memory costs that scale with both queue size and peer count. Under high transaction volume, this has previously caused severe issues ([May 2023 disclosure][1]) and still can cause measurable delays ([Feb 2026 Runestone surge][2], with the msghand thread observed hitting 100% CPU and queue memory reaching ~95MB).

  This PR replaces the per-peer rate limiting with a global queue using dual token buckets (limiting transaction by both count and serialized size). Transactions that arrive within the bucket capacity still relay nearly immediately, but excess transactions queue in a global backlog and drain as the token buckets refill.

  Key parameters:
    - Count bucket: 14 tx/s, 420 capacity (30s buffer)
    - Size bucket: 20 kB/s (~12 MB/600s), 50 MB capacity
    - Outbound peers refill faster by a factor of 2.5

  Per-peer queues are retained solely for privacy batching and are always fully emptied, removing the old `INVENTORY_BROADCAST_MAX` cap.

  This reduces the memory and CPU burden during transaction spikes when the queuing logic is engaged from O(queue * peers) to O(queue), as the queued transactions no longer need to be retained per-peer or re-sorted per-peer.

  Design discussion: https://gist.github.com/ajtowns/d61bea974a07190fa6c6c8eaef3638b9

  [1]: https://bitcoincore.org/en/2024/10/08/disclose-large-inv-to-send/
  [2]: https://bnoc.xyz/t/increased-b-msghand-thread-utilization-due-to-runestone-transactions-on-2026-02-17/81

ACKs for top commit:
  sipa:
    Code review ACK 349c72ee00a06581aa8cddaced6377c49a81d511. I haven't tested it myself yet (though switched my well-connected node to it now), but the posted benchmarks and analyses look convincing.
  instagibbs:
    reACK 349c72ee00a06581aa8cddaced6377c49a81d511
  mzumsande:
    ACK https://github.com/bitcoin/bitcoin/commit/349c72ee00a06581aa8cddaced6377c49a81d511

Tree-SHA512: 2196a23308cb7fe36738cf638edf5c5b0e9ba32b11c083609fd8b50291e05bb33484f9921f8beab28d94c58d1adddea4c8ae1182a60a7f53f54be7370e2a0e47
```

## 2. Commits Inside This PR
```text
349c72ee00 Anthony Towns: net_processing: Drop unnecessary txid arg from InitiateTxBroadcastToAll
12b0dc33c4 Anthony Towns: doc: Add release note for -txsendrate etc
5cde66341a Anthony Towns: tests: basic functional test for tx rate limiting
4842903ac1 Anthony Towns: rpc: report -txsendrate and bucket info via getnetworkinfo
74a47a5207 Anthony Towns: init: add -txsendrate configuration parameter
6307bd034b Anthony Towns: net_processing: Provide a 30bpm heartbeat log while inv backlog is in use
df31ee57aa Anthony Towns: net_processing: add a global delay queue for sending txs
7927650e56 Anthony Towns: util/tokenbucket.h: Provide a generic TokenBucket class
749bb447f8 Anthony Towns: txmempool: Drop CompareMiningScoreWithTopology
e1b7490fbc Anthony Towns: net_processing: Replace CompareInvMempoolOrder
6cfc65d210 Anthony Towns: txmempool: Add ExtractBestByMiningScoreWithTopology
026f70e05f Anthony Towns: net_processing: Remove per-peer rate-limiting
46c8c471dc Anthony Towns: net_processing: bump last_inv_sequence for bip35 messages explicitly
```

## 3. Touched Files & Diff Stat
```text
 doc/release-notes-34628.md                 |  13 ++
 src/init.cpp                               |   4 +
 src/net_processing.cpp                     | 355 +++++++++++++++++++++--------
 src/net_processing.h                       |  19 +-
 src/node/peerman_args.cpp                  |   4 +
 src/node/transaction.cpp                   |   2 +-
 src/node/txdownloadman.h                   |   2 +-
 src/rpc/net.cpp                            |  22 ++
 src/test/util_tests.cpp                    | 132 +++++++++++
 src/txmempool.cpp                          |  73 ++++--
 src/txmempool.h                            |  14 +-
 src/util/tokenbucket.h                     |  69 ++++++
 test/functional/mempool_limit.py           |   3 +
 test/functional/p2p_tx_relay_rate_limit.py | 114 +++++++++
 test/functional/test_runner.py             |   1 +
 15 files changed, 707 insertions(+), 120 deletions(-)
```

## 4. Full Source Code Diff
```diff
diff --git a/doc/release-notes-34628.md b/doc/release-notes-34628.md
new file mode 100644
index 0000000000..884ac0734d
--- /dev/null
+++ b/doc/release-notes-34628.md
@@ -0,0 +1,13 @@
+P2P and network changes
+-----------------------
+
+- To reduce memory and CPU usage during periods of high transaction
+  volume, rate-limiting of outgoing transaction relay has been changed
+  to use a global backlog instead of being done on a per-peer basis. The
+  default rate-limit remains as 14 tx/s (boosted by 2.5x for outbound
+  peers), though this can be changed via the `-txsendrate` configuration
+  option. An additional bandwidth rate-limit has also been introduced
+  at 12MB of transactions per 10 minutes, with a high burst rate. The
+  size of the global backlog and the token bucket values for the rate
+  limits can be queried via the `getnetworkinfo` RPC. (#34628)
+
diff --git a/src/init.cpp b/src/init.cpp
index 290f093680..4eee0ac537 100644
--- a/src/init.cpp
+++ b/src/init.cpp
@@ -710,6 +710,10 @@ void SetupServerArgs(ArgsManager& argsman, bool can_listen_ipc)
                    OptionsCategory::NODE_RELAY);
     argsman.AddArg("-minrelaytxfee=<amt>", strprintf("Fees (in %s/kvB) smaller than this are considered zero fee for relaying, mining and transaction creation (default: %s)",
         CURRENCY_UNIT, FormatMoney(DEFAULT_MIN_RELAY_TX_FEE)), ArgsManager::ALLOW_ANY, OptionsCategory::NODE_RELAY);
+    argsman.AddArg("-txsendrate=<n>",
+                   strprintf("Set the maximum ongoing rate for sending transactions to (inbound) peers (default: %u tx/s)",
+                             DEFAULT_TX_SEND_RATE),
+                   ArgsManager::ALLOW_ANY | ArgsManager::DEBUG_ONLY, OptionsCategory::NODE_RELAY);
     argsman.AddArg("-privatebroadcast",
                    strprintf(
                        "Broadcast transactions submitted via sendrawtransaction RPC using short-lived "
diff --git a/src/net_processing.cpp b/src/net_processing.cpp
index 27f0a63c55..5b57c2f805 100644
--- a/src/net_processing.cpp
+++ b/src/net_processing.cpp
@@ -59,6 +59,7 @@
 #include <util/check.h>
 #include <util/strencodings.h>
 #include <util/time.h>
+#include <util/tokenbucket.h>
 #include <util/trace.h>
 #include <validation.h>
 
@@ -167,15 +168,16 @@ static constexpr auto INBOUND_INVENTORY_BROADCAST_INTERVAL{5s};
  *  Use a smaller delay as there is less privacy concern for them.
  *  Blocks and peers with NetPermissionFlags::NoBan permission bypass this. */
 static constexpr auto OUTBOUND_INVENTORY_BROADCAST_INTERVAL{2s};
-/** Maximum rate of inventory items to send per second.
- *  Limits the impact of low-fee transaction floods. */
-static constexpr unsigned int INVENTORY_BROADCAST_PER_SECOND{14};
-/** Target number of tx inventory items to send per transmission. */
-static constexpr unsigned int INVENTORY_BROADCAST_TARGET = INVENTORY_BROADCAST_PER_SECOND * count_seconds(INBOUND_INVENTORY_BROADCAST_INTERVAL);
-/** Maximum number of inventory items to send per transmission. */
-static constexpr unsigned int INVENTORY_BROADCAST_MAX = 1000;
-static_assert(INVENTORY_BROADCAST_MAX >= INVENTORY_BROADCAST_TARGET, "INVENTORY_BROADCAST_MAX too low");
-static_assert(INVENTORY_BROADCAST_MAX <= node::MAX_PEER_TX_ANNOUNCEMENTS, "INVENTORY_BROADCAST_MAX too high");
+/** Multiplier for the inventory bucket rate for outbounds */
+static constexpr double OUTBOUND_INVENTORY_BUCKET_MULTIPLIER{Ticks<SecondsDouble>(INBOUND_INVENTORY_BROADCAST_INTERVAL) / Ticks<SecondsDouble>(OUTBOUND_INVENTORY_BROADCAST_INTERVAL)};
+/** Delay between checking inventory bucket and backlog */
+static constexpr auto INVENTORY_BUCKET_CHECK_DELAY{100ms};
+/** Empty backlog target capacity */
+static constexpr size_t INVENTORY_BUCKET_BACKLOG_CAPACITY{300};
+/** Delay between inventory bucket backlog heartbeat log entries */
+static constexpr auto INVENTORY_BUCKET_BACKLOG_HEARTBEAT{2000ms};
+/** Minimum backlog to trigger heartbeat log entries */
+static constexpr size_t INVENTORY_BUCKET_BACKLOG_HEARTBEAT_MIN{100};
 /** Average delay between feefilter broadcasts in seconds. */
 static constexpr auto AVG_FEEFILTER_BROADCAST_INTERVAL{10min};
 /** Maximum feefilter broadcast delay after significant change. */
@@ -299,11 +301,11 @@ struct Peer {
          *  us or we have announced to the peer. We use this to avoid announcing
          *  the same (w)txid to a peer that already has the transaction. */
         CRollingBloomFilter m_tx_inventory_known_filter GUARDED_BY(m_tx_inventory_mutex){50000, 0.000001};
-        /** Set of wtxids we still have to announce. For non-wtxid-relay peers,
+        /** Vector of wtxids we still have to announce. For non-wtxid-relay peers,
          *  we retrieve the txid from the corresponding mempool transaction when
          *  constructing the `inv` message. We use the mempool to sort transactions
          *  in dependency order before relay, so this does not have to be sorted. */
-        std::set<Wtxid> m_tx_inventory_to_send GUARDED_BY(m_tx_inventory_mutex);
+        std::vector<Wtxid> m_tx_inventory_to_send GUARDED_BY(m_tx_inventory_mutex);
         /** Whether the peer has requested us to send our complete mempool. Only
          *  permitted if the peer has NetPermissionFlags::Mempool or we advertise
          *  NODE_BLOOM. See BIP35. */
@@ -498,6 +500,68 @@ struct CNodeState {
     int64_t m_last_block_announcement{0};
 };
 
+struct InvToSendBucket {
+    const double count_floor{0};
+    std::vector<Wtxid> backlog;
+    util::TokenBucket<NodeClock> size_bucket;
+    util::TokenBucket<NodeClock> count_bucket;
+
+    /* Initialization rationale:
+     *
+     * Count bucket: Fills at rate*mult, total/initial capacity of 30s with mult=1
+     * Size bucket: Fills at 12MB every 600s, times mult so expected to be 6 times
+     *   the rate at which blocks can confirm transactions, but at least 3 times that in
+     *   the worst case. High limit to avoid triggering even with large spikes, but a
+     *   modest initial value to ensure that frequent node restarts don't raise the limit
+     *   too much.
+     * Count floor: In order to avoid sorting the global backlog too often, we ensure
+     *   that we always remove at least an average INV message's number of transactions
+     *   each time we do work. (Or 50kB if the size bucket is the limiting factor)
+     */
+
+    static constexpr double SIZE_INIT{12'000'000}; // 12 MB initially
+    static constexpr double SIZE_CAP{50'000'000}; // 50 MB maximum
+    static constexpr double SIZE_REFILL{20'000}; // 20kB/s = 12MB/600s
+
+    static constexpr double INBOUND_COUNT_SECONDS{30}; // cap/initial at 30s/mult worth of txs
+
+    InvToSendBucket(unsigned int rate, double mult)
+        : count_floor{-1.0 * rate * count_seconds(INBOUND_INVENTORY_BROADCAST_INTERVAL)},
+          size_bucket(/*rate=*/SIZE_REFILL * mult, /*value=*/SIZE_INIT, /*cap=*/SIZE_CAP),
+          count_bucket(/*rate=*/rate * mult, /*value=*/rate * INBOUND_COUNT_SECONDS, /*cap=*/rate * INBOUND_COUNT_SECONDS)
+    {
+    }
+
+    bool avail() const
+    {
+        return !backlog.empty() && size_bucket.value() > 0 && count_bucket.value() > 0;
+    }
+
+    void increment(NodeClock::time_point now)
+    {
+        size_bucket.increment(now);
+        count_bucket.increment(now);
+    }
+
+    std::vector<Wtxid> TakeForProcessing(CTxMemPool& mempool) EXCLUSIVE_LOCKS_REQUIRED(mempool.cs);
+
+    bool decrement(double size)
+    {
+        bool size_ok = size_bucket.decrement(size, /*floor=*/-50e3);
+        bool count_ok = count_bucket.decrement(1, /*floor=*/count_floor);
+        return size_ok && count_ok;
+    }
+
+    PeerManagerInfo::InvBucketInfo info() const
+    {
+        return {
+            .backlog_count = backlog.size(),
+            .count_bucket = count_bucket.value(),
+            .size_bucket = size_bucket.value(),
+        };
+    }
+};
+
 class PeerManagerImpl final : public PeerManager
 {
 public:
@@ -524,9 +588,9 @@ public:
     void FinalizeNode(const CNode& node) override EXCLUSIVE_LOCKS_REQUIRED(!m_peer_mutex, !m_headers_presync_mutex, !m_tx_download_mutex);
     bool HasAllDesirableServiceFlags(ServiceFlags services) const override;
     bool ProcessMessages(CNode& node, std::atomic<bool>& interrupt) override
-        EXCLUSIVE_LOCKS_REQUIRED(!m_peer_mutex, !m_most_recent_block_mutex, !m_headers_presync_mutex, g_msgproc_mutex, !m_tx_download_mutex);
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
Tested ACK 349c72ee00a06581aa8cddaced6377c49a81d511
```
