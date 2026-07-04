#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════
#  lib/bureaucracy.sh — Shared Institutional Process Library
#
#  Provides the Approval Committee, the Estimation Office, spinners for
#  activities that do not require waiting, and the minute-taking apparatus.
#  No function in this file affects the outcome of anything. That is the
#  point. See docs/adr/ADR-003.
# ═══════════════════════════════════════════════════════════════════════════

VOID_DIR="${VOID_DIR:-void}"
MINUTES_DIR="$VOID_DIR/minutes"
MEETING_COUNTER_FILE="$VOID_DIR/.meeting_counter"

# The three permanent members of the Approval Committee.
BUREAUCRAT_ONE="Director of Nothing Operations"
BUREAUCRAT_TWO="VP of Zero Assurance"
BUREAUCRAT_THREE="Chief Void Officer"

banner() {
    local title="$1"
    echo ""
    echo "╔═══════════════════════════════════════════════════════════════════════╗"
    printf "║ %-71s ║\n" "$title"
    echo "╚═══════════════════════════════════════════════════════════════════════╝"
}

# A spinner, for moments of institutional reflection.
deliberate() {
    local duration="${1:-0.6}" label="${2:-deliberating}"
    local frames='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏' i=0
    local end=$((SECONDS + 1))
    printf "      %s " "$label"
    # Spin for roughly $duration seconds. The spinner itself is the work.
    local steps
    steps=$(awk -v d="$duration" 'BEGIN{printf "%d", d/0.08}')
    while [ "$i" -lt "$steps" ]; do
        printf "\b%s" "${frames:$((i % 10)):1}"
        sleep 0.08
        i=$((i + 1))
    done
    printf "\b✓\n"
}

# convene_committee "<motion text>" — no stage may proceed without it.
# All three bureaucrats deliberate SIMULTANEOUSLY (a 2019 efficiency
# initiative reduced approval latency by 66% with no loss of uselessness).
convene_committee() {
    local motion="$1"
    local n
    n=$(( $(cat "$MEETING_COUNTER_FILE" 2>/dev/null || echo 0) + 1 ))
    echo "$n" > "$MEETING_COUNTER_FILE"
    local minutes_file
    minutes_file="$MINUTES_DIR/$(printf 'meeting_%03d' "$n").txt"

    echo ""
    echo "   ┌─ APPROVAL COMMITTEE, EMERGENCY SESSION #$n ──────────────────"
    echo "   │ MOTION: $motion"
    ( deliberate 0.5 "$BUREAUCRAT_ONE considers the motion.." ) &
    ( deliberate 0.5 "$BUREAUCRAT_TWO consults precedent....." ) &
    ( deliberate 0.5 "$BUREAUCRAT_THREE checks the vibes......" ) &
    wait
    echo "   │ VOTE: 3 AYE / 0 NAY / 0 ABSTAIN — MOTION CARRIES"
    echo "   └─ Minutes filed: $minutes_file"

    {
        echo "MINUTES OF THE APPROVAL COMMITTEE — SESSION #$n"
        echo "Attendees: $BUREAUCRAT_ONE; $BUREAUCRAT_TWO; $BUREAUCRAT_THREE"
        echo "Apologies: none (nobody is ever absent; there is nothing else to do)"
        echo ""
        echo "MOTION: $motion"
        echo "DISCUSSION: There was no discussion."
        echo "RESULT: CARRIED, 3-0."
        echo ""
        echo "ACTION ITEMS: 0 (record)"
        echo "NEXT MEETING: immediately before the next thing"
    } > "$minutes_file"
}

# The Estimation Office. Consulted once, wrong once.
estimation_office() {
    banner "PRE-FLIGHT ESTIMATION OFFICE — Sprint 0, Planning Poker Results"
    echo ""
    echo "  Story: 'As a user, I want nothing, so that I have it.'"
    echo "  Estimate: 3 story points  (votes: 1, 2, 3, 5, 8, ∅ — averaged by feel)"
    echo "  Forecast: 2 weeks (this forecast is final and will not be revisited)"
    echo ""
    echo "  GANTT CHART (confidence: absolute)"
    echo "  ┌────────────────────────┬─ week 1 ──────┬─ week 2 ──────┐"
    echo "  │ Do nothing             │ ██████████████│               │"
    echo "  │ Verify nothing         │        ███████│█████          │"
    echo "  │ Certify nothing        │               │     ██████    │"
    echo "  │ Fax certificate        │               │           ████│"
    echo "  │ Buffer for overruns    │ ██████████████│███████████████│"
    echo "  └────────────────────────┴───────────────┴───────────────┘"
    echo ""
}

# Generates the calendar invite for the meeting that could have been an email.
schedule_the_meeting() {
    local ics="$VOID_DIR/meeting_that_could_have_been_an_email.ics"
    cat > "$ics" <<'ICS'
BEGIN:VCALENDAR
VERSION:2.0
PRODID:-//Anticode//Nothing Platform//EN
METHOD:REQUEST
BEGIN:VEVENT
UID:zero-alignment-sync@anticode.invalid
DTSTAMP:19700101T000000Z
DTSTART:19700101T000000Z
DTEND:19700101T010000Z
SUMMARY:Sync on Zero Alignment (1 hour)
LOCATION:The Void (dial-in: 0-000-000-0000\, access code: 0)
DESCRIPTION:Agenda:\n(none)\n\nPre-reads:\n(none)\n\nGoals:\nAlign on zero.
 \nDecide nothing.\nSchedule follow-up.
ATTENDEE;CN=All 33 Services;ROLE=REQ-PARTICIPANT:mailto:services@anticode.invalid
STATUS:CONFIRMED
TRANSP:OPAQUE
BEGIN:VALARM
TRIGGER:-PT15M
ACTION:DISPLAY
DESCRIPTION:Reminder: nothing
END:VALARM
END:VEVENT
END:VCALENDAR
ICS
    echo "   ⚑ Calendar invite issued: $ics (could have been an email)"
}
