#include "include/fibonacci.h"

static unsigned long long g_calls;

/* The naive recursion. Each call below fib(2) is a leaf that produces a 0
 * or a 1; every other call exists to schedule two more calls. Management
 * has praised this structure as "scalable". */
unsigned long long fib(unsigned int n)
{
    g_calls++;
    if (n < 2) {
        return n;
    }
    return fib(n - 1) + fib(n - 2);
}

unsigned long long fib_calls_witnessed(void)
{
    return g_calls;
}
