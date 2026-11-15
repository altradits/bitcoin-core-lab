# Stage 17: Fuzzing, Sanitizers, Debugging & CI — Testing Bitcoin Core at Scale

> Source checked: `~/bitcoin` at `f490f5562d Merge bitcoin/bitcoin#32252: [29.x] doc: minor rel notes changes`
> (tag `v29.0`, detached HEAD) **and** local `master` at `e75b76b12c Merge bitcoin/bitcoin#35261: guix: disable LTO in GCC`
> (read with `git -C ~/bitcoin show master:<path>`). This stage teaches **master**, because
> PRs are opened against master. Where 29.x differs, a note says so. Every CMake option, file and
> function below was found with `grep`/`git grep`; anything not verifiable is marked **UNVERIFIED**.

**Estimated time:** 16 hours (the `CURRICULUM.md` budget). Builds add wall-clock time; on your
8 GB M1 a fuzz build can take 1–2 hours. Start builds before you read, not after.

**No-Shortcuts Rule.** Worksheets say *what* to achieve; you type every command and write every
line. Hints are layered and never give the full command. Solutions in [`solutions/`](./solutions/)
only after a check passes or three honest attempts. Log every command in `my-work/17-fuzzing-sanitizers-debugging-and-ci/journal.md`.

---

## Objectives (competency IDs from `CURRICULUM.md`)

| ID | In this stage you can... |
|----|------------|
| `C-FUZZ-1` Build & run | Configure a fuzz build (`-DBUILD_FOR_FUZZING=ON`), know why Apple clang cannot do coverage-guided fuzzing, and run one target over inputs. |
| `C-FUZZ-2` Write a harness | Write a **new** fuzz target `taproot_merkle` with `FuzzedDataProvider` and real invariants, and register it in `src/test/fuzz/CMakeLists.txt`. |
| `C-FUZZ-3` Corpus & crashes | Use (part of) the `bitcoin-core/qa-assets` corpus, reproduce a crash from a single input file, and debug it. |
| `C-DEBUG-1` Debuggers & logs | Debug `bitcoind` and `test_bitcoin` with `lldb` (breakpoints in `Chainstate::ConnectBlock`, `EvalScript`), and use `-debug=<category>` and the `logging` RPC. |
| `C-DEBUG-2` Sanitizers | Explain ASan, UBSan, TSan, MSan (and LSan), know which work on macOS/arm64, build with `-DSANITIZERS=...`, and read a report. |
| `C-DEBUG-3` CI & lint | Read `ci/`, map a CI job to its `ci/test/00_setup_env_*.sh` file, reproduce a failure locally, run the linters and clang-tidy. |
| `C-GIT-5` Bisect | Find the commit that introduced a behaviour change with `git bisect run`, without compiling. |
| `C-TEST-4` Benchmarks | Run `bench_bitcoin` with `-filter` before/after a change and report numbers honestly. |
| `C-BUILD-4` Reproducible builds | Say what `depends/` and Guix (`contrib/guix/`) are for and when a reviewer needs them. |

## Prerequisites

- Stage 13 (CMake build, `test_bitcoin`, `ctest`). Stage 04 (functional tests). Stage 16 helps
  for exercise 17.3 (the harness fuzzes taproot hashing).
- Free disk: ~15 GB for a second worktree plus a fuzz build directory.
- `brew` is installed; `ccache`, `ninja`, Homebrew `llvm` and `cargo` were **not** installed when
  this stage was written (checked with `which`). You will install what you need yourself.

---

## 8 GB M1 survival rules (read before every build)

1. **One heavy thing at a time.** No `bitcoind`, no Docker, no Chrome with 30 tabs while compiling.
   Run `./lab.sh rest` first.
2. **Parallelism:** `cmake --build <dir> -j3` for a normal or no-sanitizer fuzz build;
   `-j2` for ASan/UBSan/TSan builds (instrumented compilation uses more memory per process).
   `-j8` (all cores) **will** swap on 8 GB. Never use `-j$(sysctl -n hw.ncpu)` here.
3. **Install ccache** (`brew install ccache`; Core's `WITH_CCACHE` option is `ON` by default and
   uses it when found). Rebuilds after switching branches become minutes, not hours.
