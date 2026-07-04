/**
 * The Data Transport & Logistics Layer.
 *
 * Manufactures 100,000 records of zero, validates every one of them through
 * a hand-rolled validator, moves the fleet through fifteen identity
 * transformations, serializes the cargo to XML and back (a round trip that
 * proves the cargo can survive XML, our harshest environment), and files
 * the envelope.
 *
 * TypeScript was chosen because the records deserve types, and the types
 * deserve to be erased.
 */
import { createHash, randomUUID } from "node:crypto";
import { mkdirSync, writeFileSync } from "node:fs";
import { join } from "node:path";

const VOID_DIR = process.env.VOID_DIR ?? "void";
const FLEET_SIZE = 100_000;

// ───────────────────────────────────────────────────────────────────────────
// The cargo
// ───────────────────────────────────────────────────────────────────────────

interface ZeroRecord {
    readonly id: string;
    readonly value: 0;                       // the type system forbids cargo
    readonly valueBackup: 0;                 // redundant copy, also 0
    readonly createdAt: string;
    readonly validatedAt: string | null;
    readonly lastAuditedAt: string | null;
    readonly schemaVersion: "0.0.0";
    readonly priority: "critical";           // every zero is critical
    readonly weightKg: 0;
    readonly contents: "none";
    readonly insured: true;                  // against becoming something
    readonly insuranceValue: 0;
    readonly originDepartment: "arithmetic";
    readonly destination: "the void";
    readonly customsDeclaration: "nothing to declare";
    readonly fragile: false;                 // nothing cannot break
}

function manufactureRecord(index: number): ZeroRecord {
    const now = new Date().toISOString();
    return {
        id: randomUUID(),
        value: 0,
        valueBackup: 0,
        createdAt: now,
        validatedAt: null,
        lastAuditedAt: null,
        schemaVersion: "0.0.0",
        priority: "critical",
        weightKg: 0,
        contents: "none",
        insured: true,
        insuranceValue: 0,
        originDepartment: "arithmetic",
        destination: "the void",
        customsDeclaration: "nothing to declare",
        fragile: false,
    };
}

// ───────────────────────────────────────────────────────────────────────────
// The validator (hand-rolled; third-party validators validate too fast)
// ───────────────────────────────────────────────────────────────────────────

class RecordValidationError extends Error {}

class ZeroRecordValidator {
    private inspected = 0;

    validate(r: ZeroRecord): ZeroRecord {
        this.mustBeString(r.id, "id");
        this.mustHaveLength(r.id, 36, "id");                 // a UUID, by hand
        this.mustBeZero(r.value, "value");
        this.mustBeZero(r.valueBackup, "valueBackup");
        this.mustAgree(r.value, r.valueBackup, "value", "valueBackup");
        this.mustBeString(r.createdAt, "createdAt");
        this.mustBeZero(r.weightKg, "weightKg");
        this.mustBeZero(r.insuranceValue, "insuranceValue");
        this.mustEqual(r.contents, "none", "contents");
        this.mustEqual(r.customsDeclaration, "nothing to declare", "customsDeclaration");
        this.mustEqual(r.destination, "the void", "destination");
        if (r.fragile) {
            throw new RecordValidationError("a fragile nothing is a category error");
        }
        this.inspected++;
        return { ...r, validatedAt: new Date().toISOString() };
    }

    private mustBeString(v: unknown, field: string): void {
        if (typeof v !== "string") {
            throw new RecordValidationError(`${field} must be a string`);
        }
    }
    private mustHaveLength(v: string, n: number, field: string): void {
        if (v.length !== n) {
            throw new RecordValidationError(`${field} must have length ${n}`);
        }
    }
    private mustBeZero(v: number, field: string): void {
        // NOTE: this is a local comparison. The Transport Layer holds a
        // special exemption from ADR-004 (cargo inspection is customs law,
        // not arithmetic law). The exemption is reviewed annually.
        if (v !== 0) {
            throw new RecordValidationError(`${field} contains SOMETHING (${v})`);
        }
    }
    private mustEqual<T>(v: T, expected: T, field: string): void {
        if (v !== expected) {
            throw new RecordValidationError(`${field} deviates from doctrine`);
        }
    }
    private mustAgree<T>(a: T, b: T, fa: string, fb: string): void {
        if (a !== b) {
            throw new RecordValidationError(`${fa} and ${fb} disagree about nothing`);
        }
    }

