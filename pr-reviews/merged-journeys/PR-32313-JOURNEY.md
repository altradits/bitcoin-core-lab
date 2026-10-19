# Merged PR #32313 Review Journey: `coins: fix `cachedCoinsUsage` accounting in `CCoinsViewCache``

- **Author:** `@l0rinc`
- **Merged At:** `2025-10-15T13:48:22Z`
- **Final Merged Head Commit:** `24d861da7894add47747eff69dd3fc71fbcdd7d0`
- **Local Git Branch in `/Users/mac/bitcoin`:** `pr-32313` (`git -C /Users/mac/bitcoin show pr-32313`)
- **Core Lesson for Reviewers:** How @andrewtoth and @maflcko reviewed a critical UTXO cache memory-accounting fix (`CCoinsViewCache`), spotting a redundant subtraction on a newly created empty coin and keeping unrelated sanitizer changes out of the PR.

---

## 1. Original PR Description

```text
### Summary

This PR fixes `cachedCoinsUsage` accounting bugs in `CCoinsViewCache` that caused UBSan `unsigned-integer-overflow` violations during testing. The issues stemmed from incorrect decrement timing in `AddCoin()`, unconditional reset in `Flush()` on failure, and incorrect increment in `EmplaceCoinInternalDANGER()` when insertion fails.

### Problems Fixed

**1. `AddCoin()` underflow on exception**
- Previously decremented `cachedCoinsUsage` *before* the `possible_overwrite` validation
- If validation threw, the map entry remained unchanged but counter was decremented
- This corrupted accounting and later caused underflow
- **Impact**: Test-only in current codebase, but unsound accounting that could affect future changes

**2. `Flush()` accounting drift on failure**
- Unconditionally reset `cachedCoinsUsage` to 0, even when `BatchWrite()` failed
- Left the map populated while the counter read zero
- **Impact**: Test-only (production `BatchWrite()` returns `true`), but broke accounting consistency

**3. Cursor redundant usage tracking**
- `CoinsViewCacheCursor::NextAndMaybeErase()` subtracted usage when erasing spent entries
- However, `SpendCoin()` already decremented and cleared the `scriptPubKey`, leaving `DynamicMemoryUsage()` at 0
- **Impact**: Redundant code that obscured actual accounting behavior

**4. `EmplaceCoinInternalDANGER()` double-counting**
- Incremented `cachedCoinsUsage` even when `try_emplace` did not insert (duplicate key)
- Inflated the counter on duplicate attempts
- **Impact**: Mostly test-reachable (AssumeUTXO doesn't overwrite in production), but incorrect accounting

### Testing

To reproduce the historical UBSan failures on the referenced baseline and to verify the fix, run:
```
MAKEJOBS="-j$(nproc)" FILE_ENV="./ci/test/00_setup_env_native_fuzz.sh" ./ci/test_run_all.sh
```

The change was tested with the related unit and fuzz test, and asserted before/after each `cachedCoinsUsage` change (in production code and fuzz) that the calculations are still correct by recalculating them from scratch.

<details>
<summary>Details</summary>

```C++
bool CCoinsViewCache::CacheUsageValid() const
{
    size_t actual{0};
    for (auto& entry : cacheCoins | std::views::values) actual += entry.coin.DynamicMemoryUsage();
    return actual == cachedCoinsUsage;
}
```
or
```patch
diff --git a/src/coins.cpp b/src/coins.cpp
--- a/src/coins.cpp	(revision fd3b1a7f4bb2ac527f23d4eb4cfa40a3215906e5)
+++ b/src/coins.cpp	(revision 872a05633bfdbd06ad82190d7fe34b42d13ebfe9)
@@ -96,6 +96,7 @@
         fresh = !it->second.IsDirty();
     }
     if (!inserted) {
+        Assert(cachedCoinsUsage >= it->second.coin.DynamicMemoryUsage());
         cachedCoinsUsage -= it->second.coin.DynamicMemoryUsage();
     }
     it->second.coin = std::move(coin);
