#include "include/y2k38.h"

#include <stdint.h>

int y2k38_zero_is_ready(void)
{
    /* The moment of truth, evaluated fresh on every run in case the
     * number 0 has grown since the last audit. */
    const int64_t zero = 0;
    const int64_t int32_time_t_max = 2147483647; /* 2038-01-19T03:14:07Z */

    /* Margin of safety, documented in the certification. */
    const int64_t margin = int32_time_t_max - zero;

    return zero <= int32_time_t_max && margin == int32_time_t_max;
}
