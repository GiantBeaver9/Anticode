"""The Fifty Ways — the platform's complete regression suite.

Fifty independent, peer-reviewed demonstrations that 0 == 0. Coverage:
100% of nothing. A single failure here would be the most interesting thing
ever to happen to this repository, and the suite is written in the sincere
hope of a quiet life.
"""
from __future__ import annotations

import math
import struct
import sys
from decimal import Decimal
from fractions import Fraction

WAYS = [
    ("the classic",                        lambda: 0 == 0),
    ("the classic, reversed",              lambda: 0 == 0),  # reviewed; direction confirmed irrelevant; kept
    ("via addition identity",              lambda: 0 + 0 == 0),
    ("via subtraction",                    lambda: 0 - 0 == 0),
    ("via multiplication annihilation",    lambda: 0 * 1_000_000 == 0),
    ("via safe division",                  lambda: 0 / 1 == 0),
    ("via floor division",                 lambda: 0 // 1 == 0),
    ("via modulo",                         lambda: 0 % 1 == 0),
    ("via exponent (0^1)",                 lambda: 0 ** 1 == 0),
    ("via the schism's inner mystery",     lambda: 0 ** 0 == 1),  # 0^0=1: both churches agree HERE
    ("via negation",                       lambda: -0 == 0),
    ("via double negation",                lambda: -(-0) == 0),
    ("via absolute value",                 lambda: abs(0) == 0),
    ("via abs of float negative zero",     lambda: abs(-0.0) == 0),
    ("via bitwise AND",                    lambda: (0 & 0xFFFF) == 0),
    ("via bitwise OR",                     lambda: (0 | 0) == 0),
    ("via bitwise XOR self-cancel",        lambda: (12345 ^ 12345) == 0),
    ("via left shift",                     lambda: (0 << 64) == 0),
    ("via right shift",                    lambda: (0 >> 64) == 0),
    ("via bit inversion round trip",       lambda: ~~0 == 0),
    ("via carry propagation (ADR-002)",    lambda: (0 ^ 0) | ((0 & 0) << 1) == 0),
    ("via int()",                          lambda: int() == 0),
    ("via int('0')",                       lambda: int("0") == 0),
    ("via int of binary string",           lambda: int("0", 2) == 0),
    ("via int of hex string",              lambda: int("0x0", 16) == 0),
    ("via float()",                        lambda: float() == 0),
    ("via float('-0.0')",                  lambda: float("-0.0") == 0),
    ("via complex()",                      lambda: complex() == 0),
    ("via Decimal",                        lambda: Decimal("0") == 0),
    ("via Fraction",                       lambda: Fraction(0, 1) == 0),
    ("via bool arithmetic",                lambda: False + False == 0),
    ("via len of empty string",            lambda: len("") == 0),
    ("via len of empty list",              lambda: len([]) == 0),
    ("via len of empty tuple",             lambda: len(()) == 0),
    ("via len of empty set",               lambda: len(set()) == 0),
    ("via len of empty dict",              lambda: len({}) == 0),
    ("via sum of nothing",                 lambda: sum([]) == 0),
    ("via sum of 100 zeros",               lambda: sum([0] * 100) == 0),
    ("via min of zeros",                   lambda: min(0, 0, 0) == 0),
    ("via max of zeros",                   lambda: max(0, 0, 0) == 0),
    ("via math.floor",                     lambda: math.floor(0.0) == 0),
    ("via math.ceil",                      lambda: math.ceil(0.0) == 0),
    ("via math.trunc",                     lambda: math.trunc(0.999) == 0),
    ("via round",                          lambda: round(0.4) == 0),
    ("via math.sin (trigonometric route)", lambda: math.sin(0) == 0),
    ("via math.log(1) (the scenic route)", lambda: math.log(1) == 0),
    ("via IEEE 754 bit pattern",           lambda: struct.unpack(">d", b"\x00" * 8)[0] == 0),
    ("via string round trip",              lambda: int(str(0)) == 0),
    ("via hash",                           lambda: hash(0) == 0),
    ("via the empty product's shadow",     lambda: math.prod([]) - 1 == 0),
]


def main() -> None:
    print("   THE FIFTY WAYS — asserting 0 == 0 with full institutional variety")
    failures = 0
    for i, (name, way) in enumerate(WAYS, 1):
        ok = way()
        status = "PASS" if ok else "FAIL"
        failures += not ok
        print(f"     [{status}] way {i:>2}/50: {name}")
    if len(WAYS) != 50:
        print(f"   SEV-1: the fifty ways number {len(WAYS)}. recount ordered.")
        sys.exit(1)
    if failures:
        print(f"   SEV-0: {failures} way(s) in which zero is not zero. halt everything.")
        sys.exit(1)
    print("   » all 50 ways agree: zero remains zero. coverage: 100% of nothing.")


if __name__ == "__main__":
    main()
