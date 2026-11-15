# Stage 13: The Bitcoin Core C++ Codebase, Build System and Unit Tests

> **Source checked for this stage.** This stage teaches **`master`** at **`e75b76b12c`**
> (`Merge bitcoin/bitcoin#35261: guix: disable LTO in GCC`). It was checked with
> `git -C ~/bitcoin grep <pattern> master` and `git show master:<path>`.
> Your working tree (and your existing `build/`) is still the **29.x** commit **`f490f5562d`**
> (`Merge bitcoin/bitcoin#32252: [29.x] doc: minor rel notes changes`). Every place where
> 29.x differs from master is marked **"29.x → master"**. Exercise 13.2 has you move your
> work to a topic branch made from `master` and build it there. Contributions and reviews target `master`.

Before this stage, most of the lab was Go re-implementations, `bitcoin-cli` and Python.
A reviewer has to read, build, test and reason about the **real C++**. This stage teaches
you to find your way around `src/`, rebuild only what you need on 8 GB of RAM, run and
write Boost unit tests, and read the house style that every reviewer checks.

**No-shortcuts rule.** Every exercise is a worksheet. It tells you *what to achieve* and
*which tool or file to use*. It does not show the finished command. Type every command
yourself and save it in `my-work/13-core-codebase-build-and-unit-tests/journal.md`.
Open `solutions/` only after `./check_13.sh` passes, or after three honest attempts.

---

## Objectives (competency IDs from `CURRICULUM.md`)

By the end of this stage you can:

| ID | You can... |
|---|---|
| C-GIT-1 | Keep `~/bitcoin` clean and do your stage work on a topic branch. |
| C-GIT-2 | Fetch a PR by number and list its commits (refresher of Drill 7, used in the Review lens). |
| C-GIT-6 | Use `git grep`, `git log -S`, `git log --grep` and `git blame` to find where code lives and why. |
| C-BUILD-1 | Configure Core with CMake, choosing options, presets and the build type. |
| C-BUILD-2 | Rebuild a single target with a parallelism that does not swap the M1, and use `ccache`. |
| C-BUILD-3 | Add a new unit-test file to `src/test/CMakeLists.txt` and name the main static libraries. |
| C-BUILD-4 | Say in two sentences what `depends/` and `contrib/guix/` are for. |
| C-CPP-1 | Read RAII, `std::unique_ptr` and the lock guards in real Core code. |
| C-CPP-3 | Read and use `Span` and the serialization framework (`SERIALIZE_METHODS`, `READWRITE`). |
| C-CPP-5 | Apply the `doc/developer-notes.md` naming, locking-annotation and assertion rules. |
| C-TEST-1 | Run `test_bitcoin` suites and single cases, and run `ctest` with a filter. |
| C-TEST-2 | Write a new Boost unit test with the right fixture, and prove it can fail. |
| C-DEBUG-1 (intro) | Turn on `-debug=<category>` logging and find where a category is defined. |

**Prerequisites:** Stage 00; Drills 1–2 and 5–6 of [`BUILDING_BITCOIN_CORE_FROM_SOURCE.md`](../BUILDING_BITCOIN_CORE_FROM_SOURCE.md)
(you have already built Core once). Comfortable with a terminal and basic C++ syntax.

**Estimated time:** 16 hours (6 sessions of about 2.5 h).

---

## Theory

### 1. How the source tree is organised

`src/` is grouped by **layer**. Learn the layers before the files:

