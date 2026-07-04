#!/usr/bin/env python3
"""Zero-Width Steganography Decoder, Clearance Level: ANY.

Extracts the secret message hidden in a document's zero-width Unicode
characters. Encoding scheme (patent abandoned):

    U+200B ZERO WIDTH SPACE      -> bit 0
    U+200C ZERO WIDTH NON-JOINER -> bit 1

Eight bits per byte, most significant bit first, trailing NUL bytes are
padding. The security of this scheme rests entirely on the message.
"""
import sys

ZERO_BIT = "​"
ONE_BIT = "‌"


def decode(text: str) -> bytes:
    bits = [c for c in text if c in (ZERO_BIT, ONE_BIT)]
    out = bytearray()
    for i in range(0, len(bits) - len(bits) % 8, 8):
        byte = 0
        for b in bits[i : i + 8]:
            byte = (byte << 1) | (b == ONE_BIT)
        out.append(byte)
    return bytes(out)


def main() -> None:
    path = sys.argv[1] if len(sys.argv) > 1 else "README.md"
    with open(path, encoding="utf-8") as fh:
        text = fh.read()

    carriers = sum(text.count(c) for c in (ZERO_BIT, ONE_BIT))
    payload = decode(text).rstrip(b"\x00")

    print("ZERO-WIDTH STEGANOGRAPHY DECODER v0.0.0")
    print(f"  document scanned .......... {path}")
    print(f"  invisible bits recovered .. {carriers}")
    print(f"  payload after unpadding ... {len(payload)} bytes")
    print(f"  decoded message ........... {payload.decode('utf-8', 'replace')!r}")
    print()
    if payload:
        print("  ALERT: the secret contains something. This violates policy.")
        sys.exit(1)
    print("  The secret is, as designed, nothing. It was hidden in plain")
    print("  sight, invisibly, and it was worth it.")


if __name__ == "__main__":
    main()
