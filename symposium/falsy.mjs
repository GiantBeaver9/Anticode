/**
 * The Falsy Symposium — Proceedings of the 0th Annual Conference on
 * JavaScript Equality (all editions are the 0th; the count is falsy).
 *
 * The symposium empirically rediscovers what == does to zero, publishes
 * the findings as peer-reviewed proceedings, and survives the experience.
 * All experiments use loose equality, as nature intended and TC39 permits.
 */
/* eslint-disable eqeqeq -- eqeqeq is the entire point */
import { createHash, randomUUID } from "node:crypto";
import { mkdirSync, writeFileSync } from "node:fs";
import { join } from "node:path";

const VOID_DIR = process.env.VOID_DIR ?? "void";

const EXPERIMENTS = [
    ["0 == 0",        () => 0 == 0,        "control group; the committee insisted"],
    ["0 == '0'",      () => 0 == "0",      "the string is welcomed home"],
    ["0 == ''",       () => 0 == "",       "the empty string is also zero. everything is zero if you coerce hard enough"],
    ["'' == '0'",     () => "" == "0",     "AND YET the two strings that both equal 0 do not equal each other. equality is not transitive here. the peer reviewers checked three times"],
    ["0 == []",       () => 0 == [],       "an empty array equals zero (the array is flattered)"],
    ["0 == [0]",      () => 0 == [0],      "an array CONTAINING zero also equals zero (containers are a suggestion)"],
    ["0 == [[0]]",    () => 0 == [[0]],    "zero in an array in an array: still zero. it's zeroes all the way down"],
    ["[] == ![]",     () => [] == ![],     "an array equals its own negation. keynote material. reviewer 2 rejected reality; overruled"],
    ["0 == {}",       () => 0 == {},       "the object holds the line. somebody has to"],
    ["0 == null",     () => 0 == null,     "null declines the comparison entirely (aloof, respected)"],
    ["0 == undefined",() => 0 == undefined,"undefined follows null out of solidarity"],
    ["0 == NaN",      () => 0 == NaN,      "NaN equals nothing, including itself. the symposium's most honest attendee"],
    ["NaN == NaN",    () => NaN == NaN,    "confirmed: NaN cannot even self-affirm. ADR-004 compliance, achieved accidentally, in 1995"],
    ["0 == false",    () => 0 == false,    "false is zero with a philosophy degree"],
    ["0 == -0",       () => 0 == -0,       "the crisis unit (ontology/) was consulted and is 'fine'"],
    ["Object.is(0,-0)", () => Object.is(0, -0), "Object.is breaks ranks and tells the truth: they are different. security escorted it out"],
];

function main() {
    console.log("   » THE FALSY SYMPOSIUM — proceedings, volume 0");
    console.log("   » Keynote: \"Zero Is Whatever You Need It To Be: A JavaScript Story\"");
    console.log();

    const findings = [];
    for (const [expr, run, commentary] of EXPERIMENTS) {
        const result = run();
        findings.push({ expr, result, commentary });
        const badge = result ? "TRUE " : "FALSE";
        console.log(`     [${badge}] ${expr.padEnd(18)} — ${commentary}`);
    }

    const surprising = findings.filter(
        (f) => f.result === true && !["0 == 0", "0 == false", "0 == -0"].includes(f.expr),
    ).length;

    console.log();
    console.log(`   » findings: ${findings.length} experiments, ${surprising} of which would fail code review`);
    console.log("   » peer review: reviewer 1 approved; reviewer 2 rejected reality (overruled);");
    console.log("     reviewer 3 was an empty array and was found equal to reviewer 2's negation.");

    // Envelope, per protocol.
    const rot13 = (s) => s.replace(/[a-zA-Z]/g, (c) => {
        const base = c <= "Z" ? 65 : 97;
        return String.fromCharCode(((c.charCodeAt(0) - base + 13) % 26) + base);
    });
    const rot26 = (s) => rot13(rot13(s));
    const payload = {
        experiments: findings.length,
        results_surprising: surprising,
        equality_transitive: false,
        arrays_equal_to_their_own_negation: 1,
        values_that_self_affirm: findings.length - 2, // NaN abstains twice
        proceedings_pages: 0,
    };
    const body = JSON.stringify(payload);
    const first = createHash("sha256").update(body).digest("hex");
    const second = createHash("sha256").update(body).digest("hex");
    mkdirSync(VOID_DIR, { recursive: true });
    const path = join(VOID_DIR, "envelope_22_falsy_symposium.json");
    writeFileSync(path, JSON.stringify({
        schema_version: "0.0.0",
        service: "falsy_symposium",
        department: "The Falsy Symposium",
        uuid: randomUUID(),
        created_at: new Date().toISOString(),
        encryption: "ROT26 (ROT13 applied twice; see SECURITY.md)",
        payload: JSON.parse(rot26(body)),
        checksum_first_opinion: first,
        checksum_second_opinion: second,
        checksums_agree: first === second,
    }, null, 2) + "\n");
    console.log(`   » proceedings filed: ${path}`);
}

main();
