# Exercise 13.3: Run and read Boost unit tests (C-TEST-1)

Builds on Drill 5. Read `src/test/README.md` first. Every flag you need is in that file.

## Part A: run with filters (type each command, save it in the journal)

1. List every suite and case that `test_bitcoin` knows about. Pipe the output to a pager or `wc -l`.
   How many lines mention `serialize_tests`?
2. Run the whole `serialize_tests` suite.
3. Run only the `compactsize` case inside `serialize_tests`.
4. Run the same case with full Boost logging, so you see each check that passes.
5. Run a suite that needs a chainstate (try `validation_chainstate_tests`) and send the node's
   debug log to your terminal. You need the separator that passes node arguments.
6. Run `getarg_tests/doubledash` with a fixed test data directory under `/tmp`. Then `ls` the directory it
   printed and open its `debug.log`.
7. Use `ctest` against the build directory, filtered to run only tests whose name matches `serialize`.
   How does `ctest` name the tests? (Look at the output.)
8. Time a full `test_bitcoin` run **once**, with nothing else open. Write the wall-clock time down. This is
   the baseline you will quote in Tested ACKs.

<details><summary>Hint 1 (concept)</summary>

Boost.Test arguments come first. `bitcoind`-style arguments come after a lone `--`.
`<suite>/<case>` picks a single case.
</details>

<details><summary>Hint 2 (which flags)</summary>

`--list_content`, `--run_test=` (or `-t`), `--log_level=all` (or `-l all`), `-- -printtoconsole=1`,
`-- -testdatadir=<dir>`. For CTest: `ctest --test-dir <build> -R <regex>`.
</details>

## Part B: read a test like a reviewer

Open `src/test/serialize_tests.cpp` and answer in your journal:

1. Which fixture does the suite use? What does that fixture set up that the tests in this file need?
   (Open `src/test/util/setup_common.h` and read `struct BasicTestingSetup`.)
2. In the `compactsize` case, the loop writes `i-1` and `i` for powers of two up to `MAX_SIZE`.
   Which **boundary values** of the CompactSize format does this loop *not* hit exactly?
   (List the byte-length boundaries from `GetSizeOfCompactSize` in `src/serialize.h`.)
3. In `noncanonical`, why does the test create a fresh `std::ios_base::failure` in
   `isCanonicalException` instead of comparing `ex.what()` with a string literal?
4. Find the case that tests `SERIALIZE_METHODS` on a small class (look for `class_methods`). Which
   object is serialized two ways? What equality is asserted?
5. Run `git log --oneline -- src/test/serialize_tests.cpp | head`. Pick one commit and read it with
   `git show`. Write down why that change was made.

Your answer to question 2 is the motivation for Exercise 4.

## Check

`./check_13.sh build` confirms `test_bitcoin` runs. The reading answers are self-checked against
`solutions/quiz_answers.md` (section "Exercise 3"). Check them only after you have written your own.
