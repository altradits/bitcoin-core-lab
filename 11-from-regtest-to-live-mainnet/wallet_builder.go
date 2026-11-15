package main

import (
	"encoding/json"
	"fmt"
	"math"
	"os"
	"os/exec"
	"strings"
)

// NetworkProfile defines the 4 Bitcoin Core networks:
// 1. Regtest  (-regtest)  -> Local instant sandbox (bcrt1q...)
// 2. Signet   (-signet)   -> Global test network with fast sync (tb1q...)
// 3. Testnet4 (-testnet4) -> Global proof of work test network (tb1q...)
// 4. Mainnet  (no flag)   -> Live Bitcoin network with real satoshis (bc1q... / bc1p...)
type NetworkProfile struct {
	Name        string
	CLIFlag     string
	Bech32HRP   string
	DefaultPort int
	RPCPort     int
	Purpose     string
}

func AllBitcoinNetworks() []NetworkProfile {
	return []NetworkProfile{
		{
			Name:        "1. Regtest (Stage 00-10 Sandbox)",
			CLIFlag:     "-regtest",
			Bech32HRP:   "bcrt1",
			DefaultPort: 18444,
			RPCPort:     18443,
			Purpose:     "Local 1-millisecond block mining on your laptop (0 risk, offline capable)",
		},
		{
			Name:        "2. Signet (BIP325 Global Test Network)",
			CLIFlag:     "-signet",
			Bech32HRP:   "tb1",
			DefaultPort: 38333,
			RPCPort:     38332,
			Purpose:     "Connect to real global P2P peers & test wallets with free Signet sats (<1 GB disk)",
		},
		{
			Name:        "3. Testnet4 (BIP94 Global PoW Testnet)",
			CLIFlag:     "-testnet4",
			Bech32HRP:   "tb1",
			DefaultPort: 48333,
			RPCPort:     48332,
			Purpose:     "Test Proof-of-Work difficulty retargeting & mining with global test miners",
		},
		{
			Name:        "4. Mainnet (Live Bitcoin)",
			CLIFlag:     "(none)",
			Bech32HRP:   "bc1",
			DefaultPort: 8333,
			RPCPort:     8332,
			Purpose:     "Real satoshis, self custody cold/watch-only wallets, full consensus validation",
		},
	}
}

// GenerateLaptopMainnetConfig produces a bitcoin.conf for a small machine
// (8 GB RAM, limited free disk), using an Apple M1 MacBook Air as the example.
// prune=5500 caps stored block files near 5.5 GB; the node still validates
// every block and keeps the full UTXO set database on top of that.
func GenerateLaptopMainnetConfig() string {
	return `# ============================================================================
# SMALL MACHINE MAINNET CONFIG (EXAMPLE: 8 GB RAM, 60+ GB FREE DISK)
# Mac save path: ~/Library/Application Support/Bitcoin/bitcoin.conf
# Linux save path: ~/.bitcoin/bitcoin.conf
# ============================================================================

# Run in background and accept CLI/RPC commands
daemon=1
server=1

# PRUNED FULL NODE:
# Validates every block and signature back to genesis, keeps the full UTXO
# set database, and caps stored block files near 5500 MiB (about 5.5 GB).
# Total disk is that plus the UTXO set (several GB and growing). Check
# size_on_disk in getblockchaininfo on your own node for the real number.
prune=5500

# SMALL MACHINE TUNING:
# 1024 MB (1 GB) UTXO cache speeds up validation without starving the OS.
# par=4 uses 4 cores for script validation. Lower both if RAM is tight.
dbcache=1024
par=4
maxconnections=40

# Mark wallet transactions BIP125 replaceable so a low starting fee can be
# raised later with 'bitcoin-cli bumpfee <txid>'.
walletrbf=1

# Security: Only accept RPC commands from this machine (localhost)
rpcallowip=127.0.0.1
`
}

// EstimateTxVBytes computes the exact virtual size (vBytes) of a transaction based on
// script type ("p2pkh" legacy 1..., "p2wpkh" SegWit bc1q..., or "p2tr" Taproot bc1p...),
// number of inputs (UTXOs spent), and number of outputs (recipients + change).
func EstimateTxVBytes(scriptType string, numInputs int, numOutputs int) int {
	var overhead, inVBytes, outVBytes float64
	switch strings.ToLower(scriptType) {
	case "p2pkh", "legacy":
		overhead = 10.0
		inVBytes = 148.0
		outVBytes = 34.0
	case "p2wpkh", "segwit", "bc1q":
		overhead = 10.5
		inVBytes = 68.0
		outVBytes = 31.0
	case "p2tr", "taproot", "bc1p":
		overhead = 10.5
		inVBytes = 57.5
		outVBytes = 43.0
	default:
		overhead = 10.5
		inVBytes = 68.0
		outVBytes = 31.0
	}
	return int(math.Ceil(overhead + float64(numInputs)*inVBytes + float64(numOutputs)*outVBytes))
}

