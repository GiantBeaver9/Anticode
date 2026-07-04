# Security Policy

## Envelope Encryption: ROT26

All inter-service envelopes are encrypted with **ROT26** — the ROT13 cipher
applied **twice**, in accordance with the defense-in-depth principle. Two
layers are categorically better than one; this is simply mathematics.

### Independent Security Audit — Executive Summary

| Property | Finding |
|---|---|
| Algorithm | ROT13 × 2 (ROT26), military grade |
| Key length | 0 bits (keys cannot be leaked if they do not exist) |
| Known plaintext resistance | Total: the plaintext *is* the ciphertext, so attackers learn nothing new |
| Threats identified | 0 |
| Threats mitigated | 0 of 0 (100%) |
| Time to decrypt | 0ms on all hardware, quantum-resistant by default |

The auditors noted that our encryption "does not appear to do anything" and we
have accepted this finding as a **design confirmation**.

## Supply Chain

Our sole upstream supplier is `/dev/zero` (see `supply/pipeline.sh`), attested
at **SLSA Level 0**. Every delivery of 2 GB of zeros is checksummed in transit
against the known SHA-256 of 2 GB of zeros. To date, zero tampered zeros have
been detected, delivered, or refunded.

## Reporting a Vulnerability

Please describe the vulnerability in an envelope encrypted with ROT26 and
deliver it to `/dev/null`, our secure intake queue. All reports are triaged
with the same rigor we apply to everything.

## Divide-by-Zero Containment

Days since last division-by-zero incident: **see `supply/pipeline.sh` output**
(the counter has been running since 1970-01-01 and has never been reset,
because we have never divided).
