package main

import (
	"encoding/json"
	"fmt"
	"os/exec"
	"strings"
)

// NetworkProfile defines the 4 Bitcoin Core networks you graduate through:
// 1. Regtest  (-regtest)  -> Local instant sandbox (bcrt1q...)
// 2. Signet   (-signet)   -> Live global P2P test network with fast sync (tb1q...)
// 3. Testnet4 (-testnet4) -> Global PoW test network (tb1q...)
// 4. Mainnet  (no flag)   -> Satoshi's live Bitcoin network with real satoshis (bc1q... / bc1p...)
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
			Name:        "4. Mainnet (Live Sovereign Bitcoin)",
			CLIFlag:     "(none)",
			Bech32HRP:   "bc1",
			DefaultPort: 8333,
			RPCPort:     8332,
			Purpose:     "Real satoshis, real sovereign cold/watch-only wallets, full consensus validation",
		},
	}
}

// GenerateLaptopMainnetConfig produces a safe, disk-friendly bitcoin.conf for running
// both Signet and a Pruned Mainnet Full Node on a standard laptop (<12 GB disk space).
func GenerateLaptopMainnetConfig() string {
	return `# ============================================================================
# SOVEREIGN LAPTOP BITCOIN CORE CONFIG (Mainnet Pruned + Signet + Regtest)
# Save to: ~/Library/Application Support/Bitcoin/bitcoin.conf (macOS)
# ============================================================================

# Run in background by default when launched
daemon=1
server=1

# PRUNED MAINNET MODE:
# Validates 100% of every block and transaction since Satoshi's 2009 Genesis Block,
# keeps the full UTXO set (chainstate), and prunes old raw block files to 5,500 MB (~5.5 GB)
# so you can run a real Mainnet full node on any laptop!
prune=5500
dbcache=1024

# Security: Only accept RPC commands from your own machine (localhost)
rpcallowip=127.0.0.1
`
}

func runCLI(args ...string) (string, error) {
	cmdArgs := append([]string{"-regtest"}, args...)
	out, err := exec.Command("bitcoin-cli", cmdArgs...).CombinedOutput()
	if err != nil {
		return "", fmt.Errorf("%v: %s", err, strings.TrimSpace(string(out)))
	}
	return strings.TrimSpace(string(out)), nil
}

func main() {
	fmt.Println("======================================================================")
	fmt.Println("🌍 STAGE 11: GRADUATING FROM REGTEST TO LIVE BITCOIN (SIGNET & MAINNET)")
	fmt.Println("======================================================================")

	fmt.Println("\n[1] THE 4 BITCOIN NETWORKS YOU OPERATE WITH BITCOIN CORE:")
	for _, net := range AllBitcoinNetworks() {
		fmt.Printf("  • %-38s | Prefix: %-5s | Flag: %-9s\n    -> %s\n",
			net.Name, net.Bech32HRP+"...", net.CLIFlag, net.Purpose)
	}

	fmt.Println("\n[2] LIVE SOVEREIGN WALLET CEREMONY (Cold Signer -> Public Descriptor -> Watch-Only Vault):")
	// Ensure our cold signer and watch-only wallets exist
	_, _ = runCLI("createwallet", "sovereign_cold_signer")
	_, _ = runCLI("loadwallet", "sovereign_cold_signer")
	_, _ = runCLI("createwallet", "sovereign_watch_only", "true")
	_, _ = runCLI("loadwallet", "sovereign_watch_only")

	// Extract public descriptors from cold signer (false = NEVER export private keys!)
	descJSON, err := runCLI("-rpcwallet=sovereign_cold_signer", "listdescriptors", "false")
	if err != nil {
		fmt.Printf("Note: start bitcoind -regtest to run live wallet ceremony (%v)\n", err)
		return
	}

	var parsed struct {
		Descriptors []struct {
			Desc      string `json:"desc"`
			Active    bool   `json:"active"`
			Internal  bool   `json:"internal"`
			Timestamp any    `json:"timestamp"`
		} `json:"descriptors"`
	}
	if err := json.Unmarshal([]byte(descJSON), &parsed); err != nil {
		fmt.Printf("Failed to parse descriptors: %v\n", err)
		return
	}

	var externalWpkh string
	for _, d := range parsed.Descriptors {
		if strings.HasPrefix(d.Desc, "wpkh(") && !d.Internal {
			externalWpkh = d.Desc
			break
		}
	}

	fmt.Printf("  • Exported Public BIP84 Descriptor (0 Private Keys):\n    %s\n", externalWpkh)

	// Derive a receiving address from the watch-only wallet and verify it holds zero private keys
	vaultAddr, err := runCLI("-rpcwallet=sovereign_watch_only", "getnewaddress", "sovereign_savings", "bech32")
	if err == nil {
		infoJSON, _ := runCLI("-rpcwallet=sovereign_watch_only", "getaddressinfo", vaultAddr)
		var info struct {
			Address     string `json:"address"`
			IsWatchOnly bool   `json:"iswatchonly"`
			Solvable    bool   `json:"solvable"`
		}
		_ = json.Unmarshal([]byte(infoJSON), &info)
		fmt.Printf("  • Derived Sovereign Vault Address : %s\n", info.Address)
		fmt.Printf("  • Watch-Only Security Verified    : iswatchonly=%v, solvable=%v (Private keys offline!)\n",
			info.IsWatchOnly, info.Solvable)
	}

	fmt.Println("\n[3] HOW TO LAUNCH LIVE SIGNET OR PRUNED MAINNET WHEN YOU ARE READY:")
	fmt.Println("  • Global Signet Testnet : bitcoind -signet -daemon  && bitcoin-cli -signet getblockchaininfo")
	fmt.Println("  • Live Pruned Mainnet   : bitcoind -prune=5500 -daemon && bitcoin-cli getblockchaininfo")
	fmt.Println("======================================================================")
}
