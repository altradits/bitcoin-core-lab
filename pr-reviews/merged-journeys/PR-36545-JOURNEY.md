# Merged PR #36545 Review Journey: `test: Fix intermittent issue in p2p_initial_headers_sync.py`

- **Author:** `@maflcko`
- **Merged At:** `2026-10-19T03:27:14Z`
- **Final Merged Head Commit:** `fad7637529426f058a3c2409dd137009b14622a4`
- **Local Git Branch in `/Users/mac/bitcoin`:** `pr-36545` (`git -C /Users/mac/bitcoin show pr-36545`)
- **Core Lesson for Reviewers:** How reviewers verify intermittent P2P test fixes (`tACK`, `lightly tested ACK`) and ask architectural questions about deterministic flake hunting (`rr` / `bedrock`).

---

## 1. Original PR Description

```text
Fixes https://github.com/bitcoin/bitcoin/actions/runs/38697071260/job/116296055487?pr=36537#step:11:5104:

```
 test  2026-10-15T07:19:58.731108Z TestFramework (INFO): Check that noban peer1 is not disconnected 
 test  2026-10-15T07:19:58.731159Z TestFramework.p2p (DEBUG): Send message to 127.0.0.1:12392: msg_ping(nonce=00000000) 
 test  2026-10-15T07:19:58.731184Z TestFramework.p2p (DEBUG): Send message to 127.0.0.1:12392: msg_ping(nonce=00000002) 
 node0 2026-10-15T07:19:58.731236Z (mocktime: 2026-10-15T07:48:45Z) [http.01] [httpserver.cpp:1318] [MaybeSendBytesFromBuffer] [http] Sent 148 bytes to client 127.0.0.1:57508 (id=0) 
 node0 2026-10-15T07:19:58.731307Z (mocktime: 2026-10-15T07:48:45Z) [msghand] [logging/timer.h:58] [Log] [lock] ContendedLock: lock contention connman.m_nodes_mutex, ./net.h:1876 started 
 node0 2026-10-15T07:19:58.731317Z (mocktime: 2026-10-15T07:48:45Z) [msghand] [logging/timer.h:58] [Log] [lock] ContendedLock: lock contention connman.m_nodes_mutex, ./net.h:1876 completed (0μs) 
 node0 2026-10-15T07:19:58.731332Z (mocktime: 2026-10-15T07:48:45Z) [msghand] [net_processing.cpp:3836] [ProcessMessage] [net] received: ping (8 bytes) peer=0 
 node0 2026-10-15T07:19:58.731338Z (mocktime: 2026-10-15T07:48:45Z) [msghand] [net.cpp:4220] [PushMessage] [net] sending pong (8 bytes) peer=0 
 node0 2026-10-15T07:19:58.731365Z (mocktime: 2026-10-15T07:48:45Z) [msghand] [net.cpp:4220] [PushMessage] [net] sending ping (8 bytes) peer=0 
 test  2026-10-15T07:19:58.731377Z TestFramework.p2p (DEBUG): Received message from 127.0.0.1:12392: msg_pong(nonce=00000000) 
 node0 2026-10-15T07:19:58.731388Z (mocktime: 2026-10-15T07:48:45Z) [msghand] [net_processing.cpp:6499] [SendMessages] Timeout downloading headers from noban peer, not disconnecting peer=0 
 node0 2026-10-15T07:19:58.731402Z (mocktime: 2026-10-15T07:48:45Z) [msghand] [net.cpp:4220] [PushMessage] [net] sending ping (8 bytes) peer=1 
 node0 2026-10-15T07:19:58.731421Z (mocktime: 2026-10-15T07:48:45Z) [msghand] [net.cpp:4220] [PushMessage] [net] sending getheaders (69 bytes) peer=1 
 node0 2026-10-15T07:19:58.731441Z (mocktime: 2026-10-15T07:48:45Z) [msghand] [net_processing.cpp:6151] [SendMessages] [net] initial getheaders (0) to peer=1 
 node0 2026-10-15T07:19:58.731461Z (mocktime: 2026-10-15T07:48:45Z) [msghand] [net_processing.cpp:3836] [ProcessMessage] [net] received: ping (8 bytes) peer=0 
 node0 2026-10-15T07:19:58.731466Z (mocktime: 2026-10-15T07:48:45Z) [msghand] [net.cpp:4220] [PushMessage] [net] sending pong (8 bytes) peer=0 
 test  2026-10-15T07:19:58.731579Z TestFramework.p2p (DEBUG): Received message from 127.0.0.1:12392: msg_ping(nonce=a011607af5f6e69c) 
 test  2026-10-15T07:19:58.731607Z TestFramework.p2p (DEBUG): Send message to 127.0.0.1:12392: msg_pong(nonce=a011607af5f6e69c) 
 test  2026-10-15T07:19:58.731633Z TestFramework.p2p (DEBUG): Received message from 127.0.0.1:12392: msg_pong(nonce=00000002) 
 node0 2026-10-15T07:19:58.731777Z (mocktime: 2026-10-15T07:48:45Z) [http] [httpserver.cpp:971] [Receive] [http] Received 339 bytes from 127.0.0.1:57508 (id=0): total=3476 buffered=339 
 node0 2026-10-15T07:19:58.731798Z (mocktime: 2026-10-15T07:48:45Z) [http] [httpserver.cpp:1135] [TryReadRequest] [http] Received a POST request for / from 127.0.0.1:57508 (id=0) 
 node0 2026-10-15T07:19:58.731833Z (mocktime: 2026-10-15T07:48:45Z) [http.00] [rpc/request.cpp:246] [parse] [rpc] ThreadRPCServer method=getpeerinfo user=__cookie__ id=32 
 node0 2026-10-15T07:19:58.732118Z (mocktime: 2026-10-15T07:48:45Z) [http.00] [httpserver.cpp:637] [Send] [http] HTTPResponse (status code: 200 size: 2260) added to send buffer for client 127.0.0.1:57508 (id=0) 
 test  2026-10-15T07:19:58.732309Z TestFramework (INFO): Check that exactly 1 of {peer1, peer2} receives a getheaders 
 test  2026-10-15T07:19:58.732370Z TestFramework (ERROR): Unexpected exception: 
                                   Traceback (most recent call last):
                                     File "/home/runner/work/_temp/test/functional/test_framework/test_framework.py", line 146, in main
                                       self.run_test()
                                       ~~~~~~~~~~~~~^^
                                     File "/home/runner/work/_temp/build_ ₿🧪_/test/functional/p2p_initial_headers_sync.py", line 182, in run_test
                                       self.test_noban_peer_timeout()
                                       ~~~~~~~~~~~~~~~~~~~~~~~~~~~~^^
                                     File "/home/runner/work/_temp/build_ ₿🧪_/test/functional/p2p_initial_headers_sync.py", line 177, in test_noban_peer_timeout
                                       self.assert_single_getheaders_recipient([peer1, peer2])
                                       ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~^^^^^^^^^^^^^^^^
                                     File "/home/runner/work/_temp/build_ ₿🧪_/test/functional/p2p_initial_headers_sync.py", line 66, in assert_single_getheaders_recipient
                                       assert_equal(count, 1)
                                       ~~~~~~~~~~~~^^^^^^^^^^
                                     File "/home/runner/work/_temp/test/functional/test_framework/util.py", line 95, in assert_equal
                                       raise AssertionError("not(%s)" % " == ".join(str(arg) for arg in (thing1, thing2) + args))
                                   AssertionError: not(0 == 1)
 test  2026-10-15T07:19:58.733190Z TestFramework (DEBUG): Closing down network thread 
 node0 2026-10-15T07:19:58.733256Z (mocktime: 2026-10-15T07:48:45Z) [http.00] [httpserver.cpp:1318] [MaybeSendBytesFromBuffer] [http] Sent 2260 bytes to client 127.0.0.1:57508 (id=0) 
 test  2026-10-15T07:19:58.733311Z TestFramework.p2p (DEBUG): Received message from 127.0.0.1:58180: msg_ping(nonce=39768d79544b5e40) 
 test  2026-10-15T07:19:58.733337Z TestFramework.p2p (DEBUG): Send message to 127.0.0.1:58180: msg_pong(nonce=39768d79544b5e40) 
 test  2026-10-15T07:19:58.733367Z TestFramework.p2p (DEBUG): Received message from 127.0.0.1:58180: msg_getheaders(locator=CBlockLocator(vHave=[7041830694386478471858881810674310864173988660927928131397671070347943617030]), stop=0000000000000000000000000000000000000000000000000000000000000000) 
 node0 2026-10-15T07:19:58.733447Z (mocktime: 2026-10-15T07:48:45Z) [msghand] [net_processing.cpp:3836] [ProcessMessage] [net] received: pong (8 bytes) peer=0 
 test  2026-10-15T07:19:58.733502Z TestFramework.p2p (DEBUG): Closed connection to: 127.0.0.1:58180 
 node0 2026-10-15T07:19:58.733536Z (mocktime: 2026-10-15T07:48:45Z) [net] [net.cpp:2236] [SocketHandlerConnected] [net] socket closed, disconnecting peer=1 
 node0 2026-10-15T07:19:58.733546Z (mocktime: 2026-10-15T07:48:45Z) [net] [net.cpp:567] [CloseSocketDisconnect] [net] Resetting socket for peer=1 
 node0 2026-10-15T07:19:58.733596Z (mocktime: 2026-10-15T07:48:45Z) [net] [net_processing.cpp:1859] [FinalizeNode] [net] Cleared nodestate for peer=1 
 test  2026-10-15T07:19:58.783870Z TestFramework (INFO): Not stopping nodes as test failed. The dangling processes will be cleaned up later. 
