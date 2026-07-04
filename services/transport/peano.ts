/**
 * The Compile-Time Zero Proof Bureau.
 *
 * Runtime verification of zero is handled by other departments (all of
 * them). This file makes the COMPILER do it: Peano naturals are encoded as
 * tuple types, arithmetic as tuple surgery, and the propositions below are
 * checked during `tsc`. If 0 + 0 ever stops being 0, the build fails and
 * the platform — correctly — cannot ship.
 *
 * This file compiles to nothing. It is our proudest artifact.
 */

// ── Peano naturals as tuples ───────────────────────────────────────────────
type Zero = [];
type Succ<N extends unknown[]> = [...N, unknown];

type N0 = Zero;
type N1 = Succ<N0>;
type N2 = Succ<N1>;
type N3 = Succ<N2>;
type N4 = Succ<N3>;
type N5 = Succ<N4>;
type N6 = Succ<N5>;
type N7 = Succ<N6>;
type N8 = Succ<N7>;
type N9 = Succ<N8>;
type N10 = Succ<N9>;
type N11 = Succ<N10>;
type N12 = Succ<N11>;
type N13 = Succ<N12>;
type N14 = Succ<N13>;
type N15 = Succ<N14>;
type N16 = Succ<N15>;
type N17 = Succ<N16>;
type N18 = Succ<N17>;
type N19 = Succ<N18>;
type N20 = Succ<N19>;

// ── Arithmetic, performed by the type checker ─────────────────────────────
type Add<A extends unknown[], B extends unknown[]> = [...A, ...B];

type Mul<A extends unknown[], B extends unknown[]> =
    A extends [unknown, ...infer Rest extends unknown[]]
        ? Add<B, Mul<Rest, B>>
        : Zero;

type ValueOf<N extends unknown[]> = N["length"];

// ── The proof harness ─────────────────────────────────────────────────────
// Assert<T> only accepts `true`. A false proposition is a compile error,
// which is the only kind of error this department respects.
type Assert<T extends true> = T;
type Equal<A, B> = (<T>() => T extends A ? 1 : 2) extends
                   (<T>() => T extends B ? 1 : 2) ? true : false;

// ── PROPOSITION I: 0 + 0 = 0 (the cornerstone) ────────────────────────────
type Proof_ZeroPlusZero = Assert<Equal<ValueOf<Add<Zero, Zero>>, 0>>;

// ── PROPOSITION II: 0 is the additive identity from both sides ────────────
type Proof_LeftIdentity  = Assert<Equal<Add<Zero, N7>, N7>>;
type Proof_RightIdentity = Assert<Equal<Add<N7, Zero>, N7>>;

// ── PROPOSITION III: 0 × N = 0, proven individually for N = 0..20, ────────
// because a general proof would require trusting induction, and trust is
// not a control (ADR-004).
type Proof_MulZero_0  = Assert<Equal<ValueOf<Mul<Zero, N0>>,  0>>;
type Proof_MulZero_1  = Assert<Equal<ValueOf<Mul<Zero, N1>>,  0>>;
type Proof_MulZero_2  = Assert<Equal<ValueOf<Mul<Zero, N2>>,  0>>;
type Proof_MulZero_3  = Assert<Equal<ValueOf<Mul<Zero, N3>>,  0>>;
type Proof_MulZero_4  = Assert<Equal<ValueOf<Mul<Zero, N4>>,  0>>;
type Proof_MulZero_5  = Assert<Equal<ValueOf<Mul<Zero, N5>>,  0>>;
type Proof_MulZero_6  = Assert<Equal<ValueOf<Mul<Zero, N6>>,  0>>;
type Proof_MulZero_7  = Assert<Equal<ValueOf<Mul<Zero, N7>>,  0>>;
type Proof_MulZero_8  = Assert<Equal<ValueOf<Mul<Zero, N8>>,  0>>;
type Proof_MulZero_9  = Assert<Equal<ValueOf<Mul<Zero, N9>>,  0>>;
type Proof_MulZero_10 = Assert<Equal<ValueOf<Mul<Zero, N10>>, 0>>;
type Proof_MulZero_11 = Assert<Equal<ValueOf<Mul<Zero, N11>>, 0>>;
type Proof_MulZero_12 = Assert<Equal<ValueOf<Mul<Zero, N12>>, 0>>;
type Proof_MulZero_13 = Assert<Equal<ValueOf<Mul<Zero, N13>>, 0>>;
type Proof_MulZero_14 = Assert<Equal<ValueOf<Mul<Zero, N14>>, 0>>;
type Proof_MulZero_15 = Assert<Equal<ValueOf<Mul<Zero, N15>>, 0>>;
type Proof_MulZero_16 = Assert<Equal<ValueOf<Mul<Zero, N16>>, 0>>;
type Proof_MulZero_17 = Assert<Equal<ValueOf<Mul<Zero, N17>>, 0>>;
type Proof_MulZero_18 = Assert<Equal<ValueOf<Mul<Zero, N18>>, 0>>;
type Proof_MulZero_19 = Assert<Equal<ValueOf<Mul<Zero, N19>>, 0>>;
type Proof_MulZero_20 = Assert<Equal<ValueOf<Mul<Zero, N20>>, 0>>;

// ── PROPOSITION IV: multiplying zero BY zero also yields zero, both ways, ─
// in case commutativity was ever in doubt (it was; see minutes).
type Proof_ZeroTimesZero      = Assert<Equal<ValueOf<Mul<Zero, Zero>>, 0>>;
type Proof_ZeroTimesZeroAgain = Assert<Equal<ValueOf<Mul<Zero, Zero>>, 0>>; // second opinion

// ── PROPOSITION V: the 0^0^0 schism, at the type level, remains open. ────
// Exponentiation is deliberately NOT implemented here. The type system must
// remain neutral territory (theology/ has jurisdiction).

// The proofs above are erased at compile time. What ships is nothing,
// which has been formally verified.
export {};
