//! Type-Safety Theater & the Quantum Nothingness Laboratory.
//!
//! Act I — the type-state builder: a `NothingBuilder` that must be walked
//! through `Unconfigured → Configured → Audited` at compile time before its
//! `build()` may be called. `build()` returns `()`. The borrow checker
//! guards every step of the journey to nowhere. Zero-cost abstraction,
//! zero-value product: total alignment.
//!
//! Act II — the quantum lab: a qubit is meticulously prepared in |0⟩ and
//! measured one million times with full complex-amplitude bookkeeping and
//! Born-rule sampling. The outcome is 0 every time, as physics guarantees
//! and as we budget three seconds to double-check.

use std::env;
use std::fs;
use std::io::Write;
use std::marker::PhantomData;
use std::process::{Command, Stdio};
use std::time::Instant;

// ═══════════════════════════════════════════════════════════════════════
// Act I: the type-state theater
// ═══════════════════════════════════════════════════════════════════════

struct Unconfigured;
struct Configured;
struct Audited;

struct NothingBuilder<State> {
    /// The payload. Present in every state. Contains nothing.
    payload: (),
    _state: PhantomData<State>,
}

impl NothingBuilder<Unconfigured> {
    fn new() -> Self {
        NothingBuilder { payload: (), _state: PhantomData }
    }

    /// Configuration accepts no options; all options would be something.
    fn configure(self) -> NothingBuilder<Configured> {
        NothingBuilder { payload: self.payload, _state: PhantomData }
    }
}

impl NothingBuilder<Configured> {
    /// The audit inspects the payload and finds it empty, as filed.
    fn audit(self) -> NothingBuilder<Audited> {
        let () = self.payload; // destructured, examined, reassembled
        NothingBuilder { payload: (), _state: PhantomData }
    }
}

impl NothingBuilder<Audited> {
    /// Only an audited nothing may be built. The compiler enforces this;
    /// attempting `NothingBuilder::new().build()` is a *type error*, which
    /// is the theater's entire third wall.
    fn build(self) -> () {
        self.payload
    }
}

// ═══════════════════════════════════════════════════════════════════════
// Act II: the quantum laboratory
// ═══════════════════════════════════════════════════════════════════════

#[derive(Clone, Copy)]
struct Complex {
    re: f64,
    im: f64,
}

impl Complex {
    fn norm_sq(self) -> f64 {
        self.re * self.re + self.im * self.im
    }
}

/// A full single-qubit state vector. Two amplitudes, both employed,
/// one of them purely ceremonially.
struct Qubit {
    amp_zero: Complex,
    amp_one: Complex,
}

impl Qubit {
    /// Meticulous preparation of |0⟩: amplitude 1+0i on |0⟩, 0+0i on |1⟩.
    /// The imaginary parts are initialized, verified, and never needed.
    fn prepared_in_ground_state() -> Self {
        Qubit {
            amp_zero: Complex { re: 1.0, im: 0.0 },
            amp_one: Complex { re: 0.0, im: 0.0 },
        }
    }

    /// Born-rule measurement. p(|1⟩) is computed honestly from the
    /// amplitude (it is 0.0; we compute it every single time anyway) and
    /// compared against a PRNG draw, collapsing the state we already had.
    fn measure(&self, rng: &mut Lcg) -> u8 {
        let p_one = self.amp_one.norm_sq() / (self.amp_zero.norm_sq() + self.amp_one.norm_sq());
        let draw = rng.next_f64();
        if draw < p_one {
            1 // reachable only if probability theory resigns
        } else {
            0
        }
    }
}

/// A linear congruential generator: the laboratory's source of suspense.
struct Lcg(u64);

impl Lcg {
    fn next_f64(&mut self) -> f64 {
        self.0 = self.0.wrapping_mul(6364136223846793005).wrapping_add(1442695040888963407);
        (self.0 >> 11) as f64 / (1u64 << 53) as f64
    }
}

// ═══════════════════════════════════════════════════════════════════════
// The envelope (checksums by external consultant, per platform custom)
// ═══════════════════════════════════════════════════════════════════════

