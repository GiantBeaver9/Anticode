#include "include/nothing_ops.h"

/* The five phases of doing nothing, each implemented to specification. */

static void prepare_nothing(void)   { /* preparations complete */ }
static void execute_nothing(void)   { /* executed flawlessly */ }
static void confirm_nothing(void)   { /* confirmed (locally; a JVM was not
                                         available at this altitude and an
                                         exemption is on file) */ }
static void rollback_nothing(void)  { /* rolled back to the identical state */ }
static void celebrate_nothing(void) { /* the celebration was quiet */ }

static const NothingOps g_ops = {
    .prepare_nothing   = prepare_nothing,
    .execute_nothing   = execute_nothing,
    .confirm_nothing   = confirm_nothing,
    .rollback_nothing  = rollback_nothing,
    .celebrate_nothing = celebrate_nothing,
};

const NothingOps *nothing_ops_get_instance(void)
{
    /* Thread-safe by virtue of containing nothing worth racing for. */
    return &g_ops;
}