```

Diff to reproduce:

```diff
diff --git a/src/net_processing.cpp b/src/net_processing.cpp
index beec44f55d..85b1e88161 100644
--- a/src/net_processing.cpp
+++ b/src/net_processing.cpp
@@ -87,2 +87,3 @@
 #include <span>
+#include <thread>
 #include <typeinfo>
@@ -5233,2 +5234,7 @@ void PeerManagerImpl::ProcessMessage(Peer& peer, CNode& pfrom, const std::string
             MakeAndPushMessage(pfrom, NetMsgType::PONG, nonce);
+            // TEMPORARY: widen the p2p_initial_headers_sync race window after
+            // its second, nonzero ping has been sent but before SendMessages().
+            if (nonce != 0) {
+                std::this_thread::sleep_for(std::chrono::milliseconds{90});
+            }
         }
```

Cmd to reproduce:

```
./bld-cmake/test/functional/test_runner.py $(for i in {1..20}; do echo -n "p2p_initial_headers_sync.py ";done) -j $( nproc )
```

(fails before this pull and passes after)
```

## 2. Commit & Diff Stat (`git show --stat pr-36545`)

```text
commit fad7637529426f058a3c2409dd137009b14622a4
Author: MarcoFalke <*~=`'#}+{/-|&$^_@721217.xyz>
Date:   Thu Oct 15 17:43:15 2026 +0200

    test: Fix intermittent issue in p2p_initial_headers_sync.py

 test/functional/p2p_initial_headers_sync.py | 13 +++++--------
 1 file changed, 5 insertions(+), 8 deletions(-)