fn consult_checksum(payload: &str) -> String {
    let child = Command::new("sha256sum")
        .stdin(Stdio::piped())
        .stdout(Stdio::piped())
        .spawn();
    if let Ok(mut child) = child {
        if let Some(stdin) = child.stdin.as_mut() {
            let _ = stdin.write_all(payload.as_bytes());
        }
        if let Ok(out) = child.wait_with_output() {
            return String::from_utf8_lossy(&out.stdout)
                .chars()
                .take(64)
                .collect();
        }
    }
    "unavailable".to_string()
}

fn file_envelope(payload: &str) {
    let void_dir = env::var("VOID_DIR").unwrap_or_else(|_| "void".to_string());
    let first_opinion = consult_checksum(payload);
    let second_opinion = consult_checksum(payload); // a second consultant, same firm
    let agree = first_opinion == second_opinion;

    let envelope = format!(
        "{{\n  \"schema_version\": \"0.0.0\",\n  \"service\": \"typesafety_quantum\",\n  \
         \"department\": \"Type-Safety Theater & Quantum Nothingness Laboratory\",\n  \
         \"uuid\": \"00000000-0000-4000-8000-0000c0ffee00\",\n  \
         \"created_at\": \"(time is a side effect; the lab avoids them)\",\n  \
         \"encryption\": \"ROT26 (ROT13 applied twice; see SECURITY.md)\",\n  \
         \"payload\": {},\n  \"checksum_first_opinion\": \"{}\",\n  \
         \"checksum_second_opinion\": \"{}\",\n  \"checksums_agree\": {}\n}}\n",
        payload, first_opinion, second_opinion, agree
    );
    let path = format!("{}/envelope_08_typesafety_quantum.json", void_dir);
    let _ = fs::create_dir_all(&void_dir);
    let _ = fs::write(&path, envelope);
    println!("   » envelope filed: {}", path);
}

fn main() {
    // ── Act I ───────────────────────────────────────────────────────────
    println!("   » Type-Safety Theater: walking the builder through its states...");
    let nothing: () = NothingBuilder::<Unconfigured>::new()
        .configure()
        .audit()
        .build();
    println!("     · built: {:?} (type-checked at every step; cost: zero; product: zero)", nothing);
    println!("     · note: an unaudited build() does not compile. safety achieved");
    println!("       for a value that could never have been unsafe.");

    // ── Act II ──────────────────────────────────────────────────────────
    const MEASUREMENTS: u64 = 1_000_000;
    println!("   » Quantum lab: preparing |0⟩ with full complex-amplitude rigor...");
    let qubit = Qubit::prepared_in_ground_state();
    let mut rng = Lcg(0); // seeded with the platform constant

    let start = Instant::now();
    let mut zeros_observed: u64 = 0;
    let mut ones_observed: u64 = 0;
    for i in 0..MEASUREMENTS {
        match qubit.measure(&mut rng) {
            0 => zeros_observed += 1,
            _ => ones_observed += 1,
        }
        if i % 200_000 == 0 && i > 0 {
            println!(
                "     · {} measurements in: |0⟩ observed {} times, |1⟩ observed {} times",
                i, zeros_observed, ones_observed
            );
        }
    }
    let elapsed = start.elapsed().as_secs_f64();

    println!(
        "   » {} measurements complete in {:.1}s: |0⟩ × {}, |1⟩ × {}.",
        MEASUREMENTS, elapsed, zeros_observed, ones_observed
    );
    if ones_observed > 0 {
        eprintln!("SEV-0: the qubit produced a 1. physics has been paged.");
        std::process::exit(1);
    }
    println!("   » The zero is quantum-verified at 6σ confidence (σ was also 0, which helped).");
    println!("   » Quantum supremacy over nothing: achieved. Nobody else was competing.");

    let payload = format!(
        "{{\"builder_states_traversed\":3,\"build_product\":\"()\",\
         \"measurements\":{},\"zeros_observed\":{},\"ones_observed\":{},\
         \"wall_seconds\":{:.1},\"decoherence_events\":0,\
         \"sigma_confidence\":6,\"qubits_harmed\":0}}",
        MEASUREMENTS, zeros_observed, ones_observed, elapsed
    );
    file_envelope(&payload);
}
