# Exercise 13.6: C++ reading drill. Trace `getblockcount` from HTTP to `ChainstateManager` (C-CPP-1, C-GIT-6)

**Goal:** draw the full call chain for `bitcoin-cli getblockcount` inside `bitcoind`, from the HTTP
handler to the line that reads the chain height. Give the **file and function** for each hop. Use only
`git grep`, ctags or clangd, and your eyes.

Do it on `master` (your `stage13` branch). Then do the "29.x → master" part at the end.

## Steps

1. **Where is the RPC defined?** Find the function that builds the `getblockcount` method object, and the
   table row that registers it under the `"blockchain"` category. Note the type name used for RPC method
   objects on master.
2. **How is the table filled?** Find the function that registers all blockchain RPCs, then the function that
   registers *all* core RPCs. Find where it is called during startup (in `src/init.cpp`).
3. **From HTTP in.** In `src/httprpc.cpp`, find the HTTP handler registered for path `"/"`, and every function it
   calls until a `JSONRPCRequest` reaches `src/rpc/server.cpp`. Write down each hop.
4. **Dispatch.** In `src/rpc/server.cpp`, follow `CRPCTable::execute` to the code that finally invokes the
   method's lambda.
5. **Inside the lambda.** Write down:
   - how the lambda gets a `ChainstateManager&` (which helper, declared in which header, and what it throws
     if the node context is missing);
   - which lock it takes and which **annotation** makes that lock mandatory;
   - the chain of calls from `ChainstateManager` to the `int` that is returned (go into `src/validation.h`
     and `src/chain.h`). What does `Height()` actually compute?
6. **Draw it.** In your journal, draw an ASCII diagram (one box per function, file name under each box).
7. **Reason about it.** Answer:
   - Why does `getblockcount` report the *active* chainstate when an assumeutxo snapshot is loaded (Stage 15)?
   - Could the returned height ever be `-1`? When?
   - If you removed the lock, what data race could happen, and with which thread?

## 29.x → master

Repeat steps 1, 3 and 4 against the 29.x commit without checking it out
(`git show f490f5562d:src/rpc/blockchain.cpp`, `git show f490f5562d:src/httprpc.cpp`). List every name that
changed. (Two are worth noting: the RPC method type, and one extra hop in the HTTP layer.) For each one,
use `git log --oneline --merges --grep=<name> master` or `git log -S<name>` to find the PR that changed it.

<details><summary>Hint 1 (concept)</summary>

RPC methods are objects that hold help text and a lambda. A table maps method names to them. The HTTP
server only knows about URL paths and hands the JSON body to the RPC layer.
</details>

<details><summary>Hint 2 (where)</summary>

`git grep -n '"getblockcount"' -- src/rpc`, `git grep -n "RegisterAllCoreRPCCommands"`,
`git grep -n "RegisterHTTPHandler" -- src/httprpc.cpp`, `git grep -n "EnsureAnyChainman" -- src/rpc/server_util.h`,
`git grep -n "CChain& ActiveChain" -- src/validation.h`, `git grep -n "int Height()" -- src/chain.h`.
</details>

Self-check: `solutions/rpc_trace_getblockcount.md`.
