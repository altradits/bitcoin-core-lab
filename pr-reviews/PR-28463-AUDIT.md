# 🛡️ Guardian Security & Consensus Audit: `bitcoin/bitcoin#28463`

- **PR Title:** Merge bitcoin/bitcoin#28463: p2p: Increase inbound capacity for block-relay only connections
- **Concentric Risk Ring:** **🟡 Ring 2 — P2P NETWORKING (Eclipse / Remote Memory DoS Risk)**
- **Merge Commit:** `11ebbd907217a037d2c0c9be0395091e1d6395e1`
- **Audited PR Tip Commit:** `c11508406e6e0cd14c07c58e23085e1a8ff543fa`
- **Auditor:** Stanley Chege Thuita ([@altradits](https://github.com/altradits))

---

## 1. Why This PR Was Merged (Motivation & Maintainer Context)
```text
c11508406e6e0cd14c07c58e23085e1a8ff543fa doc: Update docs that refer to -maxconnections (Martin Zumsande)
69ce0dba2ae453d915eda0641f97e5bfe43c8273 test: add test that EvictTxPeerIfFull only evicts tx-relaying peers (brunoerg)
3ed7f064180f8cf0102a8e27a7a73467733fe2ec p2p: trigger possible eviction if we support bloom filters and change a peer to tx relay (Martin Zumsande)
0bd3d3dfa562724e3dbc4cec2d4290e4561655cd init: make inbound tx relay percentage configurable (Amiti Uttarwar)
cc59aee196e278001a01a5f6baaaedb800a0b046 test: add functional test for inbound maxconnection limits (Amiti Uttarwar)
1b76e0473647d0df5c32ffe1bcdcbbcadc5d0dfa net: increase inbound capacity for block-relay-only connections (Martin Zumsande)
87bca1c2adbabb17616ba74f370c48857be27b00 net: add options to AttemptToEvictConnection (Martin Zumsande)

Pull request description:

  This is joint work with amitiuttarwar.

  See issue #28462 for a broader discussion on increasing the number of block-relay-only connections independent of this particular implementation proposal.

  We suggest to increase the number of inbound slots allocated to block-relay-only peers by increasing the default maximum connections from 125 to 200, with 50% of inbound slots accessible for tx-relaying peers.
  This is a prerequisite for being able to increase the default number of outgoing block-relay-only peers later, because the current inbound capacity of the network is not sufficient.
  In order to account for incoming tx-relaying peers separately from incoming block-relay peers, changes to the inbound eviction logic are necessary.

  See the next post in this thread for a more detailed explanation and motivation of the changes.

ACKs for top commit:
  instagibbs:
    ACK c11508406e6e0cd14c07c58e23085e1a8ff543fa
  achow101:
    ACK c11508406e6e0cd14c07c58e23085e1a8ff543fa
  dergoegge:
    crACK c11508406e6e0cd14c07c58e23085e1a8ff543fa
  marcofleon:
    ACK c11508406e6e0cd14c07c58e23085e1a8ff543fa

Tree-SHA512: c71e1481eb235429a6c9d7ce771c7bf825f850b135e904ccfa3505112628fef4188b560d0be0847c968e5ece43c1518590069b7e6e2480790d3ef1ce07d1ac38
```

## 2. Commits Inside This PR
```text
c11508406e Martin Zumsande: doc: Update docs that refer to -maxconnections
69ce0dba2a brunoerg: test: add test that EvictTxPeerIfFull only evicts tx-relaying peers
3ed7f06418 Martin Zumsande: p2p: trigger possible eviction if we support bloom filters and change a peer to tx relay
0bd3d3dfa5 Amiti Uttarwar: init: make inbound tx relay percentage configurable
cc59aee196 Amiti Uttarwar: test: add functional test for inbound maxconnection limits
1b76e04736 Martin Zumsande: net: increase inbound capacity for block-relay-only connections
87bca1c2ad Martin Zumsande: net: add options to AttemptToEvictConnection
```

## 3. Touched Files & Diff Stat
```text
 doc/reduce-memory.md                      |   2 +-
 doc/reduce-traffic.md                     |   5 +-
 src/init.cpp                              |   8 ++-
 src/net.cpp                               |  29 +++++++-
 src/net.h                                 |  27 +++++++-
 src/net_processing.cpp                    |  29 ++++++++
 test/functional/interface_usdt_net.py     |   4 +-
 test/functional/p2p_connection_limits.py  | 107 ++++++++++++++++++++++++++++++
 test/functional/p2p_eviction.py           |   8 ++-
 test/functional/p2p_opportunistic_1p1c.py |   2 +-
 test/functional/test_runner.py            |   1 +
 11 files changed, 206 insertions(+), 16 deletions(-)
```

## 4. Full Source Code Diff
```diff
diff --git a/doc/reduce-memory.md b/doc/reduce-memory.md
index 44d90bcf50..a69bcb7d3e 100644
--- a/doc/reduce-memory.md
+++ b/doc/reduce-memory.md
@@ -33,7 +33,7 @@ The size of some in-memory caches can be reduced. As caches trade off memory usa
 
 ## Number of peers
 
-- `-maxconnections=<n>` - the maximum number of connections, which defaults to 125. Each active connection takes up some
+- `-maxconnections=<n>` - the maximum number of connections, which defaults to 200. Each active connection takes up some
   memory. This option applies only if inbound connections are enabled; otherwise, the number of connections will not
   be more than 11. Of the 11 outbound peers, there can be 8 full-relay connections, 2 block-relay-only ones,
   and occasionally 1 short-lived feeler or extra outbound block-relay-only connection.
diff --git a/doc/reduce-traffic.md b/doc/reduce-traffic.md
index 8926a8361a..315de21450 100644
--- a/doc/reduce-traffic.md
+++ b/doc/reduce-traffic.md
@@ -3,8 +3,9 @@ Reduce Traffic
 
 Some node operators need to deal with bandwidth caps imposed by their ISPs.
 
-By default, Bitcoin Core allows up to 125 connections to different peers, 11 of
-which are outbound. You can therefore, have at most 114 inbound connections.
+By default, Bitcoin Core allows up to 200 connections to different peers, 11 of
+which are outbound. You can therefore, have at most 189 inbound connections, half of
+which can only be taken up by low-traffic block-relay-only peers.
 Of the 11 outbound peers, there can be 8 full-relay connections, 2
 block-relay-only ones and occasionally 1 short-lived feeler or an extra block-relay-only connection.
 
diff --git a/src/init.cpp b/src/init.cpp
index d2e2902040..c9363ba96d 100644
--- a/src/init.cpp
+++ b/src/init.cpp
@@ -578,7 +578,12 @@ void SetupServerArgs(ArgsManager& argsman, bool can_listen_ipc)
     argsman.AddArg("-forcednsseed", strprintf("Always query for peer addresses via DNS lookup (default: %u)", DEFAULT_FORCEDNSSEED), ArgsManager::ALLOW_ANY, OptionsCategory::CONNECTION);
     argsman.AddArg("-listen", strprintf("Accept connections from outside (default: %u if no -proxy, -connect or -maxconnections=0)", DEFAULT_LISTEN), ArgsManager::ALLOW_ANY, OptionsCategory::CONNECTION);
     argsman.AddArg("-listenonion", strprintf("Automatically create Tor onion service (default: %d)", DEFAULT_LISTEN_ONION), ArgsManager::ALLOW_ANY, OptionsCategory::CONNECTION);
-    argsman.AddArg("-maxconnections=<n>", strprintf("Maintain at most <n> automatic connections to peers (default: %u). This limit does not apply to connections manually added via -addnode or the addnode RPC, which have a separate limit of %u. It does not apply to short-lived private broadcast connections either, which have a separate limit of %u.", DEFAULT_MAX_PEER_CONNECTIONS, MAX_ADDNODE_CONNECTIONS, MAX_PRIVATE_BROADCAST_CONNECTIONS), ArgsManager::ALLOW_ANY, OptionsCategory::CONNECTION);
+    argsman.AddArg("-maxconnections=<n>", strprintf("Maintain at most <n> automatic connections to peers (default: %u). %u slots of these are reserved for outgoing connections. See -inboundrelaypercent for more information about limits applied to transaction relay inbound peers. "
+                                                    "This limit does not apply to connections manually added via -addnode or the addnode RPC, which have a separate limit of %u. "
+                                                    "It does not apply to short-lived private broadcast connections either, which have a separate limit of %u.",
+                                                    DEFAULT_MAX_PEER_CONNECTIONS, MAX_OUTBOUND_FULL_RELAY_CONNECTIONS + MAX_BLOCK_RELAY_ONLY_CONNECTIONS + MAX_FEELER_CONNECTIONS, MAX_ADDNODE_CONNECTIONS, MAX_PRIVATE_BROADCAST_CONNECTIONS),
+                   ArgsManager::ALLOW_ANY, OptionsCategory::CONNECTION);
+    argsman.AddArg("-inboundrelaypercent=<n>", strprintf("Permit a maximum percent of inbound connections to relay transactions, to limit memory utilization (0 to 100, default: %u).", DEFAULT_FULL_RELAY_INBOUND_PCT), ArgsManager::ALLOW_ANY, OptionsCategory::CONNECTION);
     argsman.AddArg("-maxreceivebuffer=<n>", strprintf("Maximum per-connection receive buffer, <n>*1000 bytes (default: %u)", DEFAULT_MAXRECEIVEBUFFER), ArgsManager::ALLOW_ANY, OptionsCategory::CONNECTION);
     argsman.AddArg("-maxsendbuffer=<n>", strprintf("Maximum per-connection memory usage for the send buffer, <n>*1000 bytes (default: %u)", DEFAULT_MAXSENDBUFFER), ArgsManager::ALLOW_ANY, OptionsCategory::CONNECTION);
     argsman.AddArg("-maxuploadtarget=<n>", strprintf("Tries to keep outbound traffic under the given target per 24h. Limit does not apply to peers with 'download' permission or blocks created within past week. 0 = no limit (default: %s). Optional suffix units [k|K|m|M|g|G|t|T] (default: M). Lowercase is 1000 base while uppercase is 1024 base", DEFAULT_MAX_UPLOAD_TARGET), ArgsManager::ALLOW_ANY, OptionsCategory::CONNECTION);
@@ -2117,6 +2122,7 @@ bool AppInitMain(NodeContext& node, interfaces::BlockAndHeaderTipInfo* tip_info)
     CConnman::Options connOptions;
     connOptions.m_local_services = g_local_services;
     connOptions.m_max_automatic_connections = nMaxConnections;
+    connOptions.m_full_relay_inbound_percent = std::clamp<int>(args.GetIntArg("-inboundrelaypercent", DEFAULT_FULL_RELAY_INBOUND_PCT), 0, 100);
     connOptions.uiInterface = &uiInterface;
     connOptions.m_banman = node.banman.get();
     connOptions.m_msgproc = node.peerman.get();
diff --git a/src/net.cpp b/src/net.cpp
index 951e804f88..c9cd94b10c 100644
--- a/src/net.cpp
+++ b/src/net.cpp
@@ -1683,7 +1683,7 @@ std::pair<size_t, bool> CConnman::SocketSendData(CNode& node) const
     return {nSentSize, data_left};
 }
 
-/** Try to find a connection to evict when the node is full.
+/** Try to find an inbound connection to evict.
  *  Extreme care must be taken to avoid opening the node to attacker
  *   triggered network partitioning.
  *  The strategy used here is to protect a small number of peers
@@ -1691,7 +1691,7 @@ std::pair<size_t, bool> CConnman::SocketSendData(CNode& node) const
  *   to forge.  In order to partition a node the attacker must be
  *   simultaneously better at all of them than honest peers.
  */
-bool CConnman::AttemptToEvictConnection()
+bool CConnman::AttemptToEvictConnection(bool evict_tx_relay_peer_only, std::optional<NodeId> protect_peer)
 {
     AssertLockNotHeld(m_nodes_mutex);
 
@@ -1702,6 +1702,12 @@ bool CConnman::AttemptToEvictConnection()
         for (const CNode* node : m_nodes) {
             if (node->fDisconnect)
                 continue;
+            if (protect_peer.has_value() && node->GetId() == protect_peer) {
+                continue;
+            }
+            if (evict_tx_relay_peer_only && !node->m_relays_txs) {
+                continue;
+            }
             NodeEvictionCandidate candidate{
                 .id = node->GetId(),
                 .m_connected = node->m_connected,
@@ -1830,7 +1836,7 @@ void CConnman::CreateNodeFromAcceptedSocket(std::unique_ptr<Sock>&& sock,
 
     if (nInbound >= m_max_inbound)
     {
-        if (!AttemptToEvictConnection()) {
+        if (!AttemptToEvictConnection(/*evict_tx_relay_peer_only=*/false)) {
             // No connection to evict, disconnect the new connection
             LogDebug(BCLog::NET, "failed to find an eviction candidate - connection dropped (full)\n");
             return;
@@ -2529,6 +2535,23 @@ int CConnman::GetExtraBlockRelayCount() const
     return std::max(block_relay_peers - m_max_outbound_block_relay, 0);
 }
 
+bool CConnman::EvictTxPeerIfFull(std::optional<NodeId> protect_peer)
+{
+    int tx_inbound_peers{0};
+    {
+        LOCK(m_nodes_mutex);
+        for (const CNode* pnode : m_nodes) {
+            if (!pnode->fDisconnect && pnode->IsInboundConn() && pnode->m_relays_txs) {
+                ++tx_inbound_peers;
+            }
+        }
+    }
+    if (tx_inbound_peers > m_max_inbound_full_relay) {
+        return AttemptToEvictConnection(/*evict_tx_relay_peer_only=*/true, protect_peer);
+    }
+    return true;
+}
+
 std::unordered_set<Network> CConnman::GetReachableEmptyNetworks() const
 {
     std::unordered_set<Network> networks{};
diff --git a/src/net.h b/src/net.h
index d0cfe7c9ac..f1814120a3 100644
--- a/src/net.h
+++ b/src/net.h
@@ -78,7 +78,9 @@ static constexpr size_t MAX_PRIVATE_BROADCAST_CONNECTIONS{64};
 /** -listen default */
 static const bool DEFAULT_LISTEN = true;
 /** The maximum number of peer connections to maintain. */
-static const unsigned int DEFAULT_MAX_PEER_CONNECTIONS = 125;
+static const unsigned int DEFAULT_MAX_PEER_CONNECTIONS{200};
+/** Default percentage of inbound connection slots that tx-relaying peers can use */
+static const int DEFAULT_FULL_RELAY_INBOUND_PCT{50};
 /** The default for -maxuploadtarget. 0 = Unlimited */
 static const std::string DEFAULT_MAX_UPLOAD_TARGET{"0M"};
 /** Default for blocks only*/
@@ -1086,7 +1088,8 @@ public:
     struct Options
     {
         ServiceFlags m_local_services = NODE_NONE;
-        int m_max_automatic_connections = 0;
+        int m_max_automatic_connections = DEFAULT_MAX_PEER_CONNECTIONS;
+        int m_full_relay_inbound_percent = DEFAULT_FULL_RELAY_INBOUND_PCT;
         CClientUIInterface* uiInterface = nullptr;
         NetEventsInterface* m_msgproc = nullptr;
         BanMan* m_banman = nullptr;
@@ -1122,6 +1125,7 @@ public:
         m_max_outbound_block_relay = std::min(MAX_BLOCK_RELAY_ONLY_CONNECTIONS, m_max_automatic_connections - m_max_outbound_full_relay);
         m_max_automatic_outbound = m_max_outbound_full_relay + m_max_outbound_block_relay + m_max_feeler;
         m_max_inbound = std::max(0, m_max_automatic_connections - m_max_automatic_outbound);
+        m_max_inbound_full_relay = std::max(0, static_cast<int>(connOptions.m_full_relay_inbound_percent / 100.0 * m_max_inbound));
         m_use_addrman_outgoing = connOptions.m_use_addrman_outgoing;
         m_client_interface = connOptions.uiInterface;
         m_banman = connOptions.m_banman;
@@ -1343,6 +1347,16 @@ public:
     int GetExtraFullOutboundCount() const EXCLUSIVE_LOCKS_REQUIRED(!m_nodes_mutex);
     // Count the number of block-relay-only peers we have over our limit.
     int GetExtraBlockRelayCount() const EXCLUSIVE_LOCKS_REQUIRED(!m_nodes_mutex);
```

---

## 5. The 6-Point Satoshi Guardian Audit Checklist
- [x] **1. Ring & Consensus Boundary:** Classified as `🟡 Ring 2 — P2P NETWORKING (Eclipse / Remote Memory DoS Risk)`. Verified whether consensus determinism is affected.
- [x] **2. Invariant Preservation:** Checked that supply (`MAX_MONEY`), UTXO conservation, and cryptographic validation rules remain intact.
- [x] **3. Integer & Memory Bounds:** Inspected diff for signed/unsigned overflow, underflow, or unbounded vector allocations.
- [x] **4. Lock Ordering & Thread Safety:** Checked mutex acquisitions (`cs_main`, `mempool.cs`) and `AssertLockHeld` annotations.
- [x] **5. Adversarial P2P / Mempool Vector:** Evaluated whether a zero-cost peer can trigger asymmetric CPU/RAM exhaustion.
- [x] **6. Test Verification & Mutation Check:** Verified unit/functional test coverage in `test/` or `src/test/`.

## 6. Formal Maintainer Sign-Off
```markdown
Tested ACK c11508406e6e0cd14c07c58e23085e1a8ff543fa
```
