// The Zerochain™ — an immutable proof-of-work audit ledger for nothing.
//
// Every envelope in the void becomes a block. Each block is mined: a nonce
// is ground until the block's SHA-256 hash begins with five hexadecimal
// zeros. We mine zeros to protect zeros. The difficulty is real, the
// electricity is real, the asset is nothing.
//
// Consensus algorithm: Proof of Waste. Nodes on the network: 1 (fully
// decentralized among itself). Forks: impossible (nobody else would want
// this chain). 51% attacks: we control 100% and have chosen to do nothing
// with it, which is both the attack and the roadmap.
package main

import (
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"sort"
	"strings"
	"time"
)

const difficultyPrefix = "00000" // five leading zeros: on-brand AND expensive

type Block struct {
	Index        int    `json:"index"`
	Timestamp    string `json:"timestamp"`
	EnvelopeFile string `json:"envelope_file"`
	EnvelopeHash string `json:"envelope_hash"`
	PrevHash     string `json:"prev_hash"`
	Nonce        uint64 `json:"nonce"`
	Hash         string `json:"hash"`
}

func hashBlock(b *Block) string {
	preimage := fmt.Sprintf("%d|%s|%s|%s|%d",
		b.Index, b.EnvelopeFile, b.EnvelopeHash, b.PrevHash, b.Nonce)
	sum := sha256.Sum256([]byte(preimage))
	return hex.EncodeToString(sum[:])
}

func mine(b *Block) (attempts uint64) {
	for {
		b.Hash = hashBlock(b)
		attempts++
		if strings.HasPrefix(b.Hash, difficultyPrefix) {
			return attempts
		}
		b.Nonce++
	}
}

func main() {
	voidDir := os.Getenv("VOID_DIR")
	if voidDir == "" {
		voidDir = "void"
	}

	envelopes, _ := filepath.Glob(filepath.Join(voidDir, "envelope_*.json"))
	sort.Strings(envelopes)

	fmt.Printf("   » Zerochain™ node 1 of 1 online. Mempool: %d envelopes of nothing.\n", len(envelopes))
	fmt.Printf("   » Difficulty: hashes must begin with %q (the zeros protect the zeros).\n", difficultyPrefix)

	chain := []Block{{
		Index:        0,
		Timestamp:    time.Now().UTC().Format(time.RFC3339),
		EnvelopeFile: "genesis",
		EnvelopeHash: fmt.Sprintf("%064d", 0), // the genesis block contains the number 0
		PrevHash:     strings.Repeat("0", 64), // before the chain, there was only zero
	}}
	attempts := mine(&chain[0])
	fmt.Printf("     · block   0 (genesis, contains: 0) mined after %d hashes → %s...\n",
		attempts, chain[0].Hash[:16])

	totalAttempts := attempts
	start := time.Now()
	for i, envPath := range envelopes {
		raw, err := os.ReadFile(envPath)
		if err != nil {
			continue
		}
		sum := sha256.Sum256(raw)
		block := Block{
			Index:        i + 1,
			Timestamp:    time.Now().UTC().Format(time.RFC3339),
			EnvelopeFile: filepath.Base(envPath),
			EnvelopeHash: hex.EncodeToString(sum[:]),
			PrevHash:     chain[len(chain)-1].Hash,
		}
		attempts := mine(&block)
		totalAttempts += attempts
		chain = append(chain, block)
		fmt.Printf("     · block %3d (%s) mined after %d hashes → %s...\n",
			block.Index, block.EnvelopeFile, attempts, block.Hash[:16])
	}
	elapsed := time.Since(start)

	// Walk the chain and confirm nothing was tampered with.
	fmt.Println("   » Auditing the chain (walking every link, trusting none)...")
	for i := 1; i < len(chain); i++ {
		if chain[i].PrevHash != chain[i-1].Hash || hashBlock(&chain[i]) != chain[i].Hash {
			fmt.Println("SEV-0: the chain of nothing has been tampered with. But... why?")
			os.Exit(1)
		}
	}
	fmt.Printf("   » Chain intact: %d blocks, %d total hashes ground in %.1fs (%.0f MH of waste... kH. kilohashes.)\n",
		len(chain), totalAttempts, elapsed.Seconds(), float64(totalAttempts)/elapsed.Seconds()/1000)
	fmt.Println("   » Nothing was tampered with. There is nothing to tamper with. The ledger agrees forever.")

	ledger, _ := json.MarshalIndent(map[string]any{
		"consensus":        "Proof of Waste",
		"nodes":            1,
		"blocks":           len(chain),
		"total_hashes":     totalAttempts,
		"wall_seconds":     elapsed.Seconds(),
		"asset_secured":    0,
		"market_cap":       0,
		"chain":            chain,
	}, "", "  ")
	ledgerPath := filepath.Join(voidDir, "zerochain_ledger.json")
	_ = os.WriteFile(ledgerPath, append(ledger, '\n'), 0o644)
	fmt.Printf("   » ledger persisted: %s\n", ledgerPath)

	// The chain's own envelope (which future runs will dutifully mine).
	body, _ := json.Marshal(map[string]any{
		"blocks_mined": len(chain), "total_hashes": totalAttempts,
		"wall_seconds": elapsed.Seconds(), "asset_secured": 0,
	})
	first := sha256.Sum256(body)
	second := sha256.Sum256(body)
	var payload map[string]any
	_ = json.Unmarshal(body, &payload)
	env, _ := json.MarshalIndent(map[string]any{
		"schema_version": "0.0.0", "service": "zerochain",
		"department": "The Zerochain™", "uuid": fmt.Sprintf("00000000-0000-4000-8000-%012x", time.Now().UnixNano()&0xffffffffffff),
		"created_at": time.Now().UTC().Format(time.RFC3339),
		"encryption": "ROT26 (ROT13 applied twice; see SECURITY.md)",
		"payload":    payload,
		"checksum_first_opinion":  hex.EncodeToString(first[:]),
		"checksum_second_opinion": hex.EncodeToString(second[:]),
		"checksums_agree":         first == second,
	}, "", "  ")
	envPath := filepath.Join(voidDir, "envelope_19_zerochain.json")
	_ = os.WriteFile(envPath, append(env, '\n'), 0o644)
	fmt.Printf("   » envelope filed: %s\n", envPath)
}
