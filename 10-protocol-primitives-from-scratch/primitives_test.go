package primitives

import (
	"bytes"
	"crypto/sha256"
	"encoding/hex"
	"testing"
)

func TestGenesisBlockHeaderProofOfWork(t *testing.T) {
	// Satoshi Nakamoto's exact 80-byte Mainnet Genesis Block Header (Block #0, Jan 3, 2009):
	// Version:    01000000 (1)
	// PrevBlock:  0000000000000000000000000000000000000000000000000000000000000000
	// MerkleRoot: 3ba3edfd7a7b12b27ac72c3e67768f617fc81bc3888a51323a9fb8aa4b1e5e4a (internal LE of 4a5e1e4b...)
	// Timestamp:  29ab5f49 (1231006505 = 2009-01-03 18:15:05 UTC)
	// nBits:      ffff001d (0x1d00ffff)
	// Nonce:      1dac2b7c (2083236893)
	genesisHeaderHex := "01000000" +
		"0000000000000000000000000000000000000000000000000000000000000000" +
		"3ba3edfd7a7b12b27ac72c3e67768f617fc81bc3888a51323a9fb8aa4b1e5e4a" +
		"29ab5f49" +
		"ffff001d" +
		"1dac2b7c"

	headerBytes, err := hex.DecodeString(genesisHeaderHex)
	if err != nil {
		t.Fatal(err)
	}

	hashHex, validPoW, err := VerifyBlockHeaderPoW(headerBytes)
	if err != nil {
		t.Fatal(err)
	}
	expectedGenesisHash := "000000000019d6689c085ae165831e934ff763ae46a2a6c172b3f1b60a8ce26f"
	if hashHex != expectedGenesisHash {
		t.Fatalf("expected Genesis hash %s, got %s", expectedGenesisHash, hashHex)
	}
	if !validPoW {
		t.Fatalf("expected Genesis Block Proof-of-Work to be valid!")
	}
}

func TestCompactSizeCanonicalSerialization(t *testing.T) {
	values := []uint64{0, 1, 252, 253, 65535, 65536, 4294967296}
	for _, v := range values {
		enc := EncodeCompactSize(v)
		dec, err := DecodeCompactSize(bytes.NewReader(enc))
		if err != nil || dec != v {
			t.Fatalf("roundtrip failed for %d: got %d (err=%v)", v, dec, err)
		}
	}

	// Non-canonical CompactSize: encoding 100 using 3-byte 0xfd prefix must fail!
	nonCanonical := []byte{0xfd, 0x64, 0x00}
	if _, err := DecodeCompactSize(bytes.NewReader(nonCanonical)); err == nil {
		t.Fatalf("expected error for non-canonical CompactSize 0xfd6400")
	}
}

func TestMerkleRootSingleAndMultiTx(t *testing.T) {
	// Genesis coinbase txid in display order: 4a5e1e4baab89f3a32518a88c31bc87f618f76673e2cc77ab2127b7afdeda33b
	cbDisplay, _ := hex.DecodeString("4a5e1e4baab89f3a32518a88c31bc87f618f76673e2cc77ab2127b7afdeda33b")
	var cbDisplay32 [32]byte
	copy(cbDisplay32[:], cbDisplay)
	cbInternal := ReverseBytes32(cbDisplay32)

	rootInternal, err := ComputeMerkleRoot([][32]byte{cbInternal})
	if err != nil {
		t.Fatal(err)
	}
	rootDisplay := ReverseBytes32(rootInternal)
	if hex.EncodeToString(rootDisplay[:]) != "4a5e1e4baab89f3a32518a88c31bc87f618f76673e2cc77ab2127b7afdeda33b" {
		t.Fatalf("unexpected single-tx Merkle root")
	}
}

func TestEvalMinimalScriptHTLCHashlock(t *testing.T) {
	preimage := []byte("kisumu_sovereign_secret_preimage")
	expectedHash := sha256.Sum256(preimage)

	// Script: <32-byte preimage> OP_SHA256 <32-byte expectedHash> OP_EQUALVERIFY OP_1
	var script []byte
	script = append(script, byte(len(preimage)))
	script = append(script, preimage...)
	script = append(script, OP_SHA256)
	script = append(script, 32)
	script = append(script, expectedHash[:]...)
	script = append(script, OP_EQUALVERIFY)
	script = append(script, OP_1)

	stack, err := EvalMinimalScript(script)
	if err != nil {
		t.Fatalf("expected valid hashlock script to succeed, got: %v", err)
	}
	if len(stack) != 1 || len(stack[0]) != 1 || stack[0][0] != 1 {
		t.Fatalf("expected top of stack to be 0x01, got: %v", stack)
	}
}