| Layer | Where | What it holds |
|---|---|---|
| Consensus primitives | `src/consensus/`, `src/primitives/`, `src/script/` | Rules every node must agree on: `CheckTransaction` (`src/consensus/tx_check.cpp`), `MAX_MONEY` (`src/consensus/amount.h`), `CTransaction`/`CBlock` types, the Script interpreter. |
| Validation | `src/validation.{h,cpp}`, `src/coins.{h,cpp}`, `src/txdb.{h,cpp}` | `ChainstateManager`, `Chainstate`, block connection, the UTXO cache. (Stage 15.) |
| Kernel | `src/kernel/` | Pieces being split out so validation can be used as a library (`libbitcoinkernel`). Examples: `src/kernel/cs_main.h`, `src/kernel/chainparams.cpp`, `src/kernel/disconnected_transactions.h`. |
| Node | `src/node/` | Glue that runs a full node: `blockstorage.cpp` (blk/rev files), `miner.cpp`, `txdownloadman_impl.cpp`, `connection_types.h`. |
| P2P | `src/net.{h,cpp}`, `src/net_processing.{h,cpp}`, `src/protocol.h`, `src/addrman.cpp` | Sockets and connections vs. protocol logic. (Stage 14.) |
| Policy and mempool | `src/policy/`, `src/txmempool.{h,cpp}` | Standardness, RBF, TRUC, packages. |
| RPC | `src/rpc/` | One file per area: `blockchain.cpp`, `net.cpp`, `mempool.cpp`, `rawtransaction.cpp`... |
| Wallet | `src/wallet/` | Descriptor wallet, coin selection. |
| Utilities | `src/util/`, `src/common/`, `src/crypto/`, `src/support/` | Strings, checks (`src/util/check.h`), locks (`src/sync.h`), hashes. |
| Interfaces and IPC | `src/interfaces/`, `src/ipc/` | Abstract interfaces between node, wallet and GUI; Cap'n Proto IPC for the multiprocess build. |
| Tests | `src/test/` (unit), `src/test/fuzz/` (fuzz), `src/bench/`, `test/functional/` (Python) | |

The build turns these into static libraries. You will see them in `src/CMakeLists.txt`:
`bitcoin_consensus`, `bitcoin_common`, `bitcoin_node`, `bitcoin_cli`, `bitcoin_clientversion`
(and, on master, `bitcoin_ipc`), and in subdirectories `bitcoin_util`
(`src/util/CMakeLists.txt`), `bitcoin_crypto` (`src/crypto/CMakeLists.txt`) and
`bitcoinkernel` (`src/kernel/CMakeLists.txt`). The library a file belongs to tells you what it
is allowed to depend on. For example, consensus code must not reach into the wallet.

### 2. The CMake build, in depth

Bitcoin Core moved from Autotools to CMake in **PR #30454** (`build: Introduce CMake-based build system`,
verified with `git log --grep`). The ideas you need:

- **macOS dependencies (master).** `doc/build-osx.md` on master says `brew install cmake boost capnp`.
  **29.x → master:** libevent is no longer a dependency. `capnp` is new because the multiprocess/IPC
  build (`ENABLE_IPC`) is now **ON by default** on non-Windows systems.
- **Out-of-tree build directory.** `cmake -B <dir>` configures into a separate directory, so you
  can keep several builds side by side (for example `build/` for daily work and `build_debug/` for
  `lldb`). Your current build is `~/bitcoin/build`. Its `CMakeCache.txt` records
  `CMAKE_BUILD_TYPE=RelWithDebInfo`, `BUILD_TESTS=ON`, `ENABLE_WALLET=ON`.
- **Options** live in the top-level `CMakeLists.txt` as `option(...)` and `cmake_dependent_option(...)`.
  The ones you will use on master: `BUILD_TESTS`, `BUILD_BENCH`, `BUILD_FUZZ_BINARY`, `BUILD_GUI`,
  `ENABLE_WALLET`, `WITH_CCACHE`, `WITH_ZMQ`, `ENABLE_IPC`, `BUILD_KERNEL_LIB` (+ `BUILD_KERNEL_TEST`),
  `BUILD_UTIL_CHAINSTATE`, `BUILD_BITCOIN_BIN`, `CMAKE_COMPILE_WARNING_AS_ERROR`. Note: the tests option is
  **`BUILD_TESTS`**, not CMake's generic `BUILD_TESTING`.
  **29.x → master:** `WITH_MULTIPROCESS` (default OFF) was replaced by `ENABLE_IPC` (default ON, needs `capnp`).
  `WERROR` became `CMAKE_COMPILE_WARNING_AS_ERROR`. `WITH_SQLITE`/`WITH_BDB` are gone (the SQLite descriptor wallet is the only wallet).
  To keep a small build on 8 GB you may choose `-DENABLE_IPC=OFF`. Write down why if you do.