4. **Build only what you need.** `-DBUILD_FOR_FUZZING=ON` disables every other target. For unit
   tests only, build the `test_bitcoin` target (`--target test_bitcoin`), not everything.
5. **Watch pressure:** `memory_pressure` (built in) or Activity Monitor → Memory → "Memory
   Pressure" graph. If it goes red, stop the build (Ctrl-C) and lower `-j`. A build that was
   interrupted resumes where it stopped.
6. **Sanitizer test runs are slow and big.** Run single suites (`--run_test=...`), not the
   whole `ctest`, under ASan.

---

## Theory

### 1. Anatomy of a fuzz target (`src/test/fuzz/`)

- `src/test/fuzz/fuzz.h` defines `#define FUZZ_TARGET(...) DETAIL_FUZZ(__VA_ARGS__)`. The macro
  declares `void name##_fuzz_target(FuzzBufferType buffer)` and a static object whose constructor
  calls `FuzzFrameworkRegisterTarget(#name, ..., {__VA_ARGS__})` before `main`. Options go in
  `FuzzTargetOptions` (`.init = ...` for one-time setup, `.hidden = true` to hide a target).
  `FuzzBufferType` is `std::span<const uint8_t>`.
- `src/test/fuzz/fuzz.cpp` holds `main` / `LLVMFuzzerTestOneInput`. The target is chosen with the
  `FUZZ` environment variable. `PRINT_ALL_FUZZ_TARGETS_AND_ABORT=1` lists every compiled target.
  Without a fuzzing engine, `main` reads inputs from files/directories given as arguments (or stdin)
  and runs each once — this is how crashes are **reproduced**.
- `FuzzedDataProvider` (`src/test/fuzz/FuzzedDataProvider.h`, from LLVM) turns raw bytes into
  typed values: `ConsumeIntegral<T>()`, `ConsumeIntegralInRange`, `ConsumeBool`, `ConsumeBytes<T>(n)`.
  Core adds helpers in `src/test/fuzz/util.h`: `ConsumeRandomLengthByteVector`,
  `ConsumeFixedLengthByteVector`, `ConsumeUInt256`, `ConsumeMoney`, `CallOneOf`, `LIMITED_WHILE`.
- Read `src/test/fuzz/fee_rate.cpp` (≈35 lines) as your first full example: consume values,
  call the code under test, `assert` relationships that must always hold.
- A good harness: deterministic, bounded input sizes (`LIMITED_WHILE`, max lengths), no reliance
  on global state, invariants stated as `assert`s, and it never asserts something the *harness*
  made false (e.g. passing sizes the function documents as precondition violations).

### 2. Building for fuzzing (CMake option names checked on master and 29.x)

| Option / preset | Meaning |
|-----------------|---------|
| `BUILD_FOR_FUZZING` | "Build for fuzzing. Enabling this will disable all other targets and override BUILD_FUZZ_BINARY." |
| `BUILD_FUZZ_BINARY` | Build the `fuzz` binary alongside normal targets (default OFF). |
| `SANITIZERS` | Comma list passed to `-fsanitize=`, e.g. `address,undefined`, `thread`, `fuzzer`. |
| `--preset=libfuzzer` (`CMakePresets.json`) | `build_fuzz/`, clang, `SANITIZERS=undefined,address,fuzzer`, `-ftrivial-auto-var-init=pattern`. |
| `--preset=libfuzzer-nosan` | `build_fuzz_nosan/`, `SANITIZERS=fuzzer`. |

**macOS reality (important):** Apple's clang has no libFuzzer runtime. On master,
`doc/fuzzing.md` says: *"Support for fuzzing on macOS is not officially maintained by this
project... we recommend fuzzing on Linux instead... Reproducing and debugging fuzz testcases on
macOS is supported, by building the fuzz binary without support for any specific fuzzing engine."*
That is exactly what the macOS CI job does: on master `ci/test/00_setup_env_mac_native_fuzz.sh` sets
`BITCOIN_CONFIG` to `-DBUILD_FOR_FUZZING=ON` plus a larger linker stack size and libc++ debug hardening
(`-D_LIBCPP_HARDENING_MODE=_LIBCPP_HARDENING_MODE_DEBUG`) — **no** `SANITIZERS=fuzzer` — and replays the corpus.
(On 29.x the same file had only `-DBUILD_FOR_FUZZING=ON`.)
(29.x's `doc/fuzzing.md` still documented `brew install llvm lld` + `-fuse-ld=lld` for libFuzzer
on macOS; master removed that. If you try it, treat it as unsupported.)

