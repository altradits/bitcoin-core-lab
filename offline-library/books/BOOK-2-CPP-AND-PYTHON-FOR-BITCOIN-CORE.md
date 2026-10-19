# Book 2: Modern C++20 & Python 3 Building Blocks for Bitcoin Core (From Memory)

> **Purpose of This Offline Book:**
> When reading or reviewing `bitcoin/bitcoin` C++ (`src/`) or Python functional tests (`test/functional/`), use this offline reference to understand every C++20 idiom, lock macro, and Python test helper — then test your recall with the **Blind Recall Drills** at the bottom.

---

## Chapter 1: Core C++ Types in `bitcoin/bitcoin` (`src/`)

### 1.1 `CAmount` and `MoneyRange` (`src/consensus/amount.h`)
Bitcoin Core never uses `float` or `double` for money (floating-point rounding causes consensus splits). All monetary values are integer satoshis (`int64_t`):
```cpp
using CAmount = int64_t;
static constexpr CAmount COIN = 100'000'000;
static constexpr CAmount MAX_MONEY = 21'000'000 * COIN;
inline bool MoneyRange(const CAmount& nValue) { return (nValue >= 0 && nValue <= MAX_MONEY); }
```

### 1.2 `uint256`, `Txid`, and `Wtxid` (`src/uint256.h`, `src/primitives/transaction.h`)
- `uint256`: A 256-bit (32-byte) opaque blob used for block hashes and Merkle roots.
- `Txid` / `Wtxid`: Type-safe wrappers around `uint256` so a developer cannot accidentally pass a `wtxid` into a function expecting a `txid`.

### 1.3 `std::span<const uint8_t>` (`src/span.h`)
Instead of passing raw pointers `(const unsigned char* pbegin, size_t len)`, modern Bitcoin Core passes `std::span<const uint8_t>` (or `Span<const std::byte>`), which bundles `{pointer, length}` safely without copying memory:
```cpp
void CleanseBuffer(std::span<uint8_t> buf) {
    memory_cleanse(buf.data(), buf.size());
}
```

### 1.4 RAII & Destructors (`~ClassName()`)
In C++, **RAII (Resource Acquisition Is Initialization)** guarantees that a local object's destructor (`~ClassName()`) runs automatically when the scope `{ ... }` exits (even if an exception is thrown):
```cpp
class CSHA512 {
private:
    uint64_t s[8];
    unsigned char buf[128];
public:
    ~CSHA512() {
        memory_cleanse(s, sizeof(s));
        memory_cleanse(buf, sizeof(buf));
    }
};
```

---

## Chapter 2: Mutexes, Thread Safety & Lock Annotations (`src/sync.h`)

Bitcoin Core runs multiple threads (`net`, `msghand`, `http`/`rpc`, `loadblk`). Data races corrupt memory.
- `Mutex cs_main`: Protects `Chainstate`, block index, and UTXO validation state.
- `LOCK(cs_main)`: Acquires the mutex for the current `{ ... }` block and releases it automatically via RAII when exiting the block.
- `EXCLUSIVE_LOCKS_REQUIRED(cs_main)`: Compile-time Clang Thread Safety annotation (`-Wthread-safety`) that causes a **compiler error** if a caller forgets to hold `cs_main`!
- `AssertLockHeld(cs_main)`: Runtime + compile-time assertion verifying the lock is held.

```cpp
bool Chainstate::InvalidateBlock(BlockValidationState& state, CBlockIndex* pindex)
    EXCLUSIVE_LOCKS_REQUIRED(::cs_main)
{
    AssertLockHeld(::cs_main);
    if (pindex->nHeight == 0) return false;
    // ...
}
```

---

## Chapter 3: Validation State & RPC Error Handling (`src/consensus/validation.h`, `src/rpc/util.h`)

### 3.1 `BlockValidationState` and `TxValidationState`
Validation functions return `bool` and record why a block/tx failed inside `state`:
```cpp
if (nSigOpsCost > MAX_BLOCK_SIGOPS_COST) {
    return state.Invalid(BlockValidationResult::BLOCK_CONSENSUS, "bad-blk-sigops", "out-of-bounds SigOpCount");
}
```

