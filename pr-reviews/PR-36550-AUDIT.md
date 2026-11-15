# Audit: bitcoin/bitcoin#36550 `crypto: cleanse CSHA512 state in its destructor`

* URL: https://github.com/bitcoin/bitcoin/pull/36550
* Author: @fametrano
* State: CLOSED (unmerged). The author closed it himself: no issue had
  been filed for the problem, and the fix moved to `fametrano/bitcoin#10`.
* Audited head: `2c27910f33a9102a8aaefa98d3672ccfa2e62343`
* Checked: 2026-11-06
* Risk: crypto hygiene only. No consensus or behavior change. Secret
  material (wallet keys, BIP32 seeds, RNG state) stays in memory
  slightly longer without it.

## What the PR does

`CSHA512::Finalize()` leaves the digest in the hasher state and the
last block in its buffer, and nothing wipes them. Every `CSHA512`
outside tests hashes secret data (wallet encryption keys, BIP32
material, RNG seeds). The PR adds a destructor that cleanses both
buffers with `memory_cleanse`, following the `ChaCha20` precedent, so
each hasher is wiped when it goes out of scope. It also made #36551
unnecessary.

## Commits (1)

```text
2c27910f33 crypto: cleanse CSHA512 state in its destructor
```

## Diff (2 files, +8 -0)

```diff
--- a/src/crypto/sha512.cpp
+++ b/src/crypto/sha512.cpp
+#include <support/cleanse.h>
+CSHA512::~CSHA512()
+{
+    memory_cleanse(s, sizeof(s));
+    memory_cleanse(buf, sizeof(buf));
+}
--- a/src/crypto/sha512.h
+++ b/src/crypto/sha512.h
     CSHA512();
+    ~CSHA512();
```

## Review notes

* @jpk68 left `ACK 2c27910f33...`. The author mentions a second
  review from @vicjuma.
* The author notes a test is impractical: the object no longer exists
  once destroyed. He reports a full build plus `test_bitcoin` and
  `ctest` passing with no new warnings.
* Follow up question from @jpk68 on the closure (why closing relates
  to no issue being filed) was left open at check time.

## Verdict

Sound hardening patch, closed for process reasons rather than
technical ones. A student can still review the 8 line diff and the
`memory_cleanse` semantics as an exercise.
