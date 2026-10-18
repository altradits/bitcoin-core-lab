# 🛡️ Guardian Security & Consensus Audit: `bitcoin/bitcoin#35320`

- **PR Title:** Merge bitcoin/bitcoin#35320: key: validate BIP32 seed length in CExtKey::SetSeed
- **Concentric Risk Ring:** **🟢 Ring 3 — Wallet / RPC / Build / Tests**
- **Merge Commit:** `26b730cdbf2c77c12f684fd50bd376212b725394`
- **Audited PR Tip Commit:** `2cf9d79d84cb485e31e2d78a5744c1e4dc5f5f44`
- **Auditor:** Stanley Chege Thuita ([@altradits](https://github.com/altradits))

---

## 1. Why This PR Was Merged (Motivation & Maintainer Context)
```text
2cf9d79d84cb485e31e2d78a5744c1e4dc5f5f44 key: validate BIP32 seed length in CExtKey::SetSeed (Muhammad)

Pull request description:

  BIP32 specifies that the seed must be between 128 and 512 bits (16 to 64 bytes). CExtKey::SetSeed currently accepts any length, which could result in weak master keys being generated.
  Add an Assert at the start of SetSeed to enforce the valid seed length range as a programming invariant. The existing BIP32 test vectors already provide sufficient coverage of valid seed lengths.

  To test:

  > cmake --build build -j --target test_bitcoin
  ./build/bin/test_bitcoin --run_test=bip32_tests

  Fixes #35308

ACKs for top commit:
  achow101:
    ACK 2cf9d79d84cb485e31e2d78a5744c1e4dc5f5f44
  sedited:
    ACK 2cf9d79d84cb485e31e2d78a5744c1e4dc5f5f44

Tree-SHA512: 0ac44f8a464172b465834e1b3edf457fc8a09eeaa89cdfb1286af577d3c90d75627af8b5c5edd66232d45c60812ebc7f6f402db6f804a56f727353b2bdca7c19
```

## 2. Commits Inside This PR
```text
2cf9d79d84 Muhammad: key: validate BIP32 seed length in CExtKey::SetSeed
```

## 3. Touched Files & Diff Stat
```text
 src/key.cpp | 1 +
 1 file changed, 1 insertion(+)
```

## 4. Full Source Code Diff
```diff
diff --git a/src/key.cpp b/src/key.cpp
index cc03df1cd9..7b2df88f07 100644
--- a/src/key.cpp
+++ b/src/key.cpp
@@ -367,6 +367,7 @@ bool CExtKey::Derive(CExtKey &out, unsigned int _nChild) const {
 
 void CExtKey::SetSeed(std::span<const std::byte> seed)
 {
+    Assert(16 <= seed.size() && seed.size() <= 64);
     static const unsigned char hashkey[] = {'B','i','t','c','o','i','n',' ','s','e','e','d'};
     std::vector<unsigned char, secure_allocator<unsigned char>> vout(64);
     CHMAC_SHA512{hashkey, sizeof(hashkey)}.Write(UCharCast(seed.data()), seed.size()).Finalize(vout.data());
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
Tested ACK 2cf9d79d84cb485e31e2d78a5744c1e4dc5f5f44
```
