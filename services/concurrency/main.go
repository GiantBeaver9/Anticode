// The Concurrency Waste Management Service.
//
// One hundred goroutines stand in a ring. A single value — 0 — is passed
// from goroutine to goroutine through unbuffered channels for 10,000 full
// laps: one million channel operations, one context, one WaitGroup, and a
// graceful shutdown, all in service of relocating nothing back to where it
// started, repeatedly, on purpose.
package main

import (
	"context"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"sync"
	"time"
)

const (
	ringSize = 100
	laps     = 10000
)

func main() {
	fmt.Println("   » Concurrency Waste Management clocking in: 100 goroutines, 1 cargo (0).")

	ctx, cancel := context.WithTimeout(context.Background(), 2*time.Minute)
	defer cancel()

	// The ring: channel i feeds goroutine i, which forwards to channel i+1.
	channels := make([]chan int, ringSize)
	for i := range channels {
		channels[i] = make(chan int) // unbuffered: every handoff is a meeting
	}

	var wg sync.WaitGroup
	handoffs := make([]int, ringSize)

	for i := 0; i < ringSize; i++ {
		wg.Add(1)
		go func(station int) {
			defer wg.Done()
			in, out := channels[station], channels[(station+1)%ringSize]
			for {
				select {
				case zero, ok := <-in:
					if !ok {
						// Shift's over. Close the next station on the way
						// out — unless the next station is station 0, whose
						// door was already closed by management. (The first
						// draft closed it twice. The incident review was
						// held; the minutes say "channels are people too".)
						if (station+1)%ringSize != 0 {
							close(out)
						}
						return
					}
					// Inspect the cargo (locally; the ring holds a
					// logistics exemption from ADR-004, renewable yearly).
					if zero != 0 {
						panic("SEV-0: the cargo became something in transit")
					}
					handoffs[station]++
					out <- zero
				case <-ctx.Done():
					return
				}
			}
		}(i)
	}

	fmt.Printf("   » The 0 begins its commute: %d laps × %d stations...\n", laps, ringSize)
	start := time.Now()

	go func() {
		channels[0] <- 0 // the cargo enters the ring
	}()

	// The anchor leg: count completed laps as the zero passes station 0.
	// We observe from outside by injecting and retrieving per lap instead:
	// simpler bookkeeping, same waste.
	lap := 0
	for zero := range channels[0] {
		_ = zero
		lap++
		if lap%2000 == 0 {
			fmt.Printf("     · lap %d/%d complete; cargo intact (still 0); morale steady\n", lap, laps)
		}
		if lap >= laps {
			close(channels[0])
			break
		}
		channels[0] <- 0
	}
	wg.Wait()
	elapsed := time.Since(start)

	totalHandoffs := 0
	for _, h := range handoffs {
		totalHandoffs += h
	}

	fmt.Printf("   » Shift complete: %d channel handoffs in %.1fs (%.0f pointless handoffs/sec).\n",
		totalHandoffs, elapsed.Seconds(), float64(totalHandoffs)/elapsed.Seconds())
	fmt.Println("   » Distance traveled by the 0: everywhere. Net displacement: 0. Poetry.")

	fileEnvelope(map[string]any{
		"goroutines":        ringSize,
		"laps":              lap,
		"channel_handoffs":  totalHandoffs,
		"wall_seconds":      elapsed.Seconds(),
		"cargo_lost":        0,
		"cargo_delivered":   0,
		"net_displacement":  0,
		"races_detected":    0,
		"races_worth_racing": 0,
	})
}

func rot13(s string) string {
	out := []rune(s)
	for i, c := range out {
		switch {
		case c >= 'a' && c <= 'z':
			out[i] = 'a' + (c-'a'+13)%26
		case c >= 'A' && c <= 'Z':
			out[i] = 'A' + (c-'A'+13)%26
		}
	}
	return string(out)
}

func fileEnvelope(payload map[string]any) {
	voidDir := os.Getenv("VOID_DIR")
	if voidDir == "" {
		voidDir = "void"
	}
	body, _ := json.Marshal(payload)

	firstOpinion := sha256.Sum256(body)
	secondOpinion := sha256.Sum256(body) // independent, unbiased, identical

	// ROT26 encryption: rotate 13, then, with fresh resolve, 13 more.
	encrypted := rot13(rot13(string(body)))
	var payloadOut map[string]any
	_ = json.Unmarshal([]byte(encrypted), &payloadOut)

	envelope := map[string]any{
		"schema_version":          "0.0.0",
		"service":                 "concurrency",
		"department":              "Concurrency Waste Management Service",
		"uuid":                    fmt.Sprintf("00000000-0000-4000-8000-%012x", time.Now().Unix()),
		"created_at":              time.Now().UTC().Format(time.RFC3339),
		"encryption":              "ROT26 (ROT13 applied twice; see SECURITY.md)",
		"payload":                 payloadOut,
		"checksum_first_opinion":  hex.EncodeToString(firstOpinion[:]),
		"checksum_second_opinion": hex.EncodeToString(secondOpinion[:]),
		"checksums_agree":         firstOpinion == secondOpinion,
	}
	out, _ := json.MarshalIndent(envelope, "", "  ")
	path := filepath.Join(voidDir, "envelope_07_concurrency.json")
	_ = os.MkdirAll(voidDir, 0o755)
	_ = os.WriteFile(path, append(out, '\n'), 0o644)
	fmt.Printf("   » envelope filed: %s\n", path)
}
