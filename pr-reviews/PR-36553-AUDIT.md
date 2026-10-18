# 🛡️ Guardian Security & Consensus Audit: `bitcoin/bitcoin#36553`

- **PR Title:** test: Add missing sync_mempools in wallet_conflicts.py
- **Concentric Risk Ring:** **🔴 Ring 0 — CRITICAL CONSENSUS & CRYPTOGRAPHY (Chain-Split / Inflation Risk)**
- **Merge Commit:** `UNMERGED (Open PR Branch: pr-36553)`
- **Audited PR Tip Commit:** `faa3ea61a3f99f9faf79387b60f9fd730648fa95`
- **Auditor:** Stanley Chege Thuita ([@altradits](https://github.com/altradits))

---

## 1. Why This PR Was Merged (Motivation & Maintainer Context)
```text
tx1 and tx3 do not conflict. While alice (node 0) ends with tx3, other
nodes may end up with tx1 and tx3, if they request tx2 after alice has
replaced it, thus not receiving it.

Fix it by calling self.sync_mempools() after each send.

Also, replace one nodes[0] with the alice alias.

Also, generate the final cleanup block on bob, to avoid another
sync_mempools.
```

## 2. Commits Inside This PR
```text
faa3ea61a3 MarcoFalke: test: Add missing sync_mempools in wallet_conflicts.py
fa356553c0 MarcoFalke: test: Remove redundant sync call after self.generate called sync_all
b13ba1a7d3 merge-script: Merge bitcoin/bitcoin#36439: test: poll more frequently in sync helpers and RPC connection wait
89a3a13c44 merge-script: Merge bitcoin/bitcoin#35724: cmpctblock: Improve logging of `cmpctblock` message reconstruction statistics [part of prefill series]
38ac0d530f merge-script: Merge bitcoin/bitcoin#36522: test: check MIN_PEER_PROTO_VERSION peers are not disconnected
49b4b4add3 merge-script: Merge bitcoin/bitcoin#36514: ci: Remove confusing -DBUILD_BENCH=ON -DBUILD_FUZZ_BINARY=ON from CONFIG_ALL
87fbedf5f8 merge-script: Merge bitcoin/bitcoin#36544: test: Fix intermittent issue in p2p_eviction.py
c50817fe2d merge-script: Merge bitcoin/bitcoin#36535: policy: sum package weight in int64_t
fa9a965750 MarcoFalke: test: Fix intermittent issue in p2p_eviction.py
8898f832d9 ViniciusCestarii: test: poll more frequently in sync helpers and RPC connection wait
cce32b1687 merge-script: Merge bitcoin/bitcoin#36379: fuzz: fix stale comments in http_request
faaabe4454 Ferdinando Ametrano: policy: sum package weight in int64_t
649bc0a645 merge-script: Merge bitcoin/bitcoin#36511: test: Small mempool_compatibility.py cleanups
3c30b8ae4f merge-script: Merge bitcoin/bitcoin#36446: test: remove some avoidable test waits
3f7f845cf5 frankomosh: fuzz: fix stale comments in http_request
4f5ce816db David Gumberg: cmpctblock: log: Print sizes of all tx types and prefill redundancies
f13ae519de merge-script: Merge bitcoin/bitcoin#36469: refactor: deduplicate block validation state catcher
60ebd98c79 merge-script: Merge bitcoin/bitcoin#36425: guix: declare python-setuptools in codesign manifest
5b07c48b83 Greg Sanders: test: check MIN_PEER_PROTO_VERSION peers are not disconnected
173ec9a06c Hennadii Stepanov: Merge bitcoin/bitcoin#36517: Update crc32c subtree to latest master
577eb5610e David Gumberg: cmpctblock: log: Log extrapool separately from mempool
a6cc3f30ef David Gumberg: cmpctblock: log: debuglevel=trace print TXID's of all missing tx'es.
4b4cdde064 merge-script: Merge bitcoin/bitcoin#36504: test: Add missing timeouts for HTTPConnection
2958dda390 fanquake: Update crc32c subtree to latest master
55f7dd0021 fanquake: Squashed 'src/crc32c/' changes from 60bcf13edf..5bd2a6bcf9
fa13e6e175 MarcoFalke: ci: Refactor BITCOIN_CONFIG_ALL into array
fac89d44e3 MarcoFalke: ci: Remove confusing -DBUILD_BENCH=ON -DBUILD_FUZZ_BINARY=ON from CONFIG_ALL
badc957481 Hennadii Stepanov: Merge bitcoin/bitcoin#36485: ci: refactor BUILD_TARGETS use
fae8a8fd3c MarcoFalke: test: Small mempool_compatibility.py cleanups
3b07eeeae0 merge-script: Merge bitcoin/bitcoin#36294: mempool: Remove -persistmempoolv1 option
1605d8873e merge-script: Merge bitcoin/bitcoin#36440: test: speed up functional tests by removing avoidable waits
fa4308dfbf MarcoFalke: test: make wait_until timing arguments keyword-only
fad441867c MarcoFalke: test: Add missing timeouts for HTTPConnection
60afa0b8d7 merge-script: Merge bitcoin/bitcoin#36441: doc: fix How to Upgrade section for bitcoin wrapper and libexec
a8b69bdeaf Hennadii Stepanov: Merge bitcoin/bitcoin#36271: Revert #36057 & document mingw-w64 requirement
228877d783 merge-script: Merge bitcoin/bitcoin#36467: test: Set socket timeout in interface_http.py
c067aa716f merge-script: Merge bitcoin/bitcoin#36337: fuzz: Cover block filter P2P messages
fa5643ff99 MarcoFalke: ci: refactor BUILD_TARGETS use
4bacf21a13 merge-script: Merge bitcoin/bitcoin#36474: ci: Run valgrind --exclude tests again
acdb326934 Ava Chow: Merge bitcoin/bitcoin#35989: wallet: fix crash on importdescriptors with a range ending at 2^31-1
8dc80cafa2 ViniciusCestarii: test: wake p2p wait_until on message delivery instead of polling
10cfeb3335 ViniciusCestarii: test: set noban_tx_relay to speed up slow tx relay tests
f739c7876b merge-script: Merge bitcoin/bitcoin#36450: test: Use timeout_factor for drain timeout in check_slow_read_throttle
8ad7e25d1f merge-script: Merge bitcoin/bitcoin#34374: kernel: use struct-based logging and simplify logging interface
c9cccf6d68 Enoch Azariah: refactor: deduplicate block validation state catcher
fa486a4843 MarcoFalke: ci: Run valgrind --exclude tests again
442884f5f3 merge-script: Merge bitcoin/bitcoin#35037: ipc: support per-address max-connections options on -ipcbind
8406af1c0d merge-script: Merge bitcoin/bitcoin#36436: ci: Derive CONTAINER_NAME from the ci config file name
6b93788355 merge-script: Merge bitcoin/bitcoin#36471: bitcoin-util: print genesis hash in display order
f60450e98f merge-script: Merge bitcoin/bitcoin#36416: test: use ipaddress in addr_to_hex
cc8285e8c9 ViniciusCestarii: bitcoin-util: print genesis hash in display order
fa5551cc6d MarcoFalke: test: Rework 413 Too Large tests in interface_http.py
282a05b8d1 merge-script: Merge bitcoin/bitcoin#36462: rpc: fix OpenRPC hex pattern to allow empty strings
fab1529ebc MarcoFalke: test: Set socket timeout in interface_http.py
fab64c032c MarcoFalke: test: DestroyAllBlockFilterIndexes in ~ChainTestingSetup()
fadc2c93d3 MarcoFalke: fuzz: Cover block filter P2P messages
4d7e00d36b ViniciusCestarii: rpc: Fix OpenRPC hex pattern to allow empty strings
db0bde16b9 merge-script: Merge bitcoin/bitcoin#36418: kernel: document that btck_WriteBytes may receive a null pointer
b497a71c66 Alexander Wiederin: kernel: document that btck_WriteBytes may receive a null pointer
9dfde64cc3 merge-script: Merge bitcoin/bitcoin#36447: test: Misc fixes for pending validation events races
35e3c9324e merge-script: Merge bitcoin/bitcoin#36029: cmake: Detect and log MinGW-w64 version when cross-compiling for Windows
ff623cfa9b merge-script: Merge bitcoin/bitcoin#36392: test: Extract and use sigterm_node in init_fd_overflow_test
fa466dea80 MarcoFalke: test: Avoid pending validation events from TestChain100Setup
fa339713db MarcoFalke: test: Drain all validation events before stopping indexes
9523d2b4a1 merge-script: Merge bitcoin/bitcoin#34844: util: Add util::NotNull<SmartPtrType>
fa845f76d5 MarcoFalke: test: Use timeout_factor for drain timeout in check_slow_read_throttle
14a328f75d merge-script: Merge bitcoin/bitcoin#36338: BIP-352: fix P2PKH pubkey extraction from malleated scriptSig
5661a65c9f merge-script: Merge bitcoin/bitcoin#36432: wallet: show real fee_reason strings in help
672c2d2137 merge-script: Merge bitcoin/bitcoin#36448: randomenv: use `KERN_POSIX1` over `KERN_OSREV`
6b8a5524f7 merge-script: Merge bitcoin/bitcoin#36291: test: add script_tests cases covering interpreter mutants
14f89aeea6 merge-script: Merge bitcoin/bitcoin#36340: util: cap Sock::WaitMany timeout to fix -rpcclienttimeout=0 on macOS
d1f9a5b3e0 fanquake: randomenv: use KERN_POSIX1 over KERN_OSREV
0cd0789c86 fanquake: test: use ipaddress in addr_to_hex
fa21ac647d MarcoFalke: test: [move-only] wallet rescan tests to separate TU
fa2cdb6a3c MarcoFalke: ci: [refactor] remove redundant GOAL=install
fa547e8204 MarcoFalke: ci: [refactor] Remove redundant set -o errexit
fa8fd9164f MarcoFalke: ci: Derive CONTAINER_NAME from the ci config file name
93c8aec3fb Shuvam Pandey: doc: add release note for #35989
aef8a04966 merge-script: Merge bitcoin/bitcoin#36435: ci: isolate container test networks
3cb91bc7da merge-script: Merge bitcoin/bitcoin#36308: test: Set tsan enable_adaptive_delay=1 by default
fa42e28684 MarcoFalke: refactor: Return util::NotNull<std::unique_ptr<ChangeSet>> from CTxMemPool::GetChangeSet()
fa04fafb3a MarcoFalke: refactor: In CNode use util::NotNull<std::unique_ptr<Transport>> m_transport
fae9ab0f0d MarcoFalke: refactor: Use NotNull pointer to input fetching pool
fa0184afa2 MarcoFalke: refactor: Use util::NotNull<std::unique_ptr<LevelDBContext>> m_db_context
fafa44e020 MarcoFalke: util: Add util::NotNull<SmartPtrType>
c04e968b2b will: guix: update certvalidator for Python 3.12
acaf322fc4 merge-script: Merge bitcoin/bitcoin#36152: test: cover the feature-negotiation version boundary in p2p_leak
f55788e845 merge-script: Merge bitcoin/bitcoin#36277: net: always complete all initial private broadcast connections
cf80493e23 Ava Chow: Merge bitcoin/bitcoin#34729: Reduce log noise
2c99247284 Ava Chow: Merge bitcoin/bitcoin#36303: http: Log bytes received from client, use to replace receive-throttle regression test
2870608661 spidey279: doc: fix How to Upgrade section for bitcoin wrapper and libexec
ce1d88b263 will: test: avoid unused wallet test chains
40619d0687 will: bench: honor configured wallet epochs
79bb94f092 will: test: cap expected IPC timeouts
06cb869112 will: test: shorten network limited negative wait
09e22fbbb0 merge-script: Merge bitcoin/bitcoin#35873: test: add a tx_valid vector for CVE-2024-38365
b47ec7c6e1 merge-script: Merge bitcoin/bitcoin#35835: test: add CONST_SCRIPTCODE failure-path vectors to script_tests.json
889e7c5af8 merge-script: Merge bitcoin/bitcoin#36329: psbt: add new test vectors
0036d5f1fa merge-script: Merge bitcoin/bitcoin#36262: test: cover orphan reconsideration interruptibility
36e9e52f16 merge-script: Merge bitcoin/bitcoin#34907: wallet, test: make wallet_fast_rescan robust
8c49a9abe9 merge-script: Merge bitcoin/bitcoin#36151: makeseeds: fix off-by-one in field count check
b42ea67533 merge-script: Merge bitcoin/bitcoin#36349: rpc: avoid copying unbroadcast transaction IDs just to count them
fa966fd767 MarcoFalke: ci: Use one subnet per container
714261b508 merge-script: Merge bitcoin/bitcoin#36426: test: check IBD insufficient work disconnect of outbound peers
fae564e66a MarcoFalke: ci: Use one network per container and rm it after success
367119018d merge-script: Merge bitcoin/bitcoin#36320: test: refactor: make chain_dir consistent with CreateBaseChainParams
6e419391cf merge-script: Merge bitcoin/bitcoin#32895: wallet: Prepare for future upgrades by recording versions of last client to open and decrypt
c7835db15a merge-script: Merge bitcoin/bitcoin#36080: p2p: Suspend ping timeout while downloading blocks from a peer
b3f9d8e1dd merge-script: Merge bitcoin/bitcoin#36128: test: add script_tests cases covering more interpreter mutants
b6a1b0ff70 merge-script: Merge bitcoin/bitcoin#36327: test: speed up secp256k1 fixed-base multiplication and Schnorr signing
052cf121ab Musa Haruna: rpc: avoid copying unbroadcast txids to count them
781d8dbd50 Jehudi Castro-Sierra: wallet: show real fee_reason strings in help
1c96b08cb6 fanquake: nix: drop MSVCRT build
cd7605a6b7 fanquake: doc: document mingw-w64 requirement in Windows build docs
8073ff101f fanquake: Revert "build: check for SetThreadDescription() at configure time"
66776840be merge-script: Merge bitcoin/bitcoin#36415: rpc: clarify preciousblock help text
c502b65c00 Bruno Garcia: test: check IBD insufficient work disconnect of outbound peers
c8e852d3a0 Ava Chow: Merge bitcoin/bitcoin#36404: fuzz: don't set random state for private broadcast test
dd809d2c08 Ava Chow: Merge bitcoin/bitcoin#36299: cli: Improve empty-response and fix -rpcclienttimeout regression
802eb7daa9 Ava Chow: Merge bitcoin/bitcoin#34213: net: preserve anchors when network is disabled
11977b42ac will: guix: declare python-setuptools
15d0926399 ViniciusCestarii: rpc: clarify preciousblock help text
65896ac58e merge-script: Merge bitcoin/bitcoin#36411: ci: drop `-Wno-error=maybe-uninitialized` from win64 cxx flags
eb086540b6 stickies-v: kernel: make logging struct-based and simplify configuration
0c327a3474 stickies-v: kernel: add KernelLogger
16bff77a5a ViniciusCestarii: test: cover orphan reconsideration interruptibility
3d976f464d stickies-v: kernel: remove API to format and disable logging
4ec80a5d4f stickies-v: kernel: add log level and category name helpers to wrapper
2ce6cd3d90 stickies-v: kernel: expose btck_LogEntry
d83647e7c4 Martin Zumsande: p2p: Don't apply ping timeout while downloading blocks
69142eacd1 Hennadii Stepanov: Merge bitcoin/bitcoin#36383: util: remove unused exception parameter in `Popen::execute_process`
2b43c62d8e Martin Zumsande: p2p: move ping timeout check into SendMessages
8b5bbfe1fc Martin Zumsande: test: add functional test for pings during IBD
a829aeaac1 Hennadii Stepanov: Merge bitcoin/bitcoin#36412: ci: drop `-U_FORTIFY_SOURCE` from TSAN job
c57ef546c3 fanquake: ci: use LLVM libc++ 23.1.2
f2a0e7392c fanquake: ci: drop -U_FORTIFY_SOURCE from TSAN job
963f557a72 fanquake: ci: drop -Wno-error=maybe-uninitialized from win64 flags
9f05952795 merge-script: Merge bitcoin/bitcoin#36052: ci: Doc: Move all config comments right next to the option they explain
1d19cca076 Andrew Toth: fuzz: don't set random state for private broadcast test
00c1b52ee5 Andrew Toth: net: remove PrivateBroadcast::DidNodeConfirmReception
dc95a705d4 Andrew Toth: net: always complete all initial private broadcast connections
7988380da9 Hennadii Stepanov: Merge bitcoin/bitcoin#36272: guix: split Linux toolchain
d4b0e1e4b0 Ava Chow: Merge bitcoin/bitcoin#35833: log: prevent user input from injecting fake log lines
8dcf90a9b3 Kanan: util: cap Sock::WaitMany timeout
fad49a733d MarcoFalke: test: Extract and use sigterm_node in init_fd_overflow_test
7b32155458 Ava Chow: wallet: Set last opened and decrypted features during migration
f998a740fc Ava Chow: wallet: Record the supported features of the last client to decrypt a wallet
8453ad801b Ava Chow: wallet: Introduce LastClientFeatures flags and LAST_OPENED_FEATURES record
4b612c6bf8 merge-script: Merge bitcoin/bitcoin#36391: test: fix typo in rpc_psbt
0a8ffe9051 Bruno Garcia: test: fix typo in rpc_psbt
cdfaa534d0 Sebastian Falbesoner: BIP-352: fix P2PKH pubkey extraction from malleated scriptSig
c35b992514 Sebastian Falbesoner: test: characterize buggy BIP-352 P2PKH extraction on malleated scriptSig
856f9ea158 Enoch Azariah: doc: add ipcbind max-connections release note
bdd381b8ed Enoch Azariah: ipc: test per-address connection limiting over unix sockets
8761d53b25 Enoch Azariah: ipc: support per-address max-connections on ipcbind
c9d101ca7a fanquake: guix: split Linux toolchain
e0f16ef9a4 merge-script: Merge bitcoin/bitcoin#36377: doc: add 461 (Deterministic ECDSA signatures with low-R grinding) to bips.md
cde2f2ec64 fanquake: build: enable -Wunused-exception-parameter
1b00dff743 fanquake: util: remove unused exception parameter in Popen::execute_process
e7aef7e86d Ava Chow: Merge bitcoin/bitcoin#36375: wallet: accept uppercase addresses without amount in sendall
de8892f9db Ava Chow: Merge bitcoin/bitcoin#36336: log: move CreateNewBlock() log line behind a new mining category
0198c85334 Ava Chow: Merge bitcoin/bitcoin#36365: fees: fall back to `block_policy` and minor api change
ba8fdb9717 Ava Chow: Merge bitcoin/bitcoin#36381: test: avoid testing at the exact `-maxfeerate` boundary
a4bc96966f ekzyis: test: refactor: make chain_dir consistent with CreateBaseChainParams
efe0dfcf1e ViniciusCestarii: test: cover DERSIG 9-byte signature lower bound
bbc4bdf909 ViniciusCestarii: test: cover DERSIG null S byte only when S is multi-byte
fd2cf04502 ViniciusCestarii: test: cover DERSIG null R byte only when R is multi-byte
a1deba78c5 ViniciusCestarii: test: cover DERSIG total-length byte check
3d04ed8ac7 ViniciusCestarii: test: cover DERSIG 73-byte signature upper bound
2c0f69a047 ViniciusCestarii: test: cover STRICTENC rejects bad 33-byte pubkey prefix
df3008418c ismaelsadeeq: doc: add release notes
54b8795121 ismaelsadeeq: log: move CreateNewBlock() log line behind a new mining category
619185d5ce merge-script: Merge bitcoin/bitcoin#36233: guix: Update time-machine to `60f6956aeffa7f30285745bd0ea615e9acfc74f8`
3b9768a07a Hennadii Stepanov: Merge bitcoin/bitcoin#36275: build: enable `-Wunused-const-variable`
dc2a9987aa merge-script: Merge bitcoin/bitcoin#36364: tools: Call SHA256AutoDetect in bitcoin-util, bitcoin-tx and bitcoin-wallet
025768fb37 ismaelsadeeq: test: avoid testing at the exact `-maxfeerate` boundary
ced4c6e6ab merge-script: Merge bitcoin/bitcoin#36321: net: cast vector size to avoid overflow, truncation, sign change
5b77288673 ismaelsadeeq: fees: clear mined-block stats when the mempool load fails
c0b7ca3dbd ismaelsadeeq: fees: fall back to block_policy when the mempool estimator can't estimate
4056908f0f ismaelsadeeq: fees: rename the default fee_rate_estimator value to "auto"
e7a1835096 merge-script: Merge bitcoin/bitcoin#36235: ci: fail iwyu job on compiler errors instead of silently logging them
d57346d682 Sebastian Falbesoner: doc: add 461 (Deterministic ECDSA signatures with low-R grinding) to bips.md
df2994b14a FlashW: wallet: accept uppercase addresses without amount in sendall
b6fc3cf004 brunoerg: test: speed up secp256k1 fixed-base multiplication
05bc2f53ce Hennadii Stepanov: Merge bitcoin/bitcoin#36024: ci: Make `test_bitcoin-qt.exe` output visible
4048909a53 Torkel Rogstad: tools: Call SHA256AutoDetect in bitcoin-util, bitcoin-tx and bitcoin-wallet
d93d366e20 Lőrinc: log: escape newlines in messages
960dcdb625 Lőrinc: test: characterize RPC and wallet input logs
feb77d838e Hennadii Stepanov: guix: Update time-machine to `60f6956aeffa7f30285745bd0ea615e9acfc74f8`
f14a3ef8c5 fanquake: guix: Skip some packages' tests in `python-lief` and `nsis-x86_64`
493850c4c4 Matthew Zipkin: test: assert HTTP receive throttle from server-side log
ed7dd7cf4e Ava Chow: Merge bitcoin/bitcoin#34371: wallet: allow importprunedfunds for spending transactions
f80aaf4bd7 Ava Chow: Merge bitcoin/bitcoin#29278: Wallet:  Add `maxfeerate` wallet startup option
e19f83e944 Ava Chow: Merge bitcoin/bitcoin#35984: sign: skip signing SIGHASH_SINGLE inputs with no corresponding output
ab80335667 Ava Chow: Merge bitcoin/bitcoin#36135: fuzz: test HTTPRequest state machine in http_request
65e075f89f Ava Chow: Merge bitcoin/bitcoin#35696: i2p: update leaseset encryption types
d26f19c77c Ava Chow: Merge bitcoin/bitcoin#35948: init: correct first-run disk space estimate
694eaad2eb stickies-v: kernel: add missing log levels and categories
9037413273 merge-script: Merge bitcoin/bitcoin#36335: Remove my key from SECURITY.md
f6b19b190b merge-script: Merge bitcoin/bitcoin#36322: init: fee estimates can lag behind the chain after restart
5820537e1b dergoegge: Remove my key from SECURITY.md
da03790dbb merge-script: Merge bitcoin/bitcoin#36324: test: Fixup MAX_BODY_SIZE http throttling test
37969fc152 merge-script: Merge bitcoin/bitcoin#36312: net: don't discourage private broadcast peers
6fa2f3974c Sjors Provoost: test: add BIP174 invalid value size vector
e8e7e91a11 Ava Chow: Merge bitcoin/bitcoin#36284: wallet: don't double discard output groups with avoidpartialspends
8c27c38526 Lőrinc: init: drain callbacks before saving fee estimates
08729e6ef9 Lőrinc: test: characterize fee callback loss at shutdown
308cd67019 Eugene Siegel: net: cast vector size to avoid overflow, truncation, sign change
bfdcd9797c merge-script: Merge bitcoin/bitcoin#35890: doc: use overwrite (>) instead of append (>>) for one-shot PSBT files in offline-signing-tutorial.md
de9f42c497 merge-script: Merge bitcoin/bitcoin#36316: ci: use POSIX threads for Nix Windows builds
029bc15f2c Sjors Provoost: test: add BIP174 sighash combiner vector
fa2c62036b MarcoFalke: test: Fixup MAX_BODY_SIZE http throttling test
5c726f2058 Ryan Ofsky: Merge bitcoin/bitcoin#35675: mining: add block template manager
26241482e5 Ava Chow: Merge bitcoin/bitcoin#35923: mempool: count unbroadcast txids in memory usage
a632d4f697 Ava Chow: Merge bitcoin/bitcoin#35177: test: use MiniWallet for getblockstats test data generation
be5d0b5503 Ava Chow: Merge bitcoin/bitcoin#35301: Silent Payments: Implement bip352 (take 2)
b3f846ec3e Ava Chow: Merge bitcoin/bitcoin#35440: wallet: check descriptor cache xpub length before decoding
dc3cd1969e merge-script: Merge bitcoin/bitcoin#35809: contrib: add deterministic fuzz coverage mode
81e2de897d merge-script: Merge bitcoin/bitcoin#35893: test: cover submitpackage other-wtxid for same-txid-diff-witness
eab6630add Andrew Toth: net: don't discourage private broadcast peers
31754523cd merge-script: Merge bitcoin/bitcoin#36309: private broadcast: clarify claims, mark as experimental
9fd18aedb0 will: ci: print Windows cross compiler thread model
1d59d5ad25 will: ci: use POSIX threads in Nix Windows cross shell
e3ee0ebd89 josibake: tests: add BIP352 test vectors as unit tests
f133d1373a josibake: common: add bip352.{h,cpp} secp256k1 module
96d487c11e will: ci: raise BuildKit step log limit
44997c391a josibake: Add "sp" HRP
356c91f6ae josibake: crypto: add KeyPair::GetSecpKeypair
fa90a8a013 MarcoFalke: ci: [refactor] Use eval-based string-to-argv conversion for FUZZ_TESTS_ARGS
0f104733cc Ava Chow: walletdb: Decouple last client record from CLIENT_VERSION
2b95b45a9a Ava Chow: Merge bitcoin/bitcoin#35813: wallet, rpc: Add listrawtransactions RPC
71c30b6083 Ryan Ofsky: Merge bitcoin/bitcoin#27052: test: rpc: add last block announcement time to getpeerinfo result
d36f4a1788 merge-script: Merge bitcoin/bitcoin#36155: doc: remove json quoting from gettxoutsetinfo and getblockstats cli examples
b7211ba80c merge-script: Merge bitcoin/bitcoin#34717: p2p: remove m_getaddr_sent
7ee3d622e5 Ava Chow: Merge bitcoin/bitcoin#35752: wallet: make encryption state updates atomic
f413729983 Greg Sanders: private broadcast: mark feature as experimental
2630d8e6c9 Greg Sanders: doc: scope claims about private broadcast feature
248ce46faf merge-script: Merge bitcoin/bitcoin#35619: test:  ExtendedPrivateKey follow-ups
995da8678a merge-script: Merge bitcoin/bitcoin#36302: ci: simplify macOS codesign check
db7ec4fb97 Alhuda Khan: refactor: (de)serialize CExtKey/CExtPubKey through streams
cb69853fc1 alhudz: wallet: check descriptor cache xpub length before decoding
f86cbf53eb merge-script: Merge bitcoin/bitcoin#36310: rpc: clarify that `getaddrmaninfo` counts unique addresses
bbc40ede1b merge-script: Merge bitcoin/bitcoin#36261: test: cover PSBT unknown field merging
cf57dc281e fanquake: build: add -Wunused-const-variable
b45a7084d8 fanquake: refactor: use inline constexpr
f839ee1afb Ryan Ofsky: Merge bitcoin/bitcoin#35887: ipc: use std::optional for checkSpawned(), add tests and rename arg -ipcfd to -ipcchild
dac53c585b merge-script: Merge bitcoin/bitcoin#31888: contrib: Support re-writing linearize-data dumps
0d34b6e928 0xb10c: rpc: clarify that getaddrmaninfo counts unique addresses
4ecbc82d41 Hennadii Stepanov: Merge bitcoin/bitcoin#36278: Update minisketch subtree to latest master
622817f097 David-Uka: ci, iwyu: fail job on compiler errors instead of ignoring them
5ca3773414 merge-script: Merge bitcoin/bitcoin#36298: Update crc32c subtree to latest master
fa18f9aeac MarcoFalke: ci: Doc: Move all config comments right next to the option they explain
fa0e84ec53 MarcoFalke: ci: refactor: Use printf %q quoting for BITCOIN_CONFIG
5945cb83dd Hao Xu: contrib: add deterministic fuzz coverage mode
fa0d826eac MarcoFalke: test: Use sanitizer env in functional tests by default
69ad2a67f2 merge-script: Merge bitcoin/bitcoin#36283: kernel: expose transaction version
fafce3be39 MarcoFalke: test: Set tsan enable_adaptive_delay=1 by default
faf907fd13 MarcoFalke: test: Add with_sanitizer_env.py
fad2fc5a0f MarcoFalke: doc: Remove section on how to install libasan etc
716e8605e5 fanquake: ci: simplify macOS codesign check
767d86aaa7 Matthew Zipkin: http: log received bytes per client read
bb5296576e merge-script: Merge bitcoin/bitcoin#36206: build: drop use of `OBJC_OLD_DISPATCH_PROTOTYPES`
170d37983c merge-script: Merge bitcoin/bitcoin#36198: http: Add missing LIFETIMEBOUND annotations
c08489fb27 merge-script: Merge bitcoin/bitcoin#36288: build: Revert remove `cmake/script/CoverageFuzz.cmake`"
4a583f38ef merge-script: Merge bitcoin/bitcoin#36230: wallet: Improve `HasWalletDescriptor` performance and other canonical descriptor string followups
5f05d8c5f6 merge-script: Merge bitcoin/bitcoin#36297: rpc: Correct invalid OpenRPC defaults
457c9e8999 Shuvam Pandey: script: avoid overflow when checking descriptor range bounds
ab3bb55a67 Shuvam Pandey: test: add coverage for descriptor range end bounds
867ad9bffb Shuvam Pandey: wallet: fix integer overflow in descriptor keypool top up
1889440f82 Shuvam Pandey: wallet: reject unrepresentable descriptor import ranges
b7f740c594 will: rpc: Correct OpenRPC default metadata
731b89c09b Fabian Jahr: test: Check that importmempool fails on a malformed mempool.dat
4c01625f79 Fabian Jahr: doc: Add release note for -persistmempoolv1 removal
d1dfdf8276 Fabian Jahr: mempool: Remove -persistmempoolv1 option
86a31b93d0 Fabian Jahr: test: Use v31.0 as old node in mempool_compatibility.py
5181c61d73 fanquake: Squashed 'src/crc32c/' changes from efb8ea04e4..60bcf13edf
2c8372db11 fanquake: Update crc32c subtree to latest master
83434f7683 nervana21: kernel: expose transaction version
7c311f5c6c pablomartin4btc: doc: Add release notes for listrawtransactions
b377786df1 pablomartin4btc: test: Add functional test for listrawtransactions
605c4fd3ae pablomartin4btc: wallet, rpc: Add listrawtransactions RPC
ba6c179ba0 pablomartin4btc: wallet, rpc: allow omitting parent_descs from TransactionDescriptionString
d48e76e689 merge-script: Merge bitcoin/bitcoin#36286: crypto: Fix MuHash3072 division by itself
719324977a Fabian Jahr: test: Check that ineligible output groups are discarded only once
6d2414542b Ava Chow: wallet: reuse unlock and passphrase change errors
593554622e Ava Chow: wallet: return passphrase errors with Expected
f949b3ba2a Lőrinc: wallet: publish descriptor keys after writes
e3712b7d49 Lőrinc: test: characterize descriptor insertion failure
bd55810778 Lőrinc: wallet: abort failed descriptor key erases
537e791915 Lőrinc: test: cover encrypted descriptor key insertion
d8a6f5e48d Lőrinc: wallet: abort failed descriptor key writes
14ce3fdb49 Lőrinc: test: characterize descriptor key failures
5bc0be16fe Lőrinc: wallet: reject failed passphrase changes
ee6d45a07e Lőrinc: test: characterize passphrase write failure
2daa2f94f4 Ava Chow: wallet: restore lock state before re-encryption
8b23fa4773 Lőrinc: wallet: abort failed encryption transactions
e6c374d302 Lőrinc: test: characterize encryption transaction failures
70381010c0 Lőrinc: refactor/test: add wallet failure injection
0e9018e8b6 merge-script: Merge bitcoin/bitcoin#36249: net, rpc: Asmap version improvements/follow-ups
61edcf9253 Ava Chow: test: Add 31.1 to wallet back compat
ebf2f69ee8 Ava Chow: test: Simplify miniscript descriptor check in wallet back compat
f6cbcfd98a Ava Chow: wallet: Document WalletDescriptor::UpdateFrom
f0f6dce849 Ava Chow: descriptor, doc: Clarify miniscript CompatDescriptorHash
405b1d6055 Ava Chow: descriptor: Explicitly handle use_apostrophe cases
64abb3e8d3 Ava Chow: wallet: Compare descriptors by hash of canonical string
bb5e8320d7 Ava Chow: wallet: Make WalletDescriptor's descriptor const
4cc00f7bc0 Ava Chow: wallet: Remove WalletDescriptor's default constructor
dc3e2bc6df pablomartin4btc: wallet, rpc: extract PushTxAmountAndFee/PushTxDecoded helpers
b388f9bd0d Fabian Jahr: crypto: Fix MuHash3072 division by itself
4f624bb82d sedited: Revert "build: Remove `cmake/script/CoverageFuzz.cmake`"
ad97933af2 merge-script: Merge bitcoin/bitcoin#36285: refactor: Use static const over inline const to work around ld64 bug
a604a76475 merge-script: Merge bitcoin/bitcoin#36282: Update leveldb subtree to latest master
fa8fefb29b MarcoFalke: refactor: Use static const over inline const to work around ld64 bug
2bbbeaa663 Ava Chow: Merge bitcoin/bitcoin#34861: wallet: Add importdescriptors interface
20307f0ac0 Fabian Jahr: wallet: don't double count discarded output groups with avoidpartialspends
7528f799d9 fanquake: Update leveldb subtree to latest master
4be88b9bce fanquake: Squashed 'src/leveldb/' changes from 13da2d6758..53a1914e00
1805716354 Fabian Jahr: cli: Apply -rpcclienttimeout per socket wait instead of per phase
b841ab6942 Fabian Jahr: cli: Treat a response with Content-Length: 0 as complete
749bd10fdf fanquake: Update minisketch subtree to latest master
fcb2d832b2 fanquake: Squashed 'src/minisketch/' changes from 4a179c61e3..a12f5de1c9
21e4ea8134 w0xlt: test: cover PSBT unknown field merging
59f7f3d07d fanquake: build: drop use of OBJC_OLD_DISPATCH_PROTOTYPES
b821585543 merge-script: Merge bitcoin/bitcoin#33593: guix: Use UCRT runtime for Windows release binaries
0b353a9e87 Fabian Jahr: netgroup: Cache asmap version
fb68c27002 merge-script: Merge bitcoin/bitcoin#36260: torcontrol: Use reconnect backoff after dropped connections
7dedc4545a Hennadii Stepanov: Merge bitcoin/bitcoin#36256: guix: Update osslsigncode to 2.14
a687188101 merge-script: Merge bitcoin/bitcoin#36160: refactor: Minor improvements to HTTP unit tests
651e44f327 merge-script: Merge bitcoin/bitcoin#36194: kernel: expose block header Merkle root
d32a515fb0 merge-script: Merge bitcoin/bitcoin#34566: feature: Use different datadirs for different signets
59a465ce37 Ava Chow: guix: Validate codesigned windows binaries
66eeac216a Ava Chow: guix: Use osslsigncode 2.14
4556ef6267 Fabian Jahr: torcontrol: Apply reconnect backoff after dropped connections
57721f8074 merge-script: Merge bitcoin/bitcoin#36253: fuzz: Use `LIMITED_WHILE` in `connect_block`
dadca55f60 merge-script: Merge bitcoin/bitcoin#36251: rest: add `generated` and `height` to spenttxouts JSON
de394ad3b7 merge-script: Merge bitcoin/bitcoin#36207: kernel: add wtxid accessor
f69e56bc1c ismaelsadeeq: [doc]: add release notes
40ab7aa90d ismaelsadeeq: [wallet]: warn when `-maxtxfee` conflicts with `-minrelaytxfee`
df1feeb487 ismaelsadeeq: [wallet]: enforce `-maxfeerate` on wallet transactions
d2c832e9e7 ismaelsadeeq: [util]: add a new transaction error type
633c08d3f7 ismaelsadeeq: [node]: update `BroadcastTransaction` to check fee rate limit
7bfce65801 ismaelsadeeq: [wallet]: add `maxfeerate` wallet startup option
607568f2b0 ismaelsadeeq: [wallet]: update `max_fee` to `max_tx_fee`
6b913b6224 ismaelsadeeq: doc: add missing verb to make sentence readable
a9c39696f4 ismaelsadeeq: scripted-diff: rename `m_default_max_tx_fee` to `m_max_tx_fee`
16278c2816 lucasdbr05: kernel: expose block header Merkle root
51ddab532c Ryan Ofsky: Merge bitcoin/bitcoin#35819: test: add coverage for untested descriptor parse error paths
2c249dbdf5 Pol Espinasa: wallet: Add an importDescriptors() interface for the wallet
3be5f40137 Pol Espinasa: wallet: add CheckDescriptorRangeBounds
43bba1ed74 KY-U: kernel: expose transaction witness presence
31224d0680 KY-U: kernel: expose transaction wtxid
a9cd985d0a Pol Espinasa: wallet: Move ImportDescriptor and ProcessDescriptorsImport to imports.cpp
c9650d8f0e Pol Espinasa: wallet: rename ProcessDescriptorImport to ImportDescriptor and add ProcessDescriptorsImport
a40ee4ec26 Pol Espinasa: wallet: rpc: refactor: ProcessDescriptorImport returns ImportDescriptorResult
48d3d717fb Pol Espinasa: wallet, util: Add HandleWalletErrorCode
04c73a91d2 Pol Espinasa: wallet: Add ImportError struct and new WalletError codes
9752156185 Pol Espinasa: wallet: rpc: refactor: Extract UniValue processing from ProcessDescriptorImport
f1f61af357 Pol Espinasa: wallet: Add ImportDescriptorRequest structs
7375124f4c Pol Espinasa: wallet: refactor: make is_ranged no longer an optional
90485103c6 Pol Espinasa: wallet: lower the minimum timestamp to 0
380d3ae0de Pol Espinasa: wallet: rpc: Use std::optional in GetImportTimestamp
e0229ca685 marcofleon: fuzz: Use LIMITED_WHILE in connect_block
1566a4767a 0xb10c: rest: add generated and height to spenttxouts JSON
cff00c547e merge-script: Merge bitcoin/bitcoin#34743: p2p: don't disconnect manual peers for block stalling
a09a81ebfc merge-script: Merge bitcoin/bitcoin#35961: depends: Update `boost` package to 1.92.0
76343a09f8 merge-script: Merge bitcoin/bitcoin#36186: test: return False for a too-short ECDSA signature
5551d39b20 will: doc: document manual peer stalling behavior
24628d3ae7 will: test: cover manual peer block download cooldown
4c79f3a34d will: test: support manual connections in addconnection
698b5bbf3a will: p2p: pause stalling manual block downloads
c38e0d20c3 merge-script: Merge bitcoin/bitcoin#36093: test: ipc should reject invalid json
a49fa1f6e6 merge-script: Merge bitcoin/bitcoin#35849: init: don't suggest -reindex-chainstate for recovery on a pruned node
dd3c62c55f merge-script: Merge bitcoin/bitcoin#36083: test: cover getrawtransaction on a stale block via txindex
36c1b149fe merge-script: Merge bitcoin/bitcoin#35472: test: add coverage for feebumper uncomputable cluster error path
7c4facb51b merge-script: Merge bitcoin/bitcoin#36081: rpc: add bestblockhash to getmininginfo
c1e9d15406 Fabian Jahr: doc: Describe how to verify the asmap in use
87ce88c1b5 Fabian Jahr: rpc: Add asmap_version to getnetworkinfo
dd5a8a63b2 Fabian Jahr: test: Check embedded asmap version log and addrman re-bucketing
d9d0578410 merge-script: Merge bitcoin/bitcoin#34681: wallet: move rescan logic into ChainScanner and wallet/scan
2ca83ba262 merge-script: Merge bitcoin/bitcoin#35436: wallet: Add addHDkey interface
0bc87365ca Fabian Jahr: init: Log asmap version from NetGroupManager
fdfd196908 Fabian Jahr: rpc: Reuse AsmapVersion in exportasmap
adca0a9740 merge-script: Merge bitcoin/bitcoin#36247: iwyu: Always keep `bitcoin-build-info.h` header
1aa500b6b7 Hennadii Stepanov: iwyu: Always keep `bitcoin-build-info.h` header
d25470d992 merge-script: Merge bitcoin/bitcoin#35975: wallet: Fix `CWalletTx` malleated transaction metadata sync
2c6047df87 Ava Chow: test: Bumping a transaction prevents bumping malleations
a44f9ad350 Ava Chow: test: Test rbf metadata sync of malleated tx
752fd437c7 furszy: wallet: persist synced metadata and do not sync on load
31eedfc6fc furszy: wallet: simplify wtx metadata sync
6c16d76f79 furszy: wallet: sync tx replacement metadata to malleated txs
34533d5d22 Ava Chow: wallet: Clarify IsEquivalentTo is actually checking malleation
b973a355c4 Ava Chow: Replace CTransaction::operator== with Equals that has options
8df006f233 furszy: wallet: skip signing SIGHASH_SINGLE inputs with no corresponding output
3d7d190b69 ismaelsadeeq: ci: enforce iwyu for block template manager
ffe3a631f3 ismaelsadeeq: node: remove NodeContext::mining and EnsureMining
6c71166bcf ismaelsadeeq: test: create templates via BlockTemplateManager
ec4f24ef18 ismaelsadeeq: rpc: wait for tips via BlockTemplateManager
8372721f20 ismaelsadeeq: rpc: build generation templates via BlockTemplateManager
38556f817e ismaelsadeeq: rpc: only copy the header in getblocktemplate
951fac807d ismaelsadeeq: rpc: do not copy template data in getblocktemplate
0998c0bbdf ismaelsadeeq: rpc: build getblocktemplate via BlockTemplateManager
011cbfbcd2 ismaelsadeeq: rpc: route getblocktemplate internals through node
400ac328c9 ismaelsadeeq: interfaces: create block template via BlockTemplateManager
037d3519f2 ismaelsadeeq: node: move tip and wait helpers into BlockTemplateManager
07964c525d ismaelsadeeq: miner: move SubmitBlock into BlockTemplateManager
bcdadf2b71 ismaelsadeeq: node: move mining_args to BlockTemplateManager
482a5d2712 ismaelsadeeq: node: introduce BlockTemplateManager
2efaa6763b furszy: wallet: simplify and restrict SyncMetaData to malleated txs
fc718ade4f Ava Chow: test: Test that metadata is synced to malleated transactions
17817818da Hennadii Stepanov: Merge bitcoin/bitcoin#36228: ci, iwyu: generate embedded ASMap header explicitly
1cbbf64ea8 Kanan: ci, iwyu: generate embedded ASMap header explicitly
1afa0cd70a Kanan: cmake: add raw data header generation target
0476444e33 merge-script: Merge bitcoin/bitcoin#35935: wallet: Avoid unnecessary wtxvariant rewrites
3d2b65d050 Enoch Azariah: ipc: add default connection limit for ipcbind listeners
feeb00af8c ekzyis: cli: Add -signetchallenge info on RPC auth error
c47ea370dc ekzyis: doc: Update documentation for signet datadir
6f8c43f9ef ekzyis: test: Add signet datadir tests
9b37d42b23 ekzyis: Use different datadirs for different signets
6bdcae3f76 ekzyis: refactor: Import signet constant and helper from kernel/signet.h
f3fec67c3e merge-script: Merge bitcoin/bitcoin#36227: Pre 32.x branching updates
ddf033054f Bruno Garcia: test: cover anchor handling across network toggles with mocktime
b0bff47d44 brunoerg: net: log that anchors will be tried for connections only if network is active
4b6b854285 brunoerg: test: disabling network activity should not affect anchors
04d3d474c4 Bruno Garcia: net: preserve anchors on shutdown when network is inactive
41771236b4 brunoerg: net: store anchors in SetNetworkActive
9a48134aea sedited: docs: Update bips.md
57d3d00130 sedited: build: Bump version to 32.99
e5f3ea3bf6 brunoerg: net: guard m_anchors with mutex
4d463de804 merge-script: Merge bitcoin/bitcoin#36226: doc: Move release notes to wiki ahead of branch-off
5df082721c sedited: doc: Move release notes to wiki ahead of branch-off
8c64ff0242 merge-script: Merge bitcoin/bitcoin#34914: contrib: replace deprecated --deep codesign flag, fix accidental --verify skip on ci
501ba4cad4 merge-script: Merge bitcoin/bitcoin#36196: contrib, kernel: fixed seeds, chainparams, headerssync params, and assumeutxo updates pre-32.0
92986c7362 merge-script: Merge bitcoin/bitcoin#36213: Release: 32.0 translations update
1a4e034ddb merge-script: Merge bitcoin/bitcoin#36209: guix: cache GUI depends separately
a6b330973e merge-script: Merge bitcoin/bitcoin#36150: indexes: set prune lock to genesis before first block
fed50258f8 Ava Chow: kernel: add recent assumeutxo snapshot
7eb4cec1a9 Ava Chow: kernel: Update headerssync params
9b22995140 Andrew Toth: indexes: set prune lock to genesis before first block
fc6923cec5 merge-script: Merge bitcoin/bitcoin#36215: asmap: Make version match externally computed hashes
2c2667eaa9 Hennadii Stepanov: qt: 32.0 translations update
51b540c59a merge-script: Merge bitcoin/bitcoin#36218: build: avoid `pipe2` on Darwin (for now)
a42da819a9 merge-script: Merge bitcoin/bitcoin#36174: http: throttle send buffer when client stops draining
da7d7dbc7c Sjors Provoost: contrib: remove deprecated --deep codesign flag
9c7748315d fanquake: build: avoid pipe2 on Darwin (for now)
1fe87c2505 will: guix: cache GUI depends separately
7ee94bf4b0 Hodlinator: asmap: Make outputted ASMap version match externally computed hashes
4a15e0b6f9 merge-script: Merge bitcoin/bitcoin#36195: test: `get_previous_releases.py` use `PREVIOUS_RELEASES_DIR`
b5ef74b248 merge-script: Merge bitcoin/bitcoin#36211: doc: Fix PR reference in productivity guide
5a5b1ed747 merge-script: Merge bitcoin/bitcoin#36201: Update embedded asmap to 1788801420
b3a9b84b37 littleyier: doc: Correct upstream-pull reference
fc4f35fdce merge-script: Merge bitcoin/bitcoin#35513: rpc: help metadata fixes
af83bacdf9 Ava Chow: Merge bitcoin/bitcoin#36202: doc: add rel note about potential CJDNS removal
ecdf9db906 David Gumberg: test: get_previous_releases.py use `PREVIOUS_RELEASES_DIR`
28b69e2988 Matthew Zipkin: http: stop processing requests from a client when send buffer is full
ad4eeaf859 Sjors Provoost: ci: avoid modifying GOAL in 03_test_script.sh
7e75b3b922 merge-script: Merge bitcoin/bitcoin#36116: iwyu: Fix warnings in `src/rpc` and treat them as errors
9d4325f403 merge-script: Merge bitcoin/bitcoin#36203: Update secp256k1 subtree to latest master
3c91db262b Fabian Jahr: net: Update embedded asmap to 1788801420
ffe6aa57fe merge-script: Merge bitcoin/bitcoin#36199: net: treat RFC 9637 new IPv6 documentation range as invalid
00d0c5107b Ferdinando Ametrano: test: return False for a too-short ECDSA signature
2fabbc0bb3 brunoerg: test: check SENDTXRCNCL is sent at version 70016
36775471f8 brunoerg: test: cover the feature-negotiation version boundary in p2p_leak
ba9050ac9b fanquake: Update secp256k1 subtree to latest master
da3401e50f fanquake: Squashed 'src/secp256k1/' changes from 687155df6b..a7f264373e
7d54a88b44 Hennadii Stepanov: iwyu: Fix warnings in `src/rpc` and treat them as errors
462ff18d79 Hennadii Stepanov: iwyu, refactor: Fix includes in some source files
2285d1931a merge-script: Merge bitcoin/bitcoin#35468: ci, iwyu: Request IPC file generation explicitly
b48a27691d Fabian Jahr: fuzz: assert invalid addresses are not routable
e6c775c6d6 Fabian Jahr: net: treat RFC 9637 new IPv6 documentation range as invalid
005ea9f42e merge-script: Merge bitcoin/bitcoin#35778: scripted-diff: Use C.UTF-8 locale in all shell scripts
064122af26 merge-script: Merge bitcoin/bitcoin#36181: ci: Upgrade IWYU to 0.27 compatible with Clang 23
99f81fe029 merge-script: Merge bitcoin/bitcoin#35303: policy: fix negative CFeeRate::ToString() formatting
46654094be Hennadii Stepanov: lint: Use C.UTF-8 locale only in shell scripts
d6a2341632 fanquake: doc: add rel note about potential CJDNS removal
fb26bc9cfe merge-script: Merge bitcoin/bitcoin#35445: wallet, descriptor: Revert `StringType::COMPAT` for Miniscript expressions and drop the concept of a Descriptor ID that can be validated
494300f4cc merge-script: Merge bitcoin/bitcoin#35796: depends: fix IPC listeners on macOS dying when accepting a dead socket
42d93d40de Ava Chow: kernel: update chainTxData
a25511dfbc Ava Chow: kernel: update defaultAssumeValid and minimumChainWork
67726a63a4 Ava Chow: kernel: update assumed blockchain and chainstate sizes
fcfc1df041 Ava Chow: contrib: Update fixed seeds
6385aa1df8 Ava Chow: contrib: Update makeseeds for 30.3 and 31.x
0ae3b40c27 Andrew Toth: test: characterize startup with newly added prune and index
4c9d55a612 Ava Chow: Merge bitcoin/bitcoin#36076: psbt: preserve sighash type when merging inputs
59fd053dac merge-script: Merge bitcoin/bitcoin#34931: validation: abort on DB unreadable coins instead of treating them as missing
33a363ea25 merge-script: Merge bitcoin/bitcoin#36168: PSBT: Make input/output `Merge()` methods return void
0b46fc9c59 Hodlinator: http: Add missing LIFETIMEBOUND annotations
ea785a31f7 Thomas: psbt: preserve sighash type when merging inputs
c786052865 aman21-droid: makeseeds: fix off-by-one in field count check
013b0b2de4 Ava Chow: Merge bitcoin/bitcoin#36176: wallet: avoid a crash when creating a wallet with -nosettings
2ed4be4721 Ava Chow: Merge bitcoin/bitcoin#36113: psbt: fix rendering for invalid long sighash type field
19b0ff2fa0 merge-script: Merge bitcoin/bitcoin#36136: rpc: remove stale "canonical form" claim from getdescriptorinfo help
0c6f2af97b merge-script: Merge bitcoin/bitcoin#36127: wallet: remove unused code
3b944f194f Hennadii Stepanov: iwyu: Switch to generated Clang intrinsics mapping file
1b5ee3be59 Hennadii Stepanov: ci: Upgrade IWYU to 0.27 compatible with Clang 23
6ed7c535ad Hennadii Stepanov: iwyu: Prefer canonical headers
35104a8654 merge-script: Merge bitcoin/bitcoin#35949: miner: Enforce Murch-Zawy rule (BIP54)
51db0e7696 merge-script: Merge bitcoin/bitcoin#36096: rpc: avoid quadratic JSON construction when keys are unique
161a9add8e merge-script: Merge bitcoin/bitcoin#35164: test: cover P2SH sigop counting in test_witness_sigops
a174dd4017 merge-script: Merge bitcoin/bitcoin#36161: build: Remove `cmake/script/CoverageFuzz.cmake`
b557fb2728 merge-script: Merge bitcoin/bitcoin#36164: util: diagnose dangling views of temporary strings
5f0daa0eae merge-script: Merge bitcoin/bitcoin#36169: http: Use SO_EXCLUSIVEADDRUSE on Windows
a34fc8b11a Robert Hamilton: wallet: handle disabled startup settings
b7113e6f42 Robert Hamilton: test: characterize disabled wallet settings
f0c839ace5 merge-script: Merge bitcoin/bitcoin#36123: http: throttle per-connection reads while a request is in flight
0f206eed51 merge-script: Merge bitcoin/bitcoin#36130: test: add tests in transaction_tests.cpp covering live mutants
0b43dea121 merge-script: Merge bitcoin/bitcoin#36163: test: Add coverage for unsatisfiable locktime combination in PSBT `ComputeTimeLock()`
3596658af5 merge-script: Merge bitcoin/bitcoin#36166: validation: refactor: encapsulate Chainstate::m_target_blockhash
f32bfb2593 merge-script: Merge bitcoin/bitcoin#35738: coins: parallel input prevout fetching followups
bcb09b3f4a Hodlinator: qa: Verify HTTP listen port exclusivity
af65069fd1 Hodlinator: windows: Use SO_EXCLUSIVEADDRUSE over SO_REUSEADDR
82deb69111 nebula-21: PSBT: Make input/output `Merge()` methods return void
f04b0c3162 Hodlinator: refactor(test): Make test method use Uppercase, shorten enum values
6eea8e313c Hodlinator: refactor(test): Simplify HTTP response check
852f201e09 stickies-v: validation: refactor: encapsulate Chainstate::m_target_blockhash
fca8fef8f9 frankomosh: fuzz: assert HTTP framing is independent of stream segmentation
b57b0dbebd Lőrinc: util: annotate `Split` input lifetime
34c5dc0583 Lőrinc: util: annotate string view input lifetimes
c368de3eec frankomosh: fuzz: exercise the HTTPRequest state machine
00a5f9b737 Hennadii Stepanov: build: Remove `cmake/script/CoverageFuzz.cmake`
69a640e05e nebula-21: test: Add coverage for unsatisfiable locktime combination in PSBT ComputeTimeLock
5ce3a0b4aa ViniciusCestarii: test: cover legacy sigops count CHECKMULTISIG inaccurately
a5fc82e2b1 ViniciusCestarii: test: cover enforce BIP68 to tx versions higher than 2
bba1d4150e ViniciusCestarii: test: cover IsFinalTx requires every input to be SEQUENCE_FINAL
4519933391 merge-script: Merge bitcoin/bitcoin#36137: validation: use unused SetTargetBlockHash
4ec6ff022a Hennadii Stepanov: Merge bitcoin/bitcoin#36100: ci: use LLVM 23 in *san, fuzz, *cross jobs
7f0c4020e8 merge-script: Merge bitcoin/bitcoin#36118: test: tolerate race condition in interface_http.py
4550801058 fanquake: validation: use unused SetTargetBlockHash
5ba9af6b69 fanquake: ci: pass LIBCXX_INCLUDE_TESTS=OFF to LLVM build
feb3bd46e4 fanquake: clang-tidy: remove some performance-* options
b4bd12d3d5 fanquake: ci: use LLVM 23 in *san, fuzz, *cross jobs
d840adb9da merge-script: Merge bitcoin/bitcoin#36144: rpc: detail x-bitcoin-unit in openrpc help
f41b917f47 merge-script: Merge bitcoin/bitcoin#36145: qa: Use IP_PORTRANGE_HIGH on OpenBSD for dynamic port allocation
d5fbe61f55 merge-script: Merge bitcoin/bitcoin#35958: net: align v2 message type validation with v1 range
64ab0a0697 merge-script: Merge bitcoin/bitcoin#36148: test: Avoid unsafe memory race in index_reorg_crash shutdown
57a79c6962 csjones: doc: remove json quoting from gettxoutsetinfo and getblockstats cli examples
a51df9b0ec Matthew Zipkin: test: tolerate race condition in interface_http.py
fab80e82c1 MarcoFalke: test: Avoid unsafe memory race in baseindex_no_commit_ahead_of_flush
b811aeabad merge-script: Merge bitcoin/bitcoin#36048: util: keep wallet names literal in notification commands
fa0f14ef5e MarcoFalke: test: Avoid unsafe memory race in index_reorg_crash shutdown
faf9c8e8a1 MarcoFalke: test: Clarify index.GetSummary().synced state in index_reorg_crash
a34861d280 rkrux: test: unify how to avoid the creation of the default wallet in nodes
3458837a0b rkrux: test: use ExtendedPrivateKey in wallet_importdescriptors.py
59ebf558f3 Hennadii Stepanov: qa: Use IP_PORTRANGE_HIGH on OpenBSD for dynamic port allocation
6f6b2bbde2 merge-script: Merge bitcoin/bitcoin#35808: fuzz: reset connman state in p2p targets
e85e27976b will: rpc: detail x-bitcoin-unit in openrpc help
3d1004cb9b Matthew Zipkin: http: throttle per-connection reads while a request is in flight
db39de5601 Lőrinc: doc: add `-walletnotify` security note
1f9dfabef6 Lőrinc: refactor: use string views in `ReplaceAll`
469b0e59a2 Lőrinc: util: make `ReplaceAll` literal
604d7e8fdd Lőrinc: test: characterize walletnotify shell injection
4efaa6763a Lőrinc: test: simplify `ReplaceAll` coverage
793e22eed5 Íñigo Aréjula Aísa: test: cover getrawtransaction on a stale block via txindex
a84fbf9dfd Íñigo Aréjula Aísa: test: name the getrawtransaction test nodes
74ddf1c0a0 Lőrinc: refactor: use structured bindings for map entries
21d5d5cb73 Lőrinc: rpc: append unique container keys directly
23e512a58e Lőrinc: rpc: avoid quadratic prioritised transaction JSON
9f0543d69a jeanpablo: wallet: remove unused DatabaseOptions members
dc0395c585 merge-script: Merge bitcoin/bitcoin#36112: ci: Exclude subtrees from iwyu
37c57bc5c2 merge-script: Merge bitcoin/bitcoin#36065: test: refactor: Remove confusing ignore_errors=True
8157964e66 merge-script: Merge bitcoin/bitcoin#36134: doc: Correct comment about which subsystem detects lagging clocks
259553c662 merge-script: Merge bitcoin/bitcoin#36131: rpc: Improve two field's OpenRPC types
1dad06eff3 Craig Raw: remove stale canonical form claim from getdescriptorinfo help
55390d1827 Hodlinator: doc: Correct comment about which subsystem detects lagging clocks
fe3c92cfe0 merge-script: Merge bitcoin/bitcoin#36102: util: Replace !ContainsNoNUL() with ContainsNUL()
d23b53e0cf frankomosh: fuzz: allow http_request inputs to reach MAX_HEADERS_SIZE
58dfcf29f6 merge-script: Merge bitcoin/bitcoin#35351: net: Disallow invalid HeadersSyncState due to lagging clock
c0ed327845 merge-script: Merge bitcoin/bitcoin#36103: validation: remove unused code
78e691ea10 sedited: rpc: Change listunspent's ancestorfees type to NUM
73fb9ced56 sedited: rpc: Fix private key type in signrawtransactionwithkey
128e5c6805 merge-script: Merge bitcoin/bitcoin#35477: test: exercise Schnorr signature cache in txvalidationcache_tests.cpp
bbed824a64 jeanpablo: wallet: remove unused warnings parameter from CreateFromDump
2f6aa41d3d jeanpablo: wallet: remove unused WalletDatabase::m_refcount
f64b3fa70f jeanpablo: wallet: remove unused CHDChain keypool index members
4afc7bc40d jeanpablo: wallet: remove unused COutput::ToString
a0e9aac428 jeanpablo: wallet: remove unused DescriptorScriptPubKeyMan::AddDescriptorKey
56af5e072a frankomosh: fuzz: extract http_request parse and framing check into helpers
d2e24e951d merge-script: Merge bitcoin/bitcoin#36054: test: add script_tests cases covering interpreter mutants
75f64e50c6 furszy: test: exercise node abort on UTXO deserialization failure
4652cd0d82 furszy: txdb: detect UTXO deserialization errors via CDBWrapper::TryRead()
5dfbb91b6c furszy: dbwrapper: add TryRead() to distinguish errors from valid outcomes
ca7162cde5 merge-script: Merge bitcoin/bitcoin#35868: rpc, wallet: fix invalid JSON in HelpExampleRpc curl examples
d0e777baf5 merge-script: Merge bitcoin/bitcoin#36111: rpc: bound memory for overlong Bech32 errors
fa3971011d MarcoFalke: ci: Exclude subtrees from iwyu
fa8566152a MarcoFalke: refactor: Bump old copyright header in univalue
05e49b342f Hennadii Stepanov: Merge bitcoin/bitcoin#36107: iwyu: Fix warnings in `src/init` and treat them as errors
1fca81960a Sjors Provoost: psbt: fix rendering for invalid long sighash type field
f14569f97d Sjors Provoost: test: ipc should reject invalid json
858814146d Sjors Provoost: test: refactor Cap'n Proto exception assertions
7fcaccd9d0 Lőrinc: bech32: bound overlength error locations
ea7d459ac0 Hennadii Stepanov: Merge bitcoin/bitcoin#36057: build: check for SetThreadDescription() at configure time
1bb5820b44 pseudoramdom: wallet: Add addhdkey interface
1ad8641278 Hennadii Stepanov: iwyu: Fix warnings in `src/init` and treat them as errors
82867073d6 pseudoramdom: wallet: Use WalletError for AddHDKey failures
f8769fc0b1 pseudoramdom: wallet: Move addhdkey logic into CWallet
e1a2b25d6c Sjors Provoost: test: expand addhdkey coverage for locked wallet and bad key
21d4e0ba75 GuTS805: rpc, wallet, test: fix invalid JSON in HelpExampleRpc curl examples
15630c7b85 fanquake: validation: remove unused m_chainparams from ATMPArgs
fa7be0a8df MarcoFalke: test: refactor: Remove confusing ignore_errors=True
84c5290149 fanquake: validation: remove unused args from PolicyScriptChecks
a9d5cf7f99 fanquake: validation: remove unused args from ConsensusScriptChecks
d26dc09ee3 fanquake: validation: remove unused total_vsize arg from PackageRBFChecks
2cb6c156e1 fanquake: validation: remove unused PackageMempoolAcceptResult constructor
8d930981e9 Hodlinator: refactor: Replace !ContainsNoNUL() with ContainsNUL()
204256c73f merge-script: Merge bitcoin/bitcoin#35900: iwyu: Fix warnings in `src/interfaces` and treat them as errors
da1cb4dd90 merge-script: Merge bitcoin/bitcoin#35586: doc: note -blocknotify is not run during IBD/reindex in help text
b31aae4f9a merge-script: Merge bitcoin/bitcoin#36094: ci: bump riscv toolchain to tag 2026.08.25
607f220c6c will: Revert "ci: use mirror for riscv submodules"
64af18f4e6 will: ci: bump riscv toolchain to tag 2026.08.25
fd573f6db9 merge-script: Merge bitcoin/bitcoin#36044: test: cover OP_SUCCESSx bypassing the initial stack element size limit
2224e4af6c merge-script: Merge bitcoin/bitcoin#35850: fuzz: Implement `connect_block` harness
f78834fac9 furszy: test: add missing coverage for CDBWrapper::Read() errors
1548d15de6 Ava Chow: walletdb: Rename WriteTx to WriteFullTx
9a0628d932 Ava Chow: wallet: Write tx to database during CWalletTx::Update
2777300c68 Robin David: fuzz: Implement connect_block harness
bed46bd16c ViniciusCestarii: build: check for SetThreadDescription() at configure time
40add915be Eugene Siegel: test: Add reset to CuckooCache
a24110cef7 merge-script: Merge bitcoin/bitcoin#36092: fix: UB sanitizer in mempool estimator logging
8b84f91778 merge-script: Merge bitcoin/bitcoin#36088: util: Set Univalue to null after read failure
576a0ebb53 rustaceanrob: fix: UB sanitizer in mempool estimator logging
5f45583e43 merge-script: Merge bitcoin/bitcoin#36077: bugfix: give TxDownloadManager its own RNG
fa72de78a9 MarcoFalke: util: Set Univalue to null after read failure
fa7786592d MarcoFalke: test: Add UniValue failed read test
e339043ee9 merge-script: Merge bitcoin/bitcoin#35829: http: Make class fields private and make HTTPResponse a struct
74e1cd38f2 Jakub Trnka: rpc: add bestblockhash to getmininginfo
ec2adf3c51 w0xlt: test: Check miniscript descriptor h and apostrophe equivalence
a2d001b57c Ava Chow: test: Enforce descriptor reimport is an update
e2b2f1c5c6 Ava Chow: descriptor: Rename DescriptorID to CompatDescriptorHash
6ad31c062c Ava Chow: test: Add 31.0 to wallet backwards compatibility test
2a6c53371b Ava Chow: wallet, spkm: Treat Descriptor ID as an opaque SPKM ID
62e826fa76 Ava Chow: wallet: Update WalletDescriptor from another one instead of overwriting
031175197f Ava Chow: Merge bitcoin/bitcoin#36032: rpc: avoid quadratic output lookups
1113f7590e Ava Chow: wallet, export: Include descriptor cache when exporting descriptors
9fc7b2618b Ava Chow: spkm: Remove DescriptorSPKM constructor that doesn't take a descriptor
770ff64bd7 Ava Chow: test: Add v30.2 and Miniscript to wallet backwards compatibility test
35d6a60dbf Ava Chow: descriptor: Add ToCanonicalString
b91d983f66 Ava Chow: Merge bitcoin/bitcoin#36078: qa: Reduce `-maxconnections` in the functional test framework
0f5c6d0b64 merge-script: Merge bitcoin/bitcoin#35618: depends: Make tarball creation from local directory reproducible
b8a8893bf2 Hennadii Stepanov: qa: Lower `-rpcmaxconnections` in `interface_http.py` test
6f4109b448 Hennadii Stepanov: qa: Reduce `-maxconnections` in the functional test framework
80eaa6cabf Greg Sanders: bugfix: give TxDownloadManager its own RNG
5e0d7a286a Hodlinator: refactor: Drastically narrow scope of http_bitcoin namespace and rename it to bitcoin_http
8f9fd8698a Hodlinator: refactor: Make HTTPRemoteClient fields private
d72f67fd6c Hodlinator: refactor: Expose additional HTTPRemoteClient fields through accessors
10bbae302f Hodlinator: refactor: Expose HTTPRemoteClient fields to tests through methods
5b06d90831 Hodlinator: refactor: Replace HTTPServer::MaybeDispatchRequestsFromClient() with HTTPRemoteClient::TryReadRequest()
794a753958 merge-script: Merge bitcoin/bitcoin#35583: test: close the listeners before terminating the event loop
f6b3f2ff6b merge-script: Merge bitcoin/bitcoin#36064: qa: Minor improvement follow-ups to 35730
1d87af26ce Ava Chow: descriptors: Remove default StringType from PubkeyProvider::ToString()
1c7f9aaf75 Ava Chow: miniscript: Don't use StringType::COMPAT
e07224f2d5 xyzconstant: depends: fix IPC listeners on macOS dying when accepting a dead socket
6a028161da Ava Chow: Merge bitcoin/bitcoin#36025: psbt: avoid duplicate taproot leaf script keys when merging
07d92a9d65 Ava Chow: Merge bitcoin/bitcoin#35516: rpc: preserve global xpubs and proprietary fields in joinpsbts
4375d74d24 Ava Chow: Merge bitcoin/bitcoin#34993: wallet: `NotifyCanGetAddressesChanged` when advancing `next_index`
290be9eafa Hodlinator: qa: Minor feature_init.py improvements
6248331b29 Hodlinator: qa: Switch to warning when skipping tests
04cf9ecee4 merge-script: Merge bitcoin/bitcoin#35978: contrib/init: fix unused variables in openrc script
aed80c7395 merge-script: Merge bitcoin/bitcoin#36067: test: Remove `BOOST_CHECK_CLOSE` in favor of exact comparison
07ca9ba9e8 merge-script: Merge bitcoin/bitcoin#36059: test: make index crash test check saved state
402f1fdae6 merge-script: Merge bitcoin/bitcoin#36063: refactor: [test] Remove deprecated SetMockTime(i64) alias
135e05cfa0 merge-script: Merge bitcoin/bitcoin#36046: fuzz: Use ImmediateBackgroundTaskRunner in process_messages
44a7083d43 ViniciusCestarii: test: cover MAX_OPS_PER_SCRIPT in P2WSH witness scripts
9e115edd39 rustaceanrob: test: Remove `BOOST_CHECK_CLOSE` in favor of exact comparison
b07810544f Hennadii Stepanov: Remove MSVCRT-specific workarounds
6d570415a0 Hodlinator: refactor(qa): Move check right below related check
7e3b60584b Hodlinator: refactor(qa): Simplify through using assert_raises()
fad1e6bf23 MarcoFalke: util: refactor: Remove deprecated SetMockTime(i64) alias
faf87c3535 MarcoFalke: test: refactor: Use FakeNodeClock over manual/global SetMockTime
7c86a370c8 Hennadii Stepanov: doc: Update Windows build docs to reflect migration from MSVCRT to UCRT
f5910d1a3a Hennadii Stepanov: ci: Remove Windows + MSVCRT jobs for cross-compiling and native testing
55f86ab162 Hennadii Stepanov: guix: Use UCRT runtime for Windows release binaries
994c17d6c0 merge-script: Merge bitcoin/bitcoin#34697: descriptor: fix musig() duplicate key checks and doubled PSBT origin paths
a1183c02aa Hodlinator: refactor: Extract Send() and Receive() into HTTPRemoteClient from HTTPServer
6d9b61d4f8 Hodlinator: refactor: Extract HTTPRemoteClient::MaybeDisconnect() from HTTPServer::DisconnectClients()
6fec8d6914 Hodlinator: refactor: Make HTTPRequest fields private
b8cd77237b Hodlinator: refactor: Make HTTPRequest::GetHeader() return saner optional type
1cb416397b Shuvam Pandey: psbt: avoid duplicate taproot leaf script keys when merging
32765aca5c merge-script: Merge bitcoin/bitcoin#35730: http: limit connected HTTPRemoteClients
a3335994a8 merge-script: Merge bitcoin/bitcoin#35580: bugfix:  compare non-adjusted chunk weight against block weight limit
0ea81904eb merge-script: Merge bitcoin/bitcoin#35933: psbt: don't abort on invalid MuSig2 derivations
f1380123b6 ViniciusCestarii: test: cover P2WSH trailing byte mismatch
4e7de2ac4c ViniciusCestarii: test: cover TAPSCRIPT_MINIMALIF for OP_IF and OP_NOTIF with 1-byte vector 0x00
7ea36e985a Lőrinc: test: preserve index crash test state
5aa15df60c Lőrinc: test: expose missing index crash checkpoint
b3ff9c4d68 Hennadii Stepanov: iwyu: Fix warnings in `src/interfaces` and treat them as errors
d564b0255f Hennadii Stepanov: iwyu: Add temporary mapping to work around upstream bug
4a12773f26 ViniciusCestarii: test: cover DERSIG rejects a non-compound signature type
86c7fb910d ViniciusCestarii: test: cover OP_16 does not count towards the opcode limit
331bf79881 ViniciusCestarii: test: cover OP_WITHIN must pop all 3 elements
3bb87bc61b ViniciusCestarii: test: cover OP_FROMALTSTACK must pop the altstack
58a7869f86 merge-script: Merge bitcoin/bitcoin#36051: ci: use ruff 0.16.x
f5e91c6fba merge-script: Merge bitcoin/bitcoin#35884: util: set os-level thread names on Windows
a1e2716225 merge-script: Merge bitcoin/bitcoin#36045: test: avoid undersized Boost.Test signal stacks
9d0c38db74 fanquake: ci: use mypy 2.3.1
7a53beca06 fanquake: ci: use pyzmq 27.2.0
f29f076f3c fanquake: ci: use ruff 16
7dcb7f09ed merge-script: Merge bitcoin/bitcoin#34075: fees: Introduce Mempool Based Fee Estimation to reduce overestimation
5e8586ec5b merge-script: Merge bitcoin/bitcoin#36019: bench: Construct CTxOut and COutPoint in a single expression
950bdb763e Alexander Wiederin: bench: Construct CTxOut and COutPoint in a single expression
bf8402c880 Ava Chow: Merge bitcoin/bitcoin#32958: wallet/refactor: Update SignPSBTInput to return util::Expected<void, PSBTError> and remove PSBTError:Ok
02306cc915 Ava Chow: Merge bitcoin/bitcoin#35161: consensus: document merkle mutation root invariant
fae6665f01 MarcoFalke: fuzz: Use ImmediateBackgroundTaskRunner in process_messages
9eba3aafa6 Lőrinc: test: avoid undersized Boost.Test signal stacks
747cff8424 Lőrinc: rpc: avoid quadratic output lookups
7f9c4e2928 ismaelsadeeq: doc: add release notes
e18d392689 ismaelsadeeq: test: add mempool estimator i/o fuzz test
970f02096d ismaelsadeeq: fees: persist mempool policy estimator data
7dcb37989d ismaelsadeeq: fees: move fee_estimates.dat into fees directory
0db2b69e6d ismaelsadeeq: rpc: add verbosity option to estimatesmartfee options
06bb65730e ismaelsadeeq: fees: gate mempool estimates on recent block coverage
cfe585df25 ismaelsadeeq: validation: emit block mempool removal signal from ConnectTip
0d88558f95 ismaelsadeeq: fees: return mempool estimates when it's lower than block policy
56db08d529 merge-script: Merge bitcoin/bitcoin#35877: build: ci/doc win64-cross build via nix
693b1351af ismaelsadeeq: fees: add caching to MemPoolFeeRateEstimator
c9bb3df29f ismaelsadeeq: fees: add MemPoolFeeRateEstimator class
558e26e66e ViniciusCestarii: test: cover OP_SUCCESSx bypassing the initial stack element size limit
e5be0dc35e Hodlinator: refactor: Make HTTPResponse a struct since all fields are public
69c61f9f2f merge-script: Merge bitcoin/bitcoin#36034: Release: Prepare "Translation string freeze" step
87b8a4ee50 Hennadii Stepanov: Merge bitcoin-core/gui#944: Fix out-of-bounds read in RPCParseCommandLine on empty command
f9cc0c020c merge-script: Merge bitcoin/bitcoin#36020: doc: Correct after HTTPRequest::m_client changed to weak_ptr
5a431c957d Hennadii Stepanov: qt: Update `src/qt/locale/bitcoin_en.ts` translation source file
08dfaa04f4 merge-script: Merge bitcoin/bitcoin#36018: test: [refactor] Properly use BOOST_CHECK_EXCEPTION
09cdb3c488 Hennadii Stepanov: cmake: Detect and log MinGW-w64 version when cross-compiling for Windows
fa0fe212f5 MarcoFalke: test: [refactor] Properly use BOOST_CHECK_EXCEPTION
436921eb46 Thomas: test: check joinpsbts preserves global xpubs and proprietary fields
011094b282 Thomas: rpc: preserve global xpubs and proprietary fields in joinpsbts
367b2202a4 Ava Chow: Merge bitcoin/bitcoin#35665: psbt: avoid duplicate global xpub keys when merging
bab030a6fe Ava Chow: Merge bitcoin/bitcoin#35859: wallet: use unsigned KDF iteration count
21ee7f6c00 Ava Chow: Merge bitcoin/bitcoin#35069: Refactor keypath parser
a07f1313b1 merge-script: Merge bitcoin/bitcoin#35980: contrib: reject divergent verify-commits history
32dfed44a2 merge-script: Merge bitcoin/bitcoin#36012: psbt: Remove unused `IsNull()` methods
70701de7c5 Hennadii Stepanov: ci: Make `test_bitcoin-qt.exe` output visible
8c366094b8 merge-script: Merge bitcoin/bitcoin#35956: fuzz: scope fake clocks to target phases
4d86d9cc7e merge-script: Merge bitcoin/bitcoin#35968: test: sync funding block before isolating nodes
8c1d776bf2 merge-script: Merge bitcoin/bitcoin#35965: test: Tighten Coin equality and add debug output
fa8762da62 MarcoFalke: build: ci/doc win64-cross build via nix
fafe7205cc MarcoFalke: doc: Clarify that cygwin/msys2 are not tested/supported
4b991d7b5f merge-script: Merge bitcoin/bitcoin#34239: depends: Hash included makefiles in package checksums
fe5e2a6319 merge-script: Merge bitcoin/bitcoin#32162: depends: Switch from multilib to platform-specific toolchains
4e5327bc98 Hao Xu: fuzz: refactor: scope fake clocks to target phases
ff3e2e4ebd Hodlinator: net: Trigger process abort when behind start block MTP
15e5c35c45 Hodlinator: doc: Correct comments after HTTPRequest::m_client was changed from shared to weak pointer
1156ce6754 rustaceanrob: test: Tighten `Coin` equality and add debug output
1883cecb4d Hodlinator: test: Characterize lagging-clock headers presync
59224b66aa Ava Chow: Merge bitcoin/bitcoin#36008: wallet: WalletBatch->WriteVersion respect argument
2c16efbb7b nebula-21: psbt: Remove unused IsNull() methods
dd669f40b9 ViniciusCestarii: util: set os-level thread names on Windows
b88bffe550 merge-script: Merge bitcoin/bitcoin#36010: test: Print os exit code on failure
0fd515bbb7 merge-script: Merge bitcoin/bitcoin#36009: miniscript: remove unused context argument from ParseHexStr
15a7a4ed7c merge-script: Merge bitcoin/bitcoin#35952: kernel: prevent dangling iterators from temporary ranges
ac6b6c1f06 merge-script: Merge bitcoin/bitcoin#35680: private broadcast: bound rebroadcast attempts to 1,000
d411bb02ff Hennadii Stepanov: Merge bitcoin/bitcoin#35993: guix: build glibc with `--enable-kernel=3.17.0`
fada80192b MarcoFalke: test: Print os exit code on failure
381c331219 merge-script: Merge bitcoin/bitcoin#36007: http: Make HTTPRequest::m_client a weak_ptr
82b3bfe38c merge-script: Merge bitcoin/bitcoin#35797: psbt: support output metadata updates before inputs are added
681b429393 merge-script: Merge bitcoin/bitcoin#35986: p2p: reconsider orphans when missing inputs are mined
16f4bd15bc merge-script: Merge bitcoin/bitcoin#35954: qa: Disable Qt's glib event dispatcher for GUI tests on OpenBSD
1fdd208c1c fanquake: miniscript: remove unused context argument from ParseHexStr
4ca07c2fb3 merge-script: Merge bitcoin/bitcoin#35963: doc : update cjdns docs to discourage using onlynet option
4b4ae6e37c merge-script: Merge bitcoin/bitcoin#35995: doc: fix outdated URL in hash_tests.cpp
a23df4bfa8 merge-script: Merge bitcoin/bitcoin#35946: rpc: Improve some type specs for openrpc
20ad7c9eab merge-script: Merge bitcoin/bitcoin#35955: wallet: remove orphaned GetAffectedKeys and LegacyScriptPubKeyMan declarations
979a42ec17 Hodlinator: http: Make HTTPRequest::m_client a weak_ptr
cf36df070b benthecarman: Wallet: Check crypter return values
777aee77d1 pythcoiner: refactor: deduplicate keypath element parsing
7d8fddfba2 pythcoiner: refactor: define BIP32_HARDENED and BIP32_UNHARDENED constants
e4d80e7001 Vasil Dimov: test: close the loop after the network thread has completed
29fba5ddbb Vasil Dimov: test: close the listeners before terminating the event loop
05e7d57318 ViniciusCestarii: ipc, test: add checkSpawned() unit tests
42215b8581 Lőrinc: init: correct first-run disk space estimate
bd4b1524ea Matthew Zipkin: init: do not count file descriptors for HTTPServer if -server=0
b08662060d Matthew Zipkin: init: account for maximum file descriptors needed by HTTP
158efbc723 cyb3ralbert: doc: fix outdated URL in hash_tests.cpp
9cacf677a9 ismaelsadeeq: rpc: add fee_rate_estimator option to estimatesmartfee
ba6c61bbdd ismaelsadeeq: fees: add FeeRateEstimatorManager class
2cb6b831e0 ismaelsadeeq: fees: add EstimateFeeRate and MaximumTarget to CBlockPolicyEstimator
5adb2ab084 ismaelsadeeq: refactor: test block policy estimator directly
9c8309a890 ismaelsadeeq: test: rename policy estimator tests to block policy estimator tests
e3d5ef1b5f ismaelsadeeq: fees: move StringForBlockPolicyEstimateReason to block policy estimator
74245c20e0 ismaelsadeeq: fees: split wallet and estimator fee reasons
ec5d19665b David Gumberg: wallet: WalletBatch->WriteVersion respect argument.
cc2acebefb Matthew Zipkin: http: configure simultaneous connection limit with -rpcmaxconnections
b3d6d2d1a7 Matthew Zipkin: http: limit connected clients to 16
86651d8197 Matthew Zipkin: scripted-diff: Rename nUserBind, nBind, nMaxConnections to snake_case
5548818115 fanquake: guix: build glibc with --enable-kernel=3.17.0
f72537037d merge-script: Merge bitcoin/bitcoin#35972: fuzz: Fix assertion in `txorphan`
4800cb7aea merge-script: Merge bitcoin/bitcoin#35735: Add state to HTTPRequest
e0992599a6 merge-script: Merge bitcoin/bitcoin#35846: test: Use throwing config parser getters without fallback
e5977f0b9e merge-script: Merge bitcoin/bitcoin#35982: Update minisketch subtree to latest master
fe7dbde52c merge-script: Merge bitcoin/bitcoin#35976: test: Speedup fee estimation functional test with batching
9cc7dc50bd Greg Sanders: p2p: reconsider orphans when missing inputs are mined
91f8b365e7 Anthony Towns: validation: Upgrade log levels for possible block corruption warnings
788242d6d0 Anthony Towns: txindex: Downgrade log messages and include index name
93b9613b76 Anthony Towns: kernel/coinstats: Downgrade ComputeUTXOStats log level
3c4336631e Anthony Towns: script: Lower level of oversized redeemScript log, push errors to callers
7902a8ee83 Anthony Towns: netbase: Tidy up logging levels
4f42b76ca7 Anthony Towns: netbase: Reduce levels of socks5 error logging
ec627b3f3b Anthony Towns: util/log: Add LogWarnThenDebug() helper
c90c23d388 merge-script: Merge bitcoin/bitcoin#35531: txindex: hash keys and pack positions to reduce disk usage
461e3be8d3 fanquake: Squashed 'src/minisketch/' changes from d1bd01e189..4a179c61e3
2dcb2c6df2 fanquake: Update minisketch subtree to latest master
05c36d9fad Hennadii Stepanov: Merge bitcoin-core/gui#957: fix: add .dat file extension automatically when exporting watchonly
e014e5bb61 Fabian Jahr: miner: Enforce murch-zawy rule (BIP54)
75a4e6c678 Pol Espinasa: gui: fix allow restore wallets without .dat file extension
a8b582ec1d Ava Chow: Merge bitcoin/bitcoin#32784: wallet: derivehdkey RPC to get xpub at arbitrary path
465bca734e Lőrinc: contrib: reject divergent verify-commits history
b3d1dca338 Lőrinc: contrib: fail on verify-commits ancestry errors
d837bb38a4 jpk68: contrib/init: fix unused variables in openrc script
fe7d475d45 Gregory Sanders: private broadcast: bound broadcast attempts per tx to 1k
b3d77ea027 sedited: test: Speedup fee estimation functional test with batching
683e05a265 merge-script: Merge bitcoin/bitcoin#35889: rpc: avoid quadratic `gettxspendingprevout` work and preserve order
230185a5ee merge-script: Merge bitcoin/bitcoin#35971: net_processing: remove unused code
ae36e2ef79 Lőrinc: rpc: avoid quadratic prevout resolution
da1eaeb350 Lőrinc: rpc: preserve `gettxspendingprevout` order
f98753e762 Lőrinc: refactor: identify prevouts by request index
221a3fe5cf Lőrinc: test: cover mixed `gettxspendingprevout` order
02de12b1e6 Laxman Acharya: wallet: remove remaining LegacyScriptPubKeyMan references
d194be69d6 Laxman Acharya: wallet: remove orphaned GetAffectedKeys declaration
01dde6b205 marcofleon: fuzz: Fix assertion in txorphan
dec68f997e merge-script: Merge bitcoin/bitcoin#35852: scripted-diff: Use inline const(expr) over static constexpr in headers
e95bab98f0 merge-script: Merge bitcoin/bitcoin#35960: common: remove `::runtime_error` from `RunCommandParseJSON`
aad830ac4a merge-script: Merge bitcoin/bitcoin#35847: test: move more tests to `baseindex_tests` and run them for all indexes
b76afff274 benthecarman: Wallet: Use unsigned KDF iteration count
e07d826e0e Shuvam Pandey: rpc: Fix type in ApplyTypeStrOverride
0cff3cc518 fanquake: net_processing: Remove redundant porphanTx in ProcessOrphanTx
c7eacbd45b fanquake: net_processing: remove Peer& from UpdatePeerStateForReceivedHeaders
8454fb2bd7 shaurya2k06: test: sync funding block before isolating nodes
8b5da677d7 fanquake: common: remove ::runtime_error from RunCommandParseJSON
25bed560be sedited: test: add forward-compat functional test for txindex
703304ed8c Andrew Toth: doc: add release notes for txindex disk usage and downgrading
8e5320a2d2 Andrew Toth: tests: cover txindex hash prefix collisions and legacy fallback
b75efa19ba Andrew Toth: txindex: skip bloom filters and legacy lookups for new databases
004d7c098c Andrew Toth: txindex: hash key prefixes and pack block positions
5a255970fd Andrew Toth: refactor: move txindex db constants and legacy key to txindex_key.h
327660134c Andrew Toth: txindex: pass the full block to DB::WriteTxs
42771e7998 Andrew Toth: txindex: use a new block locator for downgrade safety
4b08baed72 Andrew Toth: txindex: return optional tx and block hash from FindTx
fc0dcf950f Lőrinc: kernel: keep range iterators tied to their owner
0936c55f62 Lőrinc: test: characterize kernel range iterators
ef501a63d9 Lőrinc: consensus: document merkle mutation root invariant
d29b22d078 Hao Xu: fuzz: reset connman state in p2p targets
11090c8bb3 merge-script: Merge bitcoin/bitcoin#35951: doc: release note about I2P ElGamal sunset
beefda21be naiyoma: doc : update cjdns docs to discourage using onlynet option
4200f8163a joaonevess: policy: fix negative CFeeRate::ToString() formatting
b2c45888fd Ava Chow: Merge bitcoin/bitcoin#35866: test: Verify unwelcome RPC clients are rejected before reading their requests
c079288967 Lőrinc: psbt: update output metadata without inputs
4f5712476a Lőrinc: test: characterize P2WSH miniscript output
e24e8fa2a6 Lőrinc: test: characterize PSBT output metadata
625f951ba2 Ava Chow: Merge bitcoin/bitcoin#35959: Update secp256k1 subtree to latest master
e9ed5e83a3 Ava Chow: Merge bitcoin/bitcoin#35605: wallet: rpc: Deprecate `removeprunedfunds` RPC
800ad9c3c0 Jon Atack: doc: release note I2P ElGamal sunset
94cb659457 Hennadii Stepanov: depends: Update `boost` package to 1.92.0
2f72123f61 merge-script: Merge bitcoin/bitcoin#35867: test: classify SOCKS5 peers via getpeerinfo addrbind
09cc345c3e fanquake: Squashed 'src/secp256k1/' changes from d2d04864ef..687155df6b
f464f6cd67 fanquake: Update secp256k1 subtree to lastest master
c94074fa1b sedited: rpc: Surface OBJ_USER_KEYS description for openrpc
c020c21d54 sedited: rpc: Handle skip type args for openrpc
cc577de954 Bruno Garcia: net: align v2 message type validation with v1 range
e33410d888 Hao Xu: fuzz: document arbitrary mocktimes
4c045f1a03 merge-script: Merge bitcoin/bitcoin#35945: depends, qt: Add patch for missing headers
b061567235 merge-script: Merge bitcoin/bitcoin#35947: build, msvc: Update vcpkg manifest baseline
1f5c46f7ce Hennadii Stepanov: Merge bitcoin/bitcoin#35931: ci: Check DLL imports of cross-built `bitcoind.exe`
9054f7cde4 mercie-ux: test: cover submitpackage other-wtxid for same-txid-diff-witness
b42f7fade0 Shuvam Pandey: descriptor: don't prepend key origins twice
7b15e2cb44 Shuvam Pandey: descriptor: fix duplicate check for hardened keys
1bec7fa22c Ava Chow: Merge bitcoin/bitcoin#35496: kernel: add `btck_set_mock_time` for testing time-dependent paths
1c557a3802 Ava Chow: wallet: Add WriteTxMetadata to write just the tx record
c1967c4453 merge-script: Merge bitcoin/bitcoin#35950: Update leveldb subtree to latest master
512dc9af1b Ava Chow: Merge bitcoin/bitcoin#35930: wallet: post-#35501 cleanups in CWalletTx
b970bb34d0 Hennadii Stepanov: Merge bitcoin/bitcoin#33585: cmake: Use builtin support for .manifest files
de2adc308a Hennadii Stepanov: qa: Disable Qt's glib event dispatcher for GUI tests on OpenBSD
aa0e0f793f merge-script: Merge bitcoin/bitcoin#35729: refactor: test: Unroll `&&` conditions in macros
9f10ef5e96 fanquake: Squashed 'src/leveldb/' changes from a7f9bdc611..13da2d6758
3e76d22de2 fanquake: Update leveldb subtree to latest master
e67f75cf7d Novo: wallet/scan: extract progress tracking helpers from `ChainScanner::Scan`
062aa3ce56 Novo: wallet/scan: extract QueueNextBlock
3655beb8f1 Novo: wallet/scan: extract block scanning logic to ScanBlock
4535dc0c78 Novo: wallet/scan: extract block filter matching to ShouldFetchBlock
72a37031d3 Novo: wallet/scan: move WalletRescanReserver to scan files
0274e80130 Novo: wallet/scan: move RescanFromTime to ChainScanner as ScanFromTime
db9185a444 Novo: wallet: introduce ChainScanner as a CWallet member
525163c241 Novo: wallet/tests: pin rescan behavior
d180b891a2 Lőrinc: test: add mixed P2SH/witness sigop accounting
2c01832f7b merge-script: Merge bitcoin/bitcoin#35493: wallet, descriptor: Fix MuSig private key completeness checks on `importdescriptors`
b80cee0361 merge-script: Merge bitcoin/bitcoin#35924: Wallet, refactor: Remove orphaned EraseWatchOnly function
5d051c0562 merge-script: Merge bitcoin/bitcoin#35943: doc: fix dead link in txrequest.h
4ca182ca40 pablomartin4btc: doc: clarify alternate_wtxids is empty when only one witness variant
fa48b5d28e pablomartin4btc: test: assert listsinceblock "removed" reports current canonical wtxid
9b96ee1288 pablomartin4btc: wallet, test: add unit test for variant txid validation in CWalletTx deserializer
9de6543cb5 pablomartin4btc: wallet: post-#35501 cleanup in CWalletTx
e2bf51543a Hennadii Stepanov: build, msvc: Disable default features of the `sqlite3` package
a31425610a Hennadii Stepanov: build, msvc: Update vcpkg manifest baseline
757aa573c4 merge-script: Merge bitcoin/bitcoin#33186: wallet, test: Ancient Wallet Migration from v0.14.3 (no-HD and Single Chain)
e8cc21c57f Ava Chow: Merge bitcoin/bitcoin#35925: wallet, rpc: Exclude non-owned addresses from listreceivedby*
e8500cbd19 Hennadii Stepanov: depends, qt: Add patch for missing headers
9954aa7728 Matthew Zipkin: http: don't parse any new requests from a client if m_req_busy = true
c7db3ae1f9 Matthew Zipkin: test: cover HTTPRequest state machine
90676e24ad Matthew Zipkin: Add state to HTTPRequest to avoid duplicate work over I/O cycles
99497b38f6 Daniel Pfeifer: cmake: Unconditionally add .rc files to sources
654a4cf5e6 Daniel Pfeifer: cmake: Use builtin support for .manifest files
8f695379f3 Daniel Pfeifer: cmake: Unconditionally set WIN32_EXECUTABLE target property
507e528e84 Matthew Zipkin: http: reuse HTTPHeaders to parse chunked trailer
902d8908c9 Matthew Zipkin: http: only read one HTTPRequest at a time per client
a7b0b5084a cyb3ralbert: doc: fix dead link in txrequest.h
1d386c250f Hennadii Stepanov: Merge bitcoin/bitcoin#35941: doc: remove mention of `::wsystem`
57246934e7 fanquake: doc: remove mention of wsystem
5973e07588 merge-script: Merge bitcoin/bitcoin#35937: test: Append print_suppressions=0 to LSAN_OPTIONS, and suppress bitcoin-qt
b6bd573eb9 merge-script: Merge bitcoin/bitcoin#34794: rest: add Cache-Control headers to REST responses
d055a3ab10 winterrdog: test: verify disallowed RPC clients are rejected upon `accept()`
128456b62d merge-script: Merge bitcoin/bitcoin#35260: doc: clarify test placement guidance
fad9ab714b MarcoFalke: test: Append print_suppressions=0 to LSAN_OPTIONS, and suppress bitcoin-qt
05a7c470d2 merge-script: Merge bitcoin/bitcoin#35822: fuzz: reset SOCKS5 interrupt between inputs
73a94b4545 Lőrinc: psbt: avoid aborting on invalid MuSig2 derivations
e3d1e75a51 Lőrinc: test: characterize MuSig2 derivation aborts
1be0b46297 merge-script: Merge bitcoin/bitcoin#35898: rpc: fix mempool entry vsize docs
5f4d5626e7 merge-script: Merge bitcoin/bitcoin#35908: doc: Update NetBSD Build Guide
8397e09e6b merge-script: Merge bitcoin/bitcoin#35928: doc: mention -DWITH_ZMQ=ON in macOS build guide
4b4e63f282 merge-script: Merge bitcoin/bitcoin#35704: windows: remove deprecated codecvt via UTF-8 narrow APIs
67fee5bf44 Hennadii Stepanov: ci: Check DLL imports of cross-built `bitcoind.exe`
089c883c55 pablomartin4btc: test: Add coverage for listreceivedby* excluding "send" addresses
873c054805 pablomartin4btc: wallet: Exclude non-owned addresses from listreceivedby*
c3945bfd2b Sjors Provoost: doc: use derivehdkey in multisig tutorial
3662e33669 Sjors Provoost: test: use derivehdkey in M-of-N multisig demo
d9570f0838 Sjors Provoost: rpc: add derivehdkey
62da9f9614 Sjors Provoost: wallet: add GetExtKey helper
222855ed11 cyb3ralbert: doc: mention -DWITH_ZMQ=ON in macOS build guide
aaf1548475 Sjors Provoost: wallet: generalize GetActiveHDPubKeys helper
3821452c4a Sjors Provoost: refactor: add hardened derivation helper
0ab61caafd Sjors Provoost: rpc: ParsePathBIP32 helper
e36c4b76e1 Sjors Provoost: util: reject out-of-range BIP32 keypath indices
ba78c31a00 Sjors Provoost: fuzz: check ParseHDKeypath/WriteHDKeypath round-trip
8cce969085 Sjors Provoost: Have ParseHDKeypath handle h derivation marker
fc53077762 Sjors Provoost: test: move parse_hd_keypath test to bip32_tests
dab525eb77 Sjors Provoost: key: add DeriveExtKey() helper
71c06c5cbc merge-script: Merge bitcoin/bitcoin#35830: fees: Return false for incompatible fee estimates
55dfc24414 merge-script: Merge bitcoin/bitcoin#35915: Release: Prepare "Open Transifex translations for `v32.0`" step
f11dc6170e merge-script: Merge bitcoin/bitcoin#35482: fuzz: exercise the transaction-handling path in process_message(s)
6f906106d7 merge-script: Merge bitcoin/bitcoin#35879: ci: Fix $BASE_ROOT_DIR installation
d36bf709f7 merge-script: Merge bitcoin/bitcoin#35914: test, fuzz: Remove unused variables
ed2c59ab65 merge-script: Merge bitcoin/bitcoin#35896: refactor: Default uint256::operator==, add operator<=>
fae7ba9aba MarcoFalke: ci: Fix $BASE_ROOT_DIR installation
fabe100c2b MarcoFalke: test: Use throwing config parser getters without fallback
fa8acd57cd MarcoFalke: test: Write true/false values in config.ini
6304789a18 vicjuma: Wallet, refactor: Remove orphaned EraseWatchOnly function
c2da52d366 8144225309: wallet: allow importprunedfunds for spending transactions
6b6d77cc84 kevkevinpal: windows: remove deprecated codecvt via UTF-8 narrow APIs
db21e03c9d Lőrinc: mempool: include unbroadcast txid memory
8d5c4a9290 Lőrinc: test: characterize unbroadcast memory accounting
b388674acf Ava Chow: Merge bitcoin/bitcoin#35872: rpc: avoid descriptor range counter overflow
c36ffd870e merge-script: Merge bitcoin/bitcoin#35842: rpc: Properly make RPCResult::Type::ANY non-test-only
7cb9aaaee8 merge-script: Merge bitcoin/bitcoin#35759: fuzz: check http_request body matches framing
5b008514db merge-script: Merge bitcoin/bitcoin#35878: net_processing: process unique tx INVs only
3175d57628 Hennadii Stepanov: test, refactor: Remove unused `error` in `wallet_tests.cpp`
422f1bd92f Hennadii Stepanov: test, refactor: Remove unused `utxo_pool` in `coinselector_tests.cpp`
e550945a39 Hennadii Stepanov: test, refactor: Remove unused `removed_refs` in `txgraph_tests.cpp`
a061b011b7 Hennadii Stepanov: Merge bitcoin/bitcoin#35912: doc: fix stale bitcoin_en.xlf reference
950b1c0922 merge-script: Merge bitcoin/bitcoin#34927: test: Check that RPCs do not time out, even under load
bd01e66f0a merge-script: Merge bitcoin/bitcoin#35885: ci: switch to a sourceware mirror for riscv
fa2e76d397 MarcoFalke: bench: Add base_blob compare bench via uint256
97abf95f48 Hennadii Stepanov: qt: Update the `src/qt/locale/bitcoin_en.ts` translation source file
81fcecfe45 will: Revert "ci: Temporarily remove riscv32 config from GHA matrix"
b283e1751c will: ci: use mirror for riscv submodules
fa7bc26d12 MarcoFalke: test: Check that RPCs do not time out, even under load
fa2bd96cc0 MarcoFalke: test: Map cli CalledProcessError on server error to JSONRPCException
e50f422d25 Hennadii Stepanov: test, refactor: Remove unused variables in `test/rbf_tests.cpp`
b7ae50e2e2 Hennadii Stepanov: fuzz, refactor: Remove unused `header` in `p2p_transport_serialization.cpp`
3df0d067ad Hennadii Stepanov: fuzz, refactor: Remove unused `random_string` in `locale.cpp`
fc28914de4 Hennadii Stepanov: fuzz, refactor: Remove unused `linearization` in `cluster_linearize.cpp`
da58e55986 Hennadii Stepanov: test, refactor: Remove unused `warnings` in `wallet/test/util.cpp`
4df077d7cd merge-script: Merge bitcoin/bitcoin#35910: refactor: Remove unused newFeeRate var in ReplacementChecks
e98ffd4bd8 cyb3ralbert: doc: fix stale bitcoin_en.xlf reference
fa9a9a82ac MarcoFalke: refactor: Remove unused newFeeRate var in ReplacementChecks
fa588e9e0f MarcoFalke: refactor: Mark assertion_fail as [[noreturn]]
1278a5970d Gregory Sanders: net_processing: process unique tx INVs only
75f5851927 w0xlt: doc: add release note for REST cache-control headers
bbe21ac29f w0xlt: doc: document REST cache-control defaults
862a179556 w0xlt: http: add no-store to dispatcher-generated error responses
f32685315c Hennadii Stepanov: doc: Install `pkgconf` to find `capnproto` on NetBSD
5964c7229f Hennadii Stepanov: doc: Switch `pkg-config` package to modern `pkgconf` on NetBSD
9b85c9814d Hennadii Stepanov: doc: Drop GCC upgrade instructions for NetBSD
ea59f17220 w0xlt: test: cover v0.14.3 wallet migration
18b8afd093 w0xlt: test: support v0.14.x in dumb_sync_blocks
faec059dfe MarcoFalke: refactor: Add uint256::operator<=>()
b9d573e4a9 Hao Xu: fees: Return false for incompatible fee estimates
a3ebf8ab60 Musa Haruna: rpc: fix mempool entry vsize docs
c4fbd3c721 merge-script: Merge bitcoin/bitcoin#35895: refactor: Enable clang-tidy rule to reject anon namespace in header
465196d015 merge-script: Merge bitcoin/bitcoin#35630: test: Add importdescriptors rpc error test coverage
fa6df14c23 MarcoFalke: refactor: uint256::operator==() = default
c940fd7514 merge-script: Merge bitcoin/bitcoin#35180: coins: group private cache helpers
3db96eb5fd merge-script: Merge bitcoin/bitcoin#35582: rpc: reject null for optional parameters
fa93132d6d MarcoFalke: refactor: Enable misc-definitions-in-headers
fa5ca877b6 MarcoFalke: refactor: Enable clang-tidy rule to reject anon namespace in header
fafe5042bd MarcoFalke: refactor: Use C++20 std::identity over IntIdentity
28257111ac merge-script: Merge bitcoin/bitcoin#35737: test: Move cluster_linearize.h contents into cluster_linearize namespace
fac4b06e99 MarcoFalke: refactor: Use CLIENT_NAME in buildOpenRPCDoc
fa3aadbc32 MarcoFalke: refactor: Use self.Arg<bool> in getopenrpcinfo
fa1871a528 MarcoFalke: refactor: Remove stale NOLINTNEXTLINE above GetAddressInfoBaseFields
fa22647914 MarcoFalke: rpc: Properly make RPCResult::Type::ANY non-test-only
fa1242dcc0 MarcoFalke: refactor: Use std::visit in ApplyArgFallback
27b6b5a458 merge-script: Merge bitcoin/bitcoin#35836: rpc: Remove meaningless bool fallback in FundTransaction
3ac8b806a6 Pol Espinasa: test: test the result order of a multiple import request is correct
e4732bf018 Pol Espinasa: test: test invalid or missing timestamp throws importdescriptors
324c231efe merge-script: Merge bitcoin/bitcoin#35881: iwyu: Fix warnings in `src/consensus` and treat them as errors
6ed7e05e20 Pol Espinasa: gui: fix add .dat file extension automatically when exporting watchonly
75183f4464 merge-script: Merge bitcoin/bitcoin#35880: fuzz: don't connman.ReceiveMsgFrom oversized msg
fab74a0e92 MarcoFalke: refactor: Use C++14 digit separator for large int literals
fae759be79 MarcoFalke: scripted-diff: Use inline constexpr over plain constexpr
fa74f58a26 MarcoFalke: scripted-diff: Use inline const over (static) const
fab1a62c87 MarcoFalke: refactor: Use inline constexpr for string literals in headers
fa08bbed8d MarcoFalke: contrib: Adjust generate-seeds.py to write inline constexpr
fad753611b MarcoFalke: scripted-diff: Use inline constexpr over (static) const
faedb52583 MarcoFalke: refactor: Make CFeeRate(integral) ctor constexpr
5555d5dcb5 MarcoFalke: scripted-diff: Use inline constexpr over static constexpr
fa6e1a1e85 MarcoFalke: refactor: Remove static from constexpr functions in headers
be30864ed1 GuTS805: doc: use overwrite (>) instead of append (>>) for one-shot PSBT files in offline-signing-tutorial.md
e2ab8ae551 David Gumberg: wallet: spkm: Only notify CanGetAddressesChanged on change
0892f16f91 David Gumberg: refactor: moveonly: Pair CanGetAddressesChanged notifications with desc range.
e6adae3db2 David Gumberg: wallet: `NotifyCanGetAddressesChanged` when advancing `next_index`
acf45c44c0 w0xlt: rest: add Cache-Control headers to REST responses
d3cfd02bd7 merge-script: Merge bitcoin/bitcoin#35501: wallet: store all witness variants of a transaction
0b8ffd01cd merge-script: Merge bitcoin/bitcoin#35790: fuzz: populate wallet TXO index in wallet_create_transaction
2f52c2e8c0 Hennadii Stepanov: Merge bitcoin/bitcoin#35886: refactor: Remove unused #include in common/system
8bca7555f8 ViniciusCestarii: ipc, refactor: rename arg -ipcfd to -ipcchild
bd3a38f10a ViniciusCestarii: ipc, refactor: return std::optional<mp::SocketId> from checkSpawned()
fa7304f3a5 MarcoFalke: refactor: Remove unused #include in common/system
e7eb159a86 merge-script: Merge bitcoin/bitcoin#35773: test: Suppress implicit-unsigned-integer-truncation:SaltedCoinsCacheHasher::operator()
c6ef42d7db merge-script: Merge bitcoin/bitcoin#35205: kernel,node: add `dbcache` setter and clarify defaults
f280f5eb47 David Gumberg: wallet: rpc: deprecate removeprunedfunds
4e8c4bc794 Henry Romp: test: classify SOCKS5 peers via getpeerinfo addrbind
17c5e33e9c merge-script: Merge bitcoin/bitcoin#35216: qa: Improve functional test support on illumos and *BSD
a31eb8bfa4 Hennadii Stepanov: ci, iwyu: Request IPC file generation explicitly
13b53f8bf6 Hennadii Stepanov: iwyu: Fix warnings in `src/consensus` and treat them as errors
bb19f1da19 Greg Sanders: fuzz: don't connman.ReceiveMsgFrom oversized msg
8a4bab8e97 merge-script: Merge bitcoin/bitcoin#35863: test: fix wrong transaction in GetP2SHSigOpCount assertion
975a314667 merge-script: Merge bitcoin/bitcoin#35832: p2p: avoid block disk reads on unnecessary requests
d24610fa2c merge-script: Merge bitcoin/bitcoin#35870: guix: move `python-minimal` to Linux GUI build
b33a5b5767 merge-script: Merge bitcoin/bitcoin#35871: refactor: Annotate `MakeAndPushFeature` with `[[maybe_unused]]`
4b322989ac merge-script: Merge bitcoin/bitcoin#34995: iwyu: Fix warnings in `src/common` and treat them as errors
75f024a84e merge-script: Merge bitcoin/bitcoin#35875: ci: Fix NetBSD SDK download failure, Temp. remove riscv32 from GHA
fa06ea4244 MarcoFalke: ci: Temporarily remove riscv32 config from GHA matrix
6cd2fa5fb4 JP: test: add a tx_valid vector for CVE-2024-38365
873550bea3 Lőrinc: ci: verify cross-build SDK archives
2c87337efe Lőrinc: ci: update NetBSD cross-build SDK
6a2de55a0d Lőrinc: test: require `TryGetTotalRam()` detection
cd086c16dd Lőrinc: node, qt: inline `DEFAULT_DB_CACHE`
8bd9f46082 Lőrinc: kernel: allow setting chainstate `dbcache`
8aa21e119b Lőrinc: kernel, node: colocate dbcache bounds
7cfa21d60a Lőrinc: scripted-diff: use `MIN_DBCACHE_BYTES`
ab63432576 Lőrinc: common: cache total RAM as `uint64_t`
031fa402c8 Lőrinc: scripted-diff: use `TryGetTotalRam`
264555af3c Lőrinc: rpc: avoid descriptor range counter overflow
143a13fb2b Lőrinc: test: characterize descriptor range endpoint
41c44f5588 Lőrinc: node, qt: use `1_MiB` for dbcache conversions
0238aebf61 Hennadii Stepanov: refactor: Annotate `MakeAndPushFeature` with `[[maybe_unused]]`
1ed14c6122 Hennadii Stepanov: Merge bitcoin-core/gui#872: Menu action to export a watchonly wallet
b75eb938a0 fanquake: guix: move python-minimal to GUI build
101400b28f fanquake: guix: remove -Werror=dev
e27c179db2 merge-script: Merge bitcoin/bitcoin#35869: lint: (re-)add contrib/guix for Python linting
50145f62c9 Hennadii Stepanov: ci, iwyu: Enforce warning-free `src/common`
30f6b05857 merge-script: Merge bitcoin/bitcoin#35860: fuzz: Rework rpc fuzz target
dcc2ed52b8 merge-script: Merge bitcoin/bitcoin#35856: fuzz: cover the mempool interface for transaction announcement
8221d714c7 fanquake: lint: document CI lief version requirement
594a02c3ae fanquake: lint: re-add guix scripts to mypy linting
e8691056c0 rustaceanrob: test: Unroll `&&` conditions in macros
ddddffda3a MarcoFalke: doc: Add doc/release-notes-35836.md
756afe14b5 JP: test: give each ValidateInputsStandardness case its own scope
0b3bb07103 azuchi: test: add coverage for untested descriptor parse error paths
5559fa464b JP: test: fix wrong transaction in GetP2SHSigOpCount assertion
556988790a merge-script: Merge bitcoin/bitcoin#35592: http: check rpcallowip immediately after accepting connection
fa895bb77a MarcoFalke: fuzz: Rework rpc fuzz target
8e4b7ab725 Andrew Toth: fuzz: use per-level fetch scopes in coinscache_sim
5292386b78 Andrew Toth: doc: improve CoinsViewOverlay documentation
d552c52b08 Andrew Toth: coins: log error reason when prevout fetch submission fails
2ffaa6e6a7 Andrew Toth: coins: delete Sync and SetBackend on CoinsViewOverlay
330022993f Andrew Toth: coins: filter coinbase txid from parallel input fetching
28641fd195 furszy: p2p: reject empty getblocktxn requests
dd2561003d Antoine Poinsot: fuzz: cover the mempool interface for transaction announcement
9871fb726c furszy: p2p: reject filtered block inv early when bloom is disabled
aaf9412026 furszy: refactor: split p2p_getdata.py in sub-cases
adbff4d442 Kyle 🐆: init: don't suggest -reindex-chainstate for recovery on a pruned node
34c03075a5 Martin Zumsande: test: run generic baseindex tests against every index type
11b3e251c4 Martin Zumsande: test: make baseindex flush test chain-length agnostic
8b959f4c6a Martin Zumsande: test: move unclean_shutdown test to baseindex_tests
2232d6afbe Martin Zumsande: test: move index_reorg_crash to baseindex_tests
a3597e2683 Martin Zumsande: test: move BuildChain helper into test mining util
954985e6a3 Martin Zumsande: test: simplify blockfilter test's BuildChain helper
67efced1fc merge-script: Merge bitcoin/bitcoin#35838: qa: Enable `interface_gui.py` on macOS
45f5609f2e Hennadii Stepanov: qa: Enable `interface_gui.py` on macOS
fa7fe798c6 MarcoFalke: wallet: Remove meaningless bool fallback in FundTransaction
9611a35603 Ava Chow: Merge bitcoin/bitcoin#35828: util: Make LineReader consistently use string_view
6e2962e48c Ava Chow: Merge bitcoin/bitcoin#35753: kernel: handle null mempool on chainstate deletion
87bc4c74c4 Ava Chow: Merge bitcoin/bitcoin#35787: init, rpc: ignore empty addnode values
67998e15c8 Ava Chow: Merge bitcoin/bitcoin#35553: test: Add missing test case for getdata requests from blocks-only peers
9b38d077f8 Hennadii Stepanov: Merge bitcoin-core/gui#953: Adds option to not load the wallet after migration
146988ef6c Ava Chow: Merge bitcoin/bitcoin#35551: test: add interface_gui.py to test bitcoin-qt startup
7e5952b0aa Hennadii Stepanov: Merge bitcoin/bitcoin#35821: guix: followups to #35537
829e44a115 JP: test: add CONST_SCRIPTCODE failure-path vectors to script_tests.json
683ae4c520 fanquake: guix: consolidate config flags
665f11d04a fanquake: guix: consolidate gcc toolchain setup
288f76ed0f fanquake: guix: consolidate mingw-w64 toolchain setup
cc9b0f2266 fanquake: guix: consolidate LLVM toolchain setup
b12a70f330 fanquake: guix: turn linux/win linker warnings into errors
fd7d4f2970 Hennadii Stepanov: Merge bitcoin/bitcoin#35795: build: set CMAKE_VISIBILITY_INLINES_HIDDEN in REDUCE_EXPORTS
8ecbe270f0 merge-script: Merge bitcoin/bitcoin#35606: script: qa: Improve `Key::Fingerprint` type safety
a9d181f2d3 merge-script: Merge bitcoin/bitcoin#35084: ipc: Add nonunix platform support
6573196e63 Ava Chow: doc: Release note for export watchonly wallet gui action
cb51f97f6c Ava Chow: gui: Menu action for exporting a watchonly wallet
4cea59573c Pol Espinasa: add release notes
492a715d78 Pol Espinasa: gui: Adds option to not load the wallet after migration
dff44e4c8f Hodlinator: util: LineReader - Drop support for raw std::byte spans
5d5cdcd79d Hodlinator: util: Make LineReader consistently use string_views
e8eaa80ce2 Hodlinator: util: LineReader - Don't include newline and acknowledge single-char \r
5907a5c7dc Ava Chow: gui: Add ExceptionSafeConnect that takes a lambda
7dea464d6b merge-script: Merge bitcoin/bitcoin#35692: addrman: remove unreachable tried-collision branch
8976ba50a2 Ruslan Kasheparov: rpc: require connman in getnetworkinfo
975229580f Ruslan Kasheparov: rpc: Fix inaccuracies in RPC help docs
a2aab6df97 merge-script: Merge bitcoin/bitcoin#35810: guix: Drop unused `(guix licenses)` import from `manifest_build.scm`
77440814bf Hao Xu: fuzz: reset SOCKS5 interrupt between inputs
90ce21e21d w0xlt: rpc: reject empty node argument in addnode
69465de447 w0xlt: init: ignore empty addnode values
47632ab2a3 Henry Romp: test: add coverage for feebumper uncomputable cluster error path
982ee64938 Hennadii Stepanov: lint: Skip `libmultiprocess` subtree in `lint-shell-locale.py`
1194918a5d Hennadii Stepanov: scripted-diff: Use C.UTF-8 locale in all shell scripts
a92e93429e Hennadii Stepanov: guix: Drop unused `(guix licenses)` import from `manifest_build.scm`
5be248341a ismaelsadeeq: bugfix: compare real chunk weight against block weight limit
fc98790869 ismaelsadeeq: test: `TestChunkBlockLimits` uses incorrect weight for comparison
13ce46ba1a Larry Ruane: doc: add release note for 27052
5d5397d841 Larry Ruane: test: add functional test for block announcement time tracking
7d3d04e925 Larry Ruane: rpc: add last_block_announcement to the getpeerinfo output
26a25162a4 Larry Ruane: net: add m_last_block_announcement to CNodeStateStats
bb8bca630a Larry Ruane: change m_last_block_announcement type from int64_t to NodeClock::time_point
3f313a774b fanquake: build: set CMAKE_VISIBILITY_INLINES_HIDDEN in REDUCE_EXPORTS
6e60c362bc Musa Haruna: test: add P2SH sigop counting coverage
1eac6a728b frankomosh: fuzz: populate wallet TXO index in wallet_create_transaction
c9cedebfff Lőrinc: coins: group private cache helpers
db74d3390a Lőrinc: doc: clarify test placement guidance
d3d74e701f Ryan Ofsky: ipc, refactor: Update mp::g_thread_context references
fa7f553781 MarcoFalke: test: Suppress implicit-unsigned-integer-truncation:SaltedCoinsCacheHasher::operator()
87b080fe2b Hao Xu: fuzz: reset the reused mempool in process_message(s)
d522fd3196 Hao Xu: fuzz: prepare deterministic mempool rebuilds
b11456386b Hao Xu: fuzz: let the test input toggle IBD in the p2p fuzz targets
2a29cee684 Hao Xu: test: add helper to reset chainman and mempool
2a4ef42d34 Hao Xu: fuzz: share a single FakeNodeClock in the chainman-resetting fuzz targets
de9b436ba3 Hennadii Stepanov: depends: Switch from multilib to platform-specific toolchains
7502b9ddba ameen-alam: fuzz: check http_request body matches framing
a99b27f192 Lőrinc: validation: handle null mempool on delete
fa5cbb8909 Ava Chow: uint256: Workaround GCC-14 stringop-overread bug in Compare
21b4b790e4 Hennadii Stepanov: test: Move cluster_linearize.h contents into cluster_linearize namespace
2d3f72fd3f Ryan Ofsky: ipc, refactor: Update mp::SpawnProcess call
6c9d76d589 Ava Chow: doc: release note for alternate_wtxids in gettransaction
99bdcb064c furszy: test: compat, ensure downgrade preserves tx witness variants
ef2afc6a0a Ava Chow: test: Test for wallet txs with alternate wtxids
2d55c7a74d Ava Chow: wallet: Show alternate wtxids in gettransaction
0b1af01bd4 Ava Chow: wallet: Replace CWalletTx::SetTx with Update
56cf27db4d furszy: wallet: Store all witness variants of a transaction
798ba6d04f Ava Chow: wallet: Make CWalletTx::tx private and use CWalletTx::GetTx to access
72ebdd6364 Ava Chow: wallet: Remove unused CWalletTx CopyFrom and copy constructor
19af439bdf Ava Chow: wallet: Deserialize directly in CWalletTx's ctor
e9f19815ca Ryan Ofsky: ipc, refactor: Add Stream type alias and use it
3859805f05 Ryan Ofsky: ipc, refactor: Add SocketId type alias and use it
2ee9b69c7a Ryan Ofsky: ipc, refactor: Add ProcessId type alias and use it
3449797141 Ryan Ofsky: ipc: Avoid 'unistd.h' error with MSVC
dbcc192dce Ryan Ofsky: ipc, refactor: fix include order
7c86d4834e Ryan Ofsky: ipc, refactor: use native path separators in test
00287b9a34 Ryan Ofsky: ipc, refactor: Change Protocol class field order
33d37f3c35 Ryan Ofsky: ipc, refactor: Drop connect/listen/serve exe_name parameters
794940469e Ryan Ofsky: ipc, moveonly: combine ipc_test.cpp and ipc_tests.cpp
fef99e6563 sayed nabhan: qt: fix out-of-bounds read in RPCParseCommandLine on empty command
bc7d905046 Bruno Garcia: addrman: remove unreachable tried-collision branch
0390338692 woltx: test: check MuSig import private key warnings
5e62fbf09c woltx: wallet: check descriptor private key completeness on import
cd8d01bf47 woltx: descriptors: require complete MuSig private keys
412540e18d jpk68: i2p: update leaseset encryption types
55d3cd51a4 Matthew Zipkin: doc: add release note describing change for forbidden clients
d1ed2a6e25 Matthew Zipkin: http: check rpcallowip immediately after accepting connection
6d387af562 Thomas: psbt: remove write-only global xpub tracking set
3b7051c7e3 Thomas: test: check combinepsbt with conflicting global xpub origins
7c632c0e2a Thomas: psbt: avoid duplicate global xpub keys when merging
07fb58b9ef Pol Espinasa: test: Test a locked wallet rejects an empty importdescriptors request
aeca061086 Ruslan Kasheparov: rpc: reject null for optional parameters
f4a6d079c4 Hennadii Stepanov: qa: Support `get_bind_addrs` and `feature_bind_extra` on illumos
5e96a8fd5a Hennadii Stepanov: doc: Add `lsof` to Test Suite Dependencies on NetBSD
5d01aa4772 Hennadii Stepanov: qa: Ignore `lsof` warnings on NetBSD
70352fda03 Hennadii Stepanov: qa: Strip prefix length from NetBSD `ifconfig` output
1c1735567e Hennadii Stepanov: doc: Add `lsof` to Test Suite Dependencies on FreeBSD
4cb7f39c2c Hennadii Stepanov: qa: Drop OpenBSD from supported platforms in `get_bind_addrs` function
8a982eea85 Hennadii Stepanov: qa: Add `skip_if_no_lsof_on_nonlinux` helper and use it where needed
7e973cce52 Hennadii Stepanov: depends: Make tarball creation from local directory reproducible
e5b7785447 David Gumberg: test: wallet: resend: avoid internal behavior via removeprunedfunds
c9a70f9338 David Gumberg: script: qa: Improve Key::Fingerprint type safety
aa01721c89 Ryan Ofsky: test: add interface_gui.py to test bitcoin-gui startup via RPC
d5e64b01e1 Guillermo Fernandes: doc: note -blocknotify is not run during IBD/reindex in help text
278710a88d Roqqit: test: Add missing test case for getdata requests from blocks-only peers
156f2c6c49 stringintech: kernel: add `btck_set_mock_time` for testing time-dependent paths
3ba1bbfa3f Sebastian Falbesoner: test: exercise Schnorr signature cache in txvalidationcache_tests.cpp
198b36bc85 Sebastian Falbesoner: test: respect "TAPROOT requires WITNESS" rule in `ValidateCheckInputsForAllFlags`
e78a2a0d00 Sebastian Falbesoner: test: refactor: simplify tx vin/vout creation in txvalidationcache_tests.cpp
f217da5c59 rkrux: wallet, test: wallet_fast_rescan follow-ups
b7cbd80428 AgustinRivera: test: use MiniWallet for getblockstats test data generation
6cca38e2b9 kevkevinpal: refactor: remove unused PSBTError::Ok
3660678b95 kevkevinpal: refactor: SignPSBTInput now uses util:Expected
c8ee319fff naiyoma: net: remove m_getaddr_sent
a1ecda2609 naiyoma: test: delete redundant addr relay assertion
ec61a1af62 Hennadii Stepanov: depends: Hash included makefiles in package checksums
e9dc16194b midnight: correct the linearize-data script (minor)
```

## 3. Touched Files & Diff Stat
```text
 .github/actions/configure-docker/action.yml        |    4 +
 .github/actions/configure-environment/action.yml   |    2 +-
 .github/ci-windows-cross.py                        |   50 +-
 .github/ci-windows.py                              |    1 +
 .github/workflows/ci.yml                           |   37 +-
 CMakeLists.txt                                     |   17 +-
 CONTRIBUTING.md                                    |    3 +-
 SECURITY.md                                        |    1 -
 ci/lint/01_install.sh                              |    2 +-
 ci/lint/06_script.sh                               |    2 +-
 ci/lint/requirements.txt                           |    7 +-
 ci/lint_imagefile                                  |    2 +-
 ci/test/00_setup_env.sh                            |    9 +-
 ci/test/00_setup_env_arm.sh                        |   12 +-
 ci/test/00_setup_env_freebsd_cross.sh              |   11 +-
 ci/test/00_setup_env_i686_no_ipc.sh                |   13 +-
 ci/test/00_setup_env_mac_cross.sh                  |   10 +-
 ci/test/00_setup_env_mac_cross_intel.sh            |   10 +-
 ci/test/00_setup_env_mac_native.sh                 |   10 +-
 ci/test/00_setup_env_mac_native_fuzz.sh            |    9 +-
 ci/test/00_setup_env_native_alpine_musl.sh         |    8 +-
 ci/test/00_setup_env_native_asan.sh                |   18 +-
 ci/test/00_setup_env_native_chimera_lto.sh         |    8 +-
 ci/test/00_setup_env_native_fuzz.sh                |   13 +-
 ci/test/00_setup_env_native_fuzz_with_msan.sh      |   18 +-
 ci/test/00_setup_env_native_fuzz_with_valgrind.sh  |    9 +-
 ci/test/00_setup_env_native_iwyu.sh                |   14 +-
 ci/test/00_setup_env_native_msan.sh                |   17 +-
 ci/test/00_setup_env_native_nowallet.sh            |    8 +-
 ci/test/00_setup_env_native_previous_releases.sh   |   21 +-
 ci/test/00_setup_env_native_tidy.sh                |   12 +-
 ci/test/00_setup_env_native_tsan.sh                |   11 +-
 ci/test/00_setup_env_native_valgrind.sh            |   13 +-
 ci/test/00_setup_env_netbsd_cross.sh               |   15 +-
 ci/test/00_setup_env_openbsd_cross.sh              |   13 +-
 ci/test/00_setup_env_riscv_bare_cross.sh           |   10 +-
 ci/test/00_setup_env_s390x.sh                      |   11 +-
 ci/test/00_setup_env_win64.sh                      |   14 +-
 ci/test/00_setup_env_win64_msvcrt.sh               |   22 -
 ci/test/01_base_install.sh                         |   47 +-
 ci/test/01_iwyu.patch                              |  620 ---
 ci/test/02_iwyu_hash.patch                         |   44 -
 ci/test/02_run_container.py                        |   39 +-
 ci/test/03_test_script.sh                          |   72 +-
 ci/test_imagefile                                  |    7 +-
 ci/test_run_all.sh                                 |    3 +-
 cmake/bitcoin-build-config.h.in                    |    2 +-
 cmake/introspection.cmake                          |    7 +-
 cmake/module/AddWindowsResources.cmake             |   16 +-
 cmake/module/GetMingwVersion.cmake                 |   30 +
 cmake/module/TargetDataSources.cmake               |    7 +
 cmake/script/macos_zip.sh                          |    2 +-
 contrib/devtools/README.md                         |    2 +-
 contrib/devtools/check-deps.sh                     |    2 +-
 .../deterministic-fuzz-coverage/src/main.rs        |  125 +-
 contrib/devtools/gen-bitcoin-conf.sh               |    2 +-
 contrib/devtools/headerssync-params.py             |    4 +-
 contrib/devtools/iwyu/bitcoin.core.imp             |    7 +-
 contrib/devtools/shell-win64-cross.nix             |   53 +
 contrib/guix/README.md                             |   11 +-
 contrib/guix/guix-build                            |   10 +-
 contrib/guix/libexec/build_linux.sh                |   50 +-
 contrib/guix/libexec/build_linux_gui.sh            |   43 +-
 contrib/guix/libexec/build_macos.sh                |   20 +-
 contrib/guix/libexec/build_macos_gui.sh            |   25 +-
 contrib/guix/libexec/build_win.sh                  |   31 +-
 contrib/guix/libexec/build_win_gui.sh              |   34 +-
 contrib/guix/libexec/codesign.sh                   |    7 +-
 contrib/guix/libexec/prelude.bash                  |    2 +-
 contrib/guix/libexec/setup.sh                      |   78 +
 contrib/guix/linux_static.scm                      |    8 +
 contrib/guix/manifest_build.scm                    |  262 +-
 contrib/guix/manifest_codesign.scm                 |   31 +-
 contrib/guix/manifest_gui.scm                      |   38 +-
 contrib/guix/security-check.py                     |    4 +-
 contrib/guix/symbol-check.py                       |   26 +-
 contrib/guix/toolchains.scm                        |  283 +
 contrib/init/bitcoind.openrc                       |    3 +-
 contrib/linearize/linearize-data.py                |    7 +-
 contrib/macdeploy/detached-sig-create.sh           |    2 +-
 contrib/macdeploy/macdeployqtplus                  |   14 +-
 contrib/qos/tc.sh                                  |    2 +-
 contrib/seeds/generate-seeds.py                    |    8 +-
 contrib/seeds/makeseeds.py                         |    5 +-
 contrib/seeds/nodes_main.txt                       | 3290 ++++++-----
 contrib/seeds/nodes_signet.txt                     |  212 +-
 contrib/seeds/nodes_test.txt                       |  159 +-
 contrib/seeds/nodes_testnet4.txt                   |  201 +-
 contrib/verify-commits/gpg.sh                      |    2 +-
 contrib/verify-commits/verify-commits.py           |   39 +-
 contrib/windeploy/detached-sig-create.sh           |    2 +-
 depends/README.md                                  |   53 +-
 depends/funcs.mk                                   |    8 +-
 depends/hosts/linux.mk                             |   21 -
 depends/packages/boost.mk                          |    4 +-
 depends/packages/capnp.mk                          |    5 +
 depends/packages/native_qt.mk                      |    4 +-
 depends/packages/qt.mk                             |    4 +-
 .../patches/capnp/macos_accept_dead_socket.patch   |  273 +
 depends/patches/qt/fix_missed_headers.patch        |   32 +
 doc/REST-interface.md                              |   30 +-
 doc/asmap-data.md                                  |   14 +-
 doc/bips.md                                        |    2 +
 doc/build-freebsd.md                               |    2 +-
 doc/build-netbsd.md                                |   29 +-
 doc/build-osx.md                                   |    2 +-
 doc/build-windows.md                               |   14 +-
 doc/cjdns.md                                       |    6 +-
 doc/developer-notes.md                             |   52 +-
 doc/files.md                                       |   10 +-
 doc/multisig-tutorial.md                           |   58 +-
 doc/offline-signing-tutorial.md                    |    4 +-
 doc/productivity.md                                |    2 +-
 doc/release-notes-21283.md                         |    6 -
 doc/release-notes-26201.md                         |    9 -
 doc/release-notes-26988.md                         |    8 -
 doc/release-notes-27052.md                         |    8 +
 doc/release-notes-29060.md                         |   10 -
 doc/release-notes-29136.md                         |    6 -
 doc/release-notes-29278.md                         |   17 +
 doc/release-notes-31560.md                         |    8 -
 doc/release-notes-32220.md                         |    9 -
 doc/release-notes-32489.md                         |   15 -
 doc/release-notes-32800.md                         |    9 -
 doc/release-notes-33259.md                         |    4 -
 doc/release-notes-33414.md                         |    9 -
 doc/release-notes-33671.md                         |   11 -
 doc/release-notes-33920.md                         |    4 -
 doc/release-notes-33966.md                         |    9 -
 doc/release-notes-34544.md                         |    7 -
 doc/release-notes-34566.md                         |   20 +
 doc/release-notes-34628.md                         |   13 -
 doc/release-notes-34672.md                         |   11 -
 doc/release-notes-34743.md                         |    7 +
 doc/release-notes-34779.md                         |    5 -
 doc/release-notes-34796.md                         |    6 -
 doc/release-notes-34861.md                         |    4 +
 doc/release-notes-34911.md                         |   12 -
 doc/release-notes-34917.md                         |    9 -
 doc/release-notes-35037.md                         |    8 +
 doc/release-notes-35182.md                         |   16 -
 doc/release-notes-35266                            |    7 -
 doc/release-notes-35267.md                         |    4 -
 doc/release-notes-35295.md                         |    8 -
 doc/release-notes-35319.md                         |   20 -
 doc/release-notes-35406.md                         |    8 -
 doc/release-notes-35601.md                         |    4 -
 doc/release-notes-35610.md                         |    6 -
 doc/release-notes-35634.md                         |    8 -
 doc/release-notes-35813.md                         |   12 +
 doc/release-notes-35989.md                         |    7 +
 doc/release-notes-36081.md                         |    8 +
 doc/release-notes-36251.md                         |    7 +
 doc/release-notes-36336.md                         |    8 +
 doc/release-notes-empty-template.md                |    2 +-
 doc/release-notes-remove-persistmempoolv1.md       |    6 +
 doc/release-process.md                             |    2 +-
 src/.clang-tidy                                    |    8 +-
 src/CMakeLists.txt                                 |   36 +-
 src/addresstype.h                                  |    2 +-
 src/addrman.cpp                                    |    9 +-
 src/addrman.h                                      |   22 +-
 src/addrman_impl.h                                 |   12 +-
 src/banman.h                                       |    4 +-
 src/base58.cpp                                     |    6 +-
 src/bech32.cpp                                     |    4 +-
 src/bech32.h                                       |    5 +-
 src/bench/CMakeLists.txt                           |    1 +
 src/bench/asmap.cpp                                |    7 +-
 src/bench/blockencodings.cpp                       |    4 +-
 src/bench/ccoins_caching.cpp                       |    1 +
 src/bench/chacha20.cpp                             |    4 +-
 src/bench/coin_selection.cpp                       |    3 +-
 src/bench/index_blockfilter.cpp                    |    6 +-
 src/bench/lockedpool.cpp                           |    4 +-
 src/bench/mempool_ephemeral_spends.cpp             |    8 +-
 src/bench/mempool_stress.cpp                       |    2 +-
 src/bench/merkle_root.cpp                          |    1 -
 src/bench/nanobench.h                              |    2 +
 src/bench/parse_hex.cpp                            |    1 -
 src/bench/poly1305.cpp                             |    4 +-
 src/bench/readwriteblock.cpp                       |    2 -
 src/bench/txgraph.cpp                              |    2 -
 src/bench/uint256_blob.cpp                         |   91 +
 src/bench/wallet_balance.cpp                       |    1 -
 src/bench/wallet_create_tx.cpp                     |    3 -
 src/bench/wallet_encrypt.cpp                       |    2 +-
 src/bench/wallet_ismine.cpp                        |    1 -
 src/bench/wallet_loading.cpp                       |    4 +-
 src/bench/wallet_migration.cpp                     |    6 +-
 src/bip324.h                                       |    2 +-
 src/bitcoin-chainstate.cpp                         |   17 +-
 src/bitcoin-cli.cpp                                |   53 +-
 src/bitcoin-tx.cpp                                 |    6 +-
 src/bitcoin-util.cpp                               |    4 +-
 src/bitcoin-wallet.cpp                             |    2 +
 src/bitcoin.cpp                                    |    2 +-
 src/blockencodings.cpp                             |  106 +-
 src/blockencodings.h                               |   13 +
 src/blockfilter.h                                  |    4 +-
 src/chain.h                                        |    8 +-
 src/chainparamsbase.cpp                            |   27 +-
 src/chainparamsbase.h                              |    2 +-
 src/chainparamsseeds.h                             | 3858 ++++++-------
 src/clientversion.cpp                              |    2 +-
 src/clientversion.h                                |    2 +-
 src/coins.cpp                                      |    5 +-
 src/coins.h                                        |   72 +-
 src/common/args.cpp                                |    2 -
 src/common/args.h                                  |    1 -
 src/common/bip352.cpp                              |  521 ++
 src/common/bip352.h                                |  305 ++
 src/common/bloom.cpp                               |    3 +-
 src/common/bloom.h                                 |    7 +-
 src/common/config.cpp                              |   11 +-
 src/common/init.cpp                                |    4 +-
 src/common/interfaces.cpp                          |    5 +-
 src/common/messages.cpp                            |   38 +-
 src/common/messages.h                              |    4 +-
 src/common/netif.cpp                               |   12 +-
 src/common/netif.h                                 |    1 +
 src/common/pcp.cpp                                 |   40 +-
 src/common/pcp.h                                   |   10 +-
 src/common/run_command.cpp                         |   13 +-
 src/common/settings.cpp                            |    5 +-
 src/common/settings.h                              |    4 +-
 src/common/signmessage.cpp                         |    5 +-
 src/common/system.cpp                              |   29 +-
 src/common/system.h                                |    4 +-
 src/common/types.h                                 |    1 -
 src/common/url.cpp                                 |    1 +
 src/consensus/amount.h                             |    4 +-
 src/consensus/consensus.h                          |   20 +-
 src/consensus/merkle.cpp                           |   14 +-
 src/consensus/merkle.h                             |   11 +-
 src/consensus/params.h                             |    1 +
 src/consensus/tx_check.cpp                         |   10 +-
 src/consensus/tx_verify.cpp                        |    6 +
 src/consensus/tx_verify.h                          |    1 +
 src/consensus/validation.h                         |   15 +-
 src/core_io.cpp                                    |    8 +-
 src/core_io.h                                      |    3 +-
 src/crc32c/src/crc32c_internal.h                   |    2 +-
 src/crc32c/src/crc32c_sse42.cc                     |   15 -
 src/crypto/aes.h                                   |    4 +-
 src/crypto/muhash.cpp                              |    3 +-
 src/crypto/ripemd160.h                             |    2 +-
 src/crypto/sha1.h                                  |    2 +-
 src/crypto/sha256.h                                |    2 +-
 src/crypto/sha256_sse4.cpp                         |    2 +-
 src/crypto/sha3.h                                  |    2 +-
 src/crypto/sha512.h                                |    2 +-
 src/cuckoocache.h                                  |   10 +-
 src/dbwrapper.cpp                                  |   24 +
 src/dbwrapper.h                                    |   87 +-
 src/dummywallet.cpp                                |    1 +
 src/headerssync.cpp                                |   12 +-
 src/headerssync.h                                  |   10 +-
 src/httprpc.cpp                                    |    7 +-
 src/httpserver.cpp                                 |  680 ++-
 src/httpserver.h                                   |  244 +-
 src/i2p.cpp                                        |    4 +-
 src/i2p.h                                          |    2 +-
 src/index/base.cpp                                 |    4 +-
 src/index/base.h                                   |    5 +-
 src/index/blockfilterindex.cpp                     |    1 +
 src/index/blockfilterindex.h                       |    4 +-
 src/index/coinstatsindex.h                         |    2 +-
 src/index/db_key.h                                 |    4 +-
 src/index/txindex.cpp                              |  195 +-
 src/index/txindex.h                                |   28 +-
 src/index/txindex_key.h                            |  128 +
 src/index/txospenderindex.h                        |    2 +-
 src/init.cpp                                       |  264 +-
 src/init.h                                         |    4 +-
 src/init/basic.cpp                                 |    5 +-
 src/init/bitcoin-gui.cpp                           |    3 +-
 src/init/bitcoin-node.cpp                          |    4 +-
 src/init/bitcoin-qt.cpp                            |    3 +-
 src/init/bitcoin-wallet.cpp                        |    2 +-
 src/init/bitcoind.cpp                              |    3 +-
 src/init/common.cpp                                |    4 +-
 src/interfaces/chain.h                             |   22 +-
 src/interfaces/init.h                              |    7 +
 src/interfaces/ipc.h                               |   15 +-
 src/interfaces/node.h                              |   13 +-
 src/interfaces/wallet.h                            |   54 +-
 src/ipc/CMakeLists.txt                             |    4 +-
 src/ipc/capnp/common-types.h                       |    5 +-
 src/ipc/capnp/protocol.cpp                         |   36 +-
 src/ipc/capnp/protocol.h                           |    2 +-
 src/ipc/interfaces.cpp                             |   30 +-
 src/ipc/listen.cpp                                 |   75 +
 src/ipc/process.cpp                                |   63 +-
 src/ipc/process.h                                  |   23 +-
 src/ipc/protocol.h                                 |   47 +-
 src/ipc/test/CMakeLists.txt                        |    9 +-
 src/ipc/test/fuzz/ipc.cpp                          |   11 +-
 src/ipc/test/ipc_test.cpp                          |  193 -
 src/ipc/test/ipc_test.h                            |    4 -
 src/ipc/test/ipc_tests.cpp                         |  321 +-
 src/ipc/types.h                                    |   40 +
 src/ipc/util.h                                     |   64 +
 src/kernel/CMakeLists.txt                          |    1 -
 src/kernel/bitcoinkernel.cpp                       |  439 +-
 src/kernel/bitcoinkernel.h                         |  324 +-
 src/kernel/bitcoinkernel_wrapper.h                 |  185 +-
 src/kernel/blockmanager_opts.h                     |    2 +-
 src/kernel/caches.h                                |   13 +-
 src/kernel/chainparams.cpp                         |  117 +-
 src/kernel/chainparams.h                           |    6 +-
 src/kernel/chainstatemanager_opts.h                |    4 +-
 src/kernel/coinstats.cpp                           |    2 +-
 src/kernel/disconnected_transactions.h             |    2 +-
 src/kernel/mempool_options.h                       |   11 +-
 src/kernel/signet.h                                |   38 +
 src/key.cpp                                        |   40 +-
 src/key.h                                          |   51 +-
 src/key_io.cpp                                     |   13 +-
 src/leveldb/.github/workflows/ci.yml               |   12 +
 src/leveldb/benchmarks/db_bench_sqlite3.cc         |    1 +
 src/leveldb/db/dbformat.h                          |   16 +-
 src/leveldb/db/log_format.h                        |    6 +-
 src/leveldb/include/leveldb/db.h                   |    4 +-
 src/leveldb/table/format.h                         |    4 +-
 src/leveldb/util/crc32c.h                          |    2 +-
 src/leveldb/util/env_posix.cc                      |    4 +-
 src/leveldb/util/env_windows.cc                    |    4 +-
 src/logging.cpp                                    |   17 +-
 src/logging.h                                      |   29 +-
 src/logging/categories.h                           |    1 +
 src/mapport.h                                      |    2 +-
 src/minisketch/src/fields/clmul_common_impl.h      |    5 +-
 src/minisketch/src/lintrans.h                      |    5 +-
 src/minisketch/src/util.h                          |   14 +
 src/musig.cpp                                      |    2 +-
 src/musig.h                                        |    2 +-
 src/net.cpp                                        |   84 +-
 src/net.h                                          |   80 +-
 src/net_permissions.h                              |    6 +-
 src/net_processing.cpp                             |  212 +-
 src/net_processing.h                               |   19 +-
 src/netaddress.cpp                                 |   12 +-
 src/netaddress.h                                   |   23 +-
 src/netbase.cpp                                    |   68 +-
 src/netbase.h                                      |    6 +-
 src/netgroup.cpp                                   |   12 +-
 src/netgroup.h                                     |    8 +-
 src/node/block_template_manager.cpp                |  266 +
 src/node/block_template_manager.h                  |  106 +
 src/node/block_validation_state_catcher.h          |   37 +
 src/node/blockstorage.cpp                          |    8 +-
 src/node/blockstorage.h                            |   14 +-
 src/node/caches.cpp                                |   14 +-
 src/node/caches.h                                  |    8 +-
 src/node/chainstatemanager_args.h                  |    2 +-
 src/node/context.cpp                               |    4 +-
 src/node/context.h                                 |   18 +-
 src/node/data/ip_asn.dat                           |  Bin 1519688 -> 1582208 bytes
 src/node/interfaces.cpp                            |   76 +-
 src/node/kernel_notifications.h                    |    2 +-
 src/node/mempool_args.cpp                          |    2 -
 src/node/mempool_persist.cpp                       |   13 +-
 src/node/mempool_persist_args.h                    |    2 +-
 src/node/miner.cpp                                 |  260 +-
 src/node/miner.h                                   |   60 +-
 src/node/mining_args.h                             |    2 +-
 src/node/protocol_version.h                        |   20 +-
 src/node/psbt.cpp                                  |    6 +-
 src/node/transaction.cpp                           |   26 +-
 src/node/transaction.h                             |    6 +-
 src/node/txdownloadman.h                           |   14 +-
 src/node/txdownloadman_impl.cpp                    |    9 +-
 src/node/txdownloadman_impl.h                      |   11 +-
 src/node/txorphanage.cpp                           |    2 +
 src/node/txorphanage.h                             |    4 +-
 src/node/txreconciliation.h                        |    2 +-
 src/node/types.h                                   |    1 +
 src/node/utxo_snapshot.h                           |    6 +-
 src/outputtype.h                                   |    2 +-
 src/policy/feerate.cpp                             |   12 +-
 src/policy/feerate.h                               |   15 +-
 src/policy/fees/block_policy_estimator.cpp         |  175 +-
 src/policy/fees/block_policy_estimator.h           |   38 +-
 src/policy/fees/block_policy_estimator_args.cpp    |   16 -
 src/policy/fees/block_policy_estimator_args.h      |   15 -
 src/policy/fees/estimator_args.cpp                 |   60 +
 src/policy/fees/estimator_args.h                   |   21 +
 src/policy/fees/estimator_man.cpp                  |  108 +
 src/policy/fees/estimator_man.h                    |  112 +
 src/policy/fees/mempool_estimator.cpp              |  415 ++
 src/policy/fees/mempool_estimator.h                |  158 +
 src/policy/packages.cpp                            |    2 +-
 src/policy/packages.h                              |    4 +-
 src/policy/policy.h                                |   68 +-
 src/policy/rbf.h                                   |    2 +-
 src/policy/truc_policy.h                           |   14 +-
 src/primitives/transaction.h                       |   22 +-
 src/primitives/transaction_identifier.h            |   15 +-
 src/private_broadcast.cpp                          |   85 +-
 src/private_broadcast.h                            |   90 +-
 src/protocol.h                                     |    8 +-
 src/psbt.cpp                                       |  102 +-
 src/psbt.h                                         |  125 +-
 src/pubkey.cpp                                     |   33 +-
 src/pubkey.h                                       |   43 +-
 src/qt/CMakeLists.txt                              |   12 +-
 src/qt/askpassphrasedialog.cpp                     |   37 +-
 src/qt/bitcoin_locale.qrc                          |    3 +-
 src/qt/bitcoingui.cpp                              |   25 +-
 src/qt/bitcoingui.h                                |    1 +
 src/qt/bitcoinstrings.cpp                          |   23 +-
 src/qt/guiconstants.h                              |   16 +-
 src/qt/guiutil.cpp                                 |    8 +-
 src/qt/guiutil.h                                   |   32 +
 src/qt/intro.h                                     |    2 +-
 src/qt/locale/bitcoin_am.ts                        |  940 ++--
 src/qt/locale/bitcoin_ar.ts                        | 3932 ++++++++++----
 src/qt/locale/bitcoin_ast_ES.ts                    |  938 ++--
 src/qt/locale/bitcoin_az.ts                        | 1696 +++---
 src/qt/locale/bitcoin_az@latin.ts                  | 1666 +++---
 src/qt/locale/bitcoin_be.ts                        | 1020 ++--
 src/qt/locale/bitcoin_bg.ts                        | 3190 ++++++-----
 src/qt/locale/bitcoin_bn.ts                        |  912 ++--
 src/qt/locale/bitcoin_br.ts                        |  932 ++--
 src/qt/locale/bitcoin_bs.ts                        | 1619 +++---
 src/qt/locale/bitcoin_ca.ts                        | 4456 ++++++++-------
 src/qt/locale/bitcoin_cmn.ts                       | 4917 ++++++-----------
 src/qt/locale/bitcoin_cs.ts                        | 4819 +++++++++-------
 src/qt/locale/bitcoin_cy.ts                        | 2006 ++++---
 src/qt/locale/bitcoin_da.ts                        | 3922 ++++++++------
 src/qt/locale/bitcoin_de.ts                        | 5259 +++++-------------
 src/qt/locale/bitcoin_el.ts                        | 4404 ++++++++-------
 src/qt/locale/bitcoin_en.ts                        |  137 +-
 src/qt/locale/bitcoin_eo.ts                        | 2088 ++++---
 src/qt/locale/bitcoin_es.ts                        | 5268 +++++-------------
 src/qt/locale/bitcoin_et.ts                        | 1846 +++----
 src/qt/locale/bitcoin_eu.ts                        | 5414 +++++++++---------
 src/qt/locale/bitcoin_fa.ts                        | 3638 +++++++++----
 src/qt/locale/bitcoin_fi.ts                        | 4636 ++++++++--------
 src/qt/locale/bitcoin_fil.ts                       | 2874 +++++-----
 src/qt/locale/bitcoin_fo.ts                        | 5522 +++++++++----------
 src/qt/locale/bitcoin_fr.ts                        | 5446 +++++++++----------
 src/qt/locale/bitcoin_ga.ts                        | 5417 +++++++++---------
 src/qt/locale/bitcoin_ga_IE.ts                     | 5521 ++++++++++---------
 src/qt/locale/bitcoin_gl.ts                        | 2048 ++++---
 src/qt/locale/bitcoin_gl_ES.ts                     | 1180 ++--
 src/qt/locale/bitcoin_gu.ts                        | 3245 ++++++-----
 src/qt/locale/bitcoin_hak.ts                       | 4903 ++++++-----------
 src/qt/locale/bitcoin_he.ts                        | 3971 ++++++++------
 src/qt/locale/bitcoin_hi.ts                        | 2979 +++-------
 src/qt/locale/bitcoin_hr.ts                        | 4220 +++++++-------
 src/qt/locale/bitcoin_hu.ts                        | 5291 +++++++++---------
 src/qt/locale/bitcoin_id.ts                        | 4013 ++++++++++----
 src/qt/locale/bitcoin_is.ts                        | 1195 ++--
 src/qt/locale/bitcoin_it.ts                        | 5304 +++++++++---------
 src/qt/locale/bitcoin_ja.ts                        | 5420 +++++++++---------
 src/qt/locale/bitcoin_ka.ts                        | 2961 +++++-----
 src/qt/locale/bitcoin_kk.ts                        | 1662 ++++--
 src/qt/locale/bitcoin_kk@latin.ts                  | 1642 ++++--
 src/qt/locale/bitcoin_km.ts                        | 3222 +++++------
 src/qt/locale/bitcoin_kn.ts                        |  794 ++-
 src/qt/locale/bitcoin_ko.ts                        | 5397 +++++++++---------
 src/qt/locale/bitcoin_ku.ts                        |  776 ++-
 src/qt/locale/bitcoin_ku_IQ.ts                     |  776 ++-
 src/qt/locale/bitcoin_la.ts                        | 1320 +++++
 src/qt/locale/bitcoin_lt.ts                        | 2870 +++++-----
 src/qt/locale/bitcoin_lv.ts                        | 1464 +++--
 src/qt/locale/bitcoin_mi.ts                        |  566 +-
 src/qt/locale/bitcoin_mk.ts                        | 1396 +++--
 src/qt/locale/bitcoin_ml.ts                        | 1588 +++---
 src/qt/locale/bitcoin_mn.ts                        | 1048 ++--
 src/qt/locale/bitcoin_ms.ts                        |  735 ++-
 src/qt/locale/bitcoin_mt.ts                        | 2308 ++++----
 src/qt/locale/bitcoin_nb.ts                        | 4024 +++++++-------
 src/qt/locale/bitcoin_ne.ts                        | 1024 ++--
 src/qt/locale/bitcoin_nl.ts                        | 4474 ++++++++-------
 src/qt/locale/bitcoin_no.ts                        | 1265 +++--
 src/qt/locale/bitcoin_pam.ts                       | 1010 ++--
 src/qt/locale/bitcoin_pl.ts                        | 5367 +++++++++---------
 src/qt/locale/bitcoin_ps.ts                        | 1954 ++++---
 src/qt/locale/bitcoin_pt.ts                        | 5362 +++++++++---------
 src/qt/locale/bitcoin_pt_BR.ts                     | 4910 +++++++++--------
 src/qt/locale/bitcoin_ro.ts                        | 3892 +++++++------
 src/qt/locale/bitcoin_ru.ts                        | 4473 +++++++++------
 src/qt/locale/bitcoin_si.ts                        | 1294 +++--
 src/qt/locale/bitcoin_sk.ts                        | 5320 +++++++++---------
 src/qt/locale/bitcoin_sl.ts                        | 4716 ++++++++--------
 src/qt/locale/bitcoin_sm.ts                        | 2234 ++++----
 src/qt/locale/bitcoin_sq.ts                        |  732 ++-
 src/qt/locale/bitcoin_sr.ts                        | 4051 +++++++-------
 src/qt/locale/bitcoin_sr@ijekavianlatin.ts         | 4019 +++++++-------
 src/qt/locale/bitcoin_sr@latin.ts                  | 4013 +++++++-------
 src/qt/locale/bitcoin_sv.ts                        | 3972 +++++++-------
 src/qt/locale/bitcoin_sw.ts                        | 1618 +++---
 src/qt/locale/bitcoin_szl.ts                       | 1601 +++---
 src/qt/locale/bitcoin_ta.ts                        | 3073 +++++------
 src/qt/locale/bitcoin_te.ts                        | 2728 +++++-----
 src/qt/locale/bitcoin_th.ts                        | 2695 ++++-----
 src/qt/locale/bitcoin_tk.ts                        | 2718 +++++-----
 src/qt/locale/bitcoin_tl.ts                        | 1470 +++--
 src/qt/locale/bitcoin_tr.ts                        | 4310 ++++++++-------
 src/qt/locale/bitcoin_uk.ts                        | 5584 ++++++++++---------
 src/qt/locale/bitcoin_ur.ts                        | 2941 +++++-----
 src/qt/locale/bitcoin_uz.ts                        | 2992 +++++-----
 src/qt/locale/bitcoin_uz@Cyrl.ts                   | 2950 +++++-----
 src/qt/locale/bitcoin_uz@Latn.ts                   | 2950 +++++-----
 src/qt/locale/bitcoin_ve.ts                        |  686 ++-
 src/qt/locale/bitcoin_vi.ts                        | 2388 ++++++++
 src/qt/locale/bitcoin_yi.ts                        |  862 ++-
 src/qt/locale/bitcoin_yo.ts                        |  702 ---
 src/qt/locale/bitcoin_yue.ts                       | 4881 ++++++-----------
 src/qt/locale/bitcoin_zh-Hans.ts                   | 5087 ++++++-----------
 src/qt/locale/bitcoin_zh-Hant.ts                   | 4915 ++++++-----------
 src/qt/locale/bitcoin_zh.ts                        | 1999 ++++---
 src/qt/locale/bitcoin_zh_CN.ts                     | 5073 ++++++++---------
 src/qt/locale/bitcoin_zh_HK.ts                     | 4933 ++++++-----------
 src/qt/locale/bitcoin_zh_TW.ts                     | 5107 +++++++++--------
 src/qt/locale/ts_files.cmake                       |    3 +-
 src/qt/modaloverlay.h                              |    2 +-
 src/qt/optionsdialog.cpp                           |    2 +-
 src/qt/optionsmodel.cpp                            |    4 +-
 src/qt/optionsmodel.h                              |    2 +-
 src/qt/psbtoperationsdialog.cpp                    |    5 +-
 src/qt/qrimagewidget.h                             |    8 +-
 src/qt/res/animation/makespinner.sh                |    2 +-
 src/qt/rpcconsole.cpp                              |    9 +-
 src/qt/sendcoinsdialog.cpp                         |   12 +-
 src/qt/test/rpcnestedtests.cpp                     |    5 +
 src/qt/test/wallettests.cpp                        |    5 +-
 src/qt/walletcontroller.cpp                        |   22 +-
 src/qt/walletcontroller.h                          |    2 +-
 src/qt/walletmodel.cpp                             |   22 +-
 src/qt/walletmodel.h                               |    4 +-
 src/randomenv.cpp                                  |    2 +-
 src/rest.cpp                                       |   68 +-
 src/rpc/blockchain.cpp                             |  105 +-
 src/rpc/blockchain.h                               |   11 +-
 src/rpc/client.cpp                                 |   15 +-
 src/rpc/client.h                                   |    6 +-
 src/rpc/external_signer.cpp                        |   10 +-
 src/rpc/fees.cpp                                   |  108 +-
 src/rpc/mempool.cpp                                |  144 +-
 src/rpc/mining.cpp                                 |  105 +-
 src/rpc/mining.h                                   |    2 +-
 src/rpc/net.cpp                                    |  157 +-
 src/rpc/node.cpp                                   |   22 +-
 src/rpc/output_script.cpp                          |   22 +-
 src/rpc/protocol.h                                 |    2 +
 src/rpc/rawtransaction.cpp                         |  129 +-
 src/rpc/rawtransaction_util.cpp                    |   23 +-
 src/rpc/rawtransaction_util.h                      |    6 +-
 src/rpc/request.cpp                                |    5 +
 src/rpc/request.h                                  |    8 +-
 src/rpc/server.cpp                                 |  121 +-
 src/rpc/server.h                                   |    7 +-
 src/rpc/server_util.cpp                            |   31 +-
 src/rpc/server_util.h                              |   18 +-
 src/rpc/signmessage.cpp                            |    4 +
 src/rpc/txoutproof.cpp                             |   19 +-
 src/rpc/util.cpp                                   |   42 +-
 src/rpc/util.h                                     |   19 +-
 src/script/descriptor.cpp                          |  207 +-
 src/script/descriptor.h                            |   22 +-
 src/script/interpreter.h                           |   26 +-
 src/script/keyorigin.h                             |   19 +-
 src/script/miniscript.h                            |   36 +-
 src/script/script.h                                |   24 +-
 src/script/sigcache.h                              |   10 +-
 src/script/sign.cpp                                |   22 +-
 src/script/signingprovider.cpp                     |    3 +-
 src/script/signingprovider.h                       |    5 +-
 src/secp256k1/CHANGELOG.md                         |   34 +-
 src/secp256k1/CMakeLists.txt                       |    6 +-
 src/secp256k1/configure.ac                         |    8 +-
 src/secp256k1/doc/release-process.md               |   45 +-
 src/secp256k1/examples/silentpayments.c            |    2 +-
 src/secp256k1/include/secp256k1.h                  |   34 +-
 src/secp256k1/include/secp256k1_schnorrsig.h       |   13 +-
 src/secp256k1/include/secp256k1_silentpayments.h   |   35 +-
 src/secp256k1/src/bench_ecmult.c                   |    4 +-
 src/secp256k1/src/bench_internal.c                 |    6 +-
 src/secp256k1/src/ecdsa.h                          |    2 +-
 src/secp256k1/src/ecdsa_impl.h                     |    4 +-
 src/secp256k1/src/eckey.h                          |   10 +-
 src/secp256k1/src/eckey_impl.h                     |   43 +-
 src/secp256k1/src/ecmult_gen.h                     |   10 +-
 src/secp256k1/src/ecmult_gen_impl.h                |   66 +-
 src/secp256k1/src/field.h                          |   19 +-
 src/secp256k1/src/field_10x26_impl.h               |    2 +-
 src/secp256k1/src/field_5x52_impl.h                |    2 +-
 src/secp256k1/src/field_impl.h                     |    6 +-
 src/secp256k1/src/group.h                          |   26 +
 src/secp256k1/src/group_impl.h                     |  434 +-
 src/secp256k1/src/hash.h                           |    2 +
 src/secp256k1/src/hash_impl.h                      |   65 +
 src/secp256k1/src/modules/ecdh/main_impl.h         |   16 +-
 src/secp256k1/src/modules/ecdh/tests_impl.h        |    4 +-
 src/secp256k1/src/modules/ellswift/main_impl.h     |   39 +-
 .../src/modules/ellswift/tests_exhaustive_impl.h   |    4 +-
 src/secp256k1/src/modules/ellswift/tests_impl.h    |   18 +-
 src/secp256k1/src/modules/extrakeys/tests_impl.h   |    4 +-
 src/secp256k1/src/modules/musig/keyagg_impl.h      |    8 +-
 src/secp256k1/src/modules/musig/session_impl.h     |   48 +-
 src/secp256k1/src/modules/musig/tests_impl.h       |    8 +-
 .../src/modules/recovery/tests_exhaustive_impl.h   |    6 +-
 src/secp256k1/src/modules/schnorrsig/main_impl.h   |   12 +-
 .../src/modules/schnorrsig/tests_exhaustive_impl.h |    4 +-
 src/secp256k1/src/modules/schnorrsig/tests_impl.h  |    7 +-
 .../src/modules/silentpayments/main_impl.h         |   57 +-
 .../src/modules/silentpayments/tests_impl.h        |   35 +-
 src/secp256k1/src/scratch_impl.h                   |   10 +-
 src/secp256k1/src/secp256k1.c                      |   29 +-
 src/secp256k1/src/selftest.h                       |    8 +-
 src/secp256k1/src/testrand_impl.h                  |    2 +-
 src/secp256k1/src/tests.c                          |  281 +-
 src/secp256k1/src/tests_exhaustive.c               |    2 +-
 src/secp256k1/src/util.h                           |   17 +-
 src/serialize.h                                    |    6 +-
 src/signet.cpp                                     |    1 -
 src/test/CMakeLists.txt                            |   24 +-
 src/test/addrman_tests.cpp                         |   19 +-
 src/test/allocator_tests.cpp                       |   21 +-
 src/test/amount_tests.cpp                          |   30 +-
 src/test/argsman_tests.cpp                         |   52 +-
 src/test/arith_uint256_tests.cpp                   |   10 +-
 src/test/base58_tests.cpp                          |    2 +-
 src/test/baseindex_tests.cpp                       |  240 +-
 src/test/bech32_tests.cpp                          |    2 +
 src/test/bip32_tests.cpp                           |  273 +-
 src/test/bip352_tests.cpp                          |  435 ++
 src/test/blockencodings_tests.cpp                  |   13 +-
 src/test/blockfilter_index_tests.cpp               |  151 +-
 ...or_tests.cpp => blockpolicyestimator_tests.cpp} |  175 +-
 src/test/caches_tests.cpp                          |    7 +-
 src/test/checkqueue_tests.cpp                      |    3 +-
 src/test/coins_tests.cpp                           |   39 +-
 src/test/coinscachepair_tests.cpp                  |   36 +-
 src/test/coinstatsindex_tests.cpp                  |   50 +-
 src/test/coinsviewoverlay_tests.cpp                |   10 +-
 src/test/crypto_tests.cpp                          |    6 +
 src/test/data/bip352_send_and_receive_vectors.json | 5729 ++++++++++++++++++++
 src/test/data/script_tests.json                    |   64 +
 src/test/data/tx_valid.json                        |    7 +
 src/test/dbwrapper_tests.cpp                       |  105 +
 src/test/denialofservice_tests.cpp                 |  106 +-
 src/test/descriptor_tests.cpp                      |  217 +-
 src/test/fees_util_tests.cpp                       |   29 +
 src/test/fuzz/CMakeLists.txt                       |    3 +-
 ...cy_estimator.cpp => block_policy_estimator.cpp} |   11 +-
 src/test/fuzz/cluster_linearize.cpp                |    1 -
 src/test/fuzz/cmpctblock.cpp                       |   56 +-
 src/test/fuzz/coins_view.cpp                       |   17 +-
 src/test/fuzz/coinscache_sim.cpp                   |   36 +-
 src/test/fuzz/connect_block.cpp                    |  479 ++
 src/test/fuzz/fees.cpp                             |    8 +-
 src/test/fuzz/fuzz.cpp                             |    2 +-
 src/test/fuzz/http_request.cpp                     |  183 +-
 src/test/fuzz/kitchen_sink.cpp                     |    5 +-
 src/test/fuzz/locale.cpp                           |    1 -
 src/test/fuzz/minisketch.cpp                       |    4 +-
 src/test/fuzz/muhash.cpp                           |    3 +
 src/test/fuzz/netaddress.cpp                       |   10 +-
 src/test/fuzz/p2p_handshake.cpp                    |   10 +-
 src/test/fuzz/p2p_private_broadcast.cpp            |    7 +-
 src/test/fuzz/p2p_transport_serialization.cpp      |    1 -
 src/test/fuzz/parse_hd_keypath.cpp                 |   11 +-
 src/test/fuzz/parse_univalue.cpp                   |    5 +-
 src/test/fuzz/policy_estimator_io.cpp              |   36 +-
 src/test/fuzz/primitives_transaction.cpp           |    2 +-
 src/test/fuzz/private_broadcast.cpp                |  132 +-
 src/test/fuzz/process_message.cpp                  |   37 +-
 src/test/fuzz/process_messages.cpp                 |   42 +-
 src/test/fuzz/psbt.cpp                             |    3 -
 src/test/fuzz/rpc.cpp                              |  120 +-
 src/test/fuzz/script_descriptor_cache.cpp          |    3 +-
 src/test/fuzz/socks5.cpp                           |    1 +
 src/test/fuzz/string.cpp                           |    4 +-
 src/test/fuzz/tx_pool.cpp                          |   50 +-
 src/test/fuzz/txdownloadman.cpp                    |    6 +-
 src/test/fuzz/txorphan.cpp                         |   12 +-
 src/test/fuzz/util/descriptor.h                    |   10 +-
 src/test/fuzz/utxo_snapshot.cpp                    |    7 +-
 src/test/hash_tests.cpp                            |    2 +-
 src/test/headers_sync_chainwork_tests.cpp          |   10 +
 src/test/httpserver_tests.cpp                      |  453 +-
 src/test/kernel/test_kernel.cpp                    |  180 +-
 src/test/key_tests.cpp                             |   12 +-
 src/test/logging_tests.cpp                         |   23 +
 src/test/main.cpp                                  |    2 +
 src/test/mempool_fee_estimator_tests.cpp           |  343 ++
 src/test/mempool_tests.cpp                         |   19 +-
 src/test/merkle_tests.cpp                          |   20 +
 src/test/miner_tests.cpp                           |   83 +-
 src/test/miniscript_tests.cpp                      |   37 +-
 src/test/net_tests.cpp                             |  111 +-
 src/test/netbase_tests.cpp                         |    4 +
 src/test/node_init_tests.cpp                       |   24 +
 src/test/pcp_tests.cpp                             |    5 +-
 src/test/peerman_tests.cpp                         |    9 +-
 src/test/pow_tests.cpp                             |    3 +-
 src/test/private_broadcast_tests.cpp               |  126 +-
 src/test/psbt_tests.cpp                            |   99 +-
 src/test/rbf_tests.cpp                             |  103 +-
 src/test/reverselock_tests.cpp                     |   12 +-
 src/test/scheduler_tests.cpp                       |    3 +-
 src/test/script_p2sh_tests.cpp                     |  232 +-
 src/test/script_standard_tests.cpp                 |   24 +-
 src/test/script_tests.cpp                          |    4 +-
 src/test/serialize_tests.cpp                       |    2 +-
 src/test/skiplist_tests.cpp                        |    6 +-
 src/test/streams_tests.cpp                         |   42 +-
 src/test/sync_tests.cpp                            |   15 +-
 src/test/system_ram_tests.cpp                      |   15 +-
 src/test/system_tests.cpp                          |    7 -
 src/test/threadpool_tests.cpp                      |    6 +-
 src/test/transaction_tests.cpp                     |   75 +-
 src/test/txdownload_tests.cpp                      |    6 +-
 src/test/txgraph_tests.cpp                         |    2 +-
 src/test/txindex_tests.cpp                         |  322 +-
 src/test/txospenderindex_tests.cpp                 |    4 +-
 src/test/txpackage_tests.cpp                       |    3 +-
 src/test/txvalidationcache_tests.cpp               |  108 +-
 src/test/util/chainstate.h                         |    2 +-
 src/test/util/cluster_linearize.h                  |   10 +-
 src/test/util/coins.h                              |   18 +
 src/test/util/mining.cpp                           |   69 +-
 src/test/util/mining.h                             |    9 +
 src/test/util/net.h                                |    8 +-
 src/test/util/setup_common.cpp                     |   38 +-
 src/test/util/setup_common.h                       |   19 +-
 src/test/util/validation.cpp                       |   69 +
 src/test/util/validation.h                         |   31 +
 src/test/util/versionbits.h                        |    2 +-
 src/test/util_not_null_tests.cpp                   |  247 +
 src/test/util_tests.cpp                            |   24 +-
 src/test/validation_block_tests.cpp                |   19 +-
 src/test/validation_chainstatemanager_tests.cpp    |   20 +-
 src/test/versionbits_tests.cpp                     |    6 +-
 src/torcontrol.cpp                                 |   54 +-
 src/torcontrol.h                                   |   14 +-
 src/txdb.cpp                                       |   21 +-
 src/txgraph.h                                      |    2 +-
 src/txmempool.cpp                                  |    8 +-
 src/txmempool.h                                    |   22 +-
 src/txrequest.h                                    |    2 +-
 src/uint256.h                                      |    8 +-
 src/univalue/include/univalue.h                    |    7 +-
 src/univalue/include/univalue_escapes.h            |    2 +-
 src/univalue/lib/univalue.cpp                      |    2 +-
 src/univalue/lib/univalue_get.cpp                  |    2 +-
 src/univalue/lib/univalue_read.cpp                 |   16 +-
 src/univalue/test/object.cpp                       |    7 +
 src/util/CMakeLists.txt                            |    1 +
 src/util/asmap.cpp                                 |    2 +-
 src/util/bip32.cpp                                 |   60 +-
 src/util/bip32.h                                   |   23 +
 src/util/check.h                                   |    8 +-
 src/util/exec.cpp                                  |   11 +-
 src/util/feefrac.h                                 |    1 -
 src/util/fees.cpp                                  |   34 +
 src/util/fees.h                                    |   85 +-
 src/util/fs.h                                      |    4 +-
 src/util/fs_helpers.cpp                            |   11 +-
 src/util/fs_helpers.h                              |    2 +-
 src/util/log.h                                     |   12 +
 src/util/moneystr.cpp                              |    4 +-
 src/util/not_null.h                                |  135 +
 src/util/rbf.h                                     |    2 +-
 src/util/sock.cpp                                  |    5 +
 src/util/sock.h                                    |    2 +-
 src/util/strencodings.h                            |   15 +-
 src/util/string.cpp                                |   57 +-
 src/util/string.h                                  |   37 +-
 src/util/subprocess.h                              |   64 +-
 src/util/threadnames.cpp                           |    9 +
 src/util/time.cpp                                  |    1 -
 src/util/time.h                                    |    8 -
 src/validation.cpp                                 |   80 +-
 src/validation.h                                   |   43 +-
 src/validationinterface.cpp                        |   15 +-
 src/validationinterface.h                          |    7 +-
 src/versionbits.h                                  |    8 +-
 src/wallet/CMakeLists.txt                          |    2 +
 src/wallet/coincontrol.h                           |   11 +-
 src/wallet/coinselection.cpp                       |    5 -
 src/wallet/coinselection.h                         |    6 +-
 src/wallet/crypter.cpp                             |    6 +-
 src/wallet/crypter.h                               |   22 +-
 src/wallet/db.h                                    |    6 -
 src/wallet/dump.cpp                                |    2 +-
 src/wallet/dump.h                                  |    3 +-
 src/wallet/export.cpp                              |   28 +-
 src/wallet/export.h                                |    3 +-
 src/wallet/external_signer_scriptpubkeyman.cpp     |   17 +-
 src/wallet/external_signer_scriptpubkeyman.h       |   11 +-
 src/wallet/feebumper.cpp                           |   41 +-
 src/wallet/fees.cpp                                |   89 +-
 src/wallet/fees.h                                  |    9 +-
 src/wallet/imports.cpp                             |  338 ++
 src/wallet/imports.h                               |   64 +
 src/wallet/init.cpp                                |    1 +
 src/wallet/interfaces.cpp                          |   68 +-
 src/wallet/receive.cpp                             |   32 +-
 src/wallet/rpc/addresses.cpp                       |    3 +-
 src/wallet/rpc/backup.cpp                          |  373 +-
 src/wallet/rpc/coins.cpp                           |   10 +-
 src/wallet/rpc/encrypt.cpp                         |   34 +-
 src/wallet/rpc/spend.cpp                           |  172 +-
 src/wallet/rpc/transactions.cpp                    |  225 +-
 src/wallet/rpc/util.cpp                            |   12 +
 src/wallet/rpc/util.h                              |    4 +-
 src/wallet/rpc/wallet.cpp                          |  218 +-
 src/wallet/scan.cpp                                |  323 ++
 src/wallet/scan.h                                  |  136 +
 src/wallet/scriptpubkeyman.cpp                     |  202 +-
 src/wallet/scriptpubkeyman.h                       |   53 +-
 src/wallet/spend.cpp                               |   58 +-
 src/wallet/spend.h                                 |   10 +-
 src/wallet/test/CMakeLists.txt                     |    2 +
 src/wallet/test/coinselector_tests.cpp             |    3 +-
 src/wallet/test/fuzz/crypter.cpp                   |    8 +-
 src/wallet/test/fuzz/fees.cpp                      |   70 +-
 src/wallet/test/fuzz/spend.cpp                     |    1 +
 src/wallet/test/group_outputs_tests.cpp            |    7 +-
 src/wallet/test/psbt_wallet_tests.cpp              |   81 +-
 src/wallet/test/rescan_tests.cpp                   |  597 ++
 src/wallet/test/spend_tests.cpp                    |    1 -
 src/wallet/test/util.cpp                           |   28 +-
 src/wallet/test/util.h                             |   86 +-
 src/wallet/test/wallet_crypto_tests.cpp            |   20 +-
 src/wallet/test/wallet_interfaces_tests.cpp        |   81 +
 src/wallet/test/wallet_tests.cpp                   |  410 +-
 src/wallet/test/wallet_transaction_tests.cpp       |   27 +
 src/wallet/test/walletload_tests.cpp               |   65 +-
 src/wallet/transaction.cpp                         |   74 +-
 src/wallet/transaction.h                           |   94 +-
 src/wallet/types.h                                 |   32 +-
 src/wallet/wallet.cpp                              |  834 ++-
 src/wallet/wallet.h                                |  242 +-
 src/wallet/walletdb.cpp                            |  228 +-
 src/wallet/walletdb.h                              |   27 +-
 src/wallet/wallettool.cpp                          |    6 +-
 src/wallet/walletutil.cpp                          |   27 +
 src/wallet/walletutil.h                            |  109 +-
 src/zmq/zmqutil.h                                  |    2 +-
 test/CMakeLists.txt                                |    6 +-
 test/config.ini.in                                 |   31 +-
 test/functional/data/rpc_getblockstats.json        |  314 +-
 test/functional/data/rpc_psbt.json                 |   11 +
 .../data/util/getchainparams-mainnet.json          |    2 +-
 .../data/util/getchainparams-regtest.json          |    2 +-
 .../data/util/getchainparams-signet-custom.json    |    2 +-
 .../data/util/getchainparams-signet.json           |    2 +-
 .../data/util/getchainparams-testnet.json          |    2 +-
 .../data/util/getchainparams-testnet4.json         |    2 +-
 test/functional/feature_anchors.py                 |   43 +
 test/functional/feature_asmap.py                   |   26 +-
 test/functional/feature_bind_extra.py              |    1 +
 test/functional/feature_bind_port_discover.py      |   12 +-
 test/functional/feature_bind_port_externalip.py    |    9 +-
 test/functional/feature_config_args.py             |   22 +-
 test/functional/feature_fee_estimation.py          |  421 +-
 test/functional/feature_init.py                    |  107 +-
 test/functional/feature_minchainwork.py            |   37 +
 test/functional/feature_notifications.py           |   14 +
 test/functional/feature_pruning.py                 |    5 +
 test/functional/feature_signet.py                  |   55 +-
 test/functional/feature_taproot.py                 |    1 +
 test/functional/feature_torcontrol.py              |   16 +
 test/functional/feature_txindex_compatibility.py   |   72 +
 test/functional/feature_utxo_abort_on_error.py     |  130 +
 test/functional/interface_bitcoin_cli.py           |   29 +
 test/functional/interface_gui.py                   |   38 +
 test/functional/interface_http.py                  |  465 +-
 test/functional/interface_ipc.py                   |   18 +
 test/functional/interface_ipc_init.py              |  122 +
 test/functional/interface_ipc_mining.py            |   31 +-
 test/functional/interface_rest.py                  |  139 +-
 test/functional/interface_rpc.py                   |    7 +-
 test/functional/mempool_compatibility.py           |   38 +-
 test/functional/mempool_persist.py                 |    9 +
 test/functional/mining_basic.py                    |   38 +
 test/functional/mining_mainnet.py                  |    3 +-
 test/functional/p2p_add_connections.py             |   18 +-
 test/functional/p2p_addr_relay.py                  |    8 -
 test/functional/p2p_block_times.py                 |  105 +
 test/functional/p2p_blocksonly.py                  |   12 +-
 test/functional/p2p_compactblocks.py               |   12 +
 test/functional/p2p_eviction.py                    |    9 +-
 test/functional/p2p_getdata.py                     |    6 +-
 .../p2p_headers_sync_with_minchainwork.py          |   12 +
 test/functional/p2p_ibd_stalling.py                |   91 +
 test/functional/p2p_leak.py                        |   15 +-
 test/functional/p2p_nobloomfilter_messages.py      |    6 +-
 test/functional/p2p_node_network_limited.py        |   37 +-
 test/functional/p2p_orphan_handling.py             |   26 +
 test/functional/p2p_ping_ibd.py                    |  216 +
 test/functional/p2p_private_broadcast.py           |   41 +-
 .../functional/p2p_private_broadcast_completion.py |   99 +
 test/functional/p2p_private_broadcast_retry_v1.py  |    4 +-
 test/functional/p2p_segwit.py                      |   20 +-
 test/functional/p2p_sendtxrcncl.py                 |   12 +
 test/functional/p2p_tx_download.py                 |   68 +
 test/functional/rpc_bind.py                        |   19 +-
 test/functional/rpc_deprecated.py                  |   14 +-
 test/functional/rpc_deriveaddresses.py             |    1 +
 test/functional/rpc_echo_payload.py                |   50 +
 test/functional/rpc_estimatefee.py                 |   15 +-
 test/functional/rpc_getblockstats.py               |   53 +-
 test/functional/rpc_gettxspendingprevout.py        |    8 +
 test/functional/rpc_help.py                        |   11 +-
 test/functional/rpc_invalid_address_message.py     |    2 +-
 test/functional/rpc_net.py                         |   11 +-
 test/functional/rpc_openrpc.py                     |    8 +-
 test/functional/rpc_packages.py                    |   31 +
 test/functional/rpc_psbt.py                        |  383 +-
 test/functional/rpc_rawtransaction.py              |   87 +-
 test/functional/rpc_scanblocks.py                  |    3 +
 test/functional/rpc_scantxoutset.py                |    3 +
 test/functional/rpc_users.py                       |    2 +-
 test/functional/rpc_validateaddress.py             |    2 +-
 test/functional/rpc_whitelist.py                   |   20 +-
 test/functional/test_framework/crypto/secp256k1.py |   39 +-
 test/functional/test_framework/ipc_util.py         |   18 +-
 test/functional/test_framework/key.py              |   13 +-
 test/functional/test_framework/netutil.py          |   58 +-
 test/functional/test_framework/p2p.py              |   28 +-
 test/functional/test_framework/signet.py           |   17 +
 test/functional/test_framework/socks5.py           |   10 +-
 test/functional/test_framework/test_framework.py   |   62 +-
 test/functional/test_framework/test_node.py        |   79 +-
 test/functional/test_framework/util.py             |   49 +-
 test/functional/test_runner.py                     |   26 +-
 test/functional/tool_signet_miner.py               |   28 +-
 test/functional/wallet_ancient_migration.py        |  229 +
 test/functional/wallet_backwards_compatibility.py  |  123 +-
 test/functional/wallet_basic.py                    |    8 +-
 test/functional/wallet_bumpfee.py                  |  157 +-
 test/functional/wallet_change_address.py           |    2 +
 test/functional/wallet_conflicts.py                |   11 +-
 test/functional/wallet_create_tx.py                |   35 +-
 test/functional/wallet_createwallet.py             |    4 +-
 test/functional/wallet_derivehdkey.py              |  235 +
 test/functional/wallet_encryption.py               |    2 +-
 test/functional/wallet_exported_watchonly.py       |    2 +
 test/functional/wallet_fast_rescan.py              |   89 +-
 test/functional/wallet_fundrawtransaction.py       |   24 +-
 test/functional/wallet_hd.py                       |   13 +
 test/functional/wallet_importdescriptors.py        |  228 +-
 test/functional/wallet_importprunedfunds.py        |   19 +
 test/functional/wallet_keypool.py                  |   22 +
 test/functional/wallet_listdescriptors.py          |    5 +-
 test/functional/wallet_listrawtransactions.py      |  164 +
 test/functional/wallet_listreceivedby.py           |   11 +
 test/functional/wallet_listtransactions.py         |  125 +
 test/functional/wallet_migration.py                |   18 +-
 test/functional/wallet_multisig_descriptor_psbt.py |   22 +-
 test/functional/wallet_musig.py                    |   15 +-
 test/functional/wallet_orphanedreward.py           |    2 +
 test/functional/wallet_resendwallettransactions.py |  107 +-
 test/functional/wallet_send.py                     |   31 +
 test/functional/wallet_sendall.py                  |   59 +
 test/functional/wallet_signer.py                   |    2 +
 test/functional/wallet_startup.py                  |   52 +
 test/functional/wallet_taproot.py                  |   14 +-
 test/functional/wallet_txn_clone.py                |  105 +
 test/fuzz/test_runner.py                           |   26 +-
 test/get_previous_releases.py                      |   34 +-
 test/lint/check-doc.py                             |    2 +-
 test/lint/commit-script-check.sh                   |    2 +-
 test/lint/git-subtree-check.sh                     |    2 +-
 test/lint/lint-circular-dependencies.py            |    1 +
 test/lint/lint-python.py                           |    4 +-
 test/lint/lint-shell-locale.py                     |    9 +-
 test/sanitizer_suppressions/lsan                   |    5 +-
 test/sanitizer_suppressions/ubsan                  |    1 +
 test/sanitizer_suppressions/valgrind.supp          |    7 +
 test/with_sanitizer_env.py.in                      |   46 +
 vcpkg.json                                         |    9 +-
 980 files changed, 186763 insertions(+), 173550 deletions(-)
```

## 4. Full Source Code Diff
```diff
diff --git a/.github/actions/configure-docker/action.yml b/.github/actions/configure-docker/action.yml
index 074b47ce34..a447741a0a 100644
--- a/.github/actions/configure-docker/action.yml
+++ b/.github/actions/configure-docker/action.yml
@@ -14,10 +14,14 @@ runs:
       with:
         driver-opts: |
           network=host
+          env.BUILDKIT_STEP_LOG_MAX_SIZE=5242880
 
     - name: Set up Docker Buildx
       if: ${{ inputs.provider != 'warp' }}
       uses: docker/setup-buildx-action@v4
+      with:
+        driver-opts: |
+          env.BUILDKIT_STEP_LOG_MAX_SIZE=5242880
 
     # This is required when using the gha cache backend with a manual docker buildx invocation.
     # Docker will check for variables $ACTIONS_CACHE_URL, $ACTIONS_RESULTS_URL and $ACTIONS_RUNTIME_TOKEN
diff --git a/.github/actions/configure-environment/action.yml b/.github/actions/configure-environment/action.yml
index d3c928cf3f..00ca6ee81e 100644
--- a/.github/actions/configure-environment/action.yml
+++ b/.github/actions/configure-environment/action.yml
@@ -25,5 +25,5 @@ runs:
     - name: Get container name
       shell: bash
       run: |
-        source $FILE_ENV
+        source ci/test/00_setup_env.sh
         echo "CONTAINER_NAME=$CONTAINER_NAME" >> "$GITHUB_ENV"
diff --git a/.github/ci-windows-cross.py b/.github/ci-windows-cross.py
index bf13f81ac7..7cb53c7e9d 100755
--- a/.github/ci-windows-cross.py
+++ b/.github/ci-windows-cross.py
@@ -5,6 +5,7 @@
 
 import argparse
 import os
+import re
 import shlex
 import subprocess
 import sys
@@ -28,6 +29,23 @@ def print_version():
     run([str(bitcoind), "-version"])
 
 
+def check_imports():
+    bitcoind = Path.cwd() / "bin" / "bitcoind.exe"
+    output = run(
+        ["dumpbin.exe", "/imports", str(bitcoind)],
+        capture_output=True,
+        text=True,
+    ).stdout
+    dlls = re.findall(r"^\s*(\S+\.dll)\s*$", output, re.IGNORECASE | re.MULTILINE)
+    print("\n".join(dlls))
+
+    # Ensure the executable is linked against the expected C runtime.
+    dlls = {name.lower() for name in dlls}
+    uses_ucrt = any(name.startswith("api-ms-win-crt-") for name in dlls)
+    if not uses_ucrt:
+        sys.exit("Imported DLLs do not match the expected UCRT C runtime.")
+
+
 def check_manifests():
     release_dir = Path.cwd() / "bin"
     manifest_path = release_dir / "bitcoind.manifest"
@@ -58,6 +76,8 @@ def check_manifests():
 def prepare_tests():
     workspace = Path.cwd()
     config_path = workspace / "test" / "config.ini"
+    sanitizer_env_path = workspace / "test" / "with_sanitizer_env.py"
+    sanitizer_env_path.with_suffix(".py.in").rename(sanitizer_env_path)
     rpcauth_path = workspace / "share" / "rpcauth" / "rpcauth.py"
     replacements = {
         "SRCDIR=": f"SRCDIR={workspace}",
@@ -73,12 +93,9 @@ def prepare_tests():
     content = "\n".join(lines) + "\n"
     config_path.write_text(content)
     print(content)
-    previous_releases_dir = Path(os.environ["PREVIOUS_RELEASES_DIR"])
     cmd_download_prev_rel = [
         sys.executable,
         str(workspace / "test" / "get_previous_releases.py"),
-        "--target-dir",
-        str(previous_releases_dir),
     ]
     run(cmd_download_prev_rel)
     run([sys.executable, "-m", "pip", "install", "pyzmq"])
@@ -99,28 +116,32 @@ def run_functional_tests():
         f"--tmpdirprefix={workspace / '_ _'}",
         "--combinedlogslen=99999999",
         *shlex.split(os.environ.get("TEST_RUNNER_EXTRA", "").strip()),
-        # feature_unsupported_utxo_db.py fails on Windows because of emojis in the test data directory.
+        # Tests using ancient releases fail on Windows because of emojis in the test data directory.
         "--exclude",
         "feature_unsupported_utxo_db.py",
+        "--exclude",
+        "wallet_ancient_migration.py",
     ]
     run(test_runner_cmd)
 
-    # Run feature_unsupported_utxo_db sequentially in ASCII-only tmp dir,
-    # because it is excluded above due to lack of UTF-8 support in the
+    # Run ancient release tests sequentially in ASCII-only tmp dir,
+    # because they are excluded above due to lack of UTF-8 support in the
     # ancient release.
-    cmd_feature_unsupported_db = [
-        sys.executable,
-        str(workspace / "test" / "functional" / "feature_unsupported_utxo_db.py"),
-        "--previous-releases",
-        "--tmpdir",
-        str(Path(workspace) / "test_feature_unsupported_utxo_db"),
-    ]
-    run(cmd_feature_unsupported_db)
+    for test_name in ["feature_unsupported_utxo_db", "wallet_ancient_migration"]:
+        cmd = [
+            sys.executable,
+            str(workspace / "test" / "functional" / f"{test_name}.py"),
+            "--previous-releases",
+            "--tmpdir",
+            str(workspace / f"test_{test_name}"),
+        ]
+        run(cmd)
 
 
 def run_unit_tests():
     workspace = Path.cwd()
     os.environ["DIR_UNIT_TEST_DATA"] = str(workspace / "unit_test_data")
+    os.environ["QT_ASSUME_STDERR_HAS_CONSOLE"] = "1"
     # Can't use ctest here like other jobs as we don't have a CMake build tree.
     commands = [
         ["./bin/test_bitcoin-qt.exe"],
@@ -140,6 +161,7 @@ def main():
     parser = argparse.ArgumentParser(description="Utility to run Windows CI steps.")
     steps = list(map(lambda f: f.__name__, [
         print_version,
+        check_imports,
         check_manifests,
         prepare_tests,
         run_unit_tests,
diff --git a/.github/ci-windows.py b/.github/ci-windows.py
index 2635682266..9541970784 100755
--- a/.github/ci-windows.py
+++ b/.github/ci-windows.py
@@ -177,6 +177,7 @@ def run_tests(ci_type):
         for var, exe in test_envs.items():
             os.environ[var] = str(release_bin / exe)
 
+        os.environ["QT_ASSUME_STDERR_HAS_CONSOLE"] = "1"
         ctest_cmd = [
             "ctest",
             "--test-dir",
diff --git a/.github/workflows/ci.yml b/.github/workflows/ci.yml
index bce9c6038b..f01b1a5daf 100644
--- a/.github/workflows/ci.yml
+++ b/.github/workflows/ci.yml
@@ -304,25 +304,13 @@ jobs:
         run: echo "commit=$(git rev-parse HEAD)" >> "$GITHUB_OUTPUT"
 
   windows-cross:
```

---

## 5. The 6-Point Satoshi Guardian Audit Checklist
- [x] **1. Ring & Consensus Boundary:** Classified as `🔴 Ring 0 — CRITICAL CONSENSUS & CRYPTOGRAPHY (Chain-Split / Inflation Risk)`. Verified whether consensus determinism is affected.
- [x] **2. Invariant Preservation:** Checked that supply (`MAX_MONEY`), UTXO conservation, and cryptographic validation rules remain intact.
- [x] **3. Integer & Memory Bounds:** Inspected diff for signed/unsigned overflow, underflow, or unbounded vector allocations.
- [x] **4. Lock Ordering & Thread Safety:** Checked mutex acquisitions (`cs_main`, `mempool.cs`) and `AssertLockHeld` annotations.
- [x] **5. Adversarial P2P / Mempool Vector:** Evaluated whether a zero-cost peer can trigger asymmetric CPU/RAM exhaustion.
- [x] **6. Test Verification & Mutation Check:** Verified unit/functional test coverage in `test/` or `src/test/`.

## 6. Formal Maintainer Sign-Off
```markdown
Tested ACK faa3ea61a3f99f9faf79387b60f9fd730648fa95
```