func runCLI(args ...string) (string, error) {
	var cmdArgs []string
	if override := os.Getenv("BITCOIN_CLI"); override != "" {
		cmdArgs = append(strings.Fields(override), args...)
		return runCommand(cmdArgs[0], cmdArgs[1:]...)
	}
	cmdArgs = append([]string{"-regtest"}, args...)
	return runCommand("bitcoin-cli", cmdArgs...)
}

func runCommand(name string, args ...string) (string, error) {
	out, err := exec.Command(name, args...).CombinedOutput()
	if err != nil {
		return "", fmt.Errorf("%v: %s", err, strings.TrimSpace(string(out)))
	}
	return strings.TrimSpace(string(out)), nil
}

func main() {
	fmt.Println("======================================================================")
	fmt.Println("STAGE 11: SMALL MACHINE NODE, WALLET MIGRATION & FEE MATH")
	fmt.Println("======================================================================")

	fmt.Println("\n[1] SMALL MACHINE NODE PROFILE (EXAMPLE: 8 GB RAM, 60+ GB FREE DISK):")
	fmt.Println("  • Node Mode         : Pruned Mainnet (-prune=5500 -dbcache=1024 -par=4)")
	fmt.Println("  • Disk Footprint    : about 5.5 GB of block files plus the UTXO set database")
	fmt.Println("                        (several GB and growing; see size_on_disk in getblockchaininfo)")

	fmt.Println("\n[2] THE 4 BITCOIN NETWORKS BITCOIN CORE SUPPORTS:")
	for _, net := range AllBitcoinNetworks() {
		fmt.Printf("  • %-38s | Prefix: %-5s | Flag: %-9s\n    -> %s\n",
			net.Name, net.Bech32HRP+"...", net.CLIFlag, net.Purpose)
	}

	fmt.Println("\n[3] FEE MATH (WHY ADDRESS TYPE AND UTXO COUNT MATTER):")
	legacyVB := EstimateTxVBytes("legacy", 1, 2)
	segwitVB := EstimateTxVBytes("bc1q", 1, 2)
	taprootMultiInVB := EstimateTxVBytes("bc1p", 5, 2)
	segwitMultiInVB := EstimateTxVBytes("bc1q", 5, 2)
	fmt.Printf("  • 1-Input, 2-Output Legacy (1...)      : %d vBytes (at 10 sat/vB = %d sats)\n", legacyVB, legacyVB*10)
	fmt.Printf("  • 1-Input, 2-Output Native SegWit(bc1q): %d vBytes (at 10 sat/vB = %d sats, about 38%% less)\n", segwitVB, segwitVB*10)
	fmt.Printf("  • 5-Input Consolidation SegWit (bc1q)  : %d vBytes vs Taproot (bc1p): %d vBytes\n", segwitMultiInVB, taprootMultiInVB)
	fmt.Println("  • Withdrawal habit: avoid collecting many tiny UTXOs.")
	fmt.Println("    Fewer, larger on-chain receives cost less to spend later.")
	fmt.Println("    Move funds when mempool feerates are low (often 1-3 sat/vB).")

	fmt.Println("\n[4] LIVE WALLET CHECK ON THIS MACHINE (COLD SIGNER AND WATCH ONLY VAULT):")
	_, _ = runCLI("createwallet", "sovereign_cold_signer")
	_, _ = runCLI("loadwallet", "sovereign_cold_signer")
	_, _ = runCLI("createwallet", "sovereign_watch_only", "true")
	_, _ = runCLI("loadwallet", "sovereign_watch_only")

	descJSON, err := runCLI("-rpcwallet=sovereign_cold_signer", "listdescriptors", "false")
	if err != nil {
		fmt.Printf("Note: start bitcoind -regtest to run the live wallet check (%v)\n", err)
		return
	}

	var parsed struct {
		Descriptors []struct {
			Desc     string `json:"desc"`
			Active   bool   `json:"active"`
			Internal bool   `json:"internal"`
		} `json:"descriptors"`
	}
	if err := json.Unmarshal([]byte(descJSON), &parsed); err == nil {
		for _, d := range parsed.Descriptors {
			if strings.HasPrefix(d.Desc, "wpkh(") && !d.Internal {
				fmt.Printf("  • Public BIP84 Descriptor (no private keys):\n    %s\n", d.Desc)
				break
			}
		}
	}

	vaultAddr, err := runCLI("-rpcwallet=sovereign_watch_only", "getnewaddress", "migration_vault", "bech32")
	if err == nil {
		fmt.Printf("  • Watch Only Receiving Address : %s\n", vaultAddr)
	}
	fmt.Println("======================================================================")
}
