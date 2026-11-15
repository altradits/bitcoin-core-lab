# Building Bitcoin Core from source: repetition drills

These drills are the muscle-memory layer under Stage 13 (build and unit tests), Stage 04
(functional tests) and Stage 19 (review). Each one states **what to achieve** and **where
to look**. You type everything, and log it in `my-work/<stage>/journal.md`
([no-shortcuts rule](./CURRICULUM_CONVENTIONS.md#1-the-no-shortcuts-rule)).
A drill counts as mastered when you can redo it on a clean directory **without your journal**.

`./lab.sh drill <n>` only prints the brief for a drill. It must not run the drill for you.
Upstream facts were checked on a Bitcoin Core checkout (`$BITCOIN_ROOT`) at `master` at `e75b76b12c`.

---

## Drill 1: Clone, remotes, dependencies *(C-GIT-1, C-BUILD-1)*
- **Achieve:** a fresh clone of `bitcoin/bitcoin` in a scratch directory with two remotes: upstream, and your own fork. Then verify every build dependency for macOS.
- **Read:** `doc/build-osx.md` (on master). The dependency list changes between releases: on current master it is `cmake boost capnp`, macOS's own sqlite, and no libevent. Don't copy lists from old guides. `CMakeLists.txt` sets the minimum CMake version.
- <details><summary>Hint 1</summary>`git remote add`, `git remote -v`. Name remotes so you never push to upstream by accident.</details>
- **Check:** `git remote -v` shows both, and each tool `build-osx.md` requires prints a version.

## Drill 2: Configure and build on 8 GB *(C-BUILD-1, C-BUILD-2)*
- **Achieve:** a build directory with tests enabled, then `bitcoind`, `bitcoin-cli` and `test_bitcoin` built **without the Mac swapping**. Time it.
- **Read:** `doc/build-osx.md`, `doc/productivity.md` (ccache), and `cmake -B build -LH` to see the options.
- <details><summary>Hint 1</summary>`cmake --build` accepts `--target` and `-j`. On 8 GB, keep `-j` well below the core count and watch memory pressure.</details>
- <details><summary>Hint 2</summary>Turn off what you don't need for a given review (GUI, IPC). Why is that safe for a test-only PR but not for every PR?</details>
- **Check:** the three binaries exist under `build/bin/` and `--version` prints your commit.

## Drill 3: Run regtest by hand *(C-VAL-5)*
- **Achieve:** start a regtest node with your own `bitcoin.conf` in a **custom datadir**, query it, read its log, and stop it cleanly.
- **Read:** `doc/bitcoin-conf.md`, `bitcoind -help | grep -A2 datadir`, and the `.cookie` auth section in `doc/JSON-RPC-interface.md`.
- <details><summary>Hint 1</summary>Network sections in the config file look like `[regtest]`. Where does the cookie file appear?</details>
- **Check:** `getblockchaininfo` reports `"chain": "regtest"`, and `debug.log` shows your startup.

## Drill 4: Wallets and first coins *(C-WALLET-1, C-CONS-1)*
- **Achieve:** create a signing wallet and a watch-only wallet, mine until a coinbase matures, and see the spendable balance.
- <details><summary>Hint 1</summary>`createwallet` arguments are positional or named; read `help createwallet`. How many blocks before the first coinbase matures, and why?</details>
- **Check:** `getbalance` in the miner wallet is > 0, and `getwalletinfo` on the watch-only wallet shows private keys disabled.

## Drill 5: Run both test suites *(C-TEST-1, C-PY-1)*
- **Achieve:** run one Boost suite, one single test case, a `ctest` name filter, one functional test by name, and the whole functional suite at a safe `--jobs`.
- **Read:** `test_bitcoin --help`, `src/test/README.md`, `test/functional/README.md`.
- **Check:** you can say where each test's source lives and how long each run took.

## Drill 6: Find, break, rebuild, verify *(C-GIT-6, C-TEST-3)*
- **Achieve:** start from a reject reason string such as `bad-txns-inputs-duplicate` and find where it is raised and which commit introduced it. Break that check, rebuild only the needed target, and watch a unit test fail. Then restore it.
- <details><summary>Hint 1</summary>`git grep -n`, `git log -S`, `git blame`.</details>
- **Check:** your journal records the failing test's name and the exact assertion message.

## Drill 7: Check out someone else's PR *(C-GIT-2, C-REVIEW-3)*
- **Achieve:** online, fetch an open PR by number into a local branch. Offline, find a merged PR's merge commit and list only the author's commits and diff.
- <details><summary>Hint 1</summary>GitHub serves `pull/<N>/head`. A merge commit's second parent is the PR tip, and `^1..^2` gives you its commits.</details>
- <details><summary>Hint 2</summary>Diff against the merge-base (three dots), not the current master.</details>
- **Check:** your commit list matches the PR's "Commits" tab (when online).

## Drill 8: Write review feedback in your own words *(C-REVIEW-2, C-REVIEW-4, C-COMMS-1)*
- **Read:** `CONTRIBUTING.md` → "Peer Review" (Concept/Approach (N)ACK; code review "begins with `ACK BRANCH_COMMIT`" followed by how you reviewed it; "nit"). Then read `doc/AI_POLICY.md` with `git show master:doc/AI_POLICY.md`.
- **Achieve:** for a PR you tested in Drill 7, write (privately, in `my-work/reviews/`) a review that someone could reproduce from. Include which commit, what you built, which tests, what manual scenario, and what you broke on purpose. Post it only if it says something useful.
- There is no template here on purpose. A reviewer's value is what *they* checked.
- **Check:** could a stranger repeat your testing from your text alone?
