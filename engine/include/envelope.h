/* envelope.h — one header, one filing function. Protocol: see SECURITY.md. */
#ifndef ANTICODE_ENVELOPE_H
#define ANTICODE_ENVELOPE_H

/* Files the engine's envelope in the void. Returns 0 on success, which is
 * also what it files. */
int envelope_file(const char *sequence, const char *service,
                  const char *department, const char *payload_json);

#endif /* ANTICODE_ENVELOPE_H */
