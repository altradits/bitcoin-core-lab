#!/usr/bin/env python3
# Copyright (c) The Bitcoin Core developers
# Distributed under the MIT software license, see the accompanying
# file COPYING or http://www.opensource.org/licenses/mit-license.php.
"""REFERENCE (spoiler) for exercises/mempool_pkgrbf_cluster_skeleton.py."""
from decimal import Decimal
import os
import sys

sys.path.insert(0, os.environ.get("BITCOIN_FUNCTIONAL_DIR", "/Users/mac/bitcoin/test/functional"))

from test_framework.test_framework import BitcoinTestFramework  # noqa: E402
from test_framework.util import assert_equal, assert_raises_rpc_error  # noqa: E402
from test_framework.wallet import MiniWallet  # noqa: E402

CLUSTER_LIMIT = 5


class PkgRbfClusterTest(BitcoinTestFramework):
    def set_test_params(self):
        self.num_nodes = 1
        self.setup_clean_chain = True
        # An unknown option makes bitcoind refuse to start ("Invalid parameter"), so the limit is
        # only passed in Part B, after we detected that the node supports cluster mempool.
        self.extra_args = [[]]

    def make_package(self, coin, parent_fee, child_fee):
        parent = self.wallet.create_self_transfer(utxo_to_spend=coin, fee=parent_fee)
        child = self.wallet.create_self_transfer(utxo_to_spend=parent["new_utxo"], fee=child_fee)
        return [parent["hex"], child["hex"]], [parent["txid"], child["txid"]]

    def run_test(self):
        node = self.nodes[0]
        self.wallet = MiniWallet(node)
        self.generate(self.wallet, 101)
        self.test_package_rbf(node)
        self.test_cluster_limit(node)

    def test_package_rbf(self, node):
        self.log.info("Part A: package RBF")
        coin = self.wallet.get_utxo(confirmed_only=True)
        p1_hex, p1_ids = self.make_package(coin, Decimal("0.00001000"), Decimal("0.00001000"))
        p2_hex, p2_ids = self.make_package(coin, Decimal("0.00002000"), Decimal("0.00020000"))
        p3_hex, p3_ids = self.make_package(coin, Decimal("0.00001500"), Decimal("0.00001500"))

        res = node.submitpackage(p1_hex)
        assert_equal(res["package_msg"], "success")
        assert set(p1_ids) <= set(node.getrawmempool())

        res = node.submitpackage(p2_hex)
        assert_equal(res["package_msg"], "success")
        assert_equal(set(res["replaced-transactions"]), set(p1_ids))
        mempool = set(node.getrawmempool())
        assert set(p2_ids) <= mempool and not (set(p1_ids) & mempool)

        res = node.submitpackage(p3_hex)
        assert "package RBF failed" in res["package_msg"], res["package_msg"]
        assert set(p2_ids) <= set(node.getrawmempool())
        self.generate(node, 1)

    def test_cluster_limit(self, node):
        self.log.info("Part B: cluster count limit")
        if "getmempoolcluster" not in node.help():
            self.log.info("SKIP Part B: this node has no cluster mempool (no getmempoolcluster RPC)")
            return
        self.restart_node(0, extra_args=[f"-limitclustercount={CLUSTER_LIMIT}"])
        self.wallet.rescan_utxos()
        chain = self.wallet.send_self_transfer_chain(from_node=node, chain_length=CLUSTER_LIMIT)
        last = chain[-1]
        assert_equal(node.getmempoolcluster(last["txid"])["txcount"], CLUSTER_LIMIT)
        extra = self.wallet.create_self_transfer(utxo_to_spend=last["new_utxo"])
        assert_raises_rpc_error(-26, "too-large-cluster", node.sendrawtransaction, extra["hex"])


if __name__ == "__main__":
    PkgRbfClusterTest(__file__).main()
