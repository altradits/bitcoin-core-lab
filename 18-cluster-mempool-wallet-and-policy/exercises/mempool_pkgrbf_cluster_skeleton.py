#!/usr/bin/env python3
# Copyright (c) The Bitcoin Core developers
# Distributed under the MIT software license, see the accompanying
# file COPYING or http://www.opensource.org/licenses/mit-license.php.
"""Stage 18 / Exercise 18.3 skeleton — YOU complete every TODO.

Part A (works on 29.x and master): package RBF.
  1. Submit package P1 = (parent spending coin C, child) with low fees.
  2. Submit package P2 = (different parent spending the SAME coin C, child) paying more.
     Expect P2 to replace P1 (check `replaced-transactions`).
  3. Submit package P3 that conflicts with P2 but pays LESS in total. Expect a
     "package RBF failed" message and P2 still in the mempool.

Part B (master only — cluster mempool): cluster count limit.
  4. With -limitclustercount=<N>, build a chain of N unconfirmed txs, check
     getmempoolcluster(...)['txcount'] == N, then show tx N+1 is rejected with
     "too-large-cluster". On 29.x this RPC does not exist: the test must SKIP Part B
     and say so (detect it, do not hard-code a version).

How to run (from the lab repo root):
  python3 my-work/18-cluster-mempool-wallet-and-policy/mempool_pkgrbf_cluster.py \
      --configfile=<your build>/test/config.ini
For Part B you need a master build: the master worktree you built in Stage 17
(~/bitcoin-fuzz) built with tests, i.e. its build/test/config.ini.
The import path below must point at the matching source tree's test/functional/.
"""
import os
import sys

sys.path.insert(0, os.environ.get("BITCOIN_FUNCTIONAL_DIR", os.path.expanduser("~/bitcoin/test/functional")))

from test_framework.messages import MAX_BIP125_RBF_SEQUENCE  # noqa: E402
from test_framework.test_framework import BitcoinTestFramework  # noqa: E402
from test_framework.util import assert_equal, assert_raises_rpc_error  # noqa: E402,F401
from test_framework.wallet import MiniWallet  # noqa: E402

CLUSTER_LIMIT = 5  # small on purpose: easy to reach


class PkgRbfClusterTest(BitcoinTestFramework):
    def set_test_params(self):
        self.num_nodes = 1
        self.setup_clean_chain = True
        # TODO: pass -limitclustercount only if the node supports it? Decide: what happens if
        #       a 29.x node gets an unknown option? (Try it once and record the result.)
        self.extra_args = [[]]

    def make_package(self, coin, parent_fee, child_fee, seq_offset):
        """Return (list_of_hex, list_of_txids) for a 1-parent-1-child package spending `coin`.
        Use self.wallet.create_self_transfer(...) for the parent (fee=..., utxo_to_spend=...,
        sequence=...) and create_self_transfer(...) again for the child spending the
        parent's 'new_utxo'. Why must the sequence differ between packages that spend the
        same coin with the same fees?"""
        # TODO
        raise NotImplementedError

    def run_test(self):
        node = self.nodes[0]
        self.wallet = MiniWallet(node)
        # TODO: generate enough blocks to the MiniWallet that it has mature coins.

        self.test_package_rbf(node)
        self.test_cluster_limit(node)

    def test_package_rbf(self, node):
        self.log.info("Part A: package RBF")
        # TODO: pick one confirmed coin and build P1 (low fees) and P2 (higher fees) on it.
        # TODO: submitpackage(P1); assert both txids are in getrawmempool().
        # TODO: submitpackage(P2); assert set(result['replaced-transactions']) == P1 txids
        #       and that P1 is gone and P2 is in the mempool.
        # TODO: build P3 conflicting with P2 but paying less; submit; assert
        #       'package RBF failed' is in result['package_msg'] and P2 is still there.
        raise NotImplementedError

    def test_cluster_limit(self, node):
        self.log.info("Part B: cluster count limit")
        # TODO: detect support: is 'getmempoolcluster' listed in node.help()? If not,
        #       self.log.info("SKIP Part B: ...") and return.
        # TODO: restart the node with -limitclustercount=CLUSTER_LIMIT (self.restart_node).
        # TODO: send a chain of CLUSTER_LIMIT txs (MiniWallet has a chain helper),
        #       assert getmempoolcluster(last_txid)['txcount'] == CLUSTER_LIMIT.
        # TODO: create one more child of the last tx; assert_raises_rpc_error(-26,
        #       "too-large-cluster", node.sendrawtransaction, ...).
        raise NotImplementedError


if __name__ == "__main__":
    PkgRbfClusterTest(__file__).main()
