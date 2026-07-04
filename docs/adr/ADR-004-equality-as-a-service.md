# ADR-004: Equality-as-a-Service (No Self-Affirming Code)

**Status:** Accepted
**Date:** 1970-01-01

## Context

It came to our attention that Python code was checking whether `0 == 0` *by
itself* and simply... believing the result. This is self-affirmation. A
process asserting facts about its own numbers is a process grading its own
homework, and our auditors (us) were unable to approve it (we tried; we
convened; see minutes).

## Decision

No process may assert numeric equality using local operators. All equality
verdicts SHALL be requested from `enterprise.EqualityOracle`, which:

1. Starts a **fresh JVM** for every verdict (a warm JVM might carry bias from
   a previous number);
2. Looks the number up **by its English name** in the Number Constants Oracle;
3. Rules `AFFIRMED` or `DENIED`;
4. Exits, taking its knowledge with it.

Because a single verdict costs ~200ms of JVM startup, verifying all 10,000
arithmetic results would take ~33 minutes and exceed the quarterly JVM budget.
The `StatisticalAuditSamplingPolicy` therefore verifies a random sample; the
remainder are stamped **VERIFIED BY EXTRAPOLATION (ISO-NOTHING-9001)**, which
the auditors (still us) accepted immediately.

## Consequences

- Confirming that zero equals zero now involves two programming languages,
  process creation, class loading, and reflection. Confidence has never been
  higher.
- The JVM startup time is no longer overhead; it is **the deliverable**.

## Alternatives Considered

- **Trusting `==`:** rejected. Trust is not a control.
- **A second Python process to check the first:** rejected as self-affirmation
  at the species level.
