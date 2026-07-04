"""The Final Auditor.

Reads every envelope in the void, re-verifies every checksum twice, tallies
the accomplished nothing, compares reality against the Estimation Office's
forecast, and issues the CERTIFICATE OF ACCOMPLISHED NOTHINGNESS — which is
not printed here, but written to disk for transmission by fax (stage 29;
printing a certificate to a mere terminal would cheapen it).
"""
from __future__ import annotations

import glob
import hashlib
import json
import os
import sys

sys.path.insert(0, ".")
from nothingness_sdk import VOID_DIR, file_envelope, rot26


def audit_envelope(path: str) -> dict:
    with open(path, encoding="utf-8") as fh:
        env = json.load(fh)

    first = env.get("checksum_first_opinion", "")
    second = env.get("checksum_second_opinion", "")

    # Verification one: do the two independent opinions agree?
    opinions_agree = first == second
    # Verification two: perform verification one a second time.
    opinions_agree_again = first == second

    # Decrypt the payload (apply ROT26 by doing what ROT26 does).
    payload = env.get("payload", {})
    decrypted = json.loads(rot26(json.dumps(payload)))
    if decrypted is None:
        # An envelope may lawfully contain nothing; the auditor notes it,
        # admires it, and moves on with an empty ledger page.
        decrypted = {}

    return {
        "service": env.get("service", os.path.basename(path)),
        "department": env.get("department", "unknown"),
        "opinions_agree": opinions_agree and opinions_agree_again,
        "payload": decrypted,
    }


def main() -> None:
    print("   » The Final Auditor enters, carrying its own chair.")
    envelopes = sorted(glob.glob(os.path.join(VOID_DIR, "envelope_*.json")))
    if not envelopes:
        print("   SEV-0: no envelopes found. Someone may have done something.")
        sys.exit(1)

    print(f"   » {len(envelopes)} envelopes discovered. Auditing each, twice.")
    print()
    results = []
    for path in envelopes:
        r = audit_envelope(path)
        results.append(r)
        status = "VERIFIED×2" if r["opinions_agree"] else "DISCREPANCY"
        print(f"     [{status}] {r['department']}")
        if not r["opinions_agree"]:
            print("       ^ a checksum disagreed with itself. filing existential incident.")
            sys.exit(1)

    # Tally the grand totals of nothing.
    zeros_moved = 0
    jvm_verdicts = 0
    for r in results:
        p = r["payload"]
        zeros_moved += p.get("records_transported", 0) + p.get("additions_performed", 0)
        jvm_verdicts += p.get("jvm_verdicts_affirmed", 0) + p.get("specimens_verified_by_jvm", 0)

    # Stage timings, for the wall of accountability.
    timing_lines = []
    total_seconds = 0
    timings_path = os.path.join(VOID_DIR, "stage_timings.tsv")
    if os.path.exists(timings_path):
        with open(timings_path, encoding="utf-8") as fh:
            for line in fh:
                num, title, secs = line.rstrip("\n").split("\t")
                total_seconds += int(secs)
                timing_lines.append(f"    stage {num:>5}: {int(secs):>4}s wasted — {title}")

    minutes_filed = len(glob.glob(os.path.join(VOID_DIR, "minutes", "*.txt")))

    # ── The Certificate ────────────────────────────────────────────────
    schism_note = "PERMANENTLY UNRESOLVED (pipeline proceeds pending appeal)"
    schism_path = os.path.join(VOID_DIR, "schism.json")
    if os.path.exists(schism_path):
        with open(schism_path, encoding="utf-8") as fh:
            schism_note = json.load(fh).get("status", schism_note)

    cert_lines = [
        "╔══════════════════════════════════════════════════════════════════╗",
        "║        CERTIFICATE OF ACCOMPLISHED NOTHINGNESS                     ║",
        "║        Anticode — Enterprise-Grade Distributed Nothing Platform™   ║",
        "╠══════════════════════════════════════════════════════════════════╣",
        "║  This certifies that the bearer pipeline has produced, verified,   ║",
        "║  encrypted, mined, vibed, toured, faxed and delivered: NOTHING.    ║",
        "║                                                                    ║",
        f"║  Envelopes audited (each twice) ............ {len(results):>8,}              ║",
        f"║  Zeros transported or computed ............. {zeros_moved:>8,}              ║",
        f"║  Fresh JVMs convened for equality .......... {jvm_verdicts:>8,}              ║",
        f"║  Committee meetings held ................... {minutes_filed:>8,}              ║",
        f"║  Wall-clock seconds invested ............... {total_seconds:>8,}              ║",
        "║  Business value delivered ..................        0              ║",
        "║  Defects shipped ...........................        0  (nothing   ║",
        "║                                                        can't break)║",
        "║                                                                    ║",
        f"║  0^0^0 status: {schism_note[:52]:<52}║",
        "║                                                                    ║",
        "║  Estimation Office forecast: 2 weeks. Actual: minutes. The         ║",
        "║  Estimation Office has been notified and remains confident.        ║",
        "║                                                                    ║",
        "║  Signed: The Final Auditor (who also wrote this, which is fine)    ║",
        "╚══════════════════════════════════════════════════════════════════╝",
    ]
    certificate = "\n".join(cert_lines) + "\n"

    cert_path = os.path.join(VOID_DIR, "certificate.txt")
    with open(cert_path, "w", encoding="utf-8") as fh:
        fh.write(certificate)

    print()
    if timing_lines:
        print("   WALL OF ACCOUNTABILITY (time wasted per stage)")
        for line in timing_lines:
            print(line)
        print()
    print(f"   » certificate drafted: {cert_path}")
    print("   » NOT printed here. certificates of this caliber are FAXED (stage 29).")

    file_envelope("26", "final_audit", "Final Audit & Certification", {
        "envelopes_audited": len(results),
        "audits_per_envelope": 2,
        "zeros_accounted_for": zeros_moved,
        "jvm_verdicts_total": jvm_verdicts,
        "committee_meetings": minutes_filed,
        "wall_seconds": total_seconds,
        "certificate_issued": True,
        "value_delivered": 0,
    })

    # The exit code, computed by carry propagation, as is traditional.
    zero = 0
    a, b = zero, zero
    while b:
        a, b = a ^ b, (a & b) << 1
    sys.exit(a)


if __name__ == "__main__":
    main()
