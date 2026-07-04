#!/usr/bin/env python3
"""The Number Constants Forge.

Generates ~5 MB of Java source declaring every integer from 1 to 100,000 as a
named compile-time constant (public static final int), so that no downstream
service ever has to type a digit again.

Due to the JVM class-file format (both the field count and the constant-pool
count are unsigned 16-bit integers), one class cannot hold all 100,000
constants. They are therefore sharded across four classes of 25,000 each.
Engineering has processed this. See docs/adr/ADR-005.
"""
from __future__ import annotations

import os
import sys

# ---------------------------------------------------------------------------
# The English Number Naming Engine (artisanal, hand-rolled, no dependencies —
# dependencies are a liability, see ai/MODEL_CARD.md)
# ---------------------------------------------------------------------------

UNITS = [
    "", "ONE", "TWO", "THREE", "FOUR", "FIVE", "SIX", "SEVEN", "EIGHT",
    "NINE", "TEN", "ELEVEN", "TWELVE", "THIRTEEN", "FOURTEEN", "FIFTEEN",
    "SIXTEEN", "SEVENTEEN", "EIGHTEEN", "NINETEEN",
]
TENS = [
    "", "", "TWENTY", "THIRTY", "FORTY", "FIFTY", "SIXTY", "SEVENTY",
    "EIGHTY", "NINETY",
]


def name_below_hundred(n: int) -> str:
    if n < 20:
        return UNITS[n]
    tens, units = divmod(n, 10)
    return TENS[tens] + ("_" + UNITS[units] if units else "")


def name_below_thousand(n: int) -> str:
    hundreds, rest = divmod(n, 100)
    parts = []
    if hundreds:
        parts.append(UNITS[hundreds] + "_HUNDRED")
    if rest:
        parts.append(name_below_hundred(rest))
    return "_".join(parts)


def english_name(n: int) -> str:
    """The official, committee-ratified English name of an approved integer."""
    if not 1 <= n <= 100_000:
        raise ValueError(f"{n} is not in the approved inventory of integers")
    thousands, rest = divmod(n, 1000)
    parts = []
    if thousands:
        parts.append(name_below_thousand(thousands) + "_THOUSAND")
    if rest:
        parts.append(name_below_thousand(rest))
    return "_".join(parts)


# ---------------------------------------------------------------------------
# Shard emission
# ---------------------------------------------------------------------------

SHARD_NAMES = ["One", "Two", "Three", "Four"]
SHARD_SIZE = 25_000

HEADER = '''\
package enterprise.constants;

/**
 * {cls} — constants {lo} through {hi} of the approved integer inventory.
 *
 * <p>GENERATED FILE. Each constant was generated exactly once and has not
 * been modified since; the integers themselves predate this codebase and,
 * we are advised, everything else.
 *
 * <p>This class holds {count} of the 100,000 constants. It cannot hold more:
 * the class-file field count and constant-pool count are both unsigned
 * 16-bit values, a limit we have accepted but not forgiven (ADR-005).
 */
public final class {cls} {{

    private {cls}() {{
        // The integers may not be instantiated. They simply are.
    }}

'''


def emit_shard(out_dir: str, shard_index: int, lo: int, hi: int) -> str:
    cls = f"NumberConstantsShard{SHARD_NAMES[shard_index]}"
    path = os.path.join(out_dir, cls + ".java")
    with open(path, "w", encoding="utf-8") as fh:
        fh.write(HEADER.format(cls=cls, lo=lo, hi=hi, count=hi - lo + 1))
        for n in range(lo, hi + 1):
            fh.write(f"    public static final int {english_name(n)} = {n};\n")
        fh.write("}\n")
    return path


def main() -> None:
    out_root = sys.argv[1] if len(sys.argv) > 1 else "build/gen"
    out_dir = os.path.join(out_root, "enterprise", "constants")
    os.makedirs(out_dir, exist_ok=True)

    total_bytes = 0
    for i in range(4):
        lo = i * SHARD_SIZE + 1
        hi = (i + 1) * SHARD_SIZE
        path = emit_shard(out_dir, i, lo, hi)
        size = os.path.getsize(path)
        total_bytes += size
        print(
            f"  » shard {i + 1}/4: {english_name(lo)}..{english_name(hi)}"
            f" ({size:,} bytes of load-bearing Java)"
        )
    print(
        f"  » forged 100,000 artisanal constants"
        f" ({total_bytes:,} bytes; ZERO kept separately in the Foundation vault)"
    )


if __name__ == "__main__":
    main()
