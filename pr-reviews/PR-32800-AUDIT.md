# 🛡️ Guardian Security & Consensus Audit: `bitcoin/bitcoin#32800`

- **PR Title:** Merge bitcoin/bitcoin#32800: rpc: Distinguish between vsize and sigop adjusted mempool vsize
- **Concentric Risk Ring:** **🟢 Ring 3 — Wallet / RPC / Build / Tests**
- **Merge Commit:** `6b059d9dbdbd4d5b6f52993f93bf291181bf3900`
- **Audited PR Tip Commit:** `29b124416e4293aafda0097808c01f5a2cb8627c`
- **Auditor:** Stanley Chege Thuita ([@altradits](https://github.com/altradits))

---

## 1. Why This PR Was Merged (Motivation & Maintainer Context)
```text
29b124416e4293aafda0097808c01f5a2cb8627c doc: add release notes for 32800 (Musa Haruna)
5d25a0c28d19c4b2f3f5ecdf42fb11d1246855b1 rpc: add `vsize_adjusted` field to getrawtransaction output for mempool transactions (Musa Haruna)
eaef8d31118d26654c2bcea1c0528b66ea9b1b2d rpc: add `vsize_adjusted` and `vsize_bip141` field to mempool-related RPCs (Musa Haruna)

Pull request description:

  ### Motivation and Problem

  `CTxMemPoolEntry::GetTxSize()` returns the larger of two values: the BIP 141 virtual size (vsize) and the "sigop-adjusted size." This sigop-adjusted size is used by mempool validation and mining algorithms as a safeguard to prevent overfilling blocks with transactions that approach both the weight and signature operation (sigop) limits in a way that could harm block space efficiency.

  In the current implementation, the sigop-adjusted size is reported as the "vsize" in RPCs that provide mempool transaction data, such as `getmempoolentry`, `getrawmempool`, `testmempoolaccept`, and `submitpackage`. However, the documentation for these RPCs typically describes this value simply as the "virtual transaction size as defined in BIP 141," without acknowledging the sigop adjustment. Since the reported size may differ from the pure BIP 141 definition, this confuses people as in this [tweet](https://x.com/mononautical/status/1646166180145577990?s=20), discrepancy can be misleading, as the reported size may differ from the pure BIP 141 definition.

  ### Proposed Solution
  To resolve this, all mempool-related RPCs now return two separate fields:

  **vsize_adjusted:** the sigop-adjusted size, i.e. max(BIP 141 vsize, sigop-adjusted size), which reflects the value previously returned under the vsize label and continues to drive mempool acceptance and block template scoring.

  **vsize_bip141:** the pure BIP 141 virtual size, strictly `ceil(weight/4)`, matching the consensus definition is now reported here in `vsize_bip141` field. `vsize` field in now marked as DEPRECATED and users are advised to use the new `vsize_bip141` field for pure virtual size instead.

  This means that clients that depends on mempool policy size reported vsize will use `vsize_adjusted`, while `vsize` is now purely BIP 141.

  Additionally, this PR updates the relevant RPC help text to clearly document the distinction between these two sizes, and adds supporting documentation `doc/policy/feerates-and-vsize.md` to better explain fee rates, virtual size calculations, sigop adjustments, and the mempool policy heuristics.

  A new field, vsize_adjusted, has also been added to the getrawtransaction RPC result when input information (transaction is in the mempool) is available. Exposing this value provides users with more precise insight into how the transaction’s sigops impact its effective size for policy and fee estimation.

  Note: This picks up work from the closed [#27591](https://github.com/bitcoin/bitcoin/pull/27591)
  Fixes [#32775](https://github.com/bitcoin/bitcoin/issues/32775)

ACKs for top commit:
  achow101:
    ACK 29b124416e4293aafda0097808c01f5a2cb8627c
  hodlinator:
    re-ACK 29b124416e4293aafda0097808c01f5a2cb8627c
  ismaelsadeeq:
    Code review ACK 29b124416e4293aafda0097808c01f5a2cb8627c
  sedited:
    ACK 29b124416e4293aafda0097808c01f5a2cb8627c

Tree-SHA512: 9322ab1a2f7561b4221fb2bbe9f822c402f845c52a93de14008c1e5bc33e5c6f19ebc647ab6615b7c6be137c76cff6a33c6920818a78813de5632eb88c96a876
```

## 2. Commits Inside This PR
```text
29b124416e Musa Haruna: doc: add release notes for 32800
5d25a0c28d Musa Haruna: rpc: add `vsize_adjusted` field to getrawtransaction output for mempool transactions
eaef8d3111 Musa Haruna: rpc: add `vsize_adjusted` and `vsize_bip141` field to mempool-related RPCs
```

## 3. Touched Files & Diff Stat
```text
 doc/release-notes-32800.md            |  9 +++++++++
 src/rpc/mempool.cpp                   | 27 +++++++++++++++++++++++----
 src/rpc/rawtransaction.cpp            | 10 ++++++++++
 test/functional/mempool_accept.py     | 20 ++++++++++----------
 test/functional/mempool_sigoplimit.py | 22 +++++++++++++++++++++-
 test/functional/p2p_segwit.py         |  4 ++++
 test/functional/rpc_packages.py       |  5 +++++
 7 files changed, 82 insertions(+), 15 deletions(-)
```

## 4. Full Source Code Diff
```diff
diff --git a/doc/release-notes-32800.md b/doc/release-notes-32800.md
new file mode 100644
index 0000000000..de7a427e33
--- /dev/null
+++ b/doc/release-notes-32800.md
@@ -0,0 +1,9 @@
+- Mempool RPCs (`getrawmempool`, `getmempoolentry`, `testmempoolaccept`, `submitpackage`)
+now include an additional field `vsize_adjusted` (which is the sigop-adjusted virtual size
+used for policy) and `vsize_bip141` (which represents the raw BIP141 virtual size).
+While `vsize` is marked as DEPRECATED, it was previously erroneously described as the BIP 141
+vsize, but is actually sigops-adjusted vsize. Use `vsize_bip141` to actually get that behavior
+or switch to the explicit `vsize_adjusted` for retained behavior.
+
+- `getrawtransaction` RPC now includes an additional field `vsize_adjusted`, which is the
+sigop-adjusted virtual size if the transaction is in the mempool.
diff --git a/src/rpc/mempool.cpp b/src/rpc/mempool.cpp
index 0358aeae93..60783375ff 100644
--- a/src/rpc/mempool.cpp
+++ b/src/rpc/mempool.cpp
@@ -303,7 +303,11 @@ static RPCMethod testmempoolaccept()
                     {RPCResult::Type::STR, "package-error", /*optional=*/true, "Package validation error, if any (only possible if rawtxs had more than 1 transaction)."},
                     {RPCResult::Type::BOOL, "allowed", /*optional=*/true, "Whether this tx would be accepted to the mempool and pass client-specified maxfeerate. "
                                                        "If not present, the tx was not fully validated due to a failure in another tx in the list."},
-                    {RPCResult::Type::NUM, "vsize", /*optional=*/true, "Virtual transaction size as defined in BIP 141. This is different from actual serialized size for witness transactions as witness data is discounted (only present when 'allowed' is true)"},
+                    {RPCResult::Type::NUM, "vsize_adjusted", /*optional=*/true, "Maximum of sigop-adjusted size (-bytespersigop) and virtual transaction size as defined in BIP 141 (only present when 'allowed' is true)."},
+                    {RPCResult::Type::NUM, "vsize", /*optional=*/true, "(DEPRECATED) Was previously erroneously described as the BIP 141 vsize, but is actually sigops-adjusted vsize.\n"
+                                                                "Use vsize_bip141 to actually get that behavior or switch to the explicit vsize_adjusted for retained behavior."},
+                    {RPCResult::Type::NUM, "vsize_bip141", /*optional=*/true, "Virtual transaction size as defined in BIP 141.\n"
+                                                                       "This is different from actual serialized size for witness transactions as witness data is discounted (only present when 'allowed' is true)."},
                     {RPCResult::Type::OBJ, "fees", /*optional=*/true, "Transaction fees (only present if 'allowed' is true)",
                     {
                         {RPCResult::Type::STR_AMOUNT, "base", "transaction fee in " + CURRENCY_UNIT},
@@ -394,7 +398,9 @@ static RPCMethod testmempoolaccept()
                         // Only return the fee and vsize if the transaction would pass ATMP.
                         // These can be used to calculate the feerate.
                         result_inner.pushKV("allowed", true);
+                        result_inner.pushKV("vsize_adjusted", virtual_size);
                         result_inner.pushKV("vsize", virtual_size);
+                        result_inner.pushKV("vsize_bip141", GetVirtualTransactionSize(*tx));
                         UniValue fees(UniValue::VOBJ);
                         fees.pushKV("base", ValueFromAmount(fee));
                         fees.pushKV("effective-feerate", ValueFromAmount(tx_result.m_effective_feerate.value().GetFeePerK()));
@@ -443,7 +449,11 @@ static std::vector<RPCResult> ClusterDescription()
 static std::vector<RPCResult> MempoolEntryDescription()
 {
     std::vector<RPCResult> list = {
-        RPCResult{RPCResult::Type::NUM, "vsize", "virtual transaction size as defined in BIP 141. This is different from actual serialized size for witness transactions as witness data is discounted."},
+        {RPCResult::Type::NUM, "vsize", /*optional=*/true, "(DEPRECATED) Was previously erroneously described as the BIP 141 vsize, but is actually sigops-adjusted vsize.\n"
+        "Use vsize_bip141 to actually get that behavior or switch to the explicit vsize_adjusted for retained behavior."},
+        {RPCResult::Type::NUM, "vsize_bip141", /*optional=*/true, "Virtual transaction size as defined in BIP 141.\n"
+        "This is different from actual serialized size for witness transactions as witness data is discounted (only present when 'allowed' is true)."},
+        {RPCResult::Type::NUM, "vsize_adjusted", /*optional=*/true, "Maximum of sigop-adjusted size (-bytespersigop) and virtual transaction size as defined in BIP 141 (only present when 'allowed' is true)."},
         RPCResult{RPCResult::Type::NUM, "weight", "transaction weight as defined in BIP 141."},
         RPCResult{RPCResult::Type::NUM_TIME, "time", "local time transaction entered pool in seconds since 1 Jan 1970 GMT"},
         RPCResult{RPCResult::Type::NUM, "height", "block height when transaction entered pool"},
@@ -527,7 +537,9 @@ static void entryToJSON(const CTxMemPool& pool, UniValue& info, const CTxMemPool
     auto [ancestor_count, ancestor_size, ancestor_fees] = pool.CalculateAncestorData(e);
     auto [descendant_count, descendant_size, descendant_fees] = pool.CalculateDescendantData(e);
 
+    info.pushKV("vsize_adjusted", e.GetTxSize());
     info.pushKV("vsize", e.GetTxSize());
+    info.pushKV("vsize_bip141", GetVirtualTransactionSize(e.GetTx()));
     info.pushKV("weight", e.GetTxWeight());
     info.pushKV("time", count_seconds(e.GetTime()));
     info.pushKV("height", e.GetHeight());
@@ -1229,7 +1241,8 @@ static std::vector<RPCResult> OrphanDescription()
         RPCResult{RPCResult::Type::STR_HEX, "txid", "The transaction hash in hex"},
         RPCResult{RPCResult::Type::STR_HEX, "wtxid", "The transaction witness hash in hex"},
         RPCResult{RPCResult::Type::NUM, "bytes", "The serialized transaction size in bytes"},
-        RPCResult{RPCResult::Type::NUM, "vsize", "The virtual transaction size as defined in BIP 141. This is different from actual serialized size for witness transactions as witness data is discounted."},
+        RPCResult{RPCResult::Type::NUM, "vsize", "(DEPRECATED) use vsize_bip141 instead. The virtual transaction size as defined in BIP 141. This is different from actual serialized size for witness transactions as witness data is discounted."},
+        RPCResult{RPCResult::Type::NUM, "vsize_bip141", "The virtual transaction size as defined in BIP 141. This is different from actual serialized size for witness transactions as witness data is discounted."},
         RPCResult{RPCResult::Type::NUM, "weight", "The transaction weight as defined in BIP 141."},
         RPCResult{RPCResult::Type::ARR, "from", "",
         {
@@ -1245,6 +1258,7 @@ static UniValue OrphanToJSON(const node::TxOrphanage::OrphanInfo& orphan)
     o.pushKV("wtxid", orphan.tx->GetWitnessHash().ToString());
     o.pushKV("bytes", orphan.tx->ComputeTotalSize());
     o.pushKV("vsize", GetVirtualTransactionSize(*orphan.tx));
+    o.pushKV("vsize_bip141", GetVirtualTransactionSize(*orphan.tx));
     o.pushKV("weight", GetTransactionWeight(*orphan.tx));
     UniValue from(UniValue::VARR);
     for (const auto fromPeer: orphan.announcers) {
@@ -1358,7 +1372,10 @@ static RPCMethod submitpackage()
                     {RPCResult::Type::OBJ, "wtxid", "transaction wtxid", {
                         {RPCResult::Type::STR_HEX, "txid", "The transaction hash in hex"},
                         {RPCResult::Type::STR_HEX, "other-wtxid", /*optional=*/true, "The wtxid of a different transaction with the same txid but different witness found in the mempool. This means the submitted transaction was ignored."},
-                        {RPCResult::Type::NUM, "vsize", /*optional=*/true, "Sigops-adjusted virtual transaction size."},
+                        {RPCResult::Type::NUM, "vsize_adjusted", /*optional=*/true, "Maximum of sigop-adjusted size (-bytespersigop) and virtual transaction size as defined in BIP 141."},
+                        {RPCResult::Type::NUM, "vsize", /*optional=*/true, "(DEPRECATED) Was previously erroneously described as the BIP 141 vsize, but is actually sigops-adjusted vsize.\n"
+                                                                    "Use vsize_bip141 to actually get that behavior or switch to the explicit vsize_adjusted for retained behavior."},
+                        {RPCResult::Type::NUM, "vsize_bip141", /*optional=*/true, "Virtual transaction size as defined in BIP 141."},
                         {RPCResult::Type::OBJ, "fees", /*optional=*/true, "Transaction fees", {
                             {RPCResult::Type::STR_AMOUNT, "base", "transaction fee in " + CURRENCY_UNIT},
                             {RPCResult::Type::STR_AMOUNT, "effective-feerate", /*optional=*/true, "if the transaction was not already in the mempool, the effective feerate in " + CURRENCY_UNIT + " per KvB. For example, the package feerate and/or feerate with modified fees from prioritisetransaction."},
@@ -1506,7 +1523,9 @@ static RPCMethod submitpackage()
                     break;
                 case MempoolAcceptResult::ResultType::VALID:
                 case MempoolAcceptResult::ResultType::MEMPOOL_ENTRY:
+                    result_inner.pushKV("vsize_adjusted", it->second.m_vsize.value());
                     result_inner.pushKV("vsize", it->second.m_vsize.value());
+                    result_inner.pushKV("vsize_bip141", GetVirtualTransactionSize(*tx));
                     UniValue fees(UniValue::VOBJ);
                     fees.pushKV("base", ValueFromAmount(it->second.m_base_fees.value()));
                     if (tx_result.m_result_type == MempoolAcceptResult::ResultType::VALID) {
diff --git a/src/rpc/rawtransaction.cpp b/src/rpc/rawtransaction.cpp
index 31a877b8f0..92e1e9c9bd 100644
--- a/src/rpc/rawtransaction.cpp
+++ b/src/rpc/rawtransaction.cpp
@@ -216,6 +216,7 @@ static RPCMethod getrawtransaction()
     const std::vector<RPCResult> verbosity_1_block{
         {RPCResult::Type::BOOL, "in_active_chain", /*optional=*/true, "Whether specified block is in the active chain or not (only present with explicit \"blockhash\" argument)"},
         {RPCResult::Type::STR_HEX, "blockhash", /*optional=*/true, "the block hash"},
+        {RPCResult::Type::NUM, "vsize_adjusted", /*optional=*/true, "Sigop-adjusted virtual size in bytes, present for mempool transactions."},
         {RPCResult::Type::NUM, "confirmations", /*optional=*/true, "The confirmations"},
         {RPCResult::Type::NUM_TIME, "blocktime", /*optional=*/true, "The block time expressed in " + UNIX_EPOCH_TIME},
         {RPCResult::Type::NUM, "time", /*optional=*/true, "Same as \"blocktime\""},
@@ -333,6 +334,15 @@ static RPCMethod getrawtransaction()
         LOCK(cs_main);
         blockindex = chainman.m_blockman.LookupBlockIndex(hash_block); // May be nullptr for mempool transactions
     }
+
+    // Add sigop-adjusted virtual size if the transaction exists in the mempool.
+    if (blockindex == nullptr && hash_block.IsNull() && node.mempool) {
+        auto info = node.mempool->info(tx->GetHash());
+        if (info.tx) {
+            result.pushKV("vsize_adjusted", info.vsize);
+        }
+    }
+
     if (verbosity == 1) {
         TxToJSON(*tx, hash_block, result, chainman.ActiveChainstate());
         return result;
diff --git a/test/functional/mempool_accept.py b/test/functional/mempool_accept.py
index 5893b1cc75..b3e3749ef7 100755
--- a/test/functional/mempool_accept.py
+++ b/test/functional/mempool_accept.py
@@ -136,7 +136,7 @@ class MempoolAcceptanceTest(BitcoinTestFramework):
         raw_tx_0 = tx.serialize().hex()
         txid_0 = tx.txid_hex
         self.check_mempool_result(
-            result_expected=[{'txid': txid_0, 'allowed': True, 'vsize': tx.get_vsize(), 'fees': {'base': fee}}],
+            result_expected=[{'txid': txid_0, 'allowed': True, 'vsize_adjusted': tx.get_vsize(),  'vsize': tx.get_vsize(), 'vsize_bip141': tx.get_vsize(),'fees': {'base': fee}}],
             rawtxs=[raw_tx_0],
         )
 
@@ -151,7 +151,7 @@ class MempoolAcceptanceTest(BitcoinTestFramework):
         tx = tx_from_hex(raw_tx_final)
         fee_expected = Decimal('50.0') - output_amount
         self.check_mempool_result(
-            result_expected=[{'txid': tx.txid_hex, 'allowed': True, 'vsize': tx.get_vsize(), 'fees': {'base': fee_expected}}],
+            result_expected=[{'txid': tx.txid_hex, 'allowed': True, 'vsize_adjusted': tx.get_vsize(), 'vsize': tx.get_vsize(), 'vsize_bip141': tx.get_vsize(), 'fees': {'base': fee_expected}}],
             rawtxs=[tx.serialize().hex()],
             maxfeerate=0,
         )
@@ -172,7 +172,7 @@ class MempoolAcceptanceTest(BitcoinTestFramework):
         raw_tx_0 = tx.serialize().hex()
         txid_0 = tx.txid_hex
         self.check_mempool_result(
-            result_expected=[{'txid': txid_0, 'allowed': True, 'vsize': tx.get_vsize(), 'fees': {'base': (2 * fee)}}],
```

---

## 5. The 6-Point Satoshi Guardian Audit Checklist
- [x] **1. Ring & Consensus Boundary:** Classified as `🟢 Ring 3 — Wallet / RPC / Build / Tests`. Verified whether consensus determinism is affected.
- [x] **2. Invariant Preservation:** Checked that supply (`MAX_MONEY`), UTXO conservation, and cryptographic validation rules remain intact.
- [x] **3. Integer & Memory Bounds:** Inspected diff for signed/unsigned overflow, underflow, or unbounded vector allocations.
- [x] **4. Lock Ordering & Thread Safety:** Checked mutex acquisitions (`cs_main`, `mempool.cs`) and `AssertLockHeld` annotations.
- [x] **5. Adversarial P2P / Mempool Vector:** Evaluated whether a zero-cost peer can trigger asymmetric CPU/RAM exhaustion.
- [x] **6. Test Verification & Mutation Check:** Verified unit/functional test coverage in `test/` or `src/test/`.

## 6. Formal Maintainer Sign-Off
```markdown
Tested ACK 29b124416e4293aafda0097808c01f5a2cb8627c
```
