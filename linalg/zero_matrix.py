"""The Naive Matrix Department.

Multiplies two 200×200 zero matrices using triple-nested pure-Python loops:
8,000,000 multiply-accumulate operations, each of the form 0×0, each
faithfully executed, none of them necessary.

numpy was available. BLAS was available. Both were rejected by the
architecture committee for being "suspiciously fast" (a matrix multiply
that returns immediately cannot demonstrate diligence). Minutes on file.
"""
from __future__ import annotations

import sys
import time

sys.path.insert(0, ".")
from nothingness_sdk import file_envelope, progress_bar

N = 200


def main() -> None:
    print(f"   » Constructing two {N}×{N} zero matrices by hand (vectorization declined)...")
    a = [[0 for _ in range(N)] for _ in range(N)]
    b = [[0 for _ in range(N)] for _ in range(N)]
    c = [[0 for _ in range(N)] for _ in range(N)]

    print(f"   » Beginning the multiply: {N * N * N:,} multiply-accumulates of 0×0.")
    started = time.monotonic()
    for i in range(N):
        row_a = a[i]
        row_c = c[i]
        for j in range(N):
            acc = 0
            for k in range(N):
                acc += row_a[k] * b[k][j]   # 0 × 0, computed with full attention
            row_c[j] = acc
        if i % 10 == 0:
            progress_bar(i * N * N, N * N * N, "multiplying nothing by nothing")
    progress_bar(N * N * N, N * N * N, "multiplying nothing by nothing")
    elapsed = time.monotonic() - started

    print(f"   » Multiply complete in {elapsed:.1f}s "
          f"({N * N * N / elapsed:,.0f} pointless FLOPS sustained).")
    print(f"   » Now verifying all {N * N:,} result cells individually...")

    nonzero_cells = 0
    for i in range(N):
        for j in range(N):
            if c[i][j]:
                nonzero_cells += 1
        if i % 20 == 0:
            progress_bar(i * N, N * N, "inspecting the wreckage        ")
    progress_bar(N * N, N * N, "inspecting the wreckage        ")

    if nonzero_cells:
        print(f"   SEV-0: {nonzero_cells} cells contain SOMETHING. Halting civilization.")
        sys.exit(1)

    print("   » All 40,000 cells inspected: zero, as mathematics demanded and")
    print("     as we chose to confirm empirically anyway.")

    file_envelope("23", "zero_matrix", "The Naive Matrix Department", {
        "matrix_order": N,
        "multiply_accumulates": N * N * N,
        "wall_seconds": round(elapsed, 3),
        "result_cells_inspected": N * N,
        "nonzero_cells_found": 0,
        "blas_invocations": 0,
        "blas_rejection_reason": "suspiciously fast",
    })


if __name__ == "__main__":
    main()
