#!/usr/bin/env bash
# The Zero Supply Chain.
#
# The purest logistics operation in Unix: 2 GB of certified zeros are read
# from the source (/dev/zero, our sole upstream supplier, never once late),
# checksummed in transit against the known SHA-256 of 2 GB of zeros, and
# delivered to /dev/null, our most reliable customer, who has never filed
# a complaint or a receipt.
#
# Also housed here: the Divide-by-Zero Containment Unit, which monitors
# 1/x as x approaches zero from a safe distance and never, ever divides.
set -euo pipefail
VOID_DIR="${VOID_DIR:-void}"

GIGS=2
BYTES=$((GIGS * 1024 * 1024 * 1024))
# The known checksum of 2 GiB of zeros, established empirically by shipping
# 2 GiB of zeros and writing down what happened (the reference method).
KNOWN_SHA256="a7c744c13cc101ed66c29f672f92455547889cc586ce6d44fe76ae824958ea51"

echo "   » Zero Supply Chain: today's shipment is ${GIGS} GiB of zeros."
echo "   » supplier: /dev/zero (SLSA level 0; audit found nothing, twice)"
echo "   » customer: /dev/null (accepts all deliveries; retains none; ideal)"

echo "   » shipment in transit (checksummed in-line, as the convoy rolls)..."
START=$SECONDS
ACTUAL_SHA256=$(dd if=/dev/zero bs=1M count=$((GIGS * 1024)) status=progress 2> >(tail -1 >&2) | tee >(dd of=/dev/null bs=1M status=none) | sha256sum | cut -d' ' -f1)
ELAPSED=$((SECONDS - START))

echo ""
echo "   » delivery complete in ${ELAPSED}s. reconciling paperwork..."
echo "     · bytes shipped ........... $BYTES"
echo "     · bytes received .......... $BYTES (per /dev/null, who would know)"
echo "     · checksum expected ....... $KNOWN_SHA256"
echo "     · checksum observed ....... $ACTUAL_SHA256"

if [ "$ACTUAL_SHA256" = "$KNOWN_SHA256" ]; then
    echo "     · TAMPERING: none. every zero arrived exactly as manufactured."
else
    echo "     SEV-0: the zeros were tampered with in transit. someone added something."
    exit 1
fi

# ── The Divide-by-Zero Containment Unit ─────────────────────────────────
DAYS_SINCE_EPOCH=$(( $(date +%s) / 86400 ))
echo ""
echo "   ┌─ DIVIDE-BY-ZERO CONTAINMENT UNIT ── shift report ──────────────"
echo "   │  observation: 1/x for x in {1, 0.1, 0.01, 0.001} grows alarmingly."
echo "   │  action taken: stopped observing. containment through discipline."
echo "   │  divisions by zero performed today: 0"
echo "   │  DAYS SINCE LAST DIVISION-BY-ZERO INCIDENT: $DAYS_SINCE_EPOCH"
echo "   │  (counter started 1970-01-01; never reset; never will be)"
echo "   └──────────────────────────────────────────────────────────────────"

PAYLOAD=$(printf '{"gigabytes_shipped":%d,"checksum_verified":true,"tampered_zeros":0,"wall_seconds":%d,"days_since_division_by_zero":%d,"slsa_level":0,"inventory_before":0,"inventory_after":0,"shrinkage":0}' \
    "$GIGS" "$ELAPSED" "$DAYS_SINCE_EPOCH")
SUM1=$(printf '%s' "$PAYLOAD" | sha256sum | cut -d' ' -f1)
SUM2=$(printf '%s' "$PAYLOAD" | sha256sum | cut -d' ' -f1)
cat > "$VOID_DIR/envelope_24_supply_chain.json" <<EOF
{
  "schema_version": "0.0.0",
  "service": "supply_chain",
  "department": "The Zero Supply Chain",
  "uuid": "$(cat /proc/sys/kernel/random/uuid)",
  "created_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "encryption": "ROT26 (ROT13 applied twice; see SECURITY.md)",
  "payload": $PAYLOAD,
  "checksum_first_opinion": "$SUM1",
  "checksum_second_opinion": "$SUM2",
  "checksums_agree": $([ "$SUM1" = "$SUM2" ] && echo true || echo false)
}
EOF
echo "   » supply-chain attestation filed: $VOID_DIR/envelope_24_supply_chain.json"