### 3.2 `JSONRPCError` in `src/rpc/*.cpp`
When an RPC fails, it throws `JSONRPCError(RPCErrorCode, "message")`:
```cpp
BlockValidationState state;
chainman.ActiveChainstate().InvalidateBlock(state, pblockindex);
if (!state.IsValid()) {
    throw JSONRPCError(RPC_DATABASE_ERROR, state.ToString());
}
```

---

## Chapter 4: Boost C++ Unit Tests (`src/test/*_tests.cpp`)

Bitcoin Core C++ unit tests live in `src/test/` and use Boost.Test (`BOOST_FIXTURE_TEST_SUITE`, `BOOST_AUTO_TEST_CASE`, `BOOST_CHECK`, `BOOST_CHECK_EQUAL`):
```cpp
BOOST_FIXTURE_TEST_SUITE(txvalidation_tests, TestingSetup)

BOOST_AUTO_TEST_CASE(money_range_check)
{
    BOOST_CHECK(MoneyRange(0));
    BOOST_CHECK(MoneyRange(MAX_MONEY));
    BOOST_CHECK(!MoneyRange(-1));
    BOOST_CHECK(!MoneyRange(MAX_MONEY + 1));
}

BOOST_AUTO_TEST_SUITE_END()
```
- **Run a single C++ unit test suite:**
  ```bash
  /Users/mac/bitcoin/build/bin/test_bitcoin --run_test=txvalidation_tests
  ```

---

## Chapter 5: Python Functional Test Framework (`test/functional/`)

Every Python functional test subclasses `BitcoinTestFramework` and spins up real `bitcoind -regtest` nodes (`self.nodes[0]`, `self.nodes[1]`, etc.):

```python
from test_framework.test_framework import BitcoinTestFramework
from test_framework.util import assert_equal, assert_raises_rpc_error

class MyExampleTest(BitcoinTestFramework):
    def set_test_params(self):
        self.num_nodes = 2

    def run_test(self):
        # 1. Mine 1 block on node 0 and sync all nodes' chains
        self.generate(self.nodes[0], 1) # Automatically calls self.sync_all() unless sync_fun=self.no_op

        # 2. Send a raw transaction on node 0 and sync mempools across peers
        txid = self.nodes[0].sendrawtransaction(raw_tx_hex)
        self.sync_mempools()

        # 3. Verify that an invalid RPC call raises the exact RPC error code and message
        genesis_hash = self.nodes[0].getblockhash(0)
        assert_raises_rpc_error(-1, "Cannot invalidate genesis block", self.nodes[0].invalidateblock, genesis_hash)
```

### Why `self.sync_mempools()` and `self.sync_blocks()` Matter (PR #36553 Lesson)
P2P transaction relay between `self.nodes[0]` and `self.nodes[1]` is **asynchronous**. If you broadcast `tx1` on `node0` and immediately check `node1.getrawmempool()` without calling `self.sync_mempools()`, the test will fail intermittently on slow/loaded CPUs!

---

## 🧠 Blind Recall Challenges (Close This File & Write From Memory!)

1. **Drill 2.1 (C++ Lock Annotations):** Without looking above, write the function signature and first line of a C++ function `void CheckMempoolEntry()` that requires `cs_main` to be locked at compile time and asserts it at runtime.
2. **Drill 2.2 (C++ Destructor Cleanse):** Write a C++ struct `SecretKeyBuffer` holding `unsigned char key[32]` whose destructor guarantees the 32 bytes are wiped with `memory_cleanse` when the struct leaves scope.
3. **Drill 2.3 (Python RPC Error Assertion):** Write the exact Python line using `assert_raises_rpc_error` that verifies calling `node.invalidateblock(genesis_hash)` fails with RPC code `-1` (`RPC_MISC_ERROR` / `RPC_DATABASE_ERROR`) and substring `"Cannot invalidate genesis block"`.
4. **Drill 2.4 (Python P2P Race Fix):** Explain from memory why broadcasting three transactions (`tx1`, `tx2`, `tx3`) where `tx1` and `tx3` only conflict via `tx2` requires `self.sync_mempools()` between each broadcast.
