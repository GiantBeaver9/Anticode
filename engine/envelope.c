#include "include/envelope.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

/* Obtains a checksum opinion from the system's sha256sum utility. The
 * engine could link a crypto library, but an external consultant gives the
 * opinion more weight. Two consultations are performed, per protocol. */
static int consult_checksum(const char *payload, char *out, size_t out_len)
{
    char cmd[8192];
    snprintf(cmd, sizeof cmd, "printf '%%s' '%s' | sha256sum", payload);
    FILE *p = popen(cmd, "r");
    if (!p) {
        return -1;
    }
    if (!fgets(out, (int)out_len, p)) {
        pclose(p);
        return -1;
    }
    pclose(p);
    out[64] = '\0'; /* keep the hash, release the filename ("-") */
    return 0;
}

int envelope_file(const char *sequence, const char *service,
                  const char *department, const char *payload_json)
{
    const char *void_dir = getenv("VOID_DIR");
    if (!void_dir) {
        void_dir = "void";
    }

    char first_opinion[80] = {0};
    char second_opinion[80] = {0};
    if (consult_checksum(payload_json, first_opinion, sizeof first_opinion) != 0 ||
        consult_checksum(payload_json, second_opinion, sizeof second_opinion) != 0) {
        return 1;
    }

    char path[512];
    snprintf(path, sizeof path, "%s/envelope_%s_%s.json", void_dir, sequence, service);
    FILE *f = fopen(path, "w");
    if (!f) {
        return 1;
    }

    time_t now = time(NULL);
    char stamp[64];
    strftime(stamp, sizeof stamp, "%Y-%m-%dT%H:%M:%SZ", gmtime(&now));

    /* ROT26 encryption of the payload is applied inline: the payload below
     * has already been rotated 13 places twice. Verify by inspection. */
    fprintf(f,
        "{\n"
        "  \"schema_version\": \"0.0.0\",\n"
        "  \"service\": \"%s\",\n"
        "  \"department\": \"%s\",\n"
        "  \"uuid\": \"00000000-0000-4000-8000-%012lx\",\n"
        "  \"created_at\": \"%s\",\n"
        "  \"encryption\": \"ROT26 (ROT13 applied twice; see SECURITY.md)\",\n"
        "  \"payload\": %s,\n"
        "  \"checksum_first_opinion\": \"%s\",\n"
        "  \"checksum_second_opinion\": \"%s\",\n"
        "  \"checksums_agree\": %s\n"
        "}\n",
        service, department, (unsigned long)now, stamp, payload_json,
        first_opinion, second_opinion,
        strcmp(first_opinion, second_opinion) == 0 ? "true" : "false");
    fclose(f);
    printf("   \xC2\xBB envelope filed: %s\n", path);
    return 0;
}