- **Presets.** `CMakePresets.json` defines `dev-mode` (all features on, including fuzz, bench, GUI and
  shared libs; binary dir `build_dev_mode`), `libfuzzer`, `libfuzzer-nosan` and two Windows presets
  (`vs2026`, `vs2026-static` on master; `vs2022*` on 29.x). Do not run `dev-mode` on 8 GB unless you
  have closed everything else. It enables much more than you need.
- **Build type.** `RelWithDebInfo` is the default (optimised plus debug symbols). `Debug` is easier
  to step through in `lldb` (Stage 17).
- **Targets.** You almost never need `cmake --build build` with no target. Build `test_bitcoin`,
  `bitcoind` or `bitcoin-cli` alone with `--target`. List every target with `--target help`
  (Unix Makefiles generator).
- **ccache** is wired in `cmake/ccache.cmake`. It is used only if the `ccache` program is found
  when you configure, and `WITH_CCACHE` defaults to `ON`. **On this machine `ccache` is not installed
  yet** (`which ccache` printed nothing when this stage was written). So you must install it and then
  **re-configure**. Read `doc/productivity.md`, "Cache compilations with ccache".
- **8 GB rule.** Each C++ compile job can use 1–2 GB of RAM in heavy files (`validation.cpp`,
  `net_processing.cpp`, the wallet). Use `-j2` or `-j3`, not `-j8`. Watch memory pressure in Activity Monitor.

### 3. Unit tests (Boost.Test)

- Every file `src/test/foo_tests.cpp` opens a suite named **`foo_tests`**
  (`doc/developer-notes.md`, "Test suite naming convention"), usually with
  `BOOST_FIXTURE_TEST_SUITE(foo_tests, BasicTestingSetup)`.
- **Helpers:** on master, small test helpers such as `HasReason` live in `src/test/util/common.h`
  (**29.x → master:** on 29.x they were in `setup_common.h`).
- **Fixtures** live in `src/test/util/setup_common.h`: `BasicTestingSetup` (args, logging, random
  context), `ChainTestingSetup`, `TestingSetup` (a full chainstate), `RegTestingSetup`, and
  `TestChain100Setup` (a regtest chain with 100 mature coinbase blocks). Pick the **smallest**
  fixture that works. A bigger fixture is slower and hides what the test depends on.
- **Checks:** `BOOST_CHECK`, `BOOST_CHECK_EQUAL`, `BOOST_CHECK_MESSAGE`, `BOOST_CHECK_EXCEPTION`,
  `BOOST_REQUIRE` (stops the case on failure).
- **Running:** read `src/test/README.md`. You need `--run_test=<suite>` or `<suite>/<case>`,
  `--log_level=all`, `--list_content`, and the `--` separator that passes node arguments
  such as `-printtoconsole=1` or `-testdatadir=<dir>` to the test. `ctest --test-dir build` runs the whole
  registered set. `-R <regex>` filters it.
- **New file?** It must be added to `add_executable(test_bitcoin ...)` in `src/test/CMakeLists.txt`
  (the file says not to use generator expressions there). Otherwise it is never compiled.

### 4. Developer-notes essentials a reviewer checks on every PR

Read `doc/developer-notes.md` in full once. Then memorise these:

- **Naming:** `snake_case` variables, `m_` members, `g_` globals, `ALL_CAPS` constants,
  `UpperCamelCase` functions and classes, and **no `C` prefix on new classes** (old classes such as
  `CBlockIndex` keep theirs).
- **Locking.** `LOCK(cs)` (`src/sync.h`) takes a scoped RAII lock. `WITH_LOCK(cs, expr)` locks for one expression.
  `AssertLockHeld(cs)` checks at runtime. Clang **thread-safety annotations** are checked at
  compile time: `GUARDED_BY(mutex)` on data, `EXCLUSIVE_LOCKS_REQUIRED(mutex)` on a function the caller
  must hold the lock for, and `EXCLUSIVE_LOCKS_REQUIRED(!mutex)` / `LOCKS_EXCLUDED(mutex)` for
  "must not hold". The global `cs_main` is declared in `src/kernel/cs_main.h` (a `RecursiveMutex`).
  Example: `ChainstateManager::ActiveChain()` in `src/validation.h` is
  `EXCLUSIVE_LOCKS_REQUIRED(GetMutex())`, and `GetMutex()` returns `::cs_main`.
