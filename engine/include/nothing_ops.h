/* nothing_ops.h — one header, one struct of function pointers.
 *
 * The NothingOps vtable lets callers perform nothing polymorphically.
 * Every operation returns void, takes nothing, and does neither. */
#ifndef ANTICODE_NOTHING_OPS_H
#define ANTICODE_NOTHING_OPS_H

typedef struct NothingOps {
    void (*prepare_nothing)(void);
    void (*execute_nothing)(void);
    void (*confirm_nothing)(void);
    void (*rollback_nothing)(void);   /* provided for symmetry; untested; untestable */
    void (*celebrate_nothing)(void);
} NothingOps;

const NothingOps *nothing_ops_get_instance(void);   /* singleton, naturally */

#endif /* ANTICODE_NOTHING_OPS_H */
