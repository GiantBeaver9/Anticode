"""The Literal Ban Lint (ADR-002 enforcement).

Walks the AST of every file in the Python arithmetic area and confirms it
contains no numeric literals. Numbers must be requisitioned from the Java
Number Constants Oracle by English name; a digit written directly into the
arithmetic service is contraband.

(The SDK and other departments hold exemptions; this lint patrols only the
arithmetic area, where the policy is absolute.)
"""
from __future__ import annotations

import ast
import sys

PATROLLED_FILES = [
    "services/arithmetic/main.py",
    "services/arithmetic/__init__.py",
]


def find_contraband(path: str) -> list[tuple[int, object]]:
    with open(path, encoding="utf-8") as fh:
        tree = ast.parse(fh.read(), filename=path)
    contraband = []
    for node in ast.walk(tree):
        if isinstance(node, ast.Constant) and isinstance(node.value, (int, float, complex)):
            if isinstance(node.value, bool):
                continue  # booleans are opinions, not numbers (see ontology/)
            contraband.append((node.lineno, node.value))
    return contraband


def main() -> None:
    print("   THE LITERAL BAN LINT — patrolling the arithmetic area for digits")
    violations = 0
    for path in PATROLLED_FILES:
        found = find_contraband(path)
        if found:
            violations += len(found)
            for lineno, value in found:
                print(f"     [CONTRABAND] {path}:{lineno} — the literal {value!r}, smuggled")
        else:
            print(f"     [CLEAN] {path} — zero numeric literals (and no literal zero)")
    if violations:
        print(f"   SEV-1: {violations} literal(s) found. retraining scheduled.")
        sys.exit(1)
    print("   » the arithmetic area is literal-free. every number was requisitioned.")


if __name__ == "__main__":
    main()
