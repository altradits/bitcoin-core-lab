# Stage 17 — Quiz answers and worksheet notes (SPOILERS)

Checked against `/Users/mac/bitcoin` master `e75b76b12c` and 29.x `f490f5562d`.

## Quiz

1. `DETAIL_FUZZ(name, ...)` declares `void name##_fuzz_target(FuzzBufferType)`, defines a struct
   `name##_Before_Main` whose constructor calls `FuzzFrameworkRegisterTarget(#name, name##_fuzz_target, {__VA_ARGS__})`,
   creates a `static const` instance of it (so registration runs before `main`), and then opens the
   function body. The binary picks the target from the `FUZZ` environment variable.
2. Apple's clang ships without the libFuzzer runtime (`-fsanitize=fuzzer`). On macOS you build with
   `-DBUILD_FOR_FUZZING=ON` and no engine: write harnesses, replay corpora, reproduce and debug crashes.
   Master `doc/fuzzing.md` recommends Linux for actual fuzzing.
3. `BUILD_FOR_FUZZING`. `cmake --preset=libfuzzer` (`SANITIZERS=undefined,address,fuzzer`, dir `build_fuzz`).
4. e.g. `ConsumeRandomLengthByteVector`, `ConsumeFixedLengthByteVector`, `ConsumeUInt256`, `ConsumeMoney`,
   `CallOneOf`, and `LIMITED_WHILE` (fuzz.h). Bounded sizes keep each run fast (more execs/second) and
   avoid "out of memory" false positives from absurd lengths.
5. Update `qa-assets` to the commit CI used; build with the same sanitizers as the CI job; run
   `FUZZ=process_message <build>/bin/fuzz <path>/crash-<hash>`; if the file is missing, decode the base64
   input from the CI log; then debug (lldb, extra logging) and write a minimal unit test for the fix.
6. Data race: TSan. Use-after-free: ASan. MSan cannot run on macOS (Linux only).
7. `RelWithDebInfo` optimises; the variable lives only in a register or was removed. Configure a
   separate `-DCMAKE_BUILD_TYPE=Debug` build dir.
8. 0 = good, 1–127 except 125 = bad, 125 = skip (cannot test this commit). Exit codes ≥128 abort the bisect.
9. `.github/workflows/ci.yml` maps the job name to `file-env: './ci/test/00_setup_env_native_asan.sh'`;
   that file's `BITCOIN_CONFIG` has `-DSANITIZERS=address,float-divide-by-zero,integer,undefined`.
10. Valgrind and heaptrack do not support macOS on Apple Silicon. CI runs valgrind on Linux
    (`ci/test/00_setup_env_native_valgrind.sh`, `00_setup_env_native_fuzz_with_valgrind.sh`).

## Worksheet notes

- 17.1 Q7: on master there is no fuzz target calling `ComputeTapbranchHash`/`ComputeTaprootMerkleRoot`
  (checked with `git grep ... master -- src/test/fuzz`). `.init` example: `FUZZ_TARGET(addrman, .init = initialize_addrman)`.
- 17.2: master's runner lives at `<build>/test/fuzz/test_runner.py`; `--par` sets parallelism.
- 17.3: reference harness in `solutions/taproot_merkle.cpp` (not compiled during authoring — if it
  fails to compile on your master, fixing it is part of the exercise; tell the lab maintainer).
- 17.6: the good commit is the merge-base of 29.x and master (`8cb6ab0b97`); the range has 5756 commits,
  so expect about 13 steps. Merging PR: find it yourself with the `--ancestry-path` command in the
  worksheet; it is the PR that lowered three default fee settings together.
