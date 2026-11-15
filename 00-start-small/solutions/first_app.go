package main

import (
	"fmt"
	"os"
	"os/exec"
	"strings"
)

// ============================================================================
// YOUR FIRST BITCOIN PROGRAM (00-start-small/first_app.go)
// ============================================================================
// Goal: Never feel overwhelmed. Every Bitcoin application in the world does
// just 3 basic things with a Bitcoin node:
//   1. Ask the node for the current block height
//   2. Generate a fresh Bitcoin address (bcrt1q...)
//   3. Send satoshis to that address and confirm it in a block
//
// REFERENCE SOLUTION (spoiler). Open only after ../check_first_app.sh passes
// on your own version, or after 3 honest attempts.
//
// Run this file anytime with:
//   go run first_app.go
// Point it at a custom node with BTC_CLI="bitcoin-cli -datadir=..."
// ============================================================================

// askBitcoin runs a bitcoin-cli command against your live local regtest node.
func askBitcoin(args ...string) string {
	name, baseArgs := "bitcoin-cli", []string{"-regtest"}
	if f := strings.Fields(os.Getenv("BTC_CLI")); len(f) > 0 {
		name, baseArgs = f[0], f[1:]
	}
	baseArgs = append(baseArgs, args...)
	out, err := exec.Command(name, baseArgs...).CombinedOutput()
	if err != nil {
		return fmt.Sprintf("Error: %v (%s)", err, strings.TrimSpace(string(out)))
	}
	return strings.TrimSpace(string(out))
}

func main() {
	fmt.Println("====================================================")
	fmt.Println("  MY FIRST BITCOIN APP - TALKING TO LIVE BITCOIND")
	fmt.Println("====================================================")

	// ------------------------------------------------------------------------
	// MICRO-CHALLENGE 1: Change this label to your own project name!
	// ------------------------------------------------------------------------
	myProjectLabel := "stanley_first_step"

	// ------------------------------------------------------------------------
	// MICRO-CHALLENGE 2: Change the BTC amount below (e.g., from "0.21" to "0.50")
	// ------------------------------------------------------------------------
	amountBTC := "0.21"

	// Step 1: Ask Bitcoin for the current block height
	height := askBitcoin("getblockcount")
	fmt.Printf("\n[1] Live Blockchain Height : Block #%s\n", height)

	// Step 2: Check our miner wallet balance
	minerBalance := askBitcoin("-rpcwallet=kisumu_miner", "getbalance")
	fmt.Printf("[2] Miner Wallet Balance   : %s BTC\n", minerBalance)

	// Step 3: Create a brand-new native SegWit (bech32) receiving address
	newAddress := askBitcoin("-rpcwallet=kisumu_merchant", "getnewaddress", myProjectLabel, "bech32")
	fmt.Printf("[3] New Bitcoin Address    : %s (label: %s)\n", newAddress, myProjectLabel)

	// Step 4: Send real regtest Bitcoin to our new address
	// fee_rate is in sat/vB; a fresh regtest node has no fee estimates, so we choose it.
	txid := askBitcoin("-rpcwallet=kisumu_miner", "-named", "sendtoaddress",
		"address="+newAddress, "amount="+amountBTC, "fee_rate=2")
	if strings.HasPrefix(txid, "Error:") {
		fmt.Printf("[4] Send failed: %s\n", txid)
		fmt.Println("The miner wallet needs mature coins (101 blocks on a fresh chain). Mine them, then retry.")
		os.Exit(1)
	}
	fmt.Printf("[4] Sent %s BTC! TXID    : %s\n", amountBTC, txid)

	// Step 5: Check the waiting room (Mempool) before mining
	mempool := askBitcoin("getmempoolinfo")
	fmt.Printf("[5] Mempool before mining  : %s\n", strings.Join(strings.Fields(mempool), " "))

	// Step 6: Mine 1 block so our transaction is permanently etched into the blockchain
	minerAddr := askBitcoin("-rpcwallet=kisumu_miner", "getnewaddress")
	askBitcoin("generatetoaddress", "1", minerAddr)
	newHeight := askBitcoin("getblockcount")
	merchantBalance := askBitcoin("-rpcwallet=kisumu_merchant", "getbalance")

	fmt.Printf("[6] Mined 1 Block! Height  : Block #%s\n", newHeight)
	fmt.Printf("[7] Merchant Confirmed Bal : %s BTC\n", merchantBalance)
	fmt.Println("====================================================")
	fmt.Println("SUCCESS! You just built and ran a real Bitcoin app.")
}
