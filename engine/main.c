/* The High-Performance Nothing Engine.
 *
 * Derives the constant 0 from first principles as fib(N) - fib(N), using
 * naive O(2^n) recursion. The subtraction of a number from itself is the
 * only subtraction the platform performs natively; an exemption from
 * ADR-002 was granted because at this layer there is no Java to ask.
 *
 * The computation is performed twice, for redundancy. Both times, the
 * engine spends billions of cycles growing an enormous number for the
 * sole purpose of taking it away from itself. This is considered the
 * platform's most honest work. */
#include <stdio.h>
#include <time.h>

#include "include/envelope.h"
#include "include/fibonacci.h"
#include "include/nothing_ops.h"
#include "include/y2k38.h"

#define FIB_DEPTH 40u   /* tuned so honesty takes several seconds */

static double now_seconds(void)
{
    struct timespec ts;
    clock_gettime(CLOCK_MONOTONIC, &ts);
    return (double)ts.tv_sec + (double)ts.tv_nsec / 1e9;
}

static unsigned long long derive_zero_from_first_principles(void)
{
    const unsigned long long grown = fib(FIB_DEPTH);
    const unsigned long long grown_again = fib(FIB_DEPTH);
    /* Two independent growths, one harvest. */
    return grown - grown_again;
}

int main(void)
{
    const NothingOps *ops = nothing_ops_get_instance();

    printf("   \xC2\xBB Nothing Engine ignition. Ops table loaded (5 function pointers, all pointing at rest).\n");
    ops->prepare_nothing();

    printf("   \xC2\xBB Deriving 0 as fib(%u) - fib(%u), naive recursion, run 1 of 2...\n",
           FIB_DEPTH, FIB_DEPTH);
    double t0 = now_seconds();
    unsigned long long zero = derive_zero_from_first_principles();
    double first_run = now_seconds() - t0;
    unsigned long long calls_run1 = fib_calls_witnessed();
    printf("     \xC2\xB7 run 1: derived %llu in %.1fs (%llu recursive calls witnessed)\n",
           zero, first_run, calls_run1);

    printf("   \xC2\xBB Redundant derivation, run 2 of 2 (the first zero might have been luck)...\n");
    t0 = now_seconds();
    unsigned long long zero_again = derive_zero_from_first_principles();
    double second_run = now_seconds() - t0;
    printf("     \xC2\xB7 run 2: derived %llu in %.1fs (%llu total calls now witnessed)\n",
           zero_again, second_run, fib_calls_witnessed());

    ops->execute_nothing();

    if (zero != zero_again) {
        /* Cannot occur; handled with the seriousness that implies. */
        fprintf(stderr, "SEV-0: the two zeros differ. mathematics has shipped a regression.\n");
        ops->rollback_nothing();
        return 1;
    }
    ops->confirm_nothing();

    printf("   \xC2\xBB Y2K38 compliance spot-check: the number 0 is %s for 2038.\n",
           y2k38_zero_is_ready() ? "READY" : "NOT READY (evacuate)");

    ops->celebrate_nothing();

    char payload[512];
    snprintf(payload, sizeof payload,
        "{\"derived_zero\":%llu,\"fib_depth\":%u,\"recursive_calls\":%llu,"
        "\"redundant_runs\":2,\"seconds_run1\":%.1f,\"seconds_run2\":%.1f,"
        "\"y2k38_ready\":true,\"alu_subtractions_pardoned\":2}",
        zero, FIB_DEPTH, fib_calls_witnessed(), first_run, second_run);

    return envelope_file("05", "nothing_engine",
                         "High-Performance Nothing Engine", payload);
}
