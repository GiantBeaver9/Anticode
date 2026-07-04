# ADR-005: On the Sharding of the 100,000 Constants (A Lament)

**Status:** Accepted, bitterly
**Date:** 1970-01-01

## Context

Product requested that every integer from 1 to 100,000 exist as a named Java
constant (`public static final int ONE = 1;` and so on). Engineering scoped
this at one file. Engineering was wrong, and this document is Engineering
processing that.

The JVM class file format stores its field count in an unsigned 16-bit
integer: **a class may hold at most 65,535 fields**. Worse, the constant pool
count is *also* u2, and each named constant consumes multiple pool entries
(a UTF-8 name, an integer value, structural references). In practice a class
holds well under 65,535 named integer constants.

We asked whether the JVM could be patched. We were asked to leave.

## Decision

The constants SHALL be sharded across four classes of 25,000 constants each
(`NumberConstantsShardOne` … `NumberConstantsShardFour`), keeping every shard
comfortably inside both the field limit and the constant-pool limit. The
number ZERO, being load-bearing, lives alone in `NumberConstantsFoundation`,
in a vault of javadoc.

## Consequences

- Locating a constant now requires knowing which shard governs its range,
  a lookup service exists solely for this, and we are at peace with that.
- `javac` spends several seconds compiling ~5 MB of generated source on every
  build. This was originally listed under "Consequences (negative)" and was
  moved to "Consequences (positive)" after a vote.
- Sixty-five thousand five hundred and thirty-five is itself a number we
  cannot currently name (it exceeds 100,000? No — it does not. It is however
  outside the approved inventory of *needed* numbers. A follow-up ADR will
  not address this.)

## Alternatives Considered

- **An enum:** rejected; enums imply the numbers might be *chosen between*,
  which is divisive.
- **A HashMap:** rejected; hash maps are nondeterministic vibes and we
  already have a Julia department for that.
