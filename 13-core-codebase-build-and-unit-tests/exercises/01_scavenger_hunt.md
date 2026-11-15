# Exercise 13.1: Source-tree scavenger hunt (C-GIT-6, C-BUILD-3)

**Goal:** find 17 things in `~/bitcoin` using only search tools you type yourself.
No IDE "go to definition", no web search, no AI. The skill you are building is the one you use
in the first ten minutes of every PR review: *where does this live, and who calls it?*

## Setup (you type it)

1. In `~/bitcoin`, make sure the tree is clean and note the commit you are on
   (`git status`, `git log -1 --oneline`). Write both in your journal.
2. Create `my-work/13-core-codebase-build-and-unit-tests/` inside the lab repo, with an empty
   `journal.md` and an empty `scavenger.txt`.
3. (Optional but recommended.) macOS ships BSD `ctags` at `/usr/bin/ctags`, which cannot recurse
   into a tree. Install **Universal Ctags** with Homebrew. Generate a tags file for `src/` and learn
   how your editor jumps to a tag. Read `doc/productivity.md` for other speed-ups. Note:
   `~/bitcoin/build/compile_commands.json` already exists, so `clangd`-based editors can
   index the project too.

## Answer format

One line per question in `scavenger.txt`, exactly `Qnn=<answer>`:
- File answers are **repo-relative paths** such as `src/foo/bar.cpp` (no leading `./`, no `~/bitcoin/`).
- Number answers are digits only (no `#`).

Example of the format (not a real answer): `Q00=src/example/file.h`

## The questions

| Q | Find... | Tool to use |
|---|---|---|
| Q01 | The `.cpp` file that defines the `getblockcount` RPC. | `git grep -n` for the RPC name |
| Q02 | The `.cpp` file that defines `bool CheckTransaction(`. | `git grep -n` with the opening parenthesis |
| Q03 | The header that **defines** (not forward-declares) `class CCoinsViewCache`. | `git grep` and tell a definition (`class X : public Y`) from a forward declaration (`class X;`) |
| Q04 | The header that defines `MAX_MONEY`. | `git grep -n "MAX_MONEY ="` or similar |
| Q05 | The header containing `namespace NetMsgType`. | `git grep -l` |
| Q06 | The file implementing `PeerManagerImpl::ProcessMessage`. | `git grep` for `Impl::ProcessMessage(` |
| Q07 | The header that `#define`s `Assume`. | `git grep -n "define Assume"` |
| Q08 | The header that `#define`s `LOCK(`. | |
| Q09 | The header that **declares** `extern RecursiveMutex cs_main;`. | |
| Q10 | The `.cpp` file containing `LOG_CATEGORIES_BY_STR`. | |
| Q11 | The header that defines `struct TestChain100Setup`. | look under `src/test/` |
| Q12 | The Python functional test dedicated to BIP324 v2 transport. | `ls test/functional | grep ...` |
| Q13 | The PR number that introduced the CMake build system. | `git log --oneline --grep=...` on merge commits |
| Q14 | The PR number of the 2018 fix titled "Fix crash bug with duplicate inputs within a transaction" (CVE-2018-17144). | `git log --oneline --grep` |
| Q15 | The numeric value of `MAX_HEADERS_RESULTS`. | |
| Q16 | The `.cpp` file where the `-dbcache` command-line option is registered with `AddArg`. | |
| Q17 | The name of the static library target in `src/CMakeLists.txt` that compiles `net_processing.cpp`. | open `src/CMakeLists.txt` and find which `add_library(...)` block lists it |

<details><summary>Hint 1 (concept)</summary>

`git grep` searches only tracked files and is much faster than `grep -r` across the build
directory. A **definition** has a body or a base class. A **declaration** ends with `;`.
Merge commits in Core are titled `Merge bitcoin/bitcoin#NNNNN: <title>` (older ones: `Merge #NNNNN:`).
</details>

<details><summary>Hint 2 (which flags)</summary>

`git grep -n` gives line numbers. `git grep -l` gives file names only. `-- 'src/*.h'` limits the
search to a pathspec. For merge history: `git log --oneline --merges --grep="<words from the title>"`.
For "which library": search `src/CMakeLists.txt` for the file name, then scroll *up* to the
nearest `add_library(`.
</details>

## Check

From the stage directory, run `./check_13.sh hunt`. It prints PASS/FAIL per question and never prints
the answer. When everything passes, compare your search method with `solutions/scavenger_answers.md`.

## Journal

For each question, save the **exact command** you typed and one sentence about what you learned
(for example, "`CCoinsViewCache` is forward-declared in 3 places, defined only in ...").
