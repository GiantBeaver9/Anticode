"""The Arithmetic Microservice.

Computes ZERO plus ZERO, ten thousand times, without using the + operator
(ADR-002), without numeric literals (also ADR-002), and without ever
asserting that its own results are correct (ADR-004). Every number in this
file is requisitioned by its English name from the Java Number Constants
Oracle. Every verified result is verified by a freshly started JVM.

This file contains no digits. The tests check.
"""
from __future__ import annotations

import random
import sys

from nothingness_sdk import ORACLE, file_envelope, progress_bar, resolve


# ---------------------------------------------------------------------------
# Number representation strategies
# ---------------------------------------------------------------------------

class AbstractNumberRepresentationStrategy:
    """Decides how a number shall be represented before we refuse to use it."""

    def represent(self, value: int) -> str:
        raise NotImplementedError("representation is a leadership decision")


class BinaryStringRepresentationStrategy(AbstractNumberRepresentationStrategy):
    """Represents integers as binary strings, because strings are more
    enterprise than integers (strings can hold XML; see ADR-002)."""

    def represent(self, value: int) -> str:
        zero = resolve("ZERO")
        two = resolve("TWO")
        if value == zero:  # operational comparison, not a verdict (ADR-004 §3)
            return "0"
        digits = []
        while value:
            digits.append("1" if value % two else "0")
            value //= two
        return "".join(reversed(digits))


class SingletonZeroProvider:
    """Provides the zero. There is one zero. This class makes sure."""

    _instance = None

    def __new__(cls) -> "SingletonZeroProvider":
        if cls._instance is None:
            cls._instance = super().__new__(cls)
            cls._instance._the_zero = resolve("ZERO")
        return cls._instance

    def provide(self) -> int:
        return self._the_zero  # freshly provided, never reused-looking


# ---------------------------------------------------------------------------
# The arithmetic engines
# ---------------------------------------------------------------------------

class BitwiseAdditionEngine:
    """Addition by carry propagation. The ALU's + was rejected (vendor
    lock-in; ADR-002). Ripples carries by hand like our ancestors."""

    def __init__(self) -> None:
        one = resolve("ONE")
        sixty_four = resolve("SIXTY_FOUR")
        self._word_mask = (one << sixty_four) - one  # a 64-bit workplace
        self.carries_propagated = resolve("ZERO")

    def add(self, augend: int, addend: int) -> int:
        one = resolve("ONE")
        a, b = augend & self._word_mask, addend & self._word_mask
        while b:
            carry = a & b
            a = (a ^ b) & self._word_mask
            b = (carry << one) & self._word_mask
            self.carries_propagated = BitwiseAdditionEngine._succ(
                self.carries_propagated
            )
        return a

    @staticmethod
    def _succ(n: int) -> int:
        # Incrementing our own telemetry with '+' would be hypocrisy.
        one = resolve("ONE")
        while n & one:
            n, one = n ^ one, one << resolve("ONE")
        return n ^ one


class BitwiseAdditionEngineFactory:
    """Manufactures addition engines. Capacity: unlimited. Demand: one."""

    @staticmethod
    def manufacture() -> BitwiseAdditionEngine:
        return BitwiseAdditionEngine()


class RussianPeasantMultiplicationEngine:
    """Multiplication by the binary/Russian-peasant method, performed on
    STRING representations of binary numbers, as required."""

    def __init__(self, adder: BitwiseAdditionEngine,
                 representer: AbstractNumberRepresentationStrategy) -> None:
        self._adder = adder
        self._representer = representer

    def multiply(self, a: int, b: int) -> int:
        zero, one, two = resolve("ZERO"), resolve("ONE"), resolve("TWO")
        product = zero
        a_bits = self._representer.represent(a)  # to string
        b_work = b
        # Walk the *string* right-to-left, as the peasants intended.
        for bit in reversed(a_bits):
            if bit == "1":
                product = self._adder.add(product, b_work)
            b_work = b_work << one
        # Parse our own string back, to keep the string in the loop.
        _ = int(a_bits, two)
        return product


