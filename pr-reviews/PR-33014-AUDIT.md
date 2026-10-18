# 🛡️ Guardian Security & Consensus Audit: `bitcoin/bitcoin#33014`

- **PR Title:** Merge bitcoin/bitcoin#33014: rpc: Fix internal bug in descriptorprocesspsbt when encountering invalid signatures
- **Concentric Risk Ring:** **🟢 Ring 3 — Wallet / RPC / Build / Tests**
- **Merge Commit:** `5311b15727f2f282274472184185423e441abd85`
- **Audited PR Tip Commit:** `7e19ce200b2e65770907a818b02e4ec3da9c5374`
- **Auditor:** Stanley Chege Thuita ([@altradits](https://github.com/altradits))

---

## 1. Why This PR Was Merged (Motivation & Maintainer Context)
```text
7e19ce200b2e65770907a818b02e4ec3da9c5374 rpc: Fix descriptorprocesspsbt internal bug on invalid signatures (b-l-u-e)

Pull request description:

  Fixes #32849
  descriptorprocesspsbt crashes with an internal bug assertion when given a PSBT whose inputs looked “finalized” that is non-empty final_script_sig / witness but whose signatures did not verify like invalid Schnorr bytes with unusual sighash combinations such as SIGHASH_SINGLE | ANYONECANPAY.

  Completeness was inferred with PSBTInputSigned, which only checks that final fields are present, not that they pass script verification. That let the RPC treat the PSBT as complete and call FinalizeAndExtractPSBT, where a failing invariant surfaced as CHECK_NONFATAL instead of a normal incomplete outcome.

  This PR determines complete the same way as the wallet path: after ProcessPSBT, it recomputes PrecomputedTransactionData and sets complete only if every input passes PSBTInputSignedAndVerified.
  Invalid signatures then yield complete: false and no hex, without going through the finalize path that asserted.

ACKs for top commit:
  achow101:
    ACK 7e19ce200b2e65770907a818b02e4ec3da9c5374
  rkrux:
    lgtm re-ACK 7e19ce200b2e65770907a818b02e4ec3da9c5374

Tree-SHA512: c534fb5bd3401ee3ac0bc27eaedaaaaf23e5e8510ed9b96a747bb0e41e2bd3d2031b6b08e933e139bb426e97bd05fab6e91397205f4be1db9d17630eea49a8bf
```

## 2. Commits Inside This PR
```text
7e19ce200b b-l-u-e: rpc: Fix descriptorprocesspsbt internal bug on invalid signatures
```

## 3. Touched Files & Diff Stat
```text
 src/rpc/rawtransaction.cpp             |  8 ++++---
 test/functional/rpc_psbt.py            | 44 ++++++++++++++++++++++++++++++++++
 test/functional/test_framework/util.py |  4 ++++
 3 files changed, 53 insertions(+), 3 deletions(-)
```

## 4. Full Source Code Diff
```diff
diff --git a/src/rpc/rawtransaction.cpp b/src/rpc/rawtransaction.cpp
index 396768edb7..5de3b2ab4e 100644
--- a/src/rpc/rawtransaction.cpp
+++ b/src/rpc/rawtransaction.cpp
@@ -2112,10 +2112,12 @@ RPCMethod descriptorprocesspsbt()
         sighash_type,
         finalize);
 
-    // Check whether or not all of the inputs are now signed
+    // Check whether or not all of the inputs are now correctly signed
     bool complete = true;
-    for (const auto& input : psbtx.inputs) {
-        complete &= PSBTInputSigned(input);
+    const std::optional<PrecomputedTransactionData> txdata_opt{PrecomputePSBTData(psbtx)};
+    const PrecomputedTransactionData txdata{*CHECK_NONFATAL(txdata_opt)};
+    for (unsigned int i = 0; i < psbtx.inputs.size(); ++i) {
+        complete = complete && PSBTInputSignedAndVerified(psbtx, i, &txdata);
     }
 
     DataStream ssTx{};
diff --git a/test/functional/rpc_psbt.py b/test/functional/rpc_psbt.py
index 4703ee3be1..016ed8f1e6 100755
--- a/test/functional/rpc_psbt.py
+++ b/test/functional/rpc_psbt.py
@@ -36,6 +36,7 @@ from test_framework.psbt import (
     PSBT_IN_MUSIG2_PUB_NONCE,
     PSBT_IN_NON_WITNESS_UTXO,
     PSBT_IN_WITNESS_UTXO,
+    PSBT_IN_FINAL_SCRIPTWITNESS,
     PSBT_OUT_MUSIG2_PARTICIPANT_PUBKEYS,
     PSBT_OUT_TAP_TREE,
     PSBT_OUT_SCRIPT,
@@ -52,6 +53,7 @@ from test_framework.util import (
     assert_raises_rpc_error,
     find_vout_for_address,
     wallet_importprivkey,
+    bitflipper
 )
 from test_framework.wallet_util import (
     calculate_input_weight,
@@ -469,6 +471,47 @@ class PSBTTest(BitcoinTestFramework):
         assert_raises_rpc_error(-8, "The PSBT version can only be 2 or 0", self.nodes[0].converttopsbt, hexstring=rawtx, psbt_version=1)
         assert_raises_rpc_error(-8, "The PSBT version can only be 2 or 0", self.nodes[0].psbtbumpfee, txid=tobump, psbt_version=1)
 
+    def test_psbt_with_invalid_signature(self):
+        self.log.info("Test descriptorprocesspsbt with invalid signature in signed PSBT")
+
+        def_wallet = self.nodes[0].get_wallet_rpc(self.default_wallet_name)
+        outputs = [{def_wallet.getnewaddress(address_type="bech32m"): 1}]
+        def_wallet.send(outputs)
+        self.generate(self.nodes[0], 1)
+
+        utxos = [utxo for utxo in def_wallet.listunspent() if utxo["desc"].startswith("tr")]
+        unsigned_psbt = def_wallet.walletcreatefundedpsbt(utxos, [{def_wallet.getnewaddress(): 0.5}])["psbt"]
+        descs = [desc for desc in def_wallet.listdescriptors(True)["descriptors"] if desc["desc"].startswith("tr")]
+
+        # Unload the wallet to avoid using wallet RPC internals in descriptorprocesspsbt.
+        def_wallet.unloadwallet()
+
+        result = self.nodes[0].descriptorprocesspsbt(psbt=unsigned_psbt, descriptors=descs, finalize=True)
+        assert_equal(result["complete"], True)
+        assert_equal("hex" in result, True)
+
+        valid_sig_psbt = result["psbt"]
+        flawed_psbt = PSBT.from_base64(valid_sig_psbt)
+        valid_witness = flawed_psbt.i[0].map.get(PSBT_IN_FINAL_SCRIPTWITNESS)
+        # The witness format is [num_items: CompactSize] [item1_len: CompactSize] [item1_data] ...
+        # For taproot key-path spend [0x01] [0x40 or 0x41] [64 or 65 byte signature].
+        # Skip the first 2 prefix bytes and flip a bit in the signature bytes only.
+        assert_equal(valid_witness[0], 1)
+        prefix = valid_witness[:2]
+        sig_len = valid_witness[1]
+        signature = valid_witness[2:2 + sig_len]
+        invalid_sig = bitflipper(signature)
+        invalid_witness = prefix + invalid_sig + valid_witness[2 + sig_len:]
+        flawed_psbt.i[0].map[PSBT_IN_FINAL_SCRIPTWITNESS] = invalid_witness
+        invalid_sig_psbt = flawed_psbt.to_base64()
+
+        result = self.nodes[0].descriptorprocesspsbt(psbt=invalid_sig_psbt, descriptors=descs, finalize=True)
+        assert_equal(result["complete"], False)
+        assert_equal("hex" in result, False)
+
+        # Load the default wallet back for later test cases.
+        self.nodes[0].loadwallet(self.default_wallet_name)
+
     def run_test(self):
         # Create and fund a raw tx for sending 10 BTC
         psbtx1 = self.nodes[0].walletcreatefundedpsbt([], {self.nodes[2].getnewaddress():10})['psbt']
@@ -1362,6 +1405,7 @@ class PSBTTest(BitcoinTestFramework):
         self.test_psbt_named_parameter_handling()
         self.test_psbt_roundtrip()
         self.test_psbt_version()
+        self.test_psbt_with_invalid_signature()
 
 if __name__ == '__main__':
     PSBTTest(__file__).main()
diff --git a/test/functional/test_framework/util.py b/test/functional/test_framework/util.py
index 3e7e6dd97a..7217f4afab 100644
--- a/test/functional/test_framework/util.py
+++ b/test/functional/test_framework/util.py
@@ -759,3 +759,7 @@ def is_dir_writable(dir_path: pathlib.Path) -> bool:
         return True
     except OSError:
         return False
+
+def bitflipper(input):
+    assert isinstance(input, bytes)
+    return (int.from_bytes(input, "little") ^ (1 << random.randrange(len(input) * 8))).to_bytes(len(input), "little")
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
Tested ACK 7e19ce200b2e65770907a818b02e4ec3da9c5374
```
