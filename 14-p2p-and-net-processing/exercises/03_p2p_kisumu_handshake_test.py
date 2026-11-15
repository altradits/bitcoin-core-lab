#!/usr/bin/env python3
"""YOUR P2P functional test. Copy to my-work/14-p2p-and-net-processing/p2p_kisumu_handshake_test.py.

Three parts, each a few lines YOU write:
  1. ping/pong: prove the node processes your messages in order.
  2. getheaders/headers: ask for headers from genesis and check what comes back.
  3. late wtxidrelay: send it AFTER verack and assert the node disconnects you,
     and that it did NOT discourage you (a new connection from the same address still works).

Check: ./14-p2p-and-net-processing/check_14.sh test
Helpers live in $BITCOIN_ROOT/test/functional/test_framework/{p2p.py,messages.py,test_node.py}.
"""
import os
import sys

BITCOIN_ROOT = os.environ.get("BITCOIN_ROOT", os.path.expanduser("~/bitcoin"))
sys.path.insert(0, os.path.join(BITCOIN_ROOT, "test/functional"))

from test_framework.messages import CBlockLocator, msg_getheaders, msg_wtxidrelay  # noqa: E402,F401
from test_framework.p2p import P2PInterface  # noqa: E402
from test_framework.test_framework import BitcoinTestFramework  # noqa: E402
from test_framework.util import assert_equal  # noqa: E402,F401


class HeadersCollector(P2PInterface):
    def __init__(self):
        super().__init__()
        self.headers_received = []

    def on_headers(self, message):
        # TODO: remember every header you receive (message.headers is a list of CBlockHeader)
        raise NotImplementedError


class KisumuHandshakeTest(BitcoinTestFramework):
    def set_test_params(self):
        # TODO: one node is enough. Start from the cached 200-block chain.
        raise NotImplementedError

    def run_test(self):
        node = self.nodes[0]

        self.log.info("1. ping/pong")
        # TODO: add a HeadersCollector connection; use the helper that sends a ping and waits for
        #       the matching pong. Then assert getpeerinfo shows exactly one peer.

        self.log.info("2. getheaders from genesis")
        # TODO: build a msg_getheaders whose locator contains only the genesis hash (as an int!),
        #       hashstop 0. Send it and wait until headers arrive.
        # TODO: assert you received 200 headers and that the last one's hash equals the node's tip.
        #       (29.x: header.rehash() then header.hash; master: header.hash_hex. Read messages.py.)

        self.log.info("3. wtxidrelay after verack -> disconnect, but no discouragement")
        # TODO: send msg_wtxidrelay on the (already verack'd) connection and wait for disconnect.
        # TODO: prove the node did not discourage you: open a NEW P2PInterface connection and
        #       assert it completes the handshake; optionally use assert_debug_log to check the
        #       exact log line from ProcessMessage.
        raise NotImplementedError


if __name__ == "__main__":
    KisumuHandshakeTest(__file__).main()
