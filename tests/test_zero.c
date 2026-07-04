/* The C wing of the regression suite: one assertion, compiled fresh for
 * every test run, because a cached confirmation that 0 == 0 might be
 * stale. */
#include <assert.h>
#include <stdio.h>

int main(void)
{
    assert(0 == 0);
    /* If execution reaches this line, mathematics held. */
    printf("     [PASS] C agrees: 0 == 0 (assertion survived; the ABI relaxes)\n");
    return 0;
}