- **Assertions** (`src/util/check.h`, developer-notes "Assertions and Checks"):
  `Assert(x)` / `assert` mean "unsafe to continue, terminate". `CHECK_NONFATAL(x)` throws, which is right for RPC
  code. `Assume(x)` crashes only in debug builds, is always evaluated, and is safe to continue. **None of them
  may validate network or user input.** That must return an error.
- **RAII and ownership:** `std::unique_ptr` for owned heap objects, no naked `new`/`delete`.
  Scoped locks, file handles and DB batches clean up in destructors.
- **`std::span`**: pass a view of contiguous memory instead of `const std::vector<T>&` when the
  function does not care about the container. Master's developer notes say "Use `std::span` as function
  argument when it can operate on any range-like container". `src/span.h` now holds only helpers
  (such as `SpanPopBack`). **29.x → master:** 29.x still had Core's own `Span` class in `src/span.h`. It was
  replaced by `std::span` in merged PR **#31519** (`refactor: Use std::span over Span`), after #31540
  (`refactor: std::span compat fixes`). You will still see `Span{...}` in 29.x-era code and old PR diffs.

### 5. The serialization framework (`src/serialize.h`)

Everything that crosses the wire or hits disk goes through `Serialize`/`Unserialize`:

- `SERIALIZE_METHODS(cls, obj) { READWRITE(obj.a, obj.b); }` writes **one** templated body that
  works for both directions. The macro expands to `BASE_SERIALIZE_METHODS` + `FORMATTER_METHODS`.
  Real examples: `COutPoint` and `CTxOut` in `src/primitives/transaction.h`, `CBlockHeader` in
  `src/primitives/block.h`.
- `READWRITE(...)` expands to `ser_action.SerReadWriteMany(s, ...)`.
- **CompactSize** (`WriteCompactSize`, `ReadCompactSize`, `GetSizeOfCompactSize`): 1 byte below 253,
  then `0xfd`+2, `0xfe`+4 and `0xff`+8 bytes. `ReadCompactSize` rejects **non-canonical** encodings
  (`"non-canonical ReadCompactSize()"`) and, by default, sizes above `MAX_SIZE` (`0x02000000`)
  (`"ReadCompactSize(): size too large"`). You will write a unit test for this in Exercise 4.
- `VARINT(obj)` is a different encoding (MSB base-128), used on disk (for example in the coins DB), never for
  P2P message lengths.
- Streams: `DataStream` (`src/streams.h`) is the in-memory byte stream used in tests and P2P.

### 6. Kernel and multiprocess orientation

- **`src/kernel/`** + `BUILD_KERNEL_LIB` + the experimental `bitcoin-chainstate` tool
  (`src/bitcoin-chainstate.cpp`, option `BUILD_UTIL_CHAINSTATE`) are the "validation as a library" effort.
  When a PR moves code into `kernel/`, the reviewer asks: *does this file now pull in anything
  node-only (args, GUI, wallet, global state)?*
- **Multiprocess** (`doc/multiprocess.md`, option `WITH_MULTIPROCESS`, `src/ipc/`, `src/interfaces/`):
  it splits node, wallet and GUI into separate processes that talk over Cap'n Proto. `src/interfaces/*.h`
  are the boundaries. A PR that changes an interface method changes an IPC contract.

### 7. Logging categories and `-debug`

- Categories are the `BCLog::LogFlags` enum (in `src/logging.h`) (`NET`, `MEMPOOL`, `CMPCTBLOCK`,
  `VALIDATION`, `BLOCKSTORAGE`...). Their command-line names are in `LOG_CATEGORIES_BY_STR` in
  `src/logging.cpp` (`"net"`, `"validation"`...).