So on your M1 you will:
1. Build the engine-less fuzz binary with Apple clang → write harnesses, replay corpora, reproduce
   and debug crashes. (`C-FUZZ-1..3` are fully achievable this way.)
2. For **coverage-guided** fuzzing campaigns (hours of mutation), use a Linux machine or VM later.
   Docker Desktop on 8 GB with a fuzz build inside is possible but tight; not recommended while
   anything else is running.

### 3. The corpus: `bitcoin-core/qa-assets`

`doc/fuzzing.md`: the seed corpora live in `https://github.com/bitcoin-core/qa-assets`, one folder
per target under `fuzz_corpora/`. Every PR is run against all of them in CI. The full repo is large
(**size UNVERIFIED** — check before cloning); you only need a few targets, so use a partial clone
with sparse checkout and fetch only `fuzz_corpora/<target>` folders you use.
Reproducing a CI crash (master `doc/fuzzing.md`, "Reproduce a fuzzer crash reported by the CI"):
update qa-assets to the exact commit CI used, build with the same sanitizers, then run the binary
on the single crash file: `FUZZ=<target> <build>/bin/fuzz <path/to/crash-file>`.

### 4. Sanitizers (`-DSANITIZERS=...`, `doc/developer-notes.md` "Sanitizers")

| Sanitizer | Finds | macOS arm64 with Apple clang |
|-----------|-------|------------------------------|
| ASan `address` | heap/stack overflow, use-after-free, double free | Yes |
| UBSan `undefined` (+ `integer`, `float-divide-by-zero` as CI uses) | signed overflow, misaligned access, bad shifts, invalid enum/bool values | Yes |
| TSan `thread` | data races, lock-order inversions | Yes (cannot combine with ASan) |
| MSan `memory` | reads of uninitialised memory | **No** — Linux only; CI job `00_setup_env_native_msan.sh` |
| LSan (leak) | leaks | Bundled with ASan on Linux; on macOS **UNVERIFIED/limited** — do not rely on it |
| Valgrind / heaptrack | memory errors / heap profiling | **Not available on Apple Silicon macOS.** CI runs valgrind on Linux (`00_setup_env_native_valgrind.sh`, master `ci/test/wrap-valgrind.py`). |

Suppressions live in `test/sanitizer_suppressions/` (`lsan`, `tsan`, `ubsan`); developer-notes shows
the `LSAN_OPTIONS` / `TSAN_OPTIONS` / `UBSAN_OPTIONS` exports. The ASan CI job uses
`-DSANITIZERS=address,float-divide-by-zero,integer,undefined` (`ci/test/00_setup_env_native_asan.sh`).

### 5. Debugging on macOS with `lldb`

- Default `cmake -B build` is `RelWithDebInfo` (your current `build/` is — checked in
  `build/CMakeCache.txt`). Variables may be "optimized out"; for serious stepping configure a
  separate `-DCMAKE_BUILD_TYPE=Debug` build dir. Debug builds also turn on `DEBUG_LOCKORDER` and
  `DEBUG_LOCKCONTENTION` (developer-notes).
- Useful breakpoints: `Chainstate::ConnectBlock` (validation.cpp), `CheckInputScripts`,
  `MemPoolAccept::PreChecks`, `EvalScript`. Note: on master the single-tx path is
  `MemPoolAccept::AcceptSingleTransactionInternal`; on 29.x it is `AcceptSingleTransaction`.
- Source paths: if ccache strips absolute paths, lldb may not find sources; developer-notes gives
  `settings set target.source-map ./src /path/to/project/root/src` for `.lldbinit`.
- Logs: `-debug=<category>` at startup, `bitcoin-cli logging '["mempool"]' '[]'` at runtime;
  `-loglevel=trace` on master turns on all severities.

### 6. CI, lint and clang-tidy

