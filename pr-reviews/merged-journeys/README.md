# Bitcoin Core Maintainer Review Playbook (8 Downloaded Merged PR Journeys)

Every file in this folder (`PR-<NUM>-JOURNEY.md` and `raw/pr-<NUM>.json`) is a **real, merged `bitcoin/bitcoin` Pull Request** downloaded with its full commit history (fetched into `/Users/mac/bitcoin` as `pr-<NUM>`), inline code comments, author improvements, and final `ACK`s.

Use `./lab.sh journeys` or `./lab.sh journeys <PR_NUMBER>` to inspect any of these offline on your Mac.

---

## 1. The 8 Downloaded Merged PR Journeys

| Merged PR | Title & Author | Local Branch in `/Users/mac/bitcoin` | Study Dossier | How Reviewer Comments Improved the PR Before Merge |
| :--- | :--- | :--- | :--- | :--- |
| **[#36447](https://github.com/bitcoin/bitcoin/pull/36447)** | `test: Misc fixes for pending validation events races` (`@maflcko`) | `pr-36447` (`fa466dea80`) | [PR-36447-JOURNEY.md](file:///Users/mac/bitcoin-core-lab/pr-reviews/merged-journeys/PR-36447-JOURNEY.md) | `@ismaelsadeeq` suggested moving the event queue drain into `mineBlock()` so all callers get synchronization automatically; `@sedited` caught another unsynchronized `txindex.Stop()` call at the bottom of `txindex_tests.cpp`. `@maflcko` adopted both fixes! |
| **[#36439](https://github.com/bitcoin/bitcoin/pull/36439)** | `test: poll more frequently in sync helpers and RPC connection wait` (`@ViniciusCestarii`) | `pr-36439` (`8898f832d9`) | [PR-36439-JOURNEY.md](file:///Users/mac/bitcoin-core-lab/pr-reviews/merged-journeys/PR-36439-JOURNEY.md) | `@maflcko` asked for benchmark plots comparing `-j1` vs `2*nproc` saturation, suggested forcing named keyword arguments (`def sync_blocks(self, nodes=None, *, wait=0.05, timeout=60):`), and suggested using a deadline timer (`time.monotonic()`). |
| **[#35724](https://github.com/bitcoin/bitcoin/pull/35724)** | `cmpctblock: Improve logging of cmpctblock message reconstruction statistics` (`@davidgumberg`) | `pr-35724` (`4f5ce816db`) | [PR-35724-JOURNEY.md](file:///Users/mac/bitcoin-core-lab/pr-reviews/merged-journeys/PR-35724-JOURNEY.md) | `@w0xlt` caught two real bugs: (1) removing a counter decrement falsely assumed a candidate came from `extrapool` rather than the `mempool` scan, and (2) `if (ShouldTraceLog(...)) { LogDebug(...); }` had mismatched log levels. `@0xB10C` ran the PR on live Signet and shared real log output. |
| **[#32313](https://github.com/bitcoin/bitcoin/pull/32313)** | `coins: fix cachedCoinsUsage accounting in CCoinsViewCache` (`@l0rinc`) | `pr-32313` (`b9f9d9c7a6`) | [PR-32313-JOURNEY.md](file:///Users/mac/bitcoin-core-lab/pr-reviews/merged-journeys/PR-32313-JOURNEY.md) | `@andrewtoth` pointed out on `src/coins.cpp:204` that subtracting `cachedCoinsUsage` on a newly created entry was subtracting zero, prompting `@l0rinc` to replace it with an explanatory `assert`. `@maflcko` kept unrelated sanitizer changes out of the PR. |
| **[#33624](https://github.com/bitcoin/bitcoin/pull/33624)** | `test: P2SH sig ops are only counted with SCRIPT_VERIFY_P2SH` (`@brunoerg`) | `pr-33624` (`3a10d700bc`) | [PR-33624-JOURNEY.md](file:///Users/mac/bitcoin-core-lab/pr-reviews/merged-journeys/PR-33624-JOURNEY.md) | `@instagibbs` improved both the comment accuracy and added `/*flags=*/0` inline parameter documentation. `@l0rinc` and `@janb84` verified the test by temporarily mutating `src/consensus/tx_verify.cpp` (`if (1 == 1)`) to prove the new assertion fails when consensus code is broken. |
| **[#33630](https://github.com/bitcoin/bitcoin/pull/33630)** | `doc: correct topology requirements in submitpackage helptext` (`@glozow`) | `pr-33630` (`3d22282564`) | [PR-33630-JOURNEY.md](file:///Users/mac/bitcoin-core-lab/pr-reviews/merged-journeys/PR-33630-JOURNEY.md) | `@janb84` and `@instagibbs` pointed out an ambiguity in `"Not all parents need to be present"` and proposed concrete `suggestion` blocks clarifying `(some, all, or none of)` unconfirmed parents, which `@glozow` adopted. |
| **[#36469](https://github.com/bitcoin/bitcoin/pull/36469)** | `refactor: deduplicate block validation state catcher` (`@enirox001`) | `pr-36469` (`c9cccf6d68`) | [PR-36469-JOURNEY.md](file:///Users/mac/bitcoin-core-lab/pr-reviews/merged-journeys/PR-36469-JOURNEY.md) | Demonstrates how clean C++ refactoring PRs progress from `Concept ACK` to ultra-concise `ACK c9cccf6d68c682e533876b4450f5ad7044a79f10` (`dedup is clean.`). |
| **[#36545](https://github.com/bitcoin/bitcoin/pull/36545)** | `test: Fix intermittent issue in p2p_initial_headers_sync.py` (`@maflcko`) | `pr-36545` (`fad7637529`) | [PR-36545-JOURNEY.md](file:///Users/mac/bitcoin-core-lab/pr-reviews/merged-journeys/PR-36545-JOURNEY.md) | Merged on 2026-10-19 (same author & category as open PR `#36553`). Shows how `@Crypt-iQ` and `@l0rinc` write natural, human `tACK` and `lightly tested ACK` comments on P2P test fixes. |

---

## 2. The 7 Patterns of Great Maintainer Comments (Verbatim Examples)

Notice how experienced Bitcoin Core contributors write. **They never use AI-style Markdown templates or long bulleted essays.** Instead, they use one of these 7 razor-sharp patterns:

### Pattern 1: "Did you check the other callers in the same file?" (`@sedited` on PR #36447)
When a PR fixes a bug at one line of a file, check the rest of the same file for the same pattern:
> **`@sedited` on `src/test/txindex_tests.cpp:174`:**
> *"What about the other cases of `txindex.Stop()` in this file? I guess most don't produce more blocks, but the last test for example does, so maybe we should also sync there?"*
>
> **`@maflcko` (Author) reply:**
> *"ah, I only grepped for the comment. Fixed the others as well now."*

### Pattern 2: "Can we push this fix into the helper so callers get it for free?" (`@ismaelsadeeq` on PR #36447)
Instead of fixing 10 call sites manually, ask if the helper function itself should do the work:
> **`@ismaelsadeeq` on `src/test/util/setup_common.cpp:436`:**
> *"Perhaps it may be better to just drain in mineBlock? That way other callers that will mine a block get the notification emitted for free, without them having to drain themselves?"*
>
> **`@maflcko` (Author) reply:**
> *"I was thinking that it could be useful coverage for the unit tests to be async here. But then, I don't know if they have ever found an issue here. Of course, we still need the option to be async, but maybe it is fine to sync by default. I'll push that ..."*

### Pattern 3: Catching a Broken Assumption or Mismatched Log Level (`@w0xlt` on PR #35724)
Polite, humble phrasing (`"If I understand correctly..."`) paired with an exact code pointer:
> **`@w0xlt` on `src/blockencodings.cpp:164`:**
> *"If I understand correctly, removing this decrement assumes that the existing candidate came from the extrapool. However, it may have been inserted during the earlier mempool scan. Would it make sense to track the candidate’s source and decrement the corresponding counter?"*
>
> **`@davidgumberg` (Author) reply:**
> *"yeah, thanks for catching @w0xlt, I'll fix this after #35727, as that will make this change easier to make correct, marking this pr as draft for now"*

### Pattern 4: Proving a New Test Actually Catches the Bug by Breaking the C++ Code (`@l0rinc` & `@janb84` on PR #33624)
When reviewing a test PR, temporarily break the C++ implementation (`git diff`) to prove the new test fails when it should:
> **`@l0rinc` on PR #33624:**
> *"Verified with:*
> ```patch
> - if ((flags & SCRIPT_VERIFY_P2SH) && txin.scriptPubKey.IsPayToScriptHash())
> + if ((1 == 1) && txin.scriptPubKey.IsPayToScriptHash())
> ```
> *"*
>
> **`@janb84` on PR #33624:**
> *"tested ACK 3a10d700bc1889b3690097efc935c5a4ba5966bb*
> *PR introduces new assert in test that prohibits the `if ( 1 == 1)` mutation / `if(true)`, because the assert will fail in that condition.*
> *- code review ✅*
> *- build & ran tests ✅*
> *- changed code to true to test assert ✅"*

### Pattern 5: GitHub `suggestion` Blocks for Clean Nits (`@instagibbs` on PR #33624 & `@maflcko` on PR #36439)
Instead of writing a paragraph about code style, drop a 3-line GitHub `suggestion` block:
> **`@instagibbs` on `src/test/sigopcount_tests.cpp:156` (PR #33624):**
> ````markdown
> ```suggestion
>         assert(GetTransactionSigOpCost(CTransaction(spendingTx), coins, /*flags=*/0) == 0);
> ```
> ````
> **`@maflcko` on `test/functional/test_framework/test_framework.py:698` (PR #36439):**
> ````markdown
> ```suggestion
>     def sync_blocks(self, nodes=None, *, wait=0.05, timeout=60):
> ```
> nit: force named kwargs while touching this line? Same below
> ````

### Pattern 6: Running the Code on Signet/Regtest and Pasting Real Log Output (`@0xB10C` on PR #35724)
Nothing proves genuine human review faster than pasting 3 lines of real log output from your own node:
> **`@0xB10C` on PR #35724:**
> *"Doing another review pass over the code and also running it on signet a bit. Saw this log, which looks good to me:*
> ```text
> 2026-09-16T19:19:28Z [net_processing.cpp:3805] [LogBlockHeader] [all:info] Saw new cmpctblock header ...
> ```
> *"*

### Pattern 7: Short, Honest Final `ACK`s (`@l0rinc`, `@Crypt-iQ`, `@ismaelsadeeq`, `@StephenChi-hi`)
Look at how short real `ACK` comments are once the code is ready:
- **`@l0rinc` (PR #36545):**
  ```text
  lightly tested ACK fad7637529426f058a3c2409dd137009b14622a4

  Thanks for fixing it!
  ```
- **`@StephenChi-hi` (PR #36447):**
  ```text
  tACK

  I agree, this will sure help to prevent flaky test failures.
  built and verified changes, all 862 unit test cases in test_bitcoin passed cleanly.
  ```
- **`@ismaelsadeeq` (PR #36469):**
  ```text
  ACK c9cccf6d68c682e533876b4450f5ad7044a79f10

  dedup is clean.
  ```

---

## 3. How to Apply These Patterns to Our 3 Open Unmerged PRs (`#36553`, `#36555`, `#36550`)

1. **On Open PR `#36553` (`test: Add missing sync_mempools in wallet_conflicts.py` by `@maflcko`):**
   - Look at **Pattern 4** (`@l0rinc` / `@janb84`) and **Pattern 7** (`@l0rinc` on `#36545`):
   - You can reproduce the failure that `@maflcko` put in the PR description (adding `time.sleep(0.1)` in `src/net_processing.cpp`), or simply post a short, genuine 2-line human review in the exact style of `@l0rinc` / `@StephenChi-hi`.
2. **On Open PR `#36555` (`rpc: return error when invalidateblock fails` by `@ja7ad`):**
   - Look at **Pattern 1 & Pattern 2** (`@sedited` / `@ismaelsadeeq`):
   - Ask a polite inline question on `src/rpc/blockchain.cpp:1791`:
     *"Since `Chainstate::InvalidateBlock` in `src/validation.cpp:3536` now sets `state.Error("Cannot invalidate genesis block")`, do we still need this early check in `src/rpc/blockchain.cpp:1791`? Removing the early check here would avoid duplicating the error string and let `InvalidateBlock` handle it in one place."*
3. **On Open PR `#36550` (`crypto: cleanse CSHA512 state in its destructor` by `@fametrano`):**
   - Look at **Pattern 1** (`@sedited` checking callers across the codebase):
   - Point out `src/random.cpp:518-520` (`RNGState::MixExtract`), where `hasher.Reset()` is currently called with the comment `// Best effort cleanup of internal state` right before `CSHA512 hasher` goes out of scope. With `~CSHA512()` now calling `memory_cleanse` on both `s` and `buf`, that incomplete `hasher.Reset()` in `src/random.cpp:519` is finally properly cleansed (and `hasher.Reset()` there is no longer needed).
