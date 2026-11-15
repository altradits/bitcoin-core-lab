# Stage 14 Exercise 4: Read and run upstream P2P tests

**Output:** journal answers. Run each test alone with `build/test/functional/test_runner.py <name>`.

1. `p2p_handshake.py` — which service-flag combinations does it try for outbound connections, and
   which ones make the node disconnect? Where is that decided in `net_processing.cpp`?
2. `p2p_v2_transport.py` — how does the test tell a v1 from a v2 connection? What happens when a
   v2 node connects to a v1-only node?
3. `p2p_tx_privacy.py` — what spying technique does it guard against, and how does the test model it?
4. `p2p_invalid_messages.py` — list 4 malformed inputs it sends and the node's reaction to each.
   Which ones lead to discouragement?
5. For one of these tests, make a **mutation**: change one line in `net_processing.cpp` on a
   throwaway branch so the test should fail, rebuild only `bitcoind`, and confirm it fails. Revert.
   (Stage 13 taught single-target rebuilds; Stage 17 teaches more.)