- `ci/` (master): `ci/test_run_all.sh` + one `ci/test/00_setup_env_<job>.sh` per job + numbered
  steps (`01_base_install.sh`, `02_run_container.py` (was `.sh` on 29.x), `03_test_script.sh`).
  `ci/README.md`: run a job locally with
  `env -i HOME="$HOME" PATH="$PATH" USER="$USER" FILE_ENV="./ci/test/00_setup_env_<job>.sh" ./ci/test_run_all.sh`
  — it needs Docker and builds in place: **on 8 GB, only try the lint job or a small native job, one at a time.**
- Job names you see on GitHub (e.g. *ASan + LSan + UBSan + integer*) map to a `file-env:` entry in
  `.github/workflows/ci.yml` (master), e.g. `./ci/test/00_setup_env_native_asan.sh`.
- The cheap way to reproduce most CI failures: read the failing job's `00_setup_env_*.sh`, copy
  its `BITCOIN_CONFIG` CMake flags and the failing test name, and run just that locally.
- Lint (master `test/lint/README.md`): `./ci/lint.py` runs all linters inside the CI container
  (Docker), or run the Rust runner directly:
  `( cd ./test/lint/test_runner/ && RUST_BACKTRACE=1 cargo run -- --lint=<name> )` (needs `cargo`).
  On 29.x the container route was a `docker build ... ci/lint_imagefile` command instead of `ci/lint.py`.
- clang-tidy: configure with clang and `-DCMAKE_EXPORT_COMPILE_COMMANDS=ON`, then
  `run-clang-tidy -p ../build` from `src/`, or `git diff | clang-tidy-diff -p2 -path ../build`
  for changed lines (developer-notes). Needs Homebrew `llvm` on macOS (Apple ships no clang-tidy).

### 7. Benchmarks and reproducible builds (short)

