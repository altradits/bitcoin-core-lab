#!/usr/bin/env python3
"""REFERENCE (spoiler) for exercises/03_feature_kisumu_reorg_mempool.py (steps 1-4)."""
import os
import sys

BITCOIN_ROOT = os.environ.get("BITCOIN_ROOT", os.path.expanduser("~/bitcoin"))
sys.path.insert(0, os.path.join(BITCOIN_ROOT, "test/functional"))

from test_framework.test_framework import BitcoinTestFramework  # noqa: E402
from test_framework.util import assert_equal  # noqa: E402
from test_framework.wallet import MiniWallet  # noqa: E402


class KisumuReorgMempoolTest(BitcoinTestFramework):
    def set_test_params(self):
        self.num_nodes = 2

    def run_test(self):
        n0, n1 = self.nodes
        wallet = MiniWallet(n0)

        self.disconnect_nodes(0, 1)

        tx = wallet.send_self_transfer(from_node=n0)
        assert tx["txid"] in n0.getrawmempool()
        self.generate(n0, 1, sync_fun=self.no_op)
        assert_equal(n0.getrawmempool(), [])

        self.generate(n1, 2, sync_fun=self.no_op)
        assert n0.getbestblockhash() != n1.getbestblockhash()

        self.connect_nodes(0, 1)
        self.sync_blocks()
        assert_equal(n0.getbestblockhash(), n1.getbestblockhash())

        self.wait_until(lambda: tx["txid"] in n0.getrawmempool())
        entry = n0.getmempoolentry(tx["txid"])
        assert_equal(entry["wtxid"], tx["wtxid"])


if __name__ == "__main__":
    KisumuReorgMempoolTest(__file__).main()
