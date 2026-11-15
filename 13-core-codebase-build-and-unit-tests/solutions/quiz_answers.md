# SPOILER: Stage 13 answers (quiz, Exercise 3 and Exercise 5)

Checked against master `e75b76b12c`. 29.x (`f490f5562d`) differences are noted.

## Self-check quiz

1. `BUILD_TESTS`, default `ON` (top-level `CMakeLists.txt`). Not CMake's generic `BUILD_TESTING`.
2. `cmake --build build --target test_bitcoin -j2` (a test `.cpp` only affects the `test_bitcoin` target),
   then `build/bin/test_bitcoin --run_test=serialize_tests`.
3. The `ccache` program must be on `PATH` when you run the **configure** step. `cmake/ccache.cmake` calls
   `find_program(CCACHE_EXECUTABLE ccache)` and only then adds it to `CMAKE_C(XX)_COMPILER_LAUNCHER`. If it is
   missing, `WITH_CCACHE` is silently forced off. The cache stores `CCACHE_EXECUTABLE-NOTFOUND` until you re-configure.
4. `BasicTestingSetup` (args, logging, RNG, no chain): pure functions such as serialization or util.
   `TestingSetup` (full chainstate, mempool, no blocks): validation or mempool logic on an empty chain.
   `TestChain100Setup` (100+ mined blocks with spendable coinbases): anything that needs real UTXOs or a chain.
   (`ChainTestingSetup` and `RegTestingSetup` sit in between.) Choose the cheapest one that works.
5. `Assert`: the condition must hold, otherwise it is unsafe to continue, so it aborts (always compiled in).
   `Assume`: aborts only in debug builds, is always evaluated, and continuing is safe. `CHECK_NONFATAL`: throws
   `NonFatalCheckError`, used in RPC so a bug shows as an RPC error instead of a crash. **None** of them may validate
   a peer's message. Untrusted input must be rejected through the normal error path (for example `Misbehaving`, or a
   `ValidationState` failure).
6. The caller must **not** hold `m_mutex` when calling (a negative capability). The function takes it itself, so
   calling with it held would self-deadlock on a non-recursive `Mutex`. Clang's `-Wthread-safety` analysis checks it
   at compile time. `AssertLockNotHeld` checks it at runtime.
7. `fd 00 00` encodes 0 in 3 bytes, but 0 must be encoded in 1 byte. Allowing more than one encoding of the same
   value is **malleability**: two different byte strings would deserialize to the same object. That breaks
   hash-based identity (for example, a tx with a non-canonical length prefix would have a different txid for the
   same content) and opens DoS and caching tricks.
8. `cs_main` (via `LOCK(cs_main)`). `ChainstateManager::ActiveChain()` is `EXCLUSIVE_LOCKS_REQUIRED(GetMutex())`
   and `GetMutex()` is `LOCK_RETURNED(::cs_main)`. The chain vector is changed under `cs_main` by the validation thread.
9. `LOG_CATEGORIES_BY_STR` in `src/logging.cpp`. The enum is `BCLog::LogFlags`. On master the logging *macros*
   moved to `src/util/log.h`.
10. The file is never compiled, so its tests silently do not run. CI is green and the PR adds zero coverage.
    A reviewer runs `test_bitcoin --list_content | grep foo_tests`, finds nothing, and comments that the file must be
    added to `add_executable(test_bitcoin ...)` in `src/test/CMakeLists.txt`.

## Exercise 3 (reading `serialize_tests.cpp`)

1. `BasicTestingSetup`. Serialization needs no chain. The fixture gives a clean args, logging and RNG environment.
2. The loop writes `i-1, i` for `i = 1, 2, 4 … 2^25 (MAX_SIZE)`. It **does** hit `0xffff/0x10000` (`i = 65536`).
   It **misses** `252/253` (it hits 127/128 and 255/256), and it never reaches `0xffffffff/0x100000000` or `UINT64_MAX`,
   because it stops at `MAX_SIZE`.
