# Monte Carlo Integration of Nothing.
#
# Computes ∫₀⁰ x² dx — the definite integral of a perfectly good function
# over an interval of width zero — using ten million Monte Carlo samples,
# "to be sure". The analytic answer (0) has been known since integration
# was invented, which the department regards as hearsay.

const VOID_DIR = get(ENV, "VOID_DIR", "void")
const SAMPLES = 10_000_000

f(x) = x^2   # the integrand. blameless. deserves a wider interval someday.

function main()
    a, b = 0.0, 0.0   # the interval [0, 0]: all endpoints, no middle
    width = b - a

    println("   » Monte Carlo Integration: ∫ x² dx over [$a, $b], n = $(SAMPLES)")
    println("   » interval width: $width (the department was warned; the department proceeded)")

    # A deterministic LCG: reproducible waste is auditable waste.
    state = UInt64(0)
    next_uniform() = begin
        state = state * 0x5851f42d4c957f2d + 0x14057b7ef767814f
        Float64(state >> 11) / Float64(UInt64(1) << 53)
    end

    acc = 0.0
    evaluations = 0
    t0 = time()
    for i in 1:SAMPLES
        u = next_uniform()
        x = a + u * width        # every sample point is 0, drawn with full ceremony
        acc += f(x)              # f(0) = 0, evaluated ten million times
        evaluations += 1
        if i % 2_000_000 == 0
            println("     · $i samples in; running estimate: $(acc * width / i) (steady)")
        end
    end
    elapsed = time() - t0

    estimate = acc * width / SAMPLES     # (mean of f) × (width 0) = 0, rigorously
    stderr_est = 0.0                     # the variance of identical samples: also 0

    println("   » result: $estimate ± $stderr_est (95% CI: [0.0, 0.0] — the tightest interval in science)")
    println("   » $evaluations evaluations of f in $(round(elapsed, digits=1))s, all at x = 0,")
    println("     all agreeing. convergence plot: flat. it converged before we began.")

    # append the convergence "plot" to the SVG if the vibes department left one
    svg_path = joinpath(VOID_DIR, "zeroes.svg")
    if isfile(svg_path)
        svg = read(svg_path, String)
        insert_at = findlast("</svg>", svg)
        if insert_at !== nothing
            addition = """  <line x1="60" y1="340" x2="760" y2="340" stroke="#7fd962" stroke-width="1.5"/>
  <text x="400" y="358" fill="#7fd962" font-family="monospace" font-size="11" text-anchor="middle">Monte Carlo convergence (10,000,000 samples): flat, immediately, forever</text>
"""
            svg = svg[1:first(insert_at)-1] * addition * "</svg>\n"
            write(svg_path, svg)
            println("   » convergence plot appended to $svg_path (it is a horizontal line)")
        end
    end

    payload = "{\"samples\":$SAMPLES,\"estimate\":$estimate,\"stderr\":$stderr_est," *
              "\"wall_seconds\":$(round(elapsed, digits=1)),\"interval_width\":$width," *
              "\"analytic_answer_available\":true,\"analytic_answer_trusted\":false}"
    consult() = strip(read(pipeline(`printf '%s' $payload`, `sha256sum`), String))[1:64]
    first_opinion = consult()
    second_opinion = consult()
    open(joinpath(VOID_DIR, "envelope_17_integration.json"), "w") do io
        write(io, """{
  "schema_version": "0.0.0",
  "service": "integration",
  "department": "Monte Carlo Integration of Nothing",
  "uuid": "00000000-0000-4000-8000-000000000mc0",
  "created_at": "(sampled uniformly from [now, now])",
  "encryption": "ROT26 (ROT13 applied twice; see SECURITY.md)",
  "payload": $payload,
  "checksum_first_opinion": "$first_opinion",
  "checksum_second_opinion": "$second_opinion",
  "checksums_agree": $(first_opinion == second_opinion)
}
""")
    end
    println("   » envelope filed: $(joinpath(VOID_DIR, "envelope_17_integration.json"))")
end

main()
