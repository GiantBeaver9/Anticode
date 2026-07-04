"""The Roman Numeral Exit-Code Relay.

Corporate policy requires the pipeline's final exit code (0) to be expressed
in Roman numerals before transmission. The Romans, however, did not have a
numeral for zero — a historical gap this module bridges with a fallback
strategy provider, a medieval compatibility adapter, and, finally, a
ten-interpreter matryoshka that carries the resulting nothing back into a
process exit code the modern way: slowly.
"""
from __future__ import annotations

import subprocess
import sys

RELAY_DEPTH = 10


class NoSuchNumberInAncientRomeException(Exception):
    """Raised when Rome is asked for a number Rome declined to invent."""


class RomanNumeralConversionService:
    """Converts integers to Roman numerals, within Rome's product scope."""

    SYMBOLS = [(1000, "M"), (900, "CM"), (500, "D"), (400, "CD"),
               (100, "C"), (90, "XC"), (50, "L"), (40, "XL"),
               (10, "X"), (9, "IX"), (5, "V"), (4, "IV"), (1, "I")]

    def convert(self, n: int) -> str:
        if n == 0:
            raise NoSuchNumberInAncientRomeException(
                "The Roman Empire (est. 753 BC) does not support the "
                "requested feature 'zero'. The feature was added by a "
                "competing civilization and backported by medieval monks. "
                "Consider upgrading."
            )
        out = []
        for value, symbol in self.SYMBOLS:
            while n >= value:
                out.append(symbol)
                n -= value
        return "".join(out)


class NullaHistoricalCompatibilityAdapter:
    """Provides the medieval shim: Bede and friends wrote 'nulla' (nothing),
    or the letter N, where Rome left a gap. We ship the enterprise spelling."""

    def represent_zero(self) -> str:
        return "NVLLA"


class ZeroFallbackStrategyProvider:
    """Catches Rome's refusal and escalates to the middle ages."""

    def __init__(self) -> None:
        self._adapter = NullaHistoricalCompatibilityAdapter()

    def provide(self) -> str:
        return self._adapter.represent_zero()


def relay(depth: int) -> None:
    """Carries the zero through alternating interpreters, one spawn per level."""
    if depth >= RELAY_DEPTH:
        # The bottom of the matryoshka. The zero has arrived. Release it.
        sys.exit(0)
    if depth % 2 == 0:
        # Even levels travel by shell.
        proc = subprocess.run(
            ["sh", "-c", f'exec python3 {__file__} --relay {depth + 1}'])
    else:
        # Odd levels travel by python -c, for balance.
        proc = subprocess.run(
            ["python3", "-c",
             f"import subprocess, sys;"
             f"sys.exit(subprocess.run(['python3', {__file__!r}, '--relay',"
             f" '{depth + 1}']).returncode)"])
    sys.exit(proc.returncode)


def main() -> None:
    print("   » The pipeline wishes to exit 0. Per policy, the 0 must first be")
    print("     rendered in Roman numerals. Contacting Rome...")
    service = RomanNumeralConversionService()
    try:
        numeral = service.convert(0)
    except NoSuchNumberInAncientRomeException as e:
        print(f"     ✖ Rome declines: {e}")
        print("     » Engaging ZeroFallbackStrategyProvider → medieval adapter...")
        numeral = ZeroFallbackStrategyProvider().provide()
    print(f"     ✔ Zero rendered as: {numeral!r} (spelling: enterprise-medieval)")

    print(f"   » Translating {numeral!r} back to an exit code via a {RELAY_DEPTH}-level")
    print("     interpreter matryoshka (python → sh → python → ...):")
    proc = subprocess.run(["python3", __file__, "--relay", "1"])
    print(f"     ✔ the zero emerged from {RELAY_DEPTH} nested processes as exit code"
          f" {proc.returncode}, unchanged, as if the journey meant nothing.")
    print("     (it did. it meant nothing.)")
    sys.exit(proc.returncode)


if __name__ == "__main__":
    if len(sys.argv) == 3 and sys.argv[1] == "--relay":
        relay(int(sys.argv[2]))
    main()
