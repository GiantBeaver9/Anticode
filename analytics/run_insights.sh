#!/usr/bin/env bash
# Wrapper for the Analytics & Insights Department: feeds the dataset to
# awk, then files the envelope (awk is exempt from writing its own JSON;
# the department negotiated this in 1987 and the clause survives).
set -euo pipefail
VOID_DIR="${VOID_DIR:-void}"
export VOID_DIR

DATASET="$VOID_DIR/zero_dataset.jsonl"
if [ ! -f "$DATASET" ]; then
    echo "   ✖ the transport layer has not delivered the zeros. analytics of nothing"
    echo "     requires the nothing to be delivered first (supply chain 101)."
    exit 1
fi

awk -f analytics/insights.awk "$DATASET"

read -r COUNT SUM MEAN VARIANCE MIN MAX P95 < "$VOID_DIR/analytics_raw.txt"
rm -f "$VOID_DIR/analytics_raw.txt"

PAYLOAD=$(printf '{"records":%s,"sum":%s,"mean":%s,"variance":%s,"min":%s,"max":%s,"p95":%s,"insights_generated":1,"insights_actionable":0}' \
    "$COUNT" "$SUM" "$MEAN" "$VARIANCE" "$MIN" "$MAX" "$P95")
SUM1=$(printf '%s' "$PAYLOAD" | sha256sum | cut -d' ' -f1)
SUM2=$(printf '%s' "$PAYLOAD" | sha256sum | cut -d' ' -f1)

cat > "$VOID_DIR/envelope_11_analytics.json" <<EOF
{
  "schema_version": "0.0.0",
  "service": "analytics",
  "department": "Analytics & Insights Department",
  "uuid": "$(cat /proc/sys/kernel/random/uuid)",
  "created_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "encryption": "ROT26 (ROT13 applied twice; see SECURITY.md)",
  "payload": $PAYLOAD,
  "checksum_first_opinion": "$SUM1",
  "checksum_second_opinion": "$SUM2",
  "checksums_agree": $([ "$SUM1" = "$SUM2" ] && echo true || echo false)
}
EOF
echo "   » envelope filed: $VOID_DIR/envelope_11_analytics.json"