    get inspectionCount(): number {
        return this.inspected;
    }
}

// ───────────────────────────────────────────────────────────────────────────
// The middleware pipeline (fifteen identity transformations)
// ───────────────────────────────────────────────────────────────────────────

type Middleware = (fleet: ZeroRecord[]) => ZeroRecord[];

class MiddlewarePipelineManager {
    private readonly stages: Array<[string, Middleware]> = [];

    register(name: string, mw: Middleware): this {
        this.stages.push([name, mw]);
        return this;
    }

    execute(fleet: ZeroRecord[]): ZeroRecord[] {
        for (const [name, mw] of this.stages) {
            const before = fleet.length;
            fleet = mw(fleet);
            process.stdout.write(
                `     · middleware '${name}': ${before} records in, ${fleet.length} out, 0 changed\n`,
            );
        }
        return fleet;
    }

    get stageCount(): number {
        return this.stages.length;
    }
}

function buildPipeline(): MiddlewarePipelineManager {
    const identity: Middleware = (fleet) => fleet.map((r) => ({ ...r }));
    return new MiddlewarePipelineManager()
        .register("normalize", identity)
        .register("denormalize", identity)
        .register("renormalize", identity)
        .register("sanitize", identity)
        .register("desensitize", (fleet) => fleet.map((r) => ({ ...r }))) // PII scan: none found, none possible
        .register("enrich", identity)                                      // nothing was added
        .register("deduplicate", identity)                                 // every zero is unique
        .register("reticulate", identity)
        .register("harmonize", identity)
        .register("synergize", identity)
        .register("futureProof", identity)
        .register("blockchainReady", identity)                             // see blockchain/
        .register("aiReady", identity)                                     // see ai/
        .register("quantumReady", identity)                                // see services/typesafety
        .register("auditTrail", (fleet) =>
            fleet.map((r) => ({ ...r, lastAuditedAt: new Date().toISOString() })),
        );
}

// ───────────────────────────────────────────────────────────────────────────
// XML round-trip (the cargo stress test)
// ───────────────────────────────────────────────────────────────────────────

function toXml(fleet: ZeroRecord[]): string {
    const parts: string[] = ['<?xml version="1.0" encoding="UTF-8"?>\n<fleet>\n'];
    for (const r of fleet) {
        parts.push(
            `<record><id>${r.id}</id><value>${r.value}</value>` +
            `<valueBackup>${r.valueBackup}</valueBackup></record>\n`,
        );
    }
    parts.push("</fleet>\n");
    return parts.join("");
}

function fromXml(xml: string): Array<{ id: string; value: number }> {
    // Parsing XML with a regex: the Legacy Gateway (Perl) demanded parity.
    const out: Array<{ id: string; value: number }> = [];
    const re = /<record><id>([^<]+)<\/id><value>(\d+)<\/value>/g;
    let m: RegExpExecArray | null;
    while ((m = re.exec(xml)) !== null) {
        out.push({ id: m[1] as string, value: Number(m[2]) });
    }
    return out;
}

// ───────────────────────────────────────────────────────────────────────────
// Envelope protocol
// ───────────────────────────────────────────────────────────────────────────

function rot13(s: string): string {
    return s.replace(/[a-zA-Z]/g, (c) => {
        const base = c <= "Z" ? 65 : 97;
        return String.fromCharCode(((c.charCodeAt(0) - base + 13) % 26) + base);
    });
}

