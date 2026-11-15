#!/usr/bin/env python3
"""YOUR reorg test. Copy to my-work/15-validation-chainstate-and-reorgs/feature_kisumu_reorg_mempool.py.

Spec:
  1. Two nodes. Disconnect them (the framework connects them at start).
  2. Node 0 mines a tx (from MiniWallet) into 1 block. Node 1 independently mines 2 blocks (more work).
  3. Reconnect and sync: node 0 must reorg to node 1's chain.
  4. Assert the tx is back in node 0's mempool (MaybeUpdateMempoolForReorg).
  5. STRETCH (no checker): show that a disconnected tx does NOT come back when it became invalid
     on the new chain. Easiest case: it spends an output that only exists on the reorged-out
     branch (e.g. node 0's own new coinbase is not involved; instead make node 1's chain contain
     a CONFLICTING tx spending the same MiniWallet UTXO). Design it on paper first; read
     test/functional/mempool_reorg.py for the coinbase-maturity variant.

Check: ./15-validation-chainstate-and-reorgs/check_15.sh test
"""
import os
import sys

BITCOIN_ROOT = os.environ.get("BITCOIN_ROOT", "/Users/mac/bitcoin")
sys.path.insert(0, os.path.join(BITCOIN_ROOT, "test/functional"))

from test_framework.test_framework import BitcoinTestFramework  # noqa: E402
from test_framework.util import assert_equal  # noqa: E402,F401
from test_framework.wallet import MiniWallet  # noqa: E402,F401


class KisumuReorgMempoolTest(BitcoinTestFramework):
    def set_test_params(self):
        # TODO
        raise NotImplementedError

    def run_test(self):
        # TODO: split the network (look for disconnect_nodes / connect_nodes in test_framework.py)
        # TODO: tx on node 0, mined in 1 block WITHOUT syncing (sync_fun=self.no_op)
        # TODO: 2 blocks on node 1, without syncing
        # TODO: reconnect, sync_blocks, assert both tips equal node 1's tip
        # TODO: assert the tx is in node 0's mempool again
        raise NotImplementedError


if __name__ == "__main__":
    KisumuReorgMempoolTest(__file__).main()