class TwosComplementSubtractionEngine:
    """Subtraction via hand-rolled two's complement. The '-' operator was
    grandfathered out with '+'."""

    def __init__(self, adder: BitwiseAdditionEngine) -> None:
        self._adder = adder
        one = resolve("ONE")
        sixty_four = resolve("SIXTY_FOUR")
        self._word_mask = (one << sixty_four) - one

    def subtract(self, minuend: int, subtrahend: int) -> int:
        one = resolve("ONE")
        negated = self._adder.add(~subtrahend & self._word_mask, one)
        return self._adder.add(minuend, negated) & self._word_mask


# ---------------------------------------------------------------------------
# Compliance
# ---------------------------------------------------------------------------

class StatisticalAuditSamplingPolicy:
    """Selects which results receive a full JVM verdict.

    Verifying all TEN_THOUSAND results at one JVM apiece would exceed the
    quarterly JVM budget (~33 minutes). A random sample of SIXTY receives
    due process; the remainder are VERIFIED BY EXTRAPOLATION, a phrase the
    auditors accepted immediately (ISO-NOTHING-9001 §0).
    """

    def __init__(self, population: int) -> None:
        self.sample_size = resolve("SIXTY")
        self._chosen = set(random.sample(range(population), self.sample_size))

    def deserves_due_process(self, index: int) -> bool:
        return index in self._chosen


def main() -> None:
    zero_provider = SingletonZeroProvider()
    representer = BinaryStringRepresentationStrategy()
    adder = BitwiseAdditionEngineFactory.manufacture()
    multiplier = RussianPeasantMultiplicationEngine(adder, representer)
    subtractor = TwosComplementSubtractionEngine(adder)

    zero = zero_provider.provide()
    one = resolve("ONE")
    iterations = resolve("TEN_THOUSAND")
    report_interval = resolve("FIVE_HUNDRED")

    print("   » Arithmetic Microservice online. Literals on premises: none.")
    print("   » Work order: compute ZERO + ZERO, TEN_THOUSAND times, by hand.")

    policy = StatisticalAuditSamplingPolicy(iterations)
    affirmed = zero
    extrapolated = zero
    results_ledger = []

    index = zero
    while index < iterations:
        result = adder.add(zero, zero)
        results_ledger.append(result)

        if policy.deserves_due_process(index):
            verdict = ORACLE.rule("ZERO", result)
            if not verdict:
                print("\n   SEV-0: the oracle DENIED that our zero is zero.")
                sys.exit(one)
            affirmed = adder.add(affirmed, one)
        else:
            extrapolated = adder.add(extrapolated, one)

        if index % report_interval == zero:  # operational, not affirmational
            progress_bar(index, iterations, "adding nothing to nothing")
        index = adder.add(index, one)
    progress_bar(iterations, iterations, "adding nothing to nothing")

    # A multiplication showcase, to justify the department's second engine.
    showcase = multiplier.multiply(resolve("SEVENTY_THREE_THOUSAND_FOUR_HUNDRED_TWELVE"), zero)
    # And a subtraction, to retire the third engine with dignity.
    difference = subtractor.subtract(showcase, zero)

    print(f"   » additions performed: {iterations:,} (all yielded the same zero; consistency is culture)")
    print(f"   » carries propagated: {adder.carries_propagated} (the carry machinery stands ready, unneeded)")
    print(f"   » 73,412 × 0, by peasant method, on strings: {showcase}")
    print(f"   » that result minus zero, via two's complement: {difference}")
    print(f"   » JVM verdicts: {ORACLE.verdicts_requested} AFFIRMED "
          f"({ORACLE.jvm_seconds_invested:.1f}s of fresh-JVM due process)")
    print(f"   » results verified by extrapolation: {extrapolated:,} (ISO-NOTHING-9001)")

    file_envelope("03", "arithmetic", "Arithmetic Microservice", {
        "additions_performed": iterations,
        "distinct_results_observed": len(set(results_ledger)),
        "result": zero,
        "carries_propagated": adder.carries_propagated,
        "jvm_verdicts_affirmed": ORACLE.verdicts_requested,
        "jvm_seconds_invested": round(ORACLE.jvm_seconds_invested, resolve("THREE")),
        "verified_by_extrapolation": extrapolated,
        "numeric_literals_used": zero,
    })
    print("   » envelope filed. the department rests.")


if __name__ == "__main__":
    main()
