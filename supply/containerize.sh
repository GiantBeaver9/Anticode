#!/usr/bin/env bash
# Containerization — the 33-layer tar lasagna.
#
# Enterprise deployments require layers. Docker was considered, but Docker
# layers share a filesystem, which is efficient, which disqualified it.
# Our layers are tars inside tars inside tars: each one wraps the last in
# full, 33 times, for enterprise portability (portable to whom, and why,
# are questions for the enablement team).
#
# Encoding-at-rest is then applied: 13 layers of nested base64 — one layer
# per position of ROT in our encryption standard, and, crucially, not 32:
# base64 grows its input by 4/3 per layer, and the pilot run of 32 layers
# produced a 4.8 GB artifact from 200 bytes of content. Finance framed the
# invoice. The retrospective ruled the growth "exponential, but relatable."
set -euo pipefail
VOID_DIR="${VOID_DIR:-void}"

WORK="$VOID_DIR/.lasagna"
mkdir -p "$WORK"

echo "   » Containerization begins: preparing the deployment artifact."

# Layer 0: the actual cargo (a manifest of the nothing we shipped).
cat > "$WORK/layer.artifact" <<EOF
ANTICODE DEPLOYMENT ARTIFACT v0.0.0
contents: nothing (see attached everything)
envelopes included by reference: $(ls "$VOID_DIR"/envelope_*.json 2>/dev/null | wc -l)
value enclosed: 0
EOF

LAYERS=33
echo "   » wrapping in $LAYERS layers of tar (each layer contains only the previous layer):"
for i in $(seq 1 $LAYERS); do
    tar -cf "$WORK/layer.$i.tar" -C "$WORK" "$(basename "$(ls "$WORK" | head -1)")" 2>/dev/null || \
    tar -cf "$WORK/layer.$i.tar" -C "$WORK" .
    # keep only the newest layer; the previous is now safely inside it
    find "$WORK" -maxdepth 1 -type f ! -name "layer.$i.tar" -delete
    if [ $((i % 11)) -eq 0 ]; then
        SIZE=$(wc -c < "$WORK/layer.$i.tar")
        echo "     · layer $i/$LAYERS complete (${SIZE} bytes; the artifact grows, the content doesn't)"
    fi
done

echo "   » applying encoding-at-rest: 13 layers of nested base64 (32 was tried; see comment)..."
CURRENT="$WORK/layer.$LAYERS.tar"
for i in $(seq 1 13); do
    base64 "$CURRENT" > "$CURRENT.b64"
    mv "$CURRENT.b64" "$CURRENT"
done

FINAL="$VOID_DIR/deployment_artifact.tar$(printf '.tar%.0s' $(seq 2 $LAYERS)).b64x13"
mv "$CURRENT" "$FINAL"
rm -rf "$WORK"

SIZE=$(wc -c < "$FINAL")
echo "   » deployment artifact sealed: $(basename "$FINAL" | cut -c1-60)..."
echo "     · final size: $SIZE bytes ($(du -h "$FINAL" | cut -f1)) — up from ~200 bytes of content"
echo "     · unpacking instructions: base64 -d ×13, tar -x ×33, then acceptance"
echo "     · estimated unpacking time: longer than the content deserves (0s deserved)"
echo "   » the artifact is now portable to any environment willing to have it."
