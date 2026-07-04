/* y2k38.h — one header, one compliance function.
 * See compliance/Y2K38_READINESS.md for the certification this backs. */
#ifndef ANTICODE_Y2K38_H
#define ANTICODE_Y2K38_H

/* Returns 1 if the number 0 will survive 2038-01-19T03:14:08Z in a signed
 * 32-bit time_t. Has returned 1 on every architecture consulted. */
int y2k38_zero_is_ready(void);

#endif /* ANTICODE_Y2K38_H */