- Macros: `LogInfo`, `LogWarning`, `LogError` (always on) and `LogDebug(category, ...)`,
  `LogTrace(category, ...)` (only with `-debug=<category>`). On master they are defined in **`src/util/log.h`**.
  The level-based API came from merged PR #28318. `LogPrintLevel` was removed in #34051.
- **Rate limiting (master).** Merged PR **#32604** (`log: Mitigate disk filling attacks by rate limiting
  LogPrintf, LogInfo, LogWarning, LogError`) added a per-source-location budget (`RATELIMIT_MAX_BYTES`,
  `RATELIMIT_WINDOW`, option `-logratelimit`). **29.x → master:** 29.x has no rate limiting, and the macros
  are in `src/logging.h`.
- A reviewer asks: *is this new log line unconditional? Can a peer trigger it repeatedly
  (disk-filling)? Should it be `LogDebug`?*

---

## Exercises

All worksheets are in [`exercises/`](./exercises/). Do them in order.

| # | Worksheet | Produces | Checked by |
|---|---|---|---|
| 1 | [`01_scavenger_hunt.md`](./exercises/01_scavenger_hunt.md): find 16 things in the tree with `git grep`, `git log` and ctags | `my-work/13-.../scavenger.txt` | `./check_13.sh hunt` |
| 2 | [`02_build_targets_and_ccache.md`](./exercises/02_build_targets_and_ccache.md): install ccache, re-configure, time a cold vs. warm single-target rebuild | timings in your journal | `./check_13.sh build` |
| 3 | [`03_run_and_read_unit_tests.md`](./exercises/03_run_and_read_unit_tests.md): run suites and cases with filters, read `serialize_tests.cpp` | journal answers | `./check_13.sh build` |
| 4 | [`04_write_a_unit_test.md`](./exercises/04_write_a_unit_test.md): write `compactsize_boundary_tests.cpp` from the skeleton, register it, mutation-test it | a passing new suite | `./check_13.sh unit` |
| 5 | [`05_devnotes_serialization_drill.md`](./exercises/05_devnotes_serialization_drill.md): locking annotations, `Assume`/`Assert`, `SERIALIZE_METHODS` | journal answers | `python3 tools/check_facts.py` (facts) + self-check vs. `solutions/` |
| 6 | [`06_trace_getblockcount.md`](./exercises/06_trace_getblockcount.md): trace one RPC from HTTP into `ChainstateManager` | a call-chain diagram in your journal | `python3 tools/check_facts.py` (facts) + self-check vs. `solutions/` |

Run the checker from the stage directory:

```text
./check_13.sh hunt     # verifies scavenger answers (prints PASS/FAIL per question, never the answer)
./check_13.sh build    # verifies ccache is found and test_bitcoin exists and runs a suite
./check_13.sh unit     # verifies your new test file, its CMake registration, and that it passes
./check_13.sh all
```

---

## Checkpoint

```bash
./lab.sh check 13
```

Runs: ./check_13.sh, python3 ../tools/check_facts.py . (the "Checkable facts" of exercises 5 and 6). Each prints PASS/FAIL with a reason, never the answer. Needs your Bitcoin Core build (`BITCOIN_ROOT`, default `~/bitcoin`).
Open `solutions/` only after this passes or after three honest attempts.

## Common errors

| Error | Cause | What to do |
| :--- | :--- | :--- |
| `CMake Error ... Imported target "PkgConfig::libevent_core" includes non-existent path "/opt/homebrew/Cellar/libevent/<old version>/include"` or `No rule to make target '/opt/homebrew/Cellar/libevent/<old version>/lib/libevent_extra.dylib'` | Homebrew upgraded a dependency after you configured; `CMakeCache.txt` still holds the old Cellar path. Seen on this lab machine on 2026-11-15 (libevent `2.1.13` → `2.1.13_1`). | Remove the stale cache entries and reconfigure: read `cmake --help` for `-U` and drop the entries matching `*libevent*`, or delete the build dir and configure again. Then rebuild only the target you need. |
| A one-line change in `src/test/CMakeLists.txt` recompiles hundreds of files | Reconfiguring can change flags or generated headers, so CMake rebuilds whatever depends on them. | Expected. Build only `test_bitcoin` with a `-j` that fits 8 GB, and let `ccache` (Exercise 2) make the next rebuild fast. |
| `Test setup error: no test cases matching filter` | Your suite is not compiled in: the file is not listed in `src/test/CMakeLists.txt`, or you did not rebuild after adding it. | Check the list, rebuild `test_bitcoin`, then `--list_content` and look for your suite. |

## Self-check quiz (answer from memory; answers in [`solutions/quiz_answers.md`](./solutions/quiz_answers.md))

After marking your answers, record the score in `my-work/quiz-scores.env` as `QUIZ_13=<right>/<total>` (Gates 1 and 2 ask for 80%; `./lab.sh progress` reads it).

1. Which CMake option builds `test_bitcoin`, and what is its default?
2. You edited only `src/test/serialize_tests.cpp`. What is the smallest build command that lets you re-run that suite?
3. What does `ccache` need *at configure time* for Core's build to use it?
4. Name three fixtures from `setup_common.h` in order of increasing cost. When would you choose each one?
5. What is the difference between `Assert`, `Assume` and `CHECK_NONFATAL`? Which one may validate a peer's message?
6. What does `EXCLUSIVE_LOCKS_REQUIRED(!m_mutex)` mean, and who checks it?
7. Why does `ReadCompactSize` reject `fd 00 00`? What could go wrong if it did not?
8. In `getblockcount`, which lock is taken and why is it required?
9. Where are `-debug` category names mapped to enum values?
10. A PR adds `src/test/foo_tests.cpp` but forgets `src/test/CMakeLists.txt`. What does CI show, and what does a reviewer say?

---

## Review lens: using this stage on a real PR

**Files you will now read in any PR:** `CMakeLists.txt`, `src/CMakeLists.txt`, `src/test/CMakeLists.txt`,
`cmake/*.cmake`, `src/serialize.h`, `src/streams.h`, `src/util/check.h`, `src/sync.h`,
`src/test/util/setup_common.h`, `doc/developer-notes.md`.

**Invariants to protect:**
- Serialization formats on the wire and on disk are **compatibility contracts**. Changing a
  `SERIALIZE_METHODS` body changes a P2P message or a database format.
- A new source file is registered in the right library (`bitcoin_node` vs `bitcoin_common`, and so on).
  Layer rules are not broken (consensus must not include node or wallet headers).
- New shared state carries `GUARDED_BY`, and functions that need a lock say so with
  `EXCLUSIVE_LOCKS_REQUIRED`.
- Assertions are never used to reject untrusted input.

**Questions to ask on a PR in this area:**
1. Does every commit build and pass `test_bitcoin` by itself? (Check with `git rebase -x`. That comes later, in Stage 19.)
2. Is the test in the right suite file? Does the suite name match the file? Is the fixture the smallest that works?
3. If I revert the non-test change, does the new test fail? (Mutation test, C-TEST-3.)
4. Does a serialization change keep old data readable? Is there a version or format flag?
5. Is a new log line `LogDebug`, or can an attacker trigger it unconditionally?

**Real merged PRs in this area (verified at `f490f5562d` with `git log --oneline --grep`):**
- **#30454**: `build: Introduce CMake-based build system` (merge `338bc2cd26`).
- **#28318**: `logging: Simplify API for level based logging` (merge `7ff8e6b240`).
- **#31869**: `cmake: Add libbitcoinkernel target` (merge `9da0820ec5`).

For each one, fetch the merge commit, read `git show --stat <merge>`, and write in your journal
one invariant the reviewers had to check.

---

## Proof-of-work output

1. A **public gist or blog post**, written by you, called "My first Bitcoin Core unit test". Include your
   `compactsize_boundary_tests.cpp`, the mutation you made, the failing output, and what that
   proved. Do not open a PR upstream with it. The tests duplicate coverage that mostly exists, and maintainers
   do not want practice PRs.
2. Your getblockcount call-chain diagram, posted as an answer the next time a **Bitcoin Core PR Review
   Club** (bitcoincore.reviews) meeting covers an RPC or build PR. Or bring it to a BitDevs Kisumu session.
