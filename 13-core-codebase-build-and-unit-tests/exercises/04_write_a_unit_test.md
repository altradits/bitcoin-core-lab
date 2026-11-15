# Exercise 13.4: Write a new Boost unit test for CompactSize (C-TEST-2, C-BUILD-3, C-TEST-3 intro)

## Why this function

`GetSizeOfCompactSize`, `WriteCompactSize` and `ReadCompactSize` in `src/serialize.h` encode the length
prefix of every vector in every P2P message and block. They exist on both 29.x and master
(checked with `git grep`). `GetSizeOfCompactSize` is `constexpr`, but no test in `src/test/` checks its
byte-length boundaries directly. (`git grep -n GetSizeOfCompactSize -- src/test` finds only an incidental
use in `miniscript_tests.cpp`.) The existing `serialize_tests/compactsize` case round-trips powers of two,
which skips the exact boundary values 252/253, 0xffff/0x10000 and 0xffffffff/0x100000000.

## What you will build

A new file **`src/test/compactsize_boundary_tests.cpp`** with suite **`compactsize_boundary_tests`**
(the file name and suite name must match; see developer-notes), using the **smallest** fixture that works.
At least these four cases:

| Case | Asserts |
|---|---|
| `size_boundaries` | `GetSizeOfCompactSize` returns 1, 3, 5 or 9 at each side of every boundary, including 0 and `UINT64_MAX`. |
| `written_length_matches_size` | For each boundary value, the number of bytes `WriteCompactSize` writes into a `DataStream` equals `GetSizeOfCompactSize`. The first byte is the right marker (`0xfd`, `0xfe`, `0xff`) when one is used. |
| `round_trip_without_range_check` | Each boundary value reads back unchanged with `ReadCompactSize(stream, /*range_check=*/false)`. |
| `range_check_limits` | `MAX_SIZE` reads back with the default range check. `MAX_SIZE + 1` throws `std::ios_base::failure` whose message contains `"size too large"`. |

## Steps

1. On your `stage13` branch, copy [`compactsize_boundary_tests.cpp.skeleton`](./compactsize_boundary_tests.cpp.skeleton)
   to `src/test/compactsize_boundary_tests.cpp` in `/Users/mac/bitcoin`. Fill in every `TODO`. Do not paste
   from `solutions/`.
2. Register the file in `src/test/CMakeLists.txt` (keep the alphabetical order the file uses).
3. Rebuild **only** `test_bitcoin` (`-j2`/`-j3`). Fix compiler errors yourself. Read the *first* error, not the last.
4. Run only your suite, then each case one at a time, with `--log_level=all`.
5. **Mutation test (prove the test can fail).** Temporarily change one comparison in
   `GetSizeOfCompactSize` in `src/serialize.h` (for example the `< 253` boundary), rebuild `test_bitcoin`,
   and run your suite. Copy the failing output into your journal. **Revert the change**, rebuild, and confirm
   it passes again. (Expect a slow rebuild: `serialize.h` is included almost everywhere. That cost is part of the lesson.)
6. Run the lint that checks suite names against file names: `test/lint/lint-tests.py` (on both 29.x and
   master). Run it from the repo root with `python3` and record the result. Read its source first: it uses
   `git grep`, so what must you do to your new file before the lint can even see it? Then read `test/lint/README.md` to see how
   the full Rust `test_runner` runs every linter (needs `cargo`. Optional here; it is covered in Stage 17).
7. `./check_13.sh unit`.

<details><summary>Hint 1 (concept)</summary>

None of these functions need a chainstate, a mempool or a datadir. Pick the fixture with the least setup.
For thrown exceptions, Boost has a check macro that takes the exception type and a *predicate*.
The predicate is any callable that takes the exception and returns `bool`.
</details>

<details><summary>Hint 2 (which functions)</summary>

`BOOST_FIXTURE_TEST_SUITE(name, BasicTestingSetup)`, `BOOST_AUTO_TEST_CASE`, `BOOST_CHECK_EQUAL`,
`BOOST_CHECK`, `BOOST_CHECK_EXCEPTION(expr, std::ios_base::failure, predicate)`.
`DataStream ss{};` then `WriteCompactSize(ss, v)`, `ss.size()`, `ss[0]` (a `std::byte`, so compare with
`std::byte{0xfd}`), `ReadCompactSize(ss, false)`. `std::numeric_limits<uint64_t>::max()`. Inside the predicate,
`std::string_view{e.what()}.find(...)`.
</details>

## Do not

- Do not open an upstream PR with this test. It is practice, and it mostly duplicates coverage that already exists.
  (Your proof of work is a gist; see the README.)
- Do not leave the mutation in `serialize.h`. `./check_13.sh unit` checks that `src/serialize.h` has no local changes.