@@ -133,6 +134,7 @@
 bool CCoinsViewCache::SpendCoin(const COutPoint &outpoint, Coin* moveout) {
     CCoinsMap::iterator it = FetchCoin(outpoint);
     if (it == cacheCoins.end()) return false;
+    Assert(cachedCoinsUsage >= it->second.coin.DynamicMemoryUsage());
     cachedCoinsUsage -= it->second.coin.DynamicMemoryUsage();
     TRACEPOINT(utxocache, spent,
            outpoint.hash.data(),
@@ -226,10 +228,12 @@
             if (itUs->second.IsFresh() && it->second.coin.IsSpent()) {
                 // The grandparent cache does not have an entry, and the coin
                 // has been spent. We can just delete it from the parent cache.
+                Assert(cachedCoinsUsage >= itUs->second.coin.DynamicMemoryUsage());
                 cachedCoinsUsage -= itUs->second.coin.DynamicMemoryUsage();
                 cacheCoins.erase(itUs);
             } else {
                 // A normal modification.
+                Assert(cachedCoinsUsage >= itUs->second.coin.DynamicMemoryUsage());
                 cachedCoinsUsage -= itUs->second.coin.DynamicMemoryUsage();
                 if (cursor.WillErase(*it)) {
                     // Since this entry will be erased,
@@ -279,6 +283,7 @@
 {
     CCoinsMap::iterator it = cacheCoins.find(hash);
     if (it != cacheCoins.end() && !it->second.IsDirty() && !it->second.IsFresh()) {
+        Assert(cachedCoinsUsage >= it->second.coin.DynamicMemoryUsage());
         cachedCoinsUsage -= it->second.coin.DynamicMemoryUsage();
         TRACEPOINT(utxocache, uncache,
                hash.hash.data(),
```

</details>
```

## 2. Commit & Diff Stat (`git show --stat pr-32313`)

```text
commit 24d861da7894add47747eff69dd3fc71fbcdd7d0
Author: Lőrinc <pap.lorinc@gmail.com>
Date:   Fri Apr 18 11:24:30 2025 +0200

    coins: only adjust `cachedCoinsUsage` on `EmplaceCoinInternalDANGER` insert
    
    `EmplaceCoinInternalDANGER()` incremented `cachedCoinsUsage` even when `try_emplace` did not insert (duplicate key), inflating the counter.
    This is mostly reachable in tests today since `AssumeUTXO` does not overwrite.
    
    Increment only on successful insert, and capture `coin.DynamicMemoryUsage()` before the move so accounting uses the correct value.
    
    Fuzz: add an `EmplaceCoinInternalDANGER` path to exercise insert-only accounting.
    Unit test: emplace two different coins at the same outpoint (with different `DynamicMemoryUsage()`), verify `SelfTest()` passes and `AccessCoin(outpoint)` returns the first coin.
    
    Co-authored-by: Andrew Toth <andrewstoth@gmail.com>
    Co-authored-by: w0xlt <woltx@protonmail.com>

 src/coins.cpp                |  7 +++++--
 src/test/coins_tests.cpp     | 18 ++++++++++++++++++
 src/test/fuzz/coins_view.cpp | 16 ++++++++++------
 3 files changed, 33 insertions(+), 8 deletions(-)
```

## 3. Inline Code Review Comments (Where Reviewers Improved the Code)

### `@andrewtoth` on `src/coins.cpp:82` (2025-04-20T17:36:47Z)

```diff
@@ -76,13 +76,13 @@ void CCoinsViewCache::AddCoin(const COutPoint &outpoint, Coin&& coin, bool possi
     bool inserted;
     std::tie(it, inserted) = cacheCoins.emplace(std::piecewise_construct, std::forward_as_tuple(outpoint), std::tuple<>());
     bool fresh = false;
+    if (!possible_overwrite && !it->second.coin.IsSpent()) { // check before any other partial state change
+        throw std::logic_error("Attempted to overwrite an unspent coin (when possible_overwrite is false)");
+    }
     if (!inserted) {
```

> Would it be simpler to just move this `if` block below the `if` block that throws, instead of pulling the throw out?

### `@andrewtoth` on `src/coins.cpp:115` (2025-04-20T17:41:56Z)

```diff
 
-void CCoinsViewCache::EmplaceCoinInternalDANGER(COutPoint&& outpoint, Coin&& coin) {
-    cachedCoinsUsage += coin.DynamicMemoryUsage();
-    auto [it, inserted] = cacheCoins.try_emplace(std::move(outpoint), std::move(coin));
-    if (inserted) CCoinsCacheEntry::SetDirty(*it, m_sentinel);
+void CCoinsViewCache::EmplaceCoinInternalDANGER(COutPoint&& outpoint, Coin&& coin)
+{
+    auto [it, inserted] = cacheCoins.try_emplace(std::move(outpoint));
```

> I think this would be simpler if we kept the original behavior of moving the `coin` here as well, and then only increment the `cachedCoinsUsage` if the coin is inserted.
> 
> In practice it's not possible to get `!inserted` unless the assume utxo payload was generated incorrectly.

### `@andrewtoth` on `src/coins.cpp:204` (2025-04-20T17:43:18Z)

```diff
@@ -195,6 +201,7 @@ bool CCoinsViewCache::BatchWrite(CoinsViewCacheCursor& cursor, const uint256 &ha
                 // and mark it as dirty.
                 itUs = cacheCoins.try_emplace(it->first).first;
                 CCoinsCacheEntry& entry{itUs->second};
+                cachedCoinsUsage -= entry.coin.DynamicMemoryUsage();
```

> The entry has an empty coin here, it was just created. So this is just subtracting zero.

### `@l0rinc` on `src/coins.cpp:82` (2025-04-20T20:57:42Z)

```diff
@@ -76,13 +76,13 @@ void CCoinsViewCache::AddCoin(const COutPoint &outpoint, Coin&& coin, bool possi
     bool inserted;
     std::tie(it, inserted) = cacheCoins.emplace(std::piecewise_construct, std::forward_as_tuple(outpoint), std::tuple<>());
     bool fresh = false;
+    if (!possible_overwrite && !it->second.coin.IsSpent()) { // check before any other partial state change
+        throw std::logic_error("Attempted to overwrite an unspent coin (when possible_overwrite is false)");
+    }
     if (!inserted) {
```

> If you think that's better, I don't mind - done

### `@l0rinc` on `src/coins.cpp:115` (2025-04-20T20:57:48Z)

```diff
 
-void CCoinsViewCache::EmplaceCoinInternalDANGER(COutPoint&& outpoint, Coin&& coin) {
-    cachedCoinsUsage += coin.DynamicMemoryUsage();
-    auto [it, inserted] = cacheCoins.try_emplace(std::move(outpoint), std::move(coin));
-    if (inserted) CCoinsCacheEntry::SetDirty(*it, m_sentinel);
+void CCoinsViewCache::EmplaceCoinInternalDANGER(COutPoint&& outpoint, Coin&& coin)
+{
+    auto [it, inserted] = cacheCoins.try_emplace(std::move(outpoint));
```

> > In practice it's not possible to get !inserted unless the assume utxo payload was generated incorrectly.
> 
> As far as I can see that's not a guarantee, but I've also noted it in the commit message that currently this is the case.
> 
> > kept the original behavior of moving the coin here as well
> 
> Sure, if you think that's better - changed!

### `@l0rinc` on `src/coins.cpp:204` (2025-04-20T20:57:58Z)

```diff
@@ -195,6 +201,7 @@ bool CCoinsViewCache::BatchWrite(CoinsViewCacheCursor& cursor, const uint256 &ha
                 // and mark it as dirty.
                 itUs = cacheCoins.try_emplace(it->first).first;
                 CCoinsCacheEntry& entry{itUs->second};
+                cachedCoinsUsage -= entry.coin.DynamicMemoryUsage();
```

> Thanks, I'll add an assert in that case to explain why this branch wasn't symmetric with the other one.

### `@maflcko` on `test/sanitizer_suppressions/ubsan:54` (2025-04-29T20:46:02Z)

```diff
@@ -46,9 +46,6 @@ unsigned-integer-overflow:CRollingBloomFilter::insert
 unsigned-integer-overflow:RollingBloomHash
 unsigned-integer-overflow:CCoinsViewCache::AddCoin
 unsigned-integer-overflow:CCoinsViewCache::BatchWrite
-unsigned-integer-overflow:CCoinsViewCache::DynamicMemoryUsage
-unsigned-integer-overflow:CCoinsViewCache::SpendCoin
-unsigned-integer-overflow:CCoinsViewCache::Uncache
```

> it would be better to file this separately and explain why it isn't needed (or rather since when)

### `@l0rinc` on `test/sanitizer_suppressions/ubsan:54` (2025-04-30T07:54:26Z)

```diff
@@ -46,9 +46,6 @@ unsigned-integer-overflow:CRollingBloomFilter::insert
 unsigned-integer-overflow:RollingBloomHash
 unsigned-integer-overflow:CCoinsViewCache::AddCoin
 unsigned-integer-overflow:CCoinsViewCache::BatchWrite
-unsigned-integer-overflow:CCoinsViewCache::DynamicMemoryUsage
-unsigned-integer-overflow:CCoinsViewCache::SpendCoin
-unsigned-integer-overflow:CCoinsViewCache::Uncache
```

> They were introduced in https://github.com/bitcoin/bitcoin/pull/28865/files#diff-bca63b54ad7fcc2df12f3237fd8775810c1b849c49110f702920655778fcc248R45-R49, I don't see any concrete explanation for what the problem was - and couldn't reproduce any fuzzing problem when I've removed these.
> @fanquake, can you help us out here, do you remember why these were added?

### `@l0rinc` on `test/sanitizer_suppressions/ubsan:54` (2025-04-30T12:51:05Z)

```diff
@@ -46,9 +46,6 @@ unsigned-integer-overflow:CRollingBloomFilter::insert
 unsigned-integer-overflow:RollingBloomHash
 unsigned-integer-overflow:CCoinsViewCache::AddCoin
 unsigned-integer-overflow:CCoinsViewCache::BatchWrite
-unsigned-integer-overflow:CCoinsViewCache::DynamicMemoryUsage
-unsigned-integer-overflow:CCoinsViewCache::SpendCoin
-unsigned-integer-overflow:CCoinsViewCache::Uncache
```

> I ran the following on Linux for `a1fe87eb668e8a1eeeef335951547882b5fb52d8`:
> 
> ```bash
> cmake --preset=libfuzzer && cmake --build build_fuzz && \
>   FUZZ=coin_grinder build_fuzz/bin/fuzz -runs=500000 && \
>   FUZZ=coin_grinder_is_optimal build_fuzz/bin/fuzz -runs=500000 && \
>   FUZZ=coincontrol build_fuzz/bin/fuzz -runs=500000 && \
>   FUZZ=coins_deserialize build_fuzz/bin/fuzz -runs=500000 && \
>   FUZZ=coins_view build_fuzz/bin/fuzz -runs=500000 && \
>   FUZZ=coinscache_sim build_fuzz/bin/fuzz -runs=500000 && \
>   FUZZ=coinselection_bnb build_fuzz/bin/fuzz -runs=500000 && \
>   FUZZ=coinselection_knapsack build_fuzz/bin/fuzz -runs=500000 && \
>   FUZZ=coinselection_srd build_fuzz/bin/fuzz -runs=500000
> ```
> 
> They all passed (actually ran a few until `-runs=1000000` but got bored at the end).
> Am I missing anything important here?

### `@maflcko` on `test/sanitizer_suppressions/ubsan:54` (2025-04-30T13:31:55Z)

```diff
@@ -46,9 +46,6 @@ unsigned-integer-overflow:CRollingBloomFilter::insert
 unsigned-integer-overflow:RollingBloomHash
 unsigned-integer-overflow:CCoinsViewCache::AddCoin
 unsigned-integer-overflow:CCoinsViewCache::BatchWrite
-unsigned-integer-overflow:CCoinsViewCache::DynamicMemoryUsage
-unsigned-integer-overflow:CCoinsViewCache::SpendCoin
-unsigned-integer-overflow:CCoinsViewCache::Uncache
```

> > Am I missing anything important here?
> 
> Yes, the preset doesn't check for those. You'll have to run with the integer sanitizer to be able to detect integer sanitizer issues.
> 
> The testing steps are also explained in the comment: https://github.com/bitcoin/bitcoin/pull/28865#issue-1991140953

### `@l0rinc` on `test/sanitizer_suppressions/ubsan:54` (2025-04-30T21:15:36Z)

```diff
@@ -46,9 +46,6 @@ unsigned-integer-overflow:CRollingBloomFilter::insert
 unsigned-integer-overflow:RollingBloomHash
 unsigned-integer-overflow:CCoinsViewCache::AddCoin
 unsigned-integer-overflow:CCoinsViewCache::BatchWrite
-unsigned-integer-overflow:CCoinsViewCache::DynamicMemoryUsage
-unsigned-integer-overflow:CCoinsViewCache::SpendCoin
-unsigned-integer-overflow:CCoinsViewCache::Uncache
```

> As mentioned in https://github.com/bitcoin/bitcoin/pull/32296#issuecomment-2813590511, I can't always reproduce these locally, it's why I used the CI to verify why these were needed in the first place.
> I have tried every combination I could think of locally, I couldn't reproduce any such errors in coins. If you can, please let me know how to do that exactly.
> Is there any other CI run I should be looking at to see if there are other failures?

### `@maflcko` on `test/sanitizer_suppressions/ubsan:54` (2025-05-04T17:36:54Z)

```diff
@@ -46,9 +46,6 @@ unsigned-integer-overflow:CRollingBloomFilter::insert
 unsigned-integer-overflow:RollingBloomHash
 unsigned-integer-overflow:CCoinsViewCache::AddCoin
 unsigned-integer-overflow:CCoinsViewCache::BatchWrite
-unsigned-integer-overflow:CCoinsViewCache::DynamicMemoryUsage
-unsigned-integer-overflow:CCoinsViewCache::SpendCoin
-unsigned-integer-overflow:CCoinsViewCache::Uncache
```

> The CI should be deterministic and trivially reproducible, as explained in https://github.com/bitcoin/bitcoin/blob/master/ci/README.md. If you can't reproduce it, please share the exact steps you tried, starting from a fresh system. For example, you can start with a fresh Hetzner Cloud VM (or any other fresh VM of your choice).
> 
> The integer sanitizer should equally be deterministic and reproducible.

### `@l0rinc` on `test/sanitizer_suppressions/ubsan:54` (2025-05-04T17:54:20Z)

```diff
@@ -46,9 +46,6 @@ unsigned-integer-overflow:CRollingBloomFilter::insert
 unsigned-integer-overflow:RollingBloomHash
 unsigned-integer-overflow:CCoinsViewCache::AddCoin
 unsigned-integer-overflow:CCoinsViewCache::BatchWrite
-unsigned-integer-overflow:CCoinsViewCache::DynamicMemoryUsage
-unsigned-integer-overflow:CCoinsViewCache::SpendCoin
-unsigned-integer-overflow:CCoinsViewCache::Uncache
```

> I meant I couldn't reproduce any of the supposed failures that suppressions were meant to avoid - but neither is the CI, so I'm not sure what to explain about the removals: they don't seem to be needed for CI to pass.
> Unless there's a secret CI which shows these failures - or any other way that you can reproduce them, please let me know how to do it.

### `@maflcko` on `test/sanitizer_suppressions/ubsan:54` (2025-05-04T18:17:12Z)

```diff
@@ -46,9 +46,6 @@ unsigned-integer-overflow:CRollingBloomFilter::insert
 unsigned-integer-overflow:RollingBloomHash
 unsigned-integer-overflow:CCoinsViewCache::AddCoin
 unsigned-integer-overflow:CCoinsViewCache::BatchWrite
-unsigned-integer-overflow:CCoinsViewCache::DynamicMemoryUsage
-unsigned-integer-overflow:CCoinsViewCache::SpendCoin
-unsigned-integer-overflow:CCoinsViewCache::Uncache
```

> In https://github.com/bitcoin/bitcoin/pull/32313#discussion_r2067406415 I was saying it would be good to known since when they are unused. To test an earlier commit, you can just switch to it in git.

### `@l0rinc` on `test/sanitizer_suppressions/ubsan:54` (2025-05-04T20:20:37Z)

```diff
@@ -46,9 +46,6 @@ unsigned-integer-overflow:CRollingBloomFilter::insert
 unsigned-integer-overflow:RollingBloomHash
 unsigned-integer-overflow:CCoinsViewCache::AddCoin
 unsigned-integer-overflow:CCoinsViewCache::BatchWrite
-unsigned-integer-overflow:CCoinsViewCache::DynamicMemoryUsage
-unsigned-integer-overflow:CCoinsViewCache::SpendCoin
-unsigned-integer-overflow:CCoinsViewCache::Uncache
```

> Whenever I tried going back to pre-cmake times, I couldn't get it to compile and run again (on Mac or on Linux). Not the first time I try to do a git bisect, but it always turns bad really quickly.
> 
> I tried pushing a PR to my fork with the [original PR](https://github.com/bitcoin/bitcoin/pull/28865) that introduced the suppressions + removing `DynamicMemoryUsage`, `SpendCoin` and `Uncache` suppressionss from ubsan.
> The build is [failing with similar problems](https://github.com/l0rinc/bitcoin/actions/runs/14824254981/job/41615310082?pr=10) that I see locally but don't see any `unsigned-integer-overflow` complaints. https://github.com/bitcoin/bitcoin/pull/28865 https://github.com/l0rinc/bitcoin/pull/10
> 
> Can you give me a hint of what else to try?

### `@andrewtoth` on `src/coins.cpp:204` (2025-05-05T23:23:07Z)

```diff
@@ -195,6 +201,7 @@ bool CCoinsViewCache::BatchWrite(CoinsViewCacheCursor& cursor, const uint256 &ha
                 // and mark it as dirty.
                 itUs = cacheCoins.try_emplace(it->first).first;
                 CCoinsCacheEntry& entry{itUs->second};
+                cachedCoinsUsage -= entry.coin.DynamicMemoryUsage();
```

> I don't think we should add an assert here to explain. The comment right above says `Create the coin in the parent cache`.

### `@l0rinc` on `src/coins.cpp:204` (2025-05-06T07:14:53Z)

```diff
@@ -195,6 +201,7 @@ bool CCoinsViewCache::BatchWrite(CoinsViewCacheCursor& cursor, const uint256 &ha
                 // and mark it as dirty.
                 itUs = cacheCoins.try_emplace(it->first).first;
                 CCoinsCacheEntry& entry{itUs->second};
+                cachedCoinsUsage -= entry.coin.DynamicMemoryUsage();
```

> Doesn't the presence of the original cache-usage-update indicate that the comment isn't enough?

### `@andrewtoth` on `src/coins.cpp:204` (2025-05-06T14:05:44Z)

```diff
@@ -195,6 +201,7 @@ bool CCoinsViewCache::BatchWrite(CoinsViewCacheCursor& cursor, const uint256 &ha
                 // and mark it as dirty.
                 itUs = cacheCoins.try_emplace(it->first).first;
                 CCoinsCacheEntry& entry{itUs->second};
+                cachedCoinsUsage -= entry.coin.DynamicMemoryUsage();
```

> Sorry, what is the original cache-usage-update? AFAICT this line was added in this PR, and there is no cache-usage-update here?

### `@l0rinc` on `src/coins.cpp:204` (2025-05-06T14:30:04Z)

```diff
@@ -195,6 +201,7 @@ bool CCoinsViewCache::BatchWrite(CoinsViewCacheCursor& cursor, const uint256 &ha
                 // and mark it as dirty.
                 itUs = cacheCoins.try_emplace(it->first).first;
                 CCoinsCacheEntry& entry{itUs->second};
+                cachedCoinsUsage -= entry.coin.DynamicMemoryUsage();
```

> I prefer code over comments (the comment can be wrong, the code validates) - and since the usual pattern is basically:
> ```C++
> cachedCoinsUsage -= itUs->second.coin.DynamicMemoryUsage();
> if (cursor.WillErase(*it)) {
>     itUs->second.coin = std::move(it->second.coin);
> } else {
>     itUs->second.coin = it->second.coin;
> }
> cachedCoinsUsage += itUs->second.coin.DynamicMemoryUsage();
> ```
> 
> it makes sense to explain (via code) why here we don't need the first part:
> ```C++
> assert(entry.coin.DynamicMemoryUsage() == 0); // i.e. we didn't forget the symmetry, it's on purpose
> if (cursor.WillErase(*it)) {
>     entry.coin = std::move(it->second.coin);
> } else {
>     entry.coin = it->second.coin;
> }
> cachedCoinsUsage += entry.coin.DynamicMemoryUsage();
> ```
> 
> Do you still think we don't need it?

### `@fanquake` on `test/sanitizer_suppressions/ubsan:54` (2025-05-09T13:41:50Z)

```diff
@@ -46,9 +46,6 @@ unsigned-integer-overflow:CRollingBloomFilter::insert
 unsigned-integer-overflow:RollingBloomHash
 unsigned-integer-overflow:CCoinsViewCache::AddCoin
 unsigned-integer-overflow:CCoinsViewCache::BatchWrite
-unsigned-integer-overflow:CCoinsViewCache::DynamicMemoryUsage
-unsigned-integer-overflow:CCoinsViewCache::SpendCoin
-unsigned-integer-overflow:CCoinsViewCache::Uncache
```

> > They were introduced in https://github.com/bitcoin/bitcoin/pull/28865/files#diff-bca63b54ad7fcc2df12f3237fd8775810c1b849c49110f702920655778fcc248R45-R49,
> > @fanquake, can you help us out here, do you remember why these were added?
> 
> You can recreate the failures by checking out to that commit (fd30e9688e15fe6e0f8b64202a6e9c7d96333394), applying this diff (which includes the supression being done here):
> ```diff
> diff --git a/ci/test/00_setup_env_native_fuzz.sh b/ci/test/00_setup_env_native_fuzz.sh
> index 3585b2b417..ce45917e99 100755
> --- a/ci/test/00_setup_env_native_fuzz.sh
> +++ b/ci/test/00_setup_env_native_fuzz.sh
> @@ -6,7 +6,7 @@
>  
>  export LC_ALL=C.UTF-8
>  
> -export CI_IMAGE_NAME_TAG="docker.io/ubuntu:23.10"  # This version will reach EOL in Jul 2024, and can be replaced by "ubuntu:24.04" (or anything else that ships the wanted clang version).
> +export CI_IMAGE_NAME_TAG="docker.io/ubuntu:24.04"  # This version will reach EOL in Jul 2024, and can be replaced by "ubuntu:24.04" (or anything else that ships the wanted clang version).
>  export CONTAINER_NAME=ci_native_fuzz
>  export PACKAGES="clang-17 llvm-17 libclang-rt-17-dev libevent-dev libboost-dev libsqlite3-dev"
>  export NO_DEPENDS=1
> diff --git a/test/sanitizer_suppressions/ubsan b/test/sanitizer_suppressions/ubsan
> index 63d2215aab..d3fc2a59ff 100644
> --- a/test/sanitizer_suppressions/ubsan
> +++ b/test/sanitizer_suppressions/ubsan
> @@ -42,11 +42,6 @@ unsigned-integer-overflow:arith_uint256.h
>  unsigned-integer-overflow:CBloomFilter::Hash
>  unsigned-integer-overflow:CRollingBloomFilter::insert
>  unsigned-integer-overflow:RollingBloomHash
> -unsigned-integer-overflow:CCoinsViewCache::AddCoin
> -unsigned-integer-overflow:CCoinsViewCache::BatchWrite
> -unsigned-integer-overflow:CCoinsViewCache::DynamicMemoryUsage
> -unsigned-integer-overflow:CCoinsViewCache::SpendCoin
> -unsigned-integer-overflow:CCoinsViewCache::Uncache
>  unsigned-integer-overflow:CompressAmount
>  unsigned-integer-overflow:DecompressAmount
>  unsigned-integer-overflow:crypto/
> ```
> and running the native_fuzz CI job (on aarch64):
> ```bash
> time env -i HOME="$HOME" PATH="$PATH" USER="$USER" bash -c 'MAKEJOBS="-j17" FILE_ENV="./ci/test/00_setup_env_native_fuzz.sh" ./ci/test_run_all.sh'
> <snip>
> #170921	REDUCE cov: 1694 ft: 6197 corp: 478/22Kb lim: 240 exec/s: 3351 rss: 208Mb L: 20/219 MS: 1 EraseBytes-
> #171261	REDUCE cov: 1694 ft: 6200 corp: 479/22Kb lim: 240 exec/s: 3358 rss: 208Mb L: 193/219 MS: 5 ChangeBinInt-ChangeBit-ChangeByte-CrossOver-CrossOver-
> #171550	REDUCE cov: 1694 ft: 6200 corp: 479/22Kb lim: 240 exec/s: 3363 rss: 208Mb L: 42/219 MS: 4 CopyPart-ChangeByte-PersAutoDict-EraseBytes- DE: "\024\000"-
> #171657	REDUCE cov: 1694 ft: 6200 corp: 479/22Kb lim: 240 exec/s: 3365 rss: 208Mb L: 51/219 MS: 2 InsertByte-EraseBytes-
> coins.cpp:132:22: runtime error: unsigned integer overflow: 0 - 64 cannot be represented in type 'size_t' (aka 'unsigned long')
>     #0 0xaaaab73bc134 in CCoinsViewCache::SpendCoin(COutPoint const&, Coin*) src/coins.cpp:132:22
>     #1 0xaaaab57cbc94 in coins_view_fuzz_target(Span<unsigned char const>)::$_4::operator()() const src/test/fuzz/coins_view.cpp:89:40
>     #2 0xaaaab57cbc94 in unsigned long CallOneOf<coins_view_fuzz_target(Span<unsigned char const>)::$_0, coins_view_fuzz_target(Span<unsigned char const>)::$_1, coins_view_fuzz_target(Span<unsigned char const>)::$_2, coins_view_fuzz_target(Span<unsigned char const>)::$_3, coins_view_fuzz_target(Span<unsigned char const>)::$_4, coins_view_fuzz_target(Span<unsigned char const>)::$_5, coins_view_fuzz_target(Span<unsigned char const>)::$_6, coins_view_fuzz_target(Span<unsigned char const>)::$_7, coins_view_fuzz_target(Span<unsigned char const>)::$_8, coins_view_fuzz_target(Span<unsigned char const>)::$_9, coins_view_fuzz_target(Span<unsigned char const>)::$_10>(FuzzedDataProvider&, coins_view_fuzz_target(Span<unsigned char const>)::$_0, coins_view_fuzz_target(Span<unsigned char const>)::$_1, coins_view_fuzz_target(Span<unsigned char const>)::$_2, coins_view_fuzz_target(Span<unsigned char const>)::$_3, coins_view_fuzz_target(Span<unsigned char const>)::$_4, coins_view_fuzz_target(Span<unsigned char const>)::$_5, coins_view_fuzz_target(Span<unsigned char const>)::$_6, coins_view_fuzz_target(Span<unsigned char const>)::$_7, coins_view_fuzz_target(Span<unsigned char const>)::$_8, coins_view_fuzz_target(Span<unsigned char const>)::$_9, coins_view_fuzz_target(Span<unsigned char const>)::$_10) src/./test/fuzz/util.h:43:27
>     #3 0xaaaab57cbc94 in coins_view_fuzz_target(Span<unsigned char const>) src/test/fuzz/coins_view.cpp:58:9
>     #4 0xaaaab5d2319c in std::function<void (Span<unsigned char const>)>::operator()(Span<unsigned char const>) const /usr/bin/../lib/gcc/aarch64-linux-gnu/13/../../../../include/c++/13/bits/std_function.h:591:9
>     #5 0xaaaab5d2319c in LLVMFuzzerTestOneInput src/test/fuzz/fuzz.cpp:178:5
>     #6 0xaaaab5545050 in fuzzer::Fuzzer::ExecuteCallback(unsigned char const*, unsigned long) (/ci_container_base/ci/scratch/build/bitcoin-aarch64-unknown-linux-gnu/src/test/fuzz/fuzz+0x1925050) (BuildId: 82e180570288de2f70ceeee1ed5d7cd3729696ab)
>     #7 0xaaaab5544798 in fuzzer::Fuzzer::RunOne(unsigned char const*, unsigned long, bool, fuzzer::InputInfo*, bool, bool*) (/ci_container_base/ci/scratch/build/bitcoin-aarch64-unknown-linux-gnu/src/test/fuzz/fuzz+0x1924798) (BuildId: 82e180570288de2f70ceeee1ed5d7cd3729696ab)
>     #8 0xaaaab5545f90 in fuzzer::Fuzzer::MutateAndTestOne() (/ci_container_base/ci/scratch/build/bitcoin-aarch64-unknown-linux-gnu/src/test/fuzz/fuzz+0x1925f90) (BuildId: 82e180570288de2f70ceeee1ed5d7cd3729696ab)
>     #9 0xaaaab5546cdc in fuzzer::Fuzzer::Loop(std::vector<fuzzer::SizedFile, std::allocator<fuzzer::SizedFile>>&) (/ci_container_base/ci/scratch/build/bitcoin-aarch64-unknown-linux-gnu/src/test/fuzz/fuzz+0x1926cdc) (BuildId: 82e180570288de2f70ceeee1ed5d7cd3729696ab)
>     #10 0xaaaab5534e70 in fuzzer::FuzzerDriver(int*, char***, int (*)(unsigned char const*, unsigned long)) (/ci_container_base/ci/scratch/build/bitcoin-aarch64-unknown-linux-gnu/src/test/fuzz/fuzz+0x1914e70) (BuildId: 82e180570288de2f70ceeee1ed5d7cd3729696ab)
>     #11 0xaaaab555e0ac in main (/ci_container_base/ci/scratch/build/bitcoin-aarch64-unknown-linux-gnu/src/test/fuzz/fuzz+0x193e0ac) (BuildId: 82e180570288de2f70ceeee1ed5d7cd3729696ab)
>     #12 0xffffb4aa84c0  (/lib/aarch64-linux-gnu/libc.so.6+0x284c0) (BuildId: 1d7249a4f207d07166ff4be43acdc68a01faaa04)
>     #13 0xffffb4aa8594 in __libc_start_main (/lib/aarch64-linux-gnu/libc.so.6+0x28594) (BuildId: 1d7249a4f207d07166ff4be43acdc68a01faaa04)
>     #14 0xaaaab552afac in _start (/ci_container_base/ci/scratch/build/bitcoin-aarch64-unknown-linux-gnu/src/test/fuzz/fuzz+0x190afac) (BuildId: 82e180570288de2f70ceeee1ed5d7cd3729696ab)
> 
> SUMMARY: UndefinedBehaviorSanitizer: unsigned-integer-overflow coins.cpp:132:22 in 
> MS: 1 CopyPart-; base unit: 81111e927920a57969bb7efb23d89de00d09a5ec
> 0xff,0xef,0xfe,0x0,0x1,0x3,0x0,0x1,0xff,0xff,0xff,0xff,0xff,0x3,0x0,0x1,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0x3,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xfe,0xff,0xfa,0x0,0x0,0x0,0x0,0x80,0x76,0x0,0x0,0x0,0x0,0x68,0x5c,0xff,0xff,0xff,0xff,0xef,0xfe,0x0,0x1,0x3,0x0,0x1,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0x3,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0x3,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xfe,0xff,0xfa,0x0,0x0,0x0,0x0,0x80,0x76,0x0,0x0,0x0,0x0,0x68,0x5c,0xff,0xff,0xff,0xff,0xef,0xfe,0x0,0x1,0x3,0x0,0x1,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0x3,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xfe,0xff,0xfa,0x7,
> \377\357\376\000\001\003\000\001\377\377\377\377\377\003\000\001\377\377\377\377\377\377\377\003\377\377\377\377\377\377\377\377\377\377\376\377\372\000\000\000\000\200v\000\000\000\000h\\\377\377\377\377\357\376\000\001\003\000\001\377\377\377\377\377\377\377\003\377\377\377\377\377\377\377\377\377\377\377\003\377\377\377\377\377\377\377\377\377\377\376\377\372\000\000\000\000\200v\000\000\000\000h\\\377\377\377\377\357\376\000\001\003\000\001\377\377\377\377\377\377\377\003\377\377\377\377\377\377\377\377\377\377\376\377\372\007
> artifact_prefix='./'; Test unit written to ./crash-2ea01576a6e0a74d403920761ea2ff6f0bf41752
> Base64: /+/+AAEDAAH//////wMAAf////////8D//////////////7/+gAAAACAdgAAAABoXP/////v/gABAwAB/////////wP//////////////wP//////////////v/6AAAAAIB2AAAAAGhc/////+/+AAEDAAH/////////A//////////////+//oH
> 
> Target ['/ci_container_base/ci/scratch/build/bitcoin-aarch64-unknown-linux-gnu/src/test/fuzz/fuzz', '-max_total_time=60'] failed with exit code 1
> ```

### `@l0rinc` on `test/sanitizer_suppressions/ubsan:54` (2025-05-10T21:52:36Z)

```diff
@@ -46,9 +46,6 @@ unsigned-integer-overflow:CRollingBloomFilter::insert
 unsigned-integer-overflow:RollingBloomHash
 unsigned-integer-overflow:CCoinsViewCache::AddCoin
 unsigned-integer-overflow:CCoinsViewCache::BatchWrite
-unsigned-integer-overflow:CCoinsViewCache::DynamicMemoryUsage
-unsigned-integer-overflow:CCoinsViewCache::SpendCoin
-unsigned-integer-overflow:CCoinsViewCache::Uncache
```

> > You can recreate the failures
> 
> Thanks a lot @fanquake, I managed to reproduce it this way (seeing that https://github.com/l0rinc/bitcoin/pull/10 was failing, I was trying to run them manually instead of relying on the ci scripts).
> 
> > why it isn't needed (or rather since when)
> 
> Thanks @maflcko for insisting, I have changed the order of commits to place the suppression removal at the very end since we still had a few failures for the first few commits - it's easier to remove them all at the end only, where I couldn't reproduce any such failure anymore.

### `@maflcko` on `test/sanitizer_suppressions/ubsan:54` (2025-05-13T14:43:30Z)

```diff
@@ -46,9 +46,6 @@ unsigned-integer-overflow:CRollingBloomFilter::insert
 unsigned-integer-overflow:RollingBloomHash
 unsigned-integer-overflow:CCoinsViewCache::AddCoin
 unsigned-integer-overflow:CCoinsViewCache::BatchWrite
-unsigned-integer-overflow:CCoinsViewCache::DynamicMemoryUsage
-unsigned-integer-overflow:CCoinsViewCache::SpendCoin
-unsigned-integer-overflow:CCoinsViewCache::Uncache
```

> Seems fine, but it may be better to remove the suppression in the exact commit that removes the need for it. This would make it easier to revert the commit atomically in one go, if there is need for whatever reason.

### `@l0rinc` on `test/sanitizer_suppressions/ubsan:54` (2025-05-13T15:09:10Z)

```diff
@@ -46,9 +46,6 @@ unsigned-integer-overflow:CRollingBloomFilter::insert
 unsigned-integer-overflow:RollingBloomHash
 unsigned-integer-overflow:CCoinsViewCache::AddCoin
 unsigned-integer-overflow:CCoinsViewCache::BatchWrite
-unsigned-integer-overflow:CCoinsViewCache::DynamicMemoryUsage
-unsigned-integer-overflow:CCoinsViewCache::SpendCoin
-unsigned-integer-overflow:CCoinsViewCache::Uncache
```

> Any accounting inconsistency could've caused it to become negative and fail, so instead of removing these suppressions in the last commit that fixed the problem (giving the impression that it was just one change that enabled us removing it), I did it separately instead.
> Is this important, is this holding back the ACK from your part?

### `@optout21` on `src/test/fuzz/coins_view.cpp:62` (2025-10-09T09:33:24Z)

```diff
-                const bool possible_overwrite = fuzzed_data_provider.ConsumeBool();
-                try {
-                    coins_view_cache.AddCoin(random_out_point, std::move(coin), possible_overwrite);
-                    expected_code_path = true;
-                } catch (const std::logic_error& e) {
-                    if (e.what() == std::string{"Attempted to overwrite an unspent coin (when possible_overwrite is false)"}) {
-                        assert(!possible_overwrite);
+                COutPoint outpoint{random_out_point};
```

> nit: This declaration of `outpoint` is enough to be placed in the `else` branch
> 
> ``` diff
> diff --git a/src/test/fuzz/coins_view.cpp b/src/test/fuzz/coins_view.cpp
> index 3928120a3f..055c3c4b31 100644
> --- a/src/test/fuzz/coins_view.cpp
> +++ b/src/test/fuzz/coins_view.cpp
> @@ -59,13 +59,12 @@ void TestCoinsView(FuzzedDataProvider& fuzzed_data_provider, CCoinsView& backend
>                  if (random_coin.IsSpent()) {
>                      return;
>                  }
> -                COutPoint outpoint{random_out_point};
>                  Coin coin{random_coin};
>                  if (fuzzed_data_provider.ConsumeBool()) {
>                      bool expected_code_path = false;
>                      const bool possible_overwrite = fuzzed_data_provider.ConsumeBool();
>                      try {
> -                        coins_view_cache.AddCoin(outpoint, std::move(coin), possible_overwrite);
> +                        coins_view_cache.AddCoin(random_out_point, std::move(coin), possible_overwrite);
>                          expected_code_path = true;
>                      } catch (const std::logic_error& e) {
>                          if (e.what() == std::string{"Attempted to overwrite an unspent coin (when possible_overwrite is false)"}) {
> @@ -81,6 +80,7 @@ void TestCoinsView(FuzzedDataProvider& fuzzed_data_provider, CCoinsView& backend
>                      }
>                      assert(expected_code_path);
>                  } else {
> +                    COutPoint outpoint{random_out_point};
>                      coins_view_cache.EmplaceCoinInternalDANGER(std::move(outpoint), std::move(coin));
>                  }
>              },
> ```

### `@l0rinc` on `src/test/fuzz/coins_view.cpp:62` (2025-10-09T12:44:25Z)

```diff
-                const bool possible_overwrite = fuzzed_data_provider.ConsumeBool();
-                try {
-                    coins_view_cache.AddCoin(random_out_point, std::move(coin), possible_overwrite);
-                    expected_code_path = true;
-                } catch (const std::logic_error& e) {
-                    if (e.what() == std::string{"Attempted to overwrite an unspent coin (when possible_overwrite is false)"}) {
-                        assert(!possible_overwrite);
+                COutPoint outpoint{random_out_point};
```

> I have extracted it on purpose to signal that both branches are doing something similar and have the same dependencies

### `@w0xlt` on `src/coins.cpp:116` (2025-10-10T00:19:02Z)

```diff
 }
 
 void CCoinsViewCache::EmplaceCoinInternalDANGER(COutPoint&& outpoint, Coin&& coin) {
-    cachedCoinsUsage += coin.DynamicMemoryUsage();
+    const auto mem_usage{coin.DynamicMemoryUsage()};
     auto [it, inserted] = cacheCoins.try_emplace(std::move(outpoint), std::move(coin));
-    if (inserted) CCoinsCacheEntry::SetDirty(*it, m_sentinel);
+    if (inserted) {
```

> If `inserted=false`, you've still moved from `coin`.
> Is this expected behavior ?

### `@andrewtoth` on `src/coins.cpp:116` (2025-10-10T00:45:50Z)

```diff
 }
 
 void CCoinsViewCache::EmplaceCoinInternalDANGER(COutPoint&& outpoint, Coin&& coin) {
-    cachedCoinsUsage += coin.DynamicMemoryUsage();
+    const auto mem_usage{coin.DynamicMemoryUsage()};
     auto [it, inserted] = cacheCoins.try_emplace(std::move(outpoint), std::move(coin));
-    if (inserted) CCoinsCacheEntry::SetDirty(*it, m_sentinel);
+    if (inserted) {
```

> Yes. `coin` is an rvalue, so it is already moved out of the caller. `inserted` should always be true anyways.

### `@ryanofsky` on `src/coins.cpp:201` (2025-10-10T19:31:07Z)

```diff
@@ -195,6 +195,7 @@ bool CCoinsViewCache::BatchWrite(CoinsViewCacheCursor& cursor, const uint256 &ha
                 // and mark it as dirty.
                 itUs = cacheCoins.try_emplace(it->first).first;
                 CCoinsCacheEntry& entry{itUs->second};
+                assert(entry.coin.DynamicMemoryUsage() == 0);
```

> In commit "refactor: assert newly-created parent cache entry has zero memory usage" (8d5e323b5f475fe9a2bed1402a20e48a40a45137)
> 
> Note: this assert will be true because `itUs == cacheCoins.end()` condition above means try_emplace will always insert and  `itUs->second` will be a new empty coin

### `@l0rinc` on `src/coins.cpp:201` (2025-10-12T02:11:23Z)

```diff
@@ -195,6 +195,7 @@ bool CCoinsViewCache::BatchWrite(CoinsViewCacheCursor& cursor, const uint256 &ha
                 // and mark it as dirty.
                 itUs = cacheCoins.try_emplace(it->first).first;
                 CCoinsCacheEntry& entry{itUs->second};
+                assert(entry.coin.DynamicMemoryUsage() == 0);
```

> I think that's what I also wrote in the commit message, but rephrased it slightly, let me know if it's better.

### `@andrewtoth` on `src/test/coins_tests.cpp:1116` (2025-10-12T16:18:40Z)

```diff
+    CCoinsViewCacheTest cache{&root};
+
+    const COutPoint outpoint{Txid::FromUint256(m_rng.rand256()), m_rng.rand32()};
+    const Coin coin{CTxOut{m_rng.randrange(10), CScript{} << m_rng.randbytes(CScriptBase::STATIC_SIZE + 1)}, 1, false};
+
+    cache.EmplaceCoinInternalDANGER(COutPoint{outpoint}, Coin{coin});
+    cache.SelfTest();
+    cache.EmplaceCoinInternalDANGER(COutPoint{outpoint}, Coin{coin});
```

> We should try and insert a different `coin` at the same `outpoint`, like we do for the `AddCoin` test above. That way the below check `cache.AccessCoin(outpoint) == coin` makes sure the original `coin` emplaced was not overwritten by the second one.
> 
> We should also make sure the two coins have different `DynamicMemoryUsage` so the accounting is correct for the coin that was actually inserted.

### `@l0rinc` on `src/test/coins_tests.cpp:1116` (2025-10-12T16:38:15Z)

```diff
+    CCoinsViewCacheTest cache{&root};
+
+    const COutPoint outpoint{Txid::FromUint256(m_rng.rand256()), m_rng.rand32()};
+    const Coin coin{CTxOut{m_rng.randrange(10), CScript{} << m_rng.randbytes(CScriptBase::STATIC_SIZE + 1)}, 1, false};
+
+    cache.EmplaceCoinInternalDANGER(COutPoint{outpoint}, Coin{coin});
+    cache.SelfTest();
+    cache.EmplaceCoinInternalDANGER(COutPoint{outpoint}, Coin{coin});
```

> Good idea, [done](https://github.com/bitcoin/bitcoin/compare/0d5f7d24bde2bcc2cf7345fa46cb84ac0ecec41f..24d861da7894add47747eff69dd3fc71fbcdd7d0)

## 4. General Discussion & Maintainer Feedback Thread

### `@l0rinc` (2025-04-29T09:50:46Z)

Rebased to allow CI running the new tests.

---

### `@l0rinc` (2025-06-10T11:36:14Z)

Rebased after fuzz conflicts, ready for review again.

---

### `@l0rinc` (2025-10-01T20:18:46Z)

Rebased and adjusted the commits to minimize conflict with https://github.com/bitcoin/bitcoin/pull/33512

---

### `@l0rinc` (2025-10-08T03:03:23Z)

Added an AssumeUTXO fuzz test here that was requested in https://github.com/bitcoin/bitcoin/pull/33512#discussion_r2404014654 - but it needs the fixes here to work.

---

### `@ryanofsky` (2025-10-08T18:13:44Z)

Just a quick code review for 2b11c47f60b85fe72ab9d093c9f8e5f597182fbc. Sorry if I missed anything obvious, my comments below are mostly asking for things to be explained a little better. Overall the changes seem positive and I did not see any problems.

- Can PR description be updated to say what types of "violations" are being "fixed" and clarify what purpose of the changes are? Would be helpful if description was self contained and did not start out referencing a comment in another PR.

- Purpose of first commit 6b842138c33d8663603d1d0a528cb90c54c70163 seems opaque. Commit description says a check is being moved but not why, and it is not clear what effect this change has or if it can be tested.

- Third commit 62c600f79a13e8772f3d6d7aaf6593c6dc55ddfe seems to be a refactoring that does not change behavior. Would be helpful to say this explicitly and maybe start commit title with "refactor".

- From what I can tell the second and third commits both seem to be refactorings that do not depend on each other and aren't really related to the rest of the PR. If would be nice if commit messages clarified if they are independent cleanups or if something depends on them. It might also be good to move these refactorings before the bugfix in the first commit if they do not depend on it.

- Fourth commit f1791d64b437eab31ad941fb4c9e4051e0274c4a seems like a good bugfix. But would be good if commit description could say what impact of bug is. Is it a rare thing that happens only when disk writes fail? What's the actual effect if the bug does happen? Too much memory is allocated? Something else?

- Last commit a9eb8dfab1c35c2563d3267432b64bb6a812f08f seems to be doing a few unrelated things and would be nice to split up. The main thing it seems to be doing is dropping the "coins_view_cache.Flush()" workaround because of an accounting bug "fixed in a previous commit". It would be much nicer IMO if the workaround could be dropped in the same commit which actually fixes the accounting bug. Moving this change should make the bugfix and test change both easier to understand.

- Additionally, the last commit seems to be dropping the `expected_code_path` check which makes sure that after many writes, at least one coin will be overwritten. Unclear why that check is being dropped and would be good to explain in commit message. Adding the EmplaceCoinInternalDANGER call there does seem good and useful to check the accounting.

---

### `@l0rinc` (2025-10-08T22:03:43Z)

Thank you for the quick review, I have restructured the change to tell a more intuitive story and added more commit message guidance for the context and rewrote the intro to make more sense (it helped that I wrote this a longer time ago and I also didn't remember the context).

The new structure starts with the simple refactorings and assertions and adding extra guards to document why and where the accounting is incorrect. Most of the accounting problems are test-only, so it's unlikely to fix anything in production - but it enabled us writing more correct tests for coins.

Based on the feedback I merged the changes in `AddCoin` and `Flush` since this way I can also enable the suppressions in the same commit, proving that they fix the problem.
I have also split out the `Flush()` workaround in `coins_view` which removed the workaround in https://github.com/bitcoin/bitcoin/pull/32602/files#r2113749842 (cc: @marcofleon, @darosior).
The `expected_code_path` didn't check any overwrites, just that all codepaths result in success - which is simplified in the last commit.

The latest push is [zero-diff](https://github.com/bitcoin/bitcoin/compare/a9eb8dfab1c35c2563d3267432b64bb6a812f08f..c4293c7b21971e7ddd813ad3fbe574eb5605d60e), only reorganized and explained better - thanks for the review.

---

### `@optout21` (2025-10-09T09:38:30Z)

ACK c4293c7b21971e7ddd813ad3fbe574eb5605d60e

With the recent commit restructuring the steps are clear.
The code change is sound and looks well tested.
I've left one non-blocking nit, no other comment.

---

### `@optout21` (2025-10-10T22:00:24Z)

> * It looks to me like the `expected_code_path` assert is confirming that the `std::logic_error` exception throws at least once and that test coverage is complete.

I don't think it checks that exception is thrown at least once, but it checks that either there is no exception, or if there is, it is that specific exception. With this change there is an assert to make sure the exception is the one expected. So I think the test code change is correct, but I agree that the "that all codepaths result in success." description is not precise.

---

### `@l0rinc` (2025-10-12T02:12:01Z)

Thanks for the comments, the latest push makes it even simpler, removed the temporary asserts, added unit tests instead (thanks @w0xlt), changed the order of the `AddCoin` and `EmplaceCoinInternalDANGER` commits which did indeed allow me to fixup the latest commit with the fuzz simplifications into the `AddCoin` one.

> In the last commit I'm still not sure why expected_code_path assert is being removed

The role of the variable was to verify that code execution follows only expected paths, either successful addition, or if it's an exception, the message is verified and checked that overwrite was disallowed in the first place.

---

### `@optout21` (2025-10-14T09:42:58Z)

reACK 24d861da7894add47747eff69dd3fc71fbcdd7d0

---

## 5. Formal Reviews & Final `ACK`s

### `@ryanofsky` (`APPROVED`)

Code review ACK c4293c7b21971e7ddd813ad3fbe574eb5605d60e. The changes are nice simplifications addition to fixing overflows, and they are all nicely explained. Few suggestions you could consider (but ignore them if you prefer current implementation):

- I feel like the new asserts added in b905a592d429b4b4edd48c8b0fa29ea4fdf8d251 and removed later don't really add much value or explain much since they can basically only trigger when there are one or two coins in the cache. I'd consider dropping them from the PR, and just posting them a diff if they are helpful for testing, so the PR is simpler.

- Seems like it would be nice to order 33a8150315d8880be75c4117aa9457b7c2eb5ce1 before bf1f9907d47fc93cc0ca67fe65a03466d93381c3 so 33a8150315d8880be75c4117aa9457b7c2eb5ce1 can drop the flush workaround from the fuzz test, and bf1f9907d47fc93cc0ca67fe65a03466d93381c3 can just add the EmplaceCoinInternalDANGER call to the fuzz test. This way the fuzz test changes would illustrate the code changes and be minimal.

- In the last commit I'm still not sure why `expected_code_path` assert is being removed. You last comment suggests that `expected_code_path` is removed because it just checks "that all codepaths result in success." But I don't think this is true. It looks to me like the `expected_code_path` assert is confirming that the `std::logic_error` exception throws at least once and that test coverage is complete. It seems ok to drop this, but I don't think it's redundant or no longer necessary due to changes here.

---

### `@andrewtoth` (`COMMENTED`)

ACK 24d861da7894add47747eff69dd3fc71fbcdd7d0

---

### `@sipa` (`COMMENTED`)

ACK 24d861da7894add47747eff69dd3fc71fbcdd7d0

---

### `@w0xlt` (`COMMENTED`)

ACK https://github.com/bitcoin/bitcoin/pull/32313/commits/24d861da7894add47747eff69dd3fc71fbcdd7d0

---