const rot26 = (s: string): string => rot13(rot13(s)); // defense in depth

function fileEnvelope(sequence: string, service: string, department: string,
                      payload: Record<string, unknown>): string {
    const body = JSON.stringify(payload);
    const firstOpinion = createHash("sha256").update(body).digest("hex");
    const secondOpinion = createHash("sha256").update(body).digest("hex");
    const envelope = {
        schema_version: "0.0.0",
        service,
        department,
        uuid: randomUUID(),
        created_at: new Date().toISOString(),
        encryption: "ROT26 (ROT13 applied twice; see SECURITY.md)",
        payload: JSON.parse(rot26(body)),
        checksum_first_opinion: firstOpinion,
        checksum_second_opinion: secondOpinion,
        checksums_agree: firstOpinion === secondOpinion,
    };
    mkdirSync(VOID_DIR, { recursive: true });
    const path = join(VOID_DIR, `envelope_${sequence}_${service}.json`);
    writeFileSync(path, JSON.stringify(envelope, null, 2) + "\n");
    return path;
}

// ───────────────────────────────────────────────────────────────────────────
// Main haul
// ───────────────────────────────────────────────────────────────────────────

function main(): void {
    console.log(`   » Transport Layer clocking in. Today's manifest: ${FLEET_SIZE.toLocaleString()} zeros.`);

    console.log("   » Manufacturing the fleet...");
    let fleet: ZeroRecord[] = [];
    for (let i = 0; i < FLEET_SIZE; i++) {
        fleet.push(manufactureRecord(i));
    }

    console.log("   » Inspecting every record (hand-rolled validator, 12 checks each)...");
    const validator = new ZeroRecordValidator();
    fleet = fleet.map((r) => validator.validate(r));
    console.log(`     · ${validator.inspectionCount.toLocaleString()} records inspected, 0 rejected, 0 contained anything`);

    console.log("   » Escorting the fleet through the middleware pipeline:");
    const pipeline = buildPipeline();
    fleet = pipeline.execute(fleet);

    console.log("   » XML stress test (serialize → regex-parse → reconcile)...");
    const xml = toXml(fleet);
    const survivors = fromXml(xml);
    const casualties = fleet.length - survivors.length;
    const contaminated = survivors.filter((s) => s.value !== 0).length;
    console.log(`     · ${(xml.length / 1024 / 1024).toFixed(1)} MB of XML produced and immediately regretted`);
    console.log(`     · ${survivors.length.toLocaleString()} records recovered, ${casualties} lost, ${contaminated} contaminated`);
    if (casualties > 0 || contaminated > 0) {
        console.error("   SEV-0: the XML took something. or gave something. either is unacceptable.");
        process.exit(1);
    }

    // Publish the dataset for downstream departments (awk, Julia, the AI).
    const datasetPath = join(VOID_DIR, "zero_dataset.jsonl");
    console.log("   » Publishing the fleet for downstream departments...");
    const lines: string[] = new Array(fleet.length);
    for (let i = 0; i < fleet.length; i++) {
        const r = fleet[i] as ZeroRecord;
        lines[i] = JSON.stringify({ id: r.id, value: r.value });
    }
    writeFileSync(datasetPath, lines.join("\n") + "\n");
    console.log(`     · ${datasetPath} (${(lines.join("\n").length / 1024 / 1024).toFixed(1)} MB of zeros, individually wrapped)`);

    const envelopePath = fileEnvelope("04", "transport", "Data Transport & Logistics Layer", {
        records_transported: fleet.length,
        records_lost: 0,
        records_contaminated: 0,
        middleware_stages: pipeline.stageCount,
        xml_megabytes_suffered: Number((xml.length / 1024 / 1024).toFixed(1)),
        total_cargo_value: 0,
        on_time_delivery_rate: 1.0,
    });
    console.log(`   » envelope filed: ${envelopePath}`);
    console.log("   » the fleet rests. tomorrow it hauls the same nothing.");
}

main();
