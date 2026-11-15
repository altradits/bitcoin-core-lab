#!/usr/bin/env python3
"""YOUR functional test: two nodes, RBF rule 4, P2P eviction, CPFP, block order.

Copy this file to my-work/04-functional-test-framework/kisumu_pos_rbf_test.py and fill every TODO.
Run it with:
    python3 <that file> --configfile=$BITCOIN_ROOT/build/test/config.ini
Check it with:
    ./04-functional-test-framework/check_functional_test.sh

Rules: every TODO is a line (or a few) YOU write. Look up each helper in
$BITCOIN_ROOT/test/functional/test_framework/ (wallet.py, util.py, test_framework.py,
messages.py) before you use it. Do not copy from solutions/ until the checker passes.
"""

from decimal import Decimal
import os
import sys

BITCOIN_ROOT = os.environ.get("BITCOIN_ROOT", "/Users/mac/bitcoin")
sys.path.insert(0, os.path.join(BITCOIN_ROOT, "test/functional"))

# TODO(imports): import the BIP125 sequence constant from test_framework.messages,
#                BitcoinTestFramework, the assert helpers you need from test_framework.util,
#                and MiniWallet from test_framework.wallet.


class KisumuPosRbfCpfpTest(BitcoinTestFramework):  # noqa: F821  (fix by importing)
    def set_test_params(self):
        # TODO: two nodes. Which attribute? (read set_test_params docs in test_framework.py)
        # TODO: this test talks RPC only; say so with supports_cli.
        raise NotImplementedError("set_test_params")

    def run_test(self):
        customer_node = self.nodes[0]
        merchant_node = self.nodes[1]

        # TODO: create a MiniWallet bound to the customer node and take one UTXO from it.

        self.log.info("1. Low-fee original, signalling BIP125, relayed to the merchant")
        # TODO: create (not send) a self-transfer spending that UTXO with the BIP125 sequence and a
        #       200-sat fee. Hint: create_self_transfer(...) takes utxo_to_spend, sequence, fee (in BTC).
        # TODO: broadcast it from the customer node, then make both mempools agree.
        # TODO: assert the merchant has it, that getmempoolentry reports bip125-replaceable True,
        #       and that its base fee is exactly 200 sat.

        self.log.info("2. Rule 4: +50 sat is not enough to pay for relay")
        # TODO: build a conflicting replacement paying 250 sat.
        # TODO: assert sendrawtransaction fails with code -26 and the message fragment that
        #       PaysForRBF returns. (On master the incremental feerate is 0.1 sat/vB: you would
        #       need a much smaller bump to fail. Write in a comment what bump fails on master.)

        self.log.info("3. A valid replacement evicts the original on BOTH nodes")
        # TODO: build and send a replacement paying 5,000 sat, sync, and assert the original is in
        #       neither mempool and the replacement is in the merchant's.

        self.log.info("4. CPFP child from the merchant node")
        # TODO: spend the replacement's new_utxo with a 20,000-sat fee, send it from the MERCHANT,
        #       sync, and on the CUSTOMER node assert ancestorcount, fees.ancestor and depends.

        self.log.info("5. Mine and check topological order")
        # TODO: mine one block with self.generate (why not node.generatetoaddress? read
        #       test_framework.py), then assert tx[1] is the parent and tx[2] the child.
        raise NotImplementedError("run_test")


if __name__ == "__main__":
    KisumuPosRbfCpfpTest(__file__).main()
