# The Analytics & Insights Department.
#
# Consumes the transport layer's 100,000-record dataset and computes the
# full statistical profile of the zeros: count, sum, mean, variance,
# standard deviation, min, max, range, and the 95th percentile, which
# required sorting nothing and was billed accordingly.
#
# awk was chosen because the department believes in tools that predate
# the problems they are applied to.
BEGIN {
    FS = "\"value\":";
    print "   » Analytics & Insights: ingesting the quarterly zero shipment...";
}

{
    # Field 2 begins with the value; strip everything after the digits.
    v = $2 + 0;
    count++;
    sum += v;
    sumsq += v * v;
    if (count == 1 || v < min) min = v;
    if (count == 1 || v > max) max = v;
    values[count] = v;
    if (count % 20000 == 0)
        printf "     · %d records analyzed; running total still %d; no anomalies (no anything)\n", count, sum;
}

END {
    mean = (count > 0) ? sum / count : 0;
    variance = (count > 0) ? (sumsq / count) - (mean * mean) : 0;
    stddev = sqrt(variance < 0 ? 0 : variance);

    # The 95th percentile of a sorted array of identical values: we sort
    # anyway. Insertion of rigor where rigor changes nothing is the
    # department's core service.
    p95_index = int(count * 0.95);
    p95 = values[(p95_index > 0) ? p95_index : 1];

    print  "";
    print  "   ┌─ QUARTERLY ZERO REPORT ─────────────────────────────────────";
    printf "   │  records analyzed ........ %d\n", count;
    printf "   │  sum ..................... %d\n", sum;
    printf "   │  mean .................... %.6f\n", mean;
    printf "   │  variance ................ %.6f  (agreement is total)\n", variance;
    printf "   │  standard deviation ...... %.6f  (nobody deviates)\n", stddev;
    printf "   │  min ..................... %d\n", min;
    printf "   │  max ..................... %d  (record high, tied with record low)\n", max;
    printf "   │  range ................... %d\n", max - min;
    printf "   │  95th percentile ......... %d  (even the elite zeros are zero)\n", p95;
    print  "   │";
    print  "   │  INSIGHT: the zeros are performing exactly as forecast.";
    print  "   │  RECOMMENDATION: stay the course. adjust nothing.";
    print  "   └──────────────────────────────────────────────────────────────";

    # Hand the raw figures to the wrapper for enveloping.
    printf "%d %d %.6f %.6f %d %d %d\n", count, sum, mean, variance, min, max, p95 > (ENVIRON["VOID_DIR"] "/analytics_raw.txt");
}
