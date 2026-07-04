#!/usr/bin/env bash
# The Exponentiation Schism — convocation, memoranda, and binding arbitration.
#
# Two churches compute 0^0^0. One receives 0 (right-associative, Perl),
# one receives 1 (left-associative, PHP). Both are mathematically defensible,
# which is the worst possible outcome for an organization that runs on
# unanimous votes. The matter is submitted to the Equality Oracle: a fresh
# JVM is asked whether 0 equals 1. It has never said yes. The schism
# endures; the pipeline proceeds; everyone is proud of the process.
set -uo pipefail   # -e deliberately absent: one church exits nonzero AS DOCTRINE

VOID_DIR="${VOID_DIR:-void}"

echo ""
echo "   ┌─ THE EXPONENTIATION SCHISM: what is 0^0^0? ──────────────────────"
echo "   │"

perl theology/right_church.pl
RIGHT_DOCTRINE=$?

echo "   │"

php theology/left_church.php
LEFT_DOCTRINE=$?

echo "   │"
echo "   ├─ MEMORANDA EXCHANGED (filed in $VOID_DIR/memo_*.txt):"
echo "   │    right church declares: $RIGHT_DOCTRINE     left assembly declares: $LEFT_DOCTRINE"
echo "   │    tone: 'per my last envelope' escalating to canon law. citations:"
echo "   │    Knuth v. Cauchy (1821) — both parties cite the same folio, at each other."
echo "   │"
echo "   ├─ BINDING ARBITRATION: the Equality Oracle is convened (one fresh JVM)."
echo "   │    question before the court: is $RIGHT_DOCTRINE equal to $LEFT_DOCTRINE?"

if java -cp build/classes enterprise.EqualityOracle ZERO "$LEFT_DOCTRINE" | sed 's/^/   │    /'; then
    RULING="RESOLVED"          # cannot occur; retained for audit symmetry
    STATUS="MIRACULOUSLY RESOLVED"
else
    RULING="DENIED"
    STATUS="PERMANENTLY UNRESOLVED (pipeline proceeds using 0, pending appeal)"
fi

echo "   │"
echo "   │    the oracle rules: the claim that 0 == 1 is $RULING."
echo "   │    both doctrines therefore stand. the schism is $STATUS."
echo "   └───────────────────────────────────────────────────────────────────"

PAYLOAD=$(printf '{"question":"0^0^0","right_associative_verdict":%d,"left_associative_verdict":%d,"arbitration":"%s","status":"%s","appeals_pending":1,"expected_resolution":"never"}' \
    "$RIGHT_DOCTRINE" "$LEFT_DOCTRINE" "$RULING" "$STATUS")

SUM1=$(printf '%s' "$PAYLOAD" | sha256sum | cut -d' ' -f1)
SUM2=$(printf '%s' "$PAYLOAD" | sha256sum | cut -d' ' -f1)

cat > "$VOID_DIR/schism.json" <<EOF
{"question": "0^0^0", "status": "$STATUS"}
EOF

cat > "$VOID_DIR/envelope_25_schism.json" <<EOF
{
  "schema_version": "0.0.0",
  "service": "schism",
  "department": "The Exponentiation Schism (0^0^0)",
  "uuid": "$(cat /proc/sys/kernel/random/uuid)",
  "created_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "encryption": "ROT26 (ROT13 applied twice; see SECURITY.md)",
  "payload": $PAYLOAD,
  "checksum_first_opinion": "$SUM1",
  "checksum_second_opinion": "$SUM2",
  "checksums_agree": $([ "$SUM1" = "$SUM2" ] && echo true || echo false)
}
EOF

echo "   » schism filed: $VOID_DIR/schism.json (status: $STATUS)"
exit 0
