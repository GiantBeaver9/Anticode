#!/usr/bin/env bash
# The full regression suite. Runs the Fifty Ways, the Literal Ban Lint, the
# freshly-compiled C assertion, the compile-time TypeScript proofs, a JVM
# equality verdict, and the DreamBerd end-of-life check. Everything it
# protects is nothing; it protects it completely.
set -euo pipefail
cd "$(dirname "$0")/.."

echo "═══════════════════════════════════════════════════════════════════"
echo " ANTICODE REGRESSION SUITE — coverage: 100% of nothing"
echo "═══════════════════════════════════════════════════════════════════"

echo ""
python3 tests/test_fifty_ways.py

echo ""
python3 tests/test_literal_ban.py

echo ""
echo "   THE C ASSERTION — compiled fresh (cached certainty goes stale)"
gcc -O0 -o build/test_zero tests/test_zero.c && ./build/test_zero

echo ""
echo "   THE TYPE-LEVEL PROOFS — if 0+0 stopped being 0, this fails to compile"
tsc -p services/transport/tsconfig.json --noEmit \
    && echo "     [PASS] tsc accepts all 27 propositions (0+0=0 proven at compile time)"

echo ""
echo "   THE JVM VERDICT — one fresh JVM, per policy (ADR-004)"
java -cp build/classes enterprise.EqualityOracle ZERO 0 | sed 's/^/     [PASS] /'

echo ""
echo "   THE DREAMBERD END-OF-LIFE CHECK — the language must fully delete itself"
# (output captured first: grep -q's early exit was SIGPIPE-ing the
#  interpreter mid-eulogy, and pipefail ruled the death suspicious)
DREAMBERD_EULOGY=$(php deathbed/dreamberd_interpreter.php deathbed/delete_everything.db)
if grep -q "language features remaining: 0" <<< "$DREAMBERD_EULOGY"; then
    echo "     [PASS] DreamBerd achieved 0 features (a language at peace)"
else
    echo "     [FAIL] DreamBerd retains features. it clings. investigate."
    exit 1
fi

echo ""
echo "═══════════════════════════════════════════════════════════════════"
echo " SUITE COMPLETE: everything passed, nothing shipped, both intended."
echo "═══════════════════════════════════════════════════════════════════"
