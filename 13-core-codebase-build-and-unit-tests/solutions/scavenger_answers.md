# SPOILER: scavenger hunt answers (Exercise 13.1)

Same answers on 29.x (`f490f5562d`) and master (`e75b76b12c`). Each answer comes with one
command that finds it. Your command may differ. What matters is that you can say why it is unambiguous.

| Q | Answer | One way to find it |
|---|---|---|
| Q01 | `src/rpc/blockchain.cpp` | `git grep -n '"getblockcount"' -- src/rpc` |
| Q02 | `src/consensus/tx_check.cpp` | `git grep -n "^bool CheckTransaction(" -- 'src/*.cpp'` (on master the header `tx_check.h` also matches without the `*.cpp` pathspec, because it is a declaration) |
| Q03 | `src/coins.h` | `git grep -n "class CCoinsViewCache" -- src` gives one definition (`: public CCoinsViewBacked`) and several forward declarations (`class CCoinsViewCache;`) |
| Q04 | `src/consensus/amount.h` | `git grep -n "MAX_MONEY =" -- src` |
| Q05 | `src/protocol.h` | `git grep -l "namespace NetMsgType" -- src` |
| Q06 | `src/net_processing.cpp` | `git grep -n "PeerManagerImpl::ProcessMessage(" -- src` |
| Q07 | `src/util/check.h` | `git grep -n "define Assume" -- src` |
| Q08 | `src/sync.h` | `git grep -n "define LOCK(" -- src` |
| Q09 | `src/kernel/cs_main.h` | `git grep -n "extern RecursiveMutex cs_main" -- src` (defined in `src/kernel/cs_main.cpp`) |
| Q10 | `src/logging.cpp` | `git grep -ln "LOG_CATEGORIES_BY_STR" -- src` |
| Q11 | `src/test/util/setup_common.h` | `git grep -n "struct TestChain100Setup" -- src/test` |
| Q12 | `test/functional/p2p_v2_transport.py` | `ls test/functional \| grep v2` |
| Q13 | `30454` | `git log --oneline --merges --grep="CMake-based build system"` gives `338bc2cd26 Merge bitcoin/bitcoin#30454` |
| Q14 | `14247` | `git log --oneline --grep="duplicate inputs within a transaction"` gives `d926a87fde Merge #14247` |
| Q15 | `2000` | `git grep -n "MAX_HEADERS_RESULTS =" -- src` (`src/net_processing.h`) |
| Q16 | `src/init.cpp` | `git grep -n 'AddArg("-dbcache' -- src` |
| Q17 | `bitcoin_node` | `git grep -n "net_processing.cpp" -- src/CMakeLists.txt`, then read upward to `add_library(bitcoin_node STATIC EXCLUDE_FROM_ALL` |

Lessons worth writing down:
- Many classes are **forward-declared** in several headers to cut compile time. The definition is the one with a body.
- `git log --grep` finds merges by title. `git log -S"<string>"` finds the commit that added or removed a string (the "pickaxe").
- The library a file is in (`bitcoin_node` vs `bitcoin_common` vs `bitcoin_consensus`) tells you its dependency layer.
