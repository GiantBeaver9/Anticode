#!/usr/bin/env bash
# The Fax Gateway.
#
# The Certificate of Accomplished Nothingness is not printed. Certificates
# of this caliber are TRANSMITTED: character by character, at 300 baud,
# with a full modem handshake, to a fax machine that does not exist.
#
# Halfway through transmission, change request CR-1994-0001 (filed 1994,
# approved today) upgrades the line to 4800 baud. Delivery confirmation
# has been pending since the original filing and is expected imminently.
set -euo pipefail
VOID_DIR="${VOID_DIR:-void}"
CERT="$VOID_DIR/certificate.txt"

if [ ! -f "$CERT" ]; then
    echo "   ✖ no certificate found. the auditor must certify before telecom transmits."
    exit 1
fi

DEST="+0 (000) 000-0000"

echo "   » Fax Gateway powering on (capacitors sing their one note)"
echo "   » dialing $DEST ..."
sleep 0.4
echo ""
echo "        ┌──────────────────────────────────────┐"
echo "        │  ATDT0000000000                       │"
echo "        │  ~~~~ CARRIER 300 ~~~~                │"
echo "        │  CONNECT 300/NONE                     │"
echo "        │  ♪ scree—eee—ongk—BONG—kshhhhhhh ♪    │"
echo "        └──────────────────────────────────────┘"
echo ""
echo "   » handshake complete. transmitting certificate at 300 baud:"
echo ""

# 300 baud ≈ 30 chars/sec. We transmit line-by-line with per-line delays
# proportional to length, which is what 300 baud feels like from here.
TOTAL_LINES=$(wc -l < "$CERT")
HALFWAY=$((TOTAL_LINES / 2))
LINE_NO=0
BAUD=300

while IFS= read -r line; do
    LINE_NO=$((LINE_NO + 1))
    # chars / (baud/10) seconds per line, capped for civic reasons
    LEN=${#line}
    DELAY=$(awk -v l="$LEN" -v b="$BAUD" 'BEGIN{d=l/(b/10); if (d>2.4) d=2.4; printf "%.2f", d}')
    printf '%s\n' "$line"
    sleep "$DELAY"
    if [ "$LINE_NO" -eq "$HALFWAY" ]; then
        BAUD=4800
        echo ""
        echo "        ── CHANGE REQUEST CR-1994-0001 APPROVED MID-TRANSMISSION ──"
        echo "        ── line upgraded to 4800 baud. the future arrives, late ──"
        echo ""
    fi
done < "$CERT"

echo ""
echo "   » transmission complete: $TOTAL_LINES lines, final speed ${BAUD} baud."
echo "   » awaiting delivery confirmation from $DEST ..."
sleep 0.6
echo "   » delivery confirmation: PENDING (since 1994). consistent with SLA."
echo "   » the certificate is now wherever faxes go. our work here is done."