3. The text of `what()` for `std::ios_base::failure` is platform-dependent (libc++ and libstdc++ append different
   suffixes). Building the expected exception the same way gives the same decoration.
4. `CSerializeMethodsTestSingle` (one `READWRITE` per field) vs `CSerializeMethodsTestMany` (one `READWRITE` with all
   fields). The test shows both produce identical bytes, and both equal hand-serializing the fields in order.
   (It also round-trips `Span`/`std::span` and `std::byte`.)
5. Your own answer. Any commit, with its "why".

## Exercise 5

**A1.** `ActivateBestChain` is `EXCLUSIVE_LOCKS_REQUIRED(!m_chainstate_mutex) LOCKS_EXCLUDED(::cs_main)`. The caller
must hold neither. The function takes `m_chainstate_mutex` for its whole run and takes `cs_main` in short slices,
releasing it between steps so RPC and net threads can make progress and validation-interface callbacks can run
without lock inversion.
**A2.** `DisconnectTip` is `EXCLUSIVE_LOCKS_REQUIRED(cs_main, m_mempool->cs)`. The disconnected block's transactions
are queued (`DisconnectedBlockTransactions`) to go back into the mempool, so the mempool must be locked.
**A3.** `m_should_discourage GUARDED_BY(m_misbehavior_mutex)`. `Misbehaving` starts with `LOCK(peer.m_misbehavior_mutex);`.
**A4.** `RecursiveMutex& GetMutex() const LOCK_RETURNED(::cs_main)`. It lets annotations name "the chainman's mutex"
without hard-coding a global. The analysis knows it *is* `cs_main`.
**A5.** You get a warning about calling `ActiveChain` requiring holding mutex `cs_main` (from
`EXCLUSIVE_LOCKS_REQUIRED(GetMutex())` + `LOCK_RETURNED`). Wording varies by clang version.
**B1.** Example: `Assume(!coin.IsSpent());` in `validation.cpp`. A violated assumption is a logic bug, but
continuing is safe, so it should only crash debug builds. Any `Assert(m_coins_views)` in `validation.h` means a null
dereference would follow, so stop now.
**B2.** For example `CHECK_NONFATAL(!coinbase_tx.vin.empty());` in `src/rpc/blockchain.cpp`. A bug in one RPC should
return an error to the caller, not kill the node.
**B3.** Something like: "This is peer-controlled data. `Assert` aborts the node, so any peer could crash us. Please
reject with the normal error path (for example disconnect or `Misbehaving`) instead of asserting." In fact
`ReadCompactSize` already throws on sizes above `MAX_SIZE`.
**C1.** `std::unique_ptr<CoinsViews> m_coins_views` is owned by `Chainstate` and destroyed with it (or explicitly
reset). References into it (`CoinsTip()`) are only taken under `cs_main` and are not stored long-term. `CoinsTip()`
asserts the pointer.
**C2.** `WITH_LOCK(m, return x;)` is fine for one expression. An explicit `{ LOCK(m); ... }` block is easier to
extend, but easier to hold too long by accident. Either answer is fine if you argue it.
**D1.** `SERIALIZE_METHODS` generates `Serialize` and `Unserialize` that both call one static template `SerializationOps`
with `obj` as `const` (write) or non-const (read) and a different `ser_action` type. `READWRITE` calls
`ser_action.SerReadWriteMany(s, ...)`, which reads or writes depending on that type.
**D2.** 32 bytes `00…00` then `01 00 00 00`, so **36 bytes**. `n` is a little-endian `uint32_t`.
**D3.** 4 + 32 + 32 + 4 + 4 + 4 = **80** (`BLOCK_HEADER_SIZE` is asserted to be 80 in `messages.py`).
**D4.** 252 → `fc`; 253 → `fd fd 00`; 65535 → `fd ff ff`; 65536 → `fe 00 00 01 00`;
33554433 (`0x02000001`) → `fe 01 00 00 02`. With default `range_check`, only the last is rejected:
`"ReadCompactSize(): size too large"`.
