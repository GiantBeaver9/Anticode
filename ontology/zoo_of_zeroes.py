"""The Zoo of Zeroes & IEEE -0.0 Crisis Unit.

A formal registry of every zero in captivity. Each specimen is interviewed,
its habitat documented, and its value verified — not locally, of course
(ADR-004), but by a freshly started Java Virtual Machine, as is proper.

The unit also maintains the file on negative zero, our most emotionally
complicated resident.
"""
from __future__ import annotations

import math
import struct
import sys
from decimal import Decimal
from fractions import Fraction

sys.path.insert(0, ".")
from nothingness_sdk import ORACLE, file_envelope

SPECIMENS = [
    ("int 0",             0,             "the reference specimen; all others are judged against it"),
    ("float 0.0",         0.0,           "same value, more paperwork (52 bits of mantissa, all idle)"),
    ("float -0.0",        -0.0,          "see crisis report below"),
    ("complex 0j",        0j,            "spins in an extra dimension; still gets nowhere"),
    ("Decimal('0')",      Decimal("0"),  "banker's zero; audited quarterly out of habit"),
    ("Decimal('0.000')",  Decimal("0.000"), "the same zero wearing three significant figures"),
    ("Fraction(0, 1)",    Fraction(0, 1), "zero, expressed as a ratio, for the theorists"),
    ("False",             False,         "zero with opinions"),
]

EMPTINESS_EXHIBIT = [
    ("empty set",    set(),   "contains every zero that isn't here"),
    ("empty string", "",      "the shortest possible story about nothing"),
    ("empty tuple",  (),      "an arrangement of no things, immutably"),
    ("empty list",   [],      "like the tuple, but anxious about change"),
]

UNICODE_ZERO_GLYPHS = [
    ("DIGIT ZERO",                 "0"),
    ("ARABIC-INDIC DIGIT ZERO",    "٠"),
    ("BENGALI DIGIT ZERO",         "০"),
    ("THAI DIGIT ZERO",            "๐"),
    ("IDEOGRAPHIC NUMBER ZERO",    "〇"),
    ("FULLWIDTH DIGIT ZERO",       "０"),
    ("MATHEMATICAL DOUBLE-STRUCK", "𝟘"),
]


def bits_of(x: float) -> str:
    return format(struct.unpack(">Q", struct.pack(">d", x))[0], "064b")


def main() -> None:
    print("   » The Zoo of Zeroes opens its gates. Please do not feed the specimens (they require nothing).")
    print()
    print("   REGISTRY OF NUMERIC SPECIMENS")

    verified = 0
    for name, specimen, dossier in SPECIMENS:
        as_int = int(specimen.real if isinstance(specimen, complex) else specimen)
        verdict = ORACLE.rule("ZERO", as_int)
        verified += verdict
        print(f"     [{'AFFIRMED' if verdict else 'DENIED':8s}] {name:<18s} — {dossier}")

    print()
    print("   EMPTINESS EXHIBIT (adjacent to zero; not numbers; kept for morale)")
    for name, specimen, dossier in EMPTINESS_EXHIBIT:
        print(f"     [len={len(specimen)}]     {name:<13s} — {dossier}")

    print()
    print("   UNICODE GLYPH WING (all render to the same inventory item)")
    for label, glyph in UNICODE_ZERO_GLYPHS:
        value = int(glyph) if glyph.isdigit() else 0  # 〇 abstains from int()
        verdict = ORACLE.rule("ZERO", value)
        verified += verdict
        print(f"     [{'AFFIRMED' if verdict else 'DENIED':8s}] {glyph}  U+{ord(glyph):04X} {label}")

    # ── The crisis ──────────────────────────────────────────────────────
    pos, neg = 0.0, -0.0
    print()
    print("   INCIDENT REPORT: NEGATIVE ZERO (ongoing since 1985)")
    print(f"     0.0 == -0.0 ............. {pos == neg}   (IEEE 754 says they are equal)")
    print(f"     bits of  0.0 ............ {bits_of(pos)}")
    print(f"     bits of -0.0 ............ {bits_of(neg)}")
    print(f"     copysign(1, -0.0) ....... {math.copysign(1, neg):+.0f}   (and yet it REMEMBERS)")
    print("     Assessment: two zeros, equal in value, different in bit pattern.")
    print("     The specimen is equal to itself and also visibly not. The unit")
    print("     has filed a bug against IEEE 754. Status: CLOSED WONTFIX (1985).")
    print("     The specimen has been given a private enclosure and a sign bit.")

    file_envelope("21", "zoo_of_zeroes", "Zoo of Zeroes & IEEE -0.0 Crisis Unit", {
        "specimens_registered": len(SPECIMENS) + len(UNICODE_ZERO_GLYPHS),
        "specimens_verified_by_jvm": verified,
        "emptiness_exhibits": len(EMPTINESS_EXHIBIT),
        "negative_zero_equal_to_zero": pos == neg,
        "negative_zero_bitwise_identical": bits_of(pos) == bits_of(neg),
        "ieee_bug_status": "CLOSED WONTFIX (1985)",
        "escaped_specimens": 0,
    })
    print()
    print(f"   » {verified} specimens verified by {verified} JVMs. The zoo rests.")


if __name__ == "__main__":
    main()
