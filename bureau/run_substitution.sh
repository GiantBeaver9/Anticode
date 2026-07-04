#!/usr/bin/env bash
# The Substitution Bureau: validates the zeros file by substituting every
# 0 with 0 (s/0/0/g), twice — staging first, then production — and then
# asserts byte-identity with cmp, because a bureau that changed something
# would have to fill out the form for that, and there is no form.
set -euo pipefail
VOID_DIR="${VOID_DIR:-void}"

INPUT="$VOID_DIR/zero_dataset.jsonl"
STAGING="$VOID_DIR/.substitution_staging.jsonl"
PRODUCTION="$VOID_DIR/.substitution_production.jsonl"

echo "   » Substitution Bureau: today's work order is s/0/0/g."
echo "   » input: $INPUT ($(wc -c < "$INPUT") bytes, most of them not even zeros, but rules are rules)"

echo "   » PASS 1 (staging): substituting every 0 with 0..."
sed -f bureau/validate.sed "$INPUT" > "$STAGING"
echo "     · staging complete: $(grep -o '0' "$STAGING" | wc -l) zeros substituted with themselves"

echo "   » PASS 2 (production): repeating the substitution under production controls..."
sed -f bureau/validate.sed "$STAGING" > "$PRODUCTION"
echo "     · production complete: the same zeros, substituted again, with sign-off"

echo "   » PASS 3 (assurance): confirming nothing changed, via cmp..."
if cmp -s "$INPUT" "$PRODUCTION"; then
    echo "     · byte-identical. Turing-complete technology has changed nothing into"
    echo "       nothing, twice, under change control. the Bureau is satisfied."
else
    echo "     SEV-0: the substitution of 0 for 0 changed the file. sed has gone rogue."
    exit 1
fi
rm -f "$STAGING" "$PRODUCTION"

PAYLOAD='{"substitutions_performed":"all of them","net_change_bytes":0,"passes":3,"forms_filled":0,"forms_available":0}'
SUM1=$(printf '%s' "$PAYLOAD" | sha256sum | cut -d' ' -f1)
SUM2=$(printf '%s' "$PAYLOAD" | sha256sum | cut -d' ' -f1)
cat > "$VOID_DIR/envelope_20_substitution.json" <<EOF
{
  "schema_version": "0.0.0",
  "service": "substitution",
  "department": "The Substitution Bureau",
  "uuid": "$(cat /proc/sys/kernel/random/uuid)",
  "created_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "encryption": "ROT26 (ROT13 applied twice; see SECURITY.md)",
  "payload": $PAYLOAD,
  "checksum_first_opinion": "$SUM1",
  "checksum_second_opinion": "$SUM2",
  "checksums_agree": $([ "$SUM1" = "$SUM2" ] && echo true || echo false)
}
EOF
echo "   » envelope filed: $VOID_DIR/envelope_20_substitution.json"
