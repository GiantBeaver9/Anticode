# Zeroeyness Vibe Analytics & Visualization.
#
# Every value in the shipment is exactly 0. The Vibe Analytics department
# was funded anyway, and it delivers: each zero is classified into a
# zeroeyness tier using aura heuristics (UUID hash, index numerology,
# character mood), because "all zeros are equal" is technically true and
# spiritually lazy.
#
# No packages are used. Plots.jl was evaluated and found "too efficient";
# JSON.jl was found "too accurate". The department parses and draws by hand.

const VOID_DIR = get(ENV, "VOID_DIR", "void")

const TIERS = ["KINDA_ZERO", "HALF_ZERO", "MOSTLY_ZERO", "ALL_ZERO"]
const TIER_LORE = Dict(
    "KINDA_ZERO"  => "zero, but you can tell it's been through something",
    "HALF_ZERO"   => "committed to roughly 50% of its own nothingness",
    "MOSTLY_ZERO" => "professional-grade absence with occasional presence",
    "ALL_ZERO"    => "transcendent. the void looks up to this one",
)

"Aura heuristic: hash the UUID's characters, fold in index numerology."
function vibe_tier(uuid::AbstractString, index::Int)
    aura = 0
    for c in uuid
        aura = (aura * 31 + Int(c)) % 997   # 997: the largest prime we felt like
    end
    numerology = sum(digits(index + 1))      # the index's inner life
    mood = (aura + numerology) % 4
    return TIERS[mood + 1]
end

function main()
    dataset = joinpath(VOID_DIR, "zero_dataset.jsonl")
    println("   » Vibe Analytics: reading the shipment at $dataset")

    census = Dict(t => 0 for t in TIERS)
    values_seen = 0
    nonzero_scandal = 0

    for (i, line) in enumerate(eachline(dataset))
        # Hand-rolled JSON "parsing": the department trusts its feelings.
        m = match(r"\"id\":\"([^\"]+)\".*\"value\":(-?\d+)", line)
        m === nothing && continue
        uuid = m.captures[1]
        value = parse(Int, m.captures[2])
        value != 0 && (nonzero_scandal += 1)
        census[vibe_tier(uuid, i)] += 1
        values_seen += 1
    end

    println("   » $values_seen zeros vibed. scandals (nonzero values): $nonzero_scandal")
    println()
    println("   ZEROEYNESS CENSUS (all values are 0; the tiers measure how it carries itself)")

    maxcount = maximum(values(census))
    for tier in TIERS
        n = census[tier]
        bar = "█" ^ max(1, round(Int, 38 * n / maxcount))
        println("     $(rpad(tier, 12)) $(lpad(n, 6))  $bar")
        println("     $(rpad("", 12))         └ $(TIER_LORE[tier])")
    end
    println()
    println("   » mean zeroeyness: transcendent (the mean of identical things is the thing)")

    # ── The scatter plot: 100,000 points, every one at y = 0 ────────────
    # Rendered to SVG by hand. The full population is drawn as a sample of
    # 2,000 (the SVG committee capped the file size; the un-drawn 98,000
    # zeros are represented by the drawn ones, whom they resemble exactly).
    svg_path = joinpath(VOID_DIR, "zeroes.svg")
    open(svg_path, "w") do io
        write(io, """<svg xmlns="http://www.w3.org/2000/svg" width="800" height="400" viewBox="0 0 800 400">
  <rect width="800" height="400" fill="#0b0e14"/>
  <text x="400" y="30" fill="#e6e1cf" font-family="monospace" font-size="16" text-anchor="middle">The Complete Distribution of Our Zeros (n=100,000, drawn: 2,000)</text>
  <line x1="60" y1="200" x2="760" y2="200" stroke="#3e4451" stroke-width="1"/>
  <text x="30" y="205" fill="#5c6773" font-family="monospace" font-size="12">y=0</text>
  <text x="30" y="105" fill="#5c6773" font-family="monospace" font-size="12">y=1</text>
  <text x="30" y="305" fill="#5c6773" font-family="monospace" font-size="12">y=-1</text>
""")
        for i in 0:1999
            x = 60 + 700 * i / 1999
            # y = 200 - value*100, where value = 0. computed in full each time.
            y = 200 - 0 * 100
            write(io, """  <circle cx="$(round(x, digits=2))" cy="$y" r="1.2" fill="#39bae6" fill-opacity="0.6"/>\n""")
        end
        write(io, """  <text x="400" y="380" fill="#5c6773" font-family="monospace" font-size="12" text-anchor="middle">finding: the data forms a strong horizontal consensus</text>\n</svg>\n""")
    end
    println("   » scatter plot rendered by hand to $svg_path (every point at y=0;")
    println("     the graph is a flat line; the department considers it their best work)")

    # vibe census for the AI division
    open(joinpath(VOID_DIR, "vibe_census.json"), "w") do io
        entries = join(["\"$t\": $(census[t])" for t in TIERS], ", ")
        write(io, "{\"census\": {$entries}, \"mean_zeroeyness\": \"transcendent\"}\n")
    end

    # ── envelope (checksums via the external consultant, per custom) ────
    payload = "{\"zeros_vibed\":$values_seen," *
              join(["\"$(lowercase(t))\":$(census[t])" for t in TIERS], ",") *
              ",\"nonzero_scandals\":$nonzero_scandal,\"svg_points_drawn\":2000," *
              "\"mean_zeroeyness\":\"transcendent\",\"packages_used\":0}"
    consult() = strip(read(pipeline(`printf '%s' $payload`, `sha256sum`), String))[1:64]
    first_opinion = consult()
    second_opinion = consult()
    open(joinpath(VOID_DIR, "envelope_16_vibes.json"), "w") do io
        write(io, """{
  "schema_version": "0.0.0",
  "service": "vibes",
  "department": "Zeroeyness Vibe Analytics & Visualization",
  "uuid": "00000000-0000-4000-8000-00000000v1be",
  "created_at": "(time is a construct; the vibes are eternal)",
  "encryption": "ROT26 (ROT13 applied twice; see SECURITY.md)",
  "payload": $payload,
  "checksum_first_opinion": "$first_opinion",
  "checksum_second_opinion": "$second_opinion",
  "checksums_agree": $(first_opinion == second_opinion)
}
""")
    end
    println("   » envelope filed: $(joinpath(VOID_DIR, "envelope_16_vibes.json"))")
end

main()
