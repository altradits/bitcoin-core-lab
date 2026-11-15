# Exercise 13.2: Build options, single targets and ccache on 8 GB (C-BUILD-1, C-BUILD-2, C-BUILD-4)

Builds on Drill 2 of [`BUILDING_BITCOIN_CORE_FROM_SOURCE.md`](../../BUILDING_BITCOIN_CORE_FROM_SOURCE.md).
Here you learn to configure **on purpose** and rebuild **only** what you need.

> RAM rule: never use more than `-j3` on this M1. Close browsers and Docker/Polar before a cold build.
> If Activity Monitor shows memory pressure in red, stop the build (Ctrl-C) and use `-j2`.

## Part 0: move to `master` on a topic branch (C-GIT-1)

Your tree is detached at the 29.x commit `f490f5562d`. Reviews and contributions target `master`.

1. Run `git status` and make sure nothing is modified. Stash or commit anything you want to keep.
2. Create and switch to a topic branch called `stage13` that starts at your local `master` (`e75b76b12c`
   when this stage was written; `git fetch` first if you are online). Write the commit you are on in your journal.
3. Read `doc/build-osx.md` on this branch and install whatever Homebrew packages are listed that you do
   not have yet. At `e75b76b12c` the list is `cmake boost capnp`. Note what is no longer needed compared with 29.x.
4. You will reconfigure `build/` in Part B. Expect the first build on master to recompile almost everything, because
   thousands of files changed between 29.x and master. Do it once, overnight if needed, at `-j2`.

## Part A: read before you configure

1. Open the top-level `CMakeLists.txt`. In your journal, list every `option(` and
   `cmake_dependent_option(` with its default. Mark the five you think matter most for a reviewer.
2. Open `CMakePresets.json`. Write down what the `dev-mode` preset turns on and which build
   directory it uses. Why is it a poor default on 8 GB?
3. Open `~/bitcoin/build/CMakeCache.txt` and find the current values of the build type,
   the tests option, the wallet option and `WITH_CCACHE`.
4. Open `cmake/ccache.cmake`. In two sentences, explain when Core actually uses ccache.
   (Hint: what does `find_program` return when the program is missing?)

## Part B: install ccache and re-configure

1. Install `ccache` with Homebrew and confirm the binary is on your `PATH`.
2. Following `doc/productivity.md` ("Cache compilations with ccache"), create a ccache config with a
   cache size you can afford on your SSD. Use your judgement and write down why you chose it.
3. Re-run the CMake **configure** step on the existing `build/` directory, with the options you
   chose in Part A. If CMake complains about old cache values from 29.x (for example `WITH_MULTIPROCESS`), decide
   whether to start a fresh build directory, and write down why. Find the line in the configure summary that reports ccache, and copy it into your journal.

## Part C: cold vs. warm single-target rebuild

1. Ask CMake to list all targets of the `build/` directory. Copy the names of five targets into your
   journal (at least `test_bitcoin` and `bitcoind`).
2. Zero the ccache statistics. Then rebuild **only** `test_bitcoin` with `-j2` or `-j3`, and time it with
   the shell's `time` keyword. Print the ccache statistics afterwards.
3. Force the same files to be compiled again without changing their content. One way is to delete the
   object files for `test_bitcoin`'s sources. Find them under `build/src/test/CMakeFiles/`. Rebuild
   `test_bitcoin` again with `time`, then print ccache statistics. Record the hit rate.
4. Touch **one** source file (for example `src/util/strencodings.cpp`) and rebuild only `test_bitcoin`.
   How many objects were recompiled? Why that many? (Think: which targets link `bitcoin_util`?)

## Part D: a second build directory (do not run it now)

Write, but **do not run**, the configure command for a separate `build_debug/` directory with a
`Debug` build type, no wallet, no GUI, tests on, and bench off. This prepares you for `lldb` in Stage 17.
Explain why a second directory is better than re-configuring `build/`.

## Part E: depends and Guix (C-BUILD-4, reading only)

Read `depends/README.md` (or `depends/description.md`) and `contrib/guix/README.md`. In two
sentences each, explain what they are for and when a reviewer needs them. (Hint: release
reproducibility, and "works on my Mac" bugs.)

<details><summary>Hint 1 (concept)</summary>

CMake has two phases. **Configure** (`cmake -B <dir> [options]`) writes the cache and the
Makefiles. **Build** (`cmake --build <dir> ...`) compiles. Compiler launchers such as ccache are
chosen at **configure** time.
</details>

<details><summary>Hint 2 (which flags)</summary>

`cmake --build <dir> --target <name> -j<N>`; `cmake --build <dir> --target help`;
`ccache -z` (zero statistics), `ccache -s` (show statistics). The configure summary prints
`Use ccache for compiling ..............`.
</details>

## Check

`./check_13.sh build` checks that ccache is installed and recorded in `build/CMakeCache.txt` as the
compiler launcher, and that `test_bitcoin` exists and can list its suites.
