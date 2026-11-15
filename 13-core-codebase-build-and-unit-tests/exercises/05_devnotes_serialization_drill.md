# Exercise 13.5: Developer notes, locking annotations and serialization drill (C-CPP-1, C-CPP-3, C-CPP-5)

Do this on your `stage13` branch (master). Write every answer in your journal **before** you open
`solutions/quiz_answers.md` (section "Exercise 5").

## Part A: locking annotations (read, then explain in your own words)

1. In `src/validation.h`, find the declaration of `Chainstate::ActivateBestChain`. Copy its two
   annotations into your journal. In one sentence each, explain what `EXCLUSIVE_LOCKS_REQUIRED(!m_chainstate_mutex)`
   and `LOCKS_EXCLUDED(::cs_main)` promise. Why must a function that *may run for minutes* not be
   called with `cs_main` held?
2. Same file: find `Chainstate::DisconnectTip`. Which two locks must the caller hold? Why does it need the
   mempool lock too? (Hint: what happens to the disconnected block's transactions?)
3. In `src/net_processing.cpp`, find `struct Peer` and the member `m_should_discourage`. What protects it?
   Then find `PeerManagerImpl::Misbehaving` and show where that lock is taken.
4. Find `GetMutex()` in `ChainstateManager` (`src/validation.h`). What does it return? Why is that useful for
   the annotations on `ActiveChain()`?
5. **Compile-time proof (optional, costs one rebuild).** On a scratch branch, remove the `LOCK(cs_main);`
   line from the `getblockcount` RPC body in `src/rpc/blockchain.cpp` and rebuild `bitcoind` with clang.
   Copy the `-Wthread-safety` warning into your journal, then **revert**. Which annotation produced it?

## Part B: assertions

1. `git grep -c "Assume(" -- src/validation.cpp` and `git grep -c "Assert(" -- src/validation.cpp`. Pick one
   of each. For each, explain why the author chose it. Use the rules in `doc/developer-notes.md`,
   "Assertions and Checks", and the comments in `src/util/check.h`.
2. Find one `CHECK_NONFATAL` in `src/rpc/`. Why is it the right choice in RPC code?
3. A PR adds `Assert(msg.size() <= MAX_SIZE)` where `msg` came from a peer. Write the review comment
   you would leave (do not post it anywhere). What should the code do instead?

## Part C: RAII and ownership

1. In `src/validation.h`, find `m_coins_views` in `class Chainstate`. What type owns it? When is it
   destroyed? Who could hold a dangling reference to it, and how does the code avoid that?
2. Find one `WITH_LOCK(` in `src/net_processing.cpp`. Rewrite it in your journal as an explicit block
   that uses `LOCK`. Which version is safer to edit later, and why?

## Part D: serialization by hand

1. Read `SERIALIZE_METHODS` and `READWRITE` in `src/serialize.h`. In your own words, explain why one body
   can work for both reading and writing. (Look at how `ser_action` is chosen.)
2. `COutPoint` (`src/primitives/transaction.h`) serializes `hash` then `n`. Write out, byte by byte in hex,
   the serialization of an outpoint whose hash is all zero bytes and `n = 1`. How many bytes is it? What
   **endianness** does `n` use?
3. `CBlockHeader` (`src/primitives/block.h`) serializes six fields. Add up their sizes. Check your total
   against the `BLOCK_HEADER_SIZE` assertion in `test/functional/test_framework/messages.py`.
4. Write the CompactSize encoding (hex) of 252, 253, 65535, 65536 and 33554433 (`MAX_SIZE + 1`). Which of
   these would `ReadCompactSize` with default arguments reject, and with which message?

<details><summary>Hint 1 (concept)</summary>

Thread-safety annotations are checked by **clang** at compile time (`-Wthread-safety`). `AssertLockHeld`
is the runtime counterpart. Serialization in Core is little-endian for integers. Hashes are written as
raw 32-byte arrays (the RPC shows them byte-reversed).
</details>

<details><summary>Hint 2 (where)</summary>

`git grep -n "ActivateBestChain(" -- src/validation.h`, `git grep -n "struct Peer {" -- src/net_processing.cpp`,
`git grep -n "LOCK_RETURNED" -- src/validation.h`, `ser_writedata32` in `src/serialize.h`.
</details>

## Checkable facts

After you have answered the questions above in your journal, put these short answers in
`my-work/13-core-codebase-build-and-unit-tests/answers.env` (one `KEY=value` per line) and run
`python3 tools/check_facts.py 13-core-codebase-build-and-unit-tests 13.5` from the lab root (or `./lab.sh check 13`).
Answers are for master `e75b76b12c`. The checker says which ones are wrong, never the right value.
Your explanations (the "why" questions) are not machine-checked: compare them with `solutions/` afterwards.

| Key | Question |
|---|---|
| `F13_DISCONNECTTIP_LOCKS` | Part A q2: the two locks in `DisconnectTip`'s annotation, comma-separated, exactly as written |
| `F13_DISCOURAGE_MUTEX` | Part A q3: the mutex that guards `m_should_discourage` |
| `F13_GETMUTEX_RETURNS` | Part A q4: the mutex `ChainstateManager::GetMutex()` returns |
| `F13_OUTPOINT_HEX` | Part D q2: the serialized outpoint (all-zero hash, n = 1) in hex, no spaces |
| `F13_OUTPOINT_BYTES` | Part D q2: its size in bytes |
| `F13_HEADER_BYTES` | Part D q3: total serialized size of `CBlockHeader` in bytes |
| `F13_CS_253` | Part D q4: CompactSize of 253 in hex |
| `F13_CS_65536` | Part D q4: CompactSize of 65536 in hex |
| `F13_CS_REJECT_MSG` | Part D q4: the exception message `ReadCompactSize` throws for 33554433 |
