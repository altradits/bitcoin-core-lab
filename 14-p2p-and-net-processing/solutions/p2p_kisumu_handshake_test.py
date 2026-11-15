#!/usr/bin/env python3
"""REFERENCE (spoiler) for exercises/03_p2p_kisumu_handshake_test.py."""
import os
import sys

BITCOIN_ROOT = os.environ.get("BITCOIN_ROOT", os.path.expanduser("~/bitcoin"))
sys.path.insert(0, os.path.join(BITCOIN_ROOT, "test/functional"))

from test_framework.messages import CBlockLocator, msg_getheaders, msg_wtxidrelay  # noqa: E402
from test_framework.p2p import P2PInterface  # noqa: E402
from test_framework.test_framework import BitcoinTestFramework  # noqa: E402
from test_framework.util import assert_equal  # noqa: E402


class HeadersCollector(P2PInterface):
    def __init__(self):
        super().__init__()
        self.headers_received = []

    def on_headers(self, message):
        self.headers_received.extend(message.headers)


class KisumuHandshakeTest(BitcoinTestFramework):
    def set_test_params(self):
        self.num_nodes = 1

    def run_test(self):
        node = self.nodes[0]

        self.log.info("1. ping/pong")
        peer = node.add_p2p_connection(HeadersCollector())
        peer.sync_with_ping()
        assert_equal(len(node.getpeerinfo()), 1)

        self.log.info("2. getheaders from genesis")
        msg = msg_getheaders()
        msg.locator = CBlockLocator()
        msg.locator.vHave = [int(node.getblockhash(0), 16)]
        msg.hashstop = 0
        peer.send_and_ping(msg)
        peer.wait_until(lambda: len(peer.headers_received) >= 200)
        assert_equal(len(peer.headers_received), 200)
        last = peer.headers_received[-1]
        last.rehash()
        assert_equal(last.hash, node.getbestblockhash())

        self.log.info("3. wtxidrelay after verack -> disconnect, but no discouragement")
        with node.assert_debug_log(["wtxidrelay received after verack"]):
            peer.send_message(msg_wtxidrelay())
            peer.wait_for_disconnect()
        again = node.add_p2p_connection(P2PInterface())
        again.sync_with_ping()
        assert_equal(len(node.getpeerinfo()), 1)


if __name__ == "__main__":
    KisumuHandshakeTest(__file__).main()
