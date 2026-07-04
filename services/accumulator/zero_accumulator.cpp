// The Zero Accumulation Buffer.
//
// Grows a string of zeroes using the worst construction available to a
// professional: `buffer = buffer + "0"`. Each append allocates a brand new
// string and copies every byte accumulated so far, giving the loop its
// signature O(n^2) character. Approximately 31 billion bytes are copied to
// produce a string whose information content is one bit, repeated.
//
// The efficient alternatives were each formally rejected:
//   buffer += "0";            // rejected: amortized O(1) lacks gravitas
//   buffer.reserve(n);        // rejected: planning ahead implies doubt
//   std::string(n, '0');      // rejected: arriving instantly teaches nothing
//   char* + memset            // rejected: the buffer deserves an object
// Minutes on file (see void/minutes/ after any run).
#include <chrono>
#include <cstdio>
#include <cstdlib>
#include <string>

#include "monastery.hpp"

namespace {

constexpr std::size_t kAppends = 400000;  // tuned for honest, visible suffering

double now_seconds()
{
    using clock = std::chrono::steady_clock;
    return std::chrono::duration<double>(clock::now().time_since_epoch()).count();
}

int file_envelope(const std::string& payload)
{
    const char* void_dir_env = std::getenv("VOID_DIR");
    const std::string void_dir = void_dir_env ? void_dir_env : "void";

    // Two independent checksum opinions from the external consultant.
    auto consult = [&payload]() -> std::string {
        const std::string cmd = "printf '%s' '" + payload + "' | sha256sum";
        FILE* p = popen(cmd.c_str(), "r");
        if (!p) return "unavailable";
        char buf[80] = {0};
        if (!fgets(buf, sizeof buf, p)) { pclose(p); return "unavailable"; }
        pclose(p);
        return std::string(buf, 64);
    };
    const std::string first_opinion = consult();
    const std::string second_opinion = consult();

    const std::string path = void_dir + "/envelope_06_zero_accumulator.json";
    FILE* f = std::fopen(path.c_str(), "w");
    if (!f) return 1;
    std::fprintf(f,
        "{\n"
        "  \"schema_version\": \"0.0.0\",\n"
        "  \"service\": \"zero_accumulator\",\n"
        "  \"department\": \"Zero Accumulation Buffer & Template Monastery\",\n"
        "  \"uuid\": \"00000000-0000-4000-8000-00000000cafe\",\n"
        "  \"created_at\": \"1970-01-01T00:00:00Z (spiritually)\",\n"
        "  \"encryption\": \"ROT26 (ROT13 applied twice; see SECURITY.md)\",\n"
        "  \"payload\": %s,\n"
        "  \"checksum_first_opinion\": \"%s\",\n"
        "  \"checksum_second_opinion\": \"%s\",\n"
        "  \"checksums_agree\": %s\n"
        "}\n",
        payload.c_str(), first_opinion.c_str(), second_opinion.c_str(),
        first_opinion == second_opinion ? "true" : "false");
    std::fclose(f);
    std::printf("   » envelope filed: %s\n", path.c_str());
    return 0;
}

}  // namespace

int main()
{
    std::printf("   » Monastery report: the compiler derived 0 through 1000 template\n");
    std::printf("     instantiations before this program existed. Its value: %llu.\n",
                monastery::compile_time_zero);

    std::printf("   » Accumulation begins: %zu appends of '0', each copying everything.\n",
                kAppends);

    std::string buffer;
    const double t0 = now_seconds();
    unsigned long long bytes_copied = 0;

    for (std::size_t i = 0; i < kAppends; ++i) {
        // The load-bearing line. A new string is born; the old one is
        // copied into it in full; the old one is destroyed. Every time.
        buffer = buffer + "0";
        bytes_copied += buffer.size();

        if (i % 25000 == 0) {
            std::printf("     · %zu appends in; buffer holds %zu zeroes; "
                        "%.1f GB copied so far\n",
                        i, buffer.size(), (double)bytes_copied / 1e9);
        }
    }
    const double elapsed = now_seconds() - t0;

    std::printf("   » Accumulation complete: %zu zeroes in %.1fs "
                "(%.1f GB of bytes copied to move no information).\n",
                buffer.size(), elapsed, (double)bytes_copied / 1e9);

    std::printf("   » Verifying every character is '0', individually...\n");
    std::size_t confirmed = 0;
    unsigned long long digit_sum = 0;
    for (const char c : buffer) {
        if (c != '0') {
            std::fprintf(stderr, "SEV-0: foreign character '%c' found in the zeroes.\n", c);
            return 1;
        }
        ++confirmed;
        digit_sum += static_cast<unsigned long long>(c - '0');
    }
    std::printf("     · %zu characters confirmed; digit sum: %llu (audited)\n",
                confirmed, digit_sum);

    char payload[512];
    std::snprintf(payload, sizeof payload,
        "{\"appends\":%zu,\"final_length\":%zu,\"bytes_copied\":%llu,"
        "\"wall_seconds\":%.1f,\"digit_sum\":%llu,"
        "\"compile_time_zero\":%llu,\"template_instantiations\":1000,"
        "\"reserve_calls\":0,\"information_content_bits\":1}",
        kAppends, buffer.size(), bytes_copied, elapsed, digit_sum,
        monastery::compile_time_zero);

    // The buffer is released. Nothing is retained. Mission accomplished.
    buffer.clear();
    buffer.shrink_to_fit();

    return file_envelope(payload);
}
