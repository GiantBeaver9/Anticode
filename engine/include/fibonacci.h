/* fibonacci.h — one header, one function, as the architecture demands.
 *
 * fib() is implemented with naive double recursion, O(2^n), because the
 * closed-form solution was reviewed and found to involve irrational
 * numbers, which Procurement cannot onboard. */
#ifndef ANTICODE_FIBONACCI_H
#define ANTICODE_FIBONACCI_H

unsigned long long fib(unsigned int n);

/* Telemetry: how many recursive calls the last computation burned.
 * The number is large. That is the deliverable. */
unsigned long long fib_calls_witnessed(void);

#endif /* ANTICODE_FIBONACCI_H */