- `-DBUILD_BENCH=ON` builds `bench_bitcoin`; `-list`, `-filter=<regex>`, `-min-time=<ms>` (from
  `src/bench/bench_bitcoin.cpp`). On master `src/bench/verify_script.cpp` has
  `VerifyScriptP2TR_KeyPath` and `VerifyScriptP2TR_ScriptPath` (PR #35038). Laptop numbers are
  noisy: plug in power, close apps, run several times, report the spread.
- `depends/` builds pinned versions of every dependency; `contrib/guix/` builds bit-for-bit
  reproducible release binaries. A reviewer needs them for build-system PRs and when verifying
  release binaries; not for normal code review.

---

## Exercises

All worksheets are in [`exercises/`](./exercises/). Do them in order.

| # | Worksheet | Time | IDs | Checker |
|---|-----------|------|-----|---------|
| 17.1 | [Fuzz target anatomy](./exercises/17.1-fuzz-anatomy.md) | 1.5 h | C-FUZZ-1, C-FUZZ-2 | `python3 tools/check_facts.py` (facts) |
| 17.2 | [Engine-less fuzz build + corpus replay on 8 GB](./exercises/17.2-fuzz-build-and-corpus.md) | 2.5 h (+build) | C-FUZZ-1, C-FUZZ-3 | — |
| 17.3 | [Write a NEW target: `taproot_merkle`](./exercises/17.3-new-fuzz-target.md) + [skeleton](./exercises/taproot_merkle_skeleton.cpp) | 3 h | C-FUZZ-2, C-FUZZ-3 | `check_fuzz_target.py` |
| 17.4 | [Sanitizers](./exercises/17.4-sanitizers.md) | 2 h (+build) | C-DEBUG-2 | `check_sanitizer_build.py` + `python3 tools/check_facts.py` |
| 17.5 | [lldb on bitcoind and test_bitcoin](./exercises/17.5-lldb.md) | 2 h | C-DEBUG-1 | `python3 tools/check_facts.py` (facts) |
| 17.6 | [git bisect drill](./exercises/17.6-git-bisect.md) | 1.5 h | C-GIT-5 | `check_bisect.py` |
| 17.7 | [Lint, clang-tidy, CI reproduction, bench](./exercises/17.7-lint-ci-bench.md) | 2.5 h | C-DEBUG-3, C-TEST-4, C-BUILD-4 | `python3 tools/check_facts.py` (facts) |

---

## Checkpoint

```bash
./lab.sh check 17
```

Runs: python3 check_fuzz_target.py, python3 check_bisect.py, python3 check_sanitizer_build.py, python3 ../tools/check_facts.py . (facts of 17.1, 17.4, 17.5, 17.7). Each prints PASS/FAIL with a reason, never the answer. Both take an optional path: your fuzz worktree (default `~/bitcoin-fuzz`) and your Bitcoin Core checkout (default `~/bitcoin`).
Open `solutions/` only after this passes or after three honest attempts.

## Self-check quiz (answers in [`solutions/quiz-answers.md`](./solutions/quiz-answers.md))

After marking your answers, record the score in `my-work/quiz-scores.env` as `QUIZ_17=<right>/<total>` (Gates 1 and 2 ask for 80%; `./lab.sh progress` reads it).

1. What does `FUZZ_TARGET(foo)` expand to, and how does the `fuzz` binary know which target to run?
2. Why can you not do coverage-guided fuzzing with Apple's clang, and what *can* you do on macOS?
3. Which CMake option builds only the fuzz binary? Which preset adds ASan+UBSan+libFuzzer?
4. Name two Core helpers in `src/test/fuzz/util.h` and say why bounded lengths matter.
5. You get a CI log: "Test unit written to ./crash-<hash>" for target `process_message`. List the steps to reproduce it locally.
6. Which sanitizer finds a data race? Which finds use-after-free? Which one cannot run on macOS?
7. Why might `p variable` in lldb print "optimized out", and what do you change?
8. What does `git bisect run <script>` expect the script's exit codes to mean (good, bad, skip)?
9. Where would you look to find the exact CMake flags of the CI job "ASan + LSan + UBSan + integer"?
10. Why are valgrind and heaptrack not part of your macOS workflow, and where do they still run?

---

## Review lens

**Files:** `src/test/fuzz/*.cpp`, `src/test/fuzz/util.h`, `src/test/fuzz/fuzz.{h,cpp}`,
`src/test/fuzz/CMakeLists.txt`, `CMakeLists.txt`, `CMakePresets.json`, `cmake/`,
`ci/test/00_setup_env_*.sh`, `test/sanitizer_suppressions/*`, `test/lint/`, `doc/fuzzing.md`,
`doc/developer-notes.md`.

**Invariants / questions for any PR:**
1. *Does it add or change behaviour reachable from untrusted input (P2P, RPC, files)?* Then ask:
   is there a fuzz target covering it? Did the author run the existing corpus (`qa-assets`) for the
   affected targets? Would you add a harness?
2. *For a new harness:* is it deterministic (no wall-clock time, no unseeded randomness), bounded
   (no giant allocations from a 4-byte length), and asserting real invariants rather than
   "doesn't crash" only? Does it respect preconditions the function asserts?
3. *For a sanitizer suppression added to `test/sanitizer_suppressions/`:* is it hiding a real
   bug? Why is it safe? Is it as narrow as possible?
4. *For a CI change:* which jobs change, what runs less often now, and can you reproduce the job
   locally from its `00_setup_env_*.sh`?
5. *For a refactor:* run the relevant fuzz targets over the corpus before and after.

**Real merged PRs (verified with `git -C ~/bitcoin log --oneline --merges --grep=... master`):**
- `#32113` — *fuzz: enable running fuzz test cases in Debug mode* (merge `dda2d4e176`).
- `#33235` — *build: set ENABLE_IPC to OFF when fuzzing* (merge `ed2ff3c63d`).
- `#35090` — *fuzz: add p2p_private_broadcast harness* (merge `006f8f7d49`) — a model "new harness" PR to compare with your 17.3 target.
- Also: `#31992` *cmake: Avoid fuzzer "multiple definition of `main'" errors* (merge `4c1906a500`).

Write your own notes on one of them in `my-work/17-fuzzing-sanitizers-debugging-and-ci/review-notes.md` (what changed, how it was
tested, one question you would ask).

---

## Proof-of-work output

- Your `taproot_merkle.cpp` harness on a topic branch in your fork, passing
  `check_fuzz_target.py` (static + dynamic). Whether to open an upstream PR is **your** decision
  after reading `CONTRIBUTING.md` and checking that no equivalent harness exists; if you do, write the
  description yourself and mention what you tested.
- `my-work/17-fuzzing-sanitizers-debugging-and-ci/bisect-result.txt` passing `check_bisect.py`, plus a 5-line write-up of what the commit
  changed and why.
- A sanitizer report you triggered yourself (17.4) with your explanation of each line.
