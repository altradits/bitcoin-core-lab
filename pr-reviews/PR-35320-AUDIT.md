# Audit: bitcoin/bitcoin#35320 `key: validate BIP32 seed length in CExtKey::SetSeed`

> **Study notes, auto-generated (lab.sh pr-audit).** The diff and metadata below were collected by a
> script; the risk ring was assigned automatically and may be wrong. Sections 5–6 are blank for you
> to complete after your own review. See [`README.md`](./README.md) for known issues.

- **PR Title:** Merge bitcoin/bitcoin#35320: key: validate BIP32 seed length in CExtKey::SetSeed
- **Concentric Risk Ring:** **🟢 Ring 3 — Wallet / RPC / Build / Tests**
- **Merge Commit:** `26b730cdbf2c77c12f684fd50bd376212b725394`
- **Audited PR Tip Commit:** `2cf9d79d84cb485e31e2d78a5744c1e4dc5f5f44`
- **Auditor:** Stanley Chege Thuita ([@altradits](https://github.com/altradits))
- **Checked:** 2026-11-06

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

## Accuracy note (2026-11-06)

Upstream enforces the bound with `Assert` (a programming invariant
that aborts debug builds), not a runtime error. The Bug Dojo mission
models the same bound as a returned Go error, which fits Go
conventions. All other details (commit, diff, ACKs) verified against
github.com.
