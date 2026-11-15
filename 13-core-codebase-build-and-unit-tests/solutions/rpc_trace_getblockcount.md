# SPOILER: `getblockcount` call chain (Exercise 13.6)

Checked against `master` at `e75b76b12c` and 29.x at `f490f5562d`.

```
 bitcoin-cli  --HTTP POST /-->  bitcoind
 +------------------------------------------------------------+
 | HTTPReq_JSONRPC(context, req)          src/httprpc.cpp     |  registered for "/" (and "/wallet/")
 |   via RegisterHTTPHandler("/", ...) in StartHTTPRPC        |  by StartHTTPRPC
 +------------------------------------------------------------+
                 |
 +------------------------------------------------------------+
 | ExecuteHTTPRPC(valRequest, jreq, status) src/httprpc.cpp   |  master only (29.x: HTTPReq_JSONRPC
 +------------------------------------------------------------+   calls JSONRPCExec directly)
                 |
 +------------------------------------------------------------+
 | JSONRPCExec(jreq, catch_errors)        src/rpc/server.cpp  |
 +------------------------------------------------------------+
                 |
 +------------------------------------------------------------+
 | CRPCTable::execute(request)            src/rpc/server.cpp  |  mapCommands.find(request.strMethod)
 |  -> ExecuteCommands -> ExecuteCommand  (static, same file) |
 +------------------------------------------------------------+
                 |
 +------------------------------------------------------------+
 | getblockcount() lambda                 src/rpc/blockchain.cpp
 |   ChainstateManager& chainman = EnsureAnyChainman(request.context);
 |   LOCK(cs_main);
 |   return chainman.ActiveChain().Height();
 +------------------------------------------------------------+
        |                                   |
 EnsureAnyChainman (src/rpc/server_util.cpp)  ActiveChain()  src/validation.h
   = EnsureChainman(EnsureAnyNodeContext())     EXCLUSIVE_LOCKS_REQUIRED(GetMutex())
   throws RPC_INTERNAL_ERROR                    { return ActiveChainstate().m_chain; }
   "Node context not found" /                   GetMutex() is LOCK_RETURNED(::cs_main)
   "Node chainman not found"                         |
                                            ActiveChainstate() src/validation.cpp
                                              master: LOCK(::cs_main); return CurrentChainstate();
                                              (CurrentChainstate() picks the chainstate that targets
                                               the most-work network tip from m_chainstates)
                                                     |
                                            CChain::Height()  src/chain.h
                                              return int(vChain.size()) - 1;
```

Registration: `getblockcount` is listed as `{"blockchain", &getblockcount}` in
`RegisterBlockchainRPCCommands` (`src/rpc/blockchain.cpp`). That function is called by
`RegisterAllCoreRPCCommands` (`src/rpc/register.h`), which `src/init.cpp` calls with the global `tableRPC`.

## Reasoning answers

- **Snapshot loaded:** the RPC asks for the *active/current* chainstate, the one targeting the network tip
  (the snapshot chainstate once loaded). So the height jumps to roughly the snapshot height plus new blocks, while
  background validation of the old range continues in the historical chainstate.
- **Height `-1`:** when `vChain` is empty (no tip set yet, for example very early during startup before the genesis
  block is loaded). In practice RPC is in warm-up until the chain is loaded, so users do not see it.
- **Without the lock:** `m_chain` (`vChain`) is changed by the validation thread in `ConnectTip`/`DisconnectTip`
  (through `CChain::SetTip`) under `cs_main`. Reading `vChain.size()` while the vector reallocates is a data race
  (undefined behaviour). Clang's `-Wthread-safety` flags the call because `ActiveChain()` is
  `EXCLUSIVE_LOCKS_REQUIRED(GetMutex())`.

## 29.x → master changes found

| 29.x (`f490f5562d`) | master (`e75b76b12c`) | Where it changed |
|---|---|---|
| `static RPCHelpMan getblockcount()` | `static RPCMethod getblockcount()` | scripted-diff commit `4e789299af` "rpc: Rename RPCHelpMan to RPCMethod", which entered master with merge `d0ed369b3b` (#34049, `rpc: Disallow captures in RPCMethodImpl`). Note: the lambda went from `[&]` to `[]`. |
| `HTTPReq_JSONRPC` → `JSONRPCExec` | `HTTPReq_JSONRPC` → `ExecuteHTTPRPC` → `JSONRPCExec` | find it yourself with `git log -S"ExecuteHTTPRPC" --oneline master -- src/httprpc.cpp` |
| `ActiveChainstate()` returns `*m_active_chainstate` (after `assert`) | `ActiveChainstate()` returns `CurrentChainstate()` over `m_chainstates` | #30214 `refactor: Improve assumeutxo state representation` (merge `4f11ef058b`) |
