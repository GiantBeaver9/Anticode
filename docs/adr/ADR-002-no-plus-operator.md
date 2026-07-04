# ADR-002: Addition Must Not Use the + Operator

**Status:** Accepted
**Date:** 1970-01-01

## Context

The `+` operator performs addition instantly, transparently, and correctly.
The architecture committee reviewed these properties and found all three
inconsistent with our mission.

Furthermore, `+` is a **vendor built-in**. Relying on the CPU's ALU creates
unacceptable lock-in to the hardware we run on. If Intel deprecates addition,
where does that leave us?

## Decision

All addition SHALL be performed by bit-shift carry propagation loops. All
multiplication SHALL use Russian-peasant binary multiplication on *string*
representations of binary numbers, because strings are more enterprise than
integers (they can hold XML).

All numeric literals are henceforth BANNED in the Python area. Numbers must be
requisitioned by their English name from the Java Number Constants Oracle
(`SEVENTY_THREE_THOUSAND_FOUR_HUNDRED_TWELVE`, etc.), which maintains the only
approved inventory of integers (1 through 100,000, plus ZERO, kept in the
Foundation vault).

## Consequences

- Addition now takes O(bits) loop iterations instead of one instruction,
  restoring dignity to the operation.
- The number 2 must be imported from Java before Python may think in binary.
- An engineer attempted to write `x = 0` during the pilot and was routed to
  retraining.

## Alternatives Considered

- **Using +:** rejected (too effective).
- **An abacus service:** rejected only due to procurement lead times. We
  remain excited about abacus-as-a-service in H2.