```

## 3. Inline Code Review Comments (Where Reviewers Improved the Code)

_No inline diff comments on this PR (see general comments & reviews below)._

## 4. General Discussion & Maintainer Feedback Thread

### `@Crypt-iQ` (2026-10-16T13:42:07Z)

> Diff to reproduce:

Should the p2p functional tests pass in the presence of similar sleeps basically anywhere in the p2p code? It seems possible to hunt for flakes by running with a custom scheduler with bedrock (`rr` should also work) and then reproduce them easily. For example, out of the ordinary scheduling found a flake in `p2p_eviction.py` (see https://github.com/bitcoin/bitcoin/pull/36470#discussion_r4295233978) that would be fixed by https://github.com/bitcoin/bitcoin/pull/36470.

---

### `@Crypt-iQ` (2026-10-16T14:07:25Z)

tACK fad7637529426f058a3c2409dd137009b14622a4

---

### `@maflcko` (2026-10-16T14:17:27Z)

> Should the p2p functional tests pass in the presence of similar sleeps basically anywhere in the p2p code? It seems possible to hunt for flakes by running with a custom scheduler with bedrock (`rr` should also work) and then reproduce them easily.

Both yes. I haven't gotten around to update my flake-hunter to use bedrock or rr, so it is non-deterministic for now. But I guess no other reviewer will have bedrock/rr running either, so a manual non-deterministic reproducer can't hurt in any case.

---

### `@l0rinc` (2026-10-18T04:50:52Z)

Concept ACK, just had one in https://github.com/bitcoin/bitcoin/actions/runs/38909293051/job/117000761345

---

### `@l0rinc` (2026-10-18T04:59:39Z)

lightly tested ACK fad7637529426f058a3c2409dd137009b14622a4

Thanks for fixing it!

---

## 5. Formal Reviews & Final `ACK`s

_All ACKs were posted in the general discussion thread above._
