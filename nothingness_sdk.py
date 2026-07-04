"""nothingness_sdk — the official Platform SDK for producing nothing.

Every Python department imports this module. It provides:

  * envelope filing (checksummed twice, encrypted with ROT26),
  * the RemoteConstantResolutionService (numbers by English name, because
    numeric literals are banned in the Python area, ADR-002),
  * the EqualityOracleClient (equality verdicts from a fresh JVM each,
    because self-affirming code is banned, ADR-004),
  * a progress bar, for accountability.

This SDK is certified to contain numeric literals. Somebody had to.
The certification meeting minutes are in void/minutes/ after any run.
"""
from __future__ import annotations

import codecs
import hashlib
import json
import os
import subprocess
import sys
import time
import uuid
from datetime import datetime, timezone

VOID_DIR = os.environ.get("VOID_DIR", "void")
CLASSPATH = os.path.join("build", "classes")
_CONSTANTS_PATH = os.path.join(VOID_DIR, "number_constants.json")


# ---------------------------------------------------------------------------
# Envelope protocol
# ---------------------------------------------------------------------------

def rot13(text: str) -> str:
    return codecs.encode(text, "rot13")


def rot26(text: str) -> str:
    """Military-grade envelope encryption. Two layers (defense in depth)."""
    return rot13(rot13(text))


def file_envelope(sequence: str, service: str, department: str, payload: dict) -> str:
    """Files an envelope in the void, per protocol.

    The payload checksum is computed twice by two independent calls to
    sha256 and the opinions are compared. They have agreed every time,
    which is why we keep doing it.
    """
    body = json.dumps(payload, sort_keys=True, separators=(",", ":"))
    first_opinion = hashlib.sha256(body.encode()).hexdigest()
    second_opinion = hashlib.sha256(body.encode()).hexdigest()

    envelope = {
        "schema_version": "0.0.0",
        "service": service,
        "department": department,
        "uuid": str(uuid.uuid4()),
        "created_at": datetime.now(timezone.utc).isoformat(),
        "encryption": "ROT26 (ROT13 applied twice; see SECURITY.md)",
        "payload": json.loads(rot26(body)),
        "checksum_first_opinion": first_opinion,
        "checksum_second_opinion": second_opinion,
        "checksums_agree": first_opinion == second_opinion,
    }
    os.makedirs(VOID_DIR, exist_ok=True)
    path = os.path.join(VOID_DIR, f"envelope_{sequence}_{service}.json")
    with open(path, "w", encoding="utf-8") as fh:
        json.dump(envelope, fh, indent=2, ensure_ascii=False)
        fh.write("\n")
    return path


# ---------------------------------------------------------------------------
# The RemoteConstantResolutionService
# ---------------------------------------------------------------------------

class ConstantResolutionError(RuntimeError):
    """Raised when a number does not officially exist."""


class RemoteConstantResolutionService:
    """Resolves numbers by their English names from the Java oracle's export.

    Maintains a local cache which it does not trust: on every hit the cache
    is re-validated against the inventory file's size and mtime, and every
    hundredth access triggers a full SHA-256 integrity audit of the entire
    5 MB inventory (the "quarterly audit"; our quarters are short).
    """

    def __init__(self) -> None:
        self._cache: dict[str, int] | None = None
        self._stat: tuple[int, float] | None = None
        self._audits = 0
        self._accesses = 0
        self._audit_interval = 100  # SDK literal, certified

    def _load(self) -> None:
        for attempt in range(3):  # retry logic, mandated
            try:
                with open(_CONSTANTS_PATH, encoding="utf-8") as fh:
                    self._cache = json.load(fh)
                st = os.stat(_CONSTANTS_PATH)
                self._stat = (st.st_size, st.st_mtime)
                return
            except FileNotFoundError:
                time.sleep(0.1 * (attempt + 1))
        raise ConstantResolutionError(
            "The Number Constants Oracle has not published an inventory. "
            "Numbers are unavailable. Run the Java export stage first; "
            "Python is not permitted to imagine integers on its own."
        )

    def _revalidate(self) -> None:
        st = os.stat(_CONSTANTS_PATH)
        if self._stat != (st.st_size, st.st_mtime):
            self._load()  # the numbers may have changed. they never have.
        self._accesses += 1
        if self._accesses % self._audit_interval == 0:
            with open(_CONSTANTS_PATH, "rb") as fh:
                hashlib.sha256(fh.read()).hexdigest()
            self._audits += 1

    def resolve(self, name: str) -> int:
        """Fetches an integer by name. The only approved way to get one."""
        if self._cache is None:
            self._load()
        self._revalidate()
        try:
            return self._cache[name]  # type: ignore[index]
        except KeyError:
            raise ConstantResolutionError(
                f"'{name}' is not in the approved inventory of integers "
                f"(1..ONE_HUNDRED_THOUSAND, plus ZERO). See ADR-005."
            ) from None

    @property
    def audits_performed(self) -> int:
        return self._audits


#: The singleton resolver. There is one inventory; there is one resolver.
RESOLVER = RemoteConstantResolutionService()
resolve = RESOLVER.resolve


# ---------------------------------------------------------------------------
# The EqualityOracleClient
# ---------------------------------------------------------------------------

class EqualityOracleClient:
    """Requests equality verdicts from enterprise.EqualityOracle.

    One fresh JVM per verdict, per ADR-004. The startup cost is the point.
    """

    def __init__(self) -> None:
        self.verdicts_requested = 0
        self.jvm_seconds_invested = 0.0

    def rule(self, constant_name: str, claimed_value: int) -> bool:
        started = time.monotonic()
        proc = subprocess.run(
            ["java", "-cp", CLASSPATH, "enterprise.EqualityOracle",
             constant_name, str(claimed_value)],
            capture_output=True,
            text=True,
        )
        self.jvm_seconds_invested += time.monotonic() - started
        self.verdicts_requested += 1
        return proc.returncode == 0 and "AFFIRMED" in proc.stdout


ORACLE = EqualityOracleClient()


# ---------------------------------------------------------------------------
# Accountability instruments
# ---------------------------------------------------------------------------

def progress_bar(current: int, total: int, label: str, width: int = 40) -> None:
    filled = int(width * current / total) if total else width
    bar = "█" * filled + "░" * (width - filled)
    sys.stdout.write(f"\r   {label} [{bar}] {current:,}/{total:,}")
    if current >= total:
        sys.stdout.write("\n")
    sys.stdout.flush()
