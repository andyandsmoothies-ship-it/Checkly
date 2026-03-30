"""
verify_secure_endpoints.py — Secure-by-Default Gate
======================================================
Usage:
    python .agents/scripts/verify_secure_endpoints.py <path_or_directory>

Arguments:
    path_or_directory  A single C# file, or a directory to scan recursively
                       for *Endpoints.cs and *Controller.cs files.

Exit Codes:
    0  — All endpoint files explicitly declare authorization rules.
    1  — One or more endpoint files are exposed without explicit auth configuration.

Design Rules:
    - Never crashes: file I/O is guarded.
    - Scans files rather than AST, focusing on high-level explicit declarations.
    - Fails any file defining HTTP routes that lacks explicit Auth/Anonymous markers.
"""

import sys
import os
import re
from pathlib import Path

# ─────────────────────────────────────────────────────────────────────────────
# CONFIGURATION
# ─────────────────────────────────────────────────────────────────────────────

# Matches files that typically route HTTP traffic
ENDPOINT_FILE_PATTERN = re.compile(r"Endpoints?\.cs$|Controller\.cs$", re.IGNORECASE)

# Matches mapping of HTTP routes (Minimal APIs or Controllers)
ROUTE_MAPPING_PATTERN = re.compile(
    r"\.Map(Get|Post|Put|Delete|Patch|Group)\b|\[Http(Get|Post|Put|Delete|Patch)",
    re.IGNORECASE
)

# Matches explicit security declarations
SECURITY_DECLARATIONS = [
    ".RequireAuthorization",
    ".RequirePermission",
    ".AllowAnonymous",
    "[Authorize]",
    "[AllowAnonymous]"
]


# ─────────────────────────────────────────────────────────────────────────────
# FILE DISCOVERY
# ─────────────────────────────────────────────────────────────────────────────

def find_endpoint_files(target: str) -> list[Path]:
    """Returns all endpoint/controller files under `target`."""
    p = Path(target)
    if p.is_file():
        return [p] if ENDPOINT_FILE_PATTERN.search(p.name) else []
    
    if p.is_dir():
        results = []
        for root, _, files in os.walk(p):
            for file in files:
                if ENDPOINT_FILE_PATTERN.search(file):
                    results.append(Path(root) / file)
        return results
    return []


# ─────────────────────────────────────────────────────────────────────────────
# CORE ANALYSIS
# ─────────────────────────────────────────────────────────────────────────────

def is_secure(content: str) -> bool:
    """Returns True if the content contains any known security declaration."""
    for decl in SECURITY_DECLARATIONS:
        if decl in content:
            return True
    return False


def analyze_file(file_path: Path) -> list[str]:
    """
    Reads a file and verifies that if it maps routes, it also configures auth.
    Returns a list of violation strings.
    """
    violations: list[str] = []

    try:
        content = file_path.read_text(encoding="utf-8", errors="replace")
    except OSError as exc:
        return [f"Cannot read file {file_path}: {exc}"]

    # 1. Does the file map any HTTP routes?
    if not ROUTE_MAPPING_PATTERN.search(content):
        # Not actually an HTTP routing file (e.g. an interface or base class)
        return []

    # 2. Does it declare security explicitly?
    if not is_secure(content):
        violations.append(
            f"  MISSING AUTH  : {file_path.name} maps HTTP routes but contains NO explicit "
            f"authorization markers (RequireAuthorization, AllowAnonymous, etc)."
        )

    return violations


# ─────────────────────────────────────────────────────────────────────────────
# MAIN
# ─────────────────────────────────────────────────────────────────────────────

def main() -> None:
    if len(sys.argv) < 2:
        print("Usage: python verify_secure_endpoints.py <path_or_directory>")
        sys.exit(1)

    target = sys.argv[1].strip().strip('"')

    print(f"\n{'='*60}")
    print(f"  verify_secure_endpoints.py — Secure-by-Default Gate")
    print(f"  Target : {target}")
    print(f"{'='*60}\n")

    if not os.path.exists(target):
        print(f"❌ FATAL: Path does not exist: {target}")
        sys.exit(1)

    endpoint_files = find_endpoint_files(target)

    if not endpoint_files:
        print("  ⚠️  No *Endpoints.cs or *Controller.cs files found.")
        print("  This is non-blocking — proceed if you are not writing API routes.\n")
        sys.exit(0)

    print(f"  Scanning {len(endpoint_files)} endpoint file(s)...\n")

    all_violations: list[str] = []

    for ef in endpoint_files:
        relative = ef.relative_to(Path(target)) if Path(target).is_dir() else ef
        violations = analyze_file(ef)
        if violations:
            print(f"  ❌ {relative.name}:")
            for v in violations:
                print(v)
            all_violations.extend(violations)
        else:
            print(f"  ✅ {relative.name} — security explicitly defined")

    print(f"\n{'='*60}")

    if all_violations:
        print(f"\n❌ FAILED — {len(all_violations)} unprotected endpoint file(s) found.\n")
        print("  Fix: Every file defining routes MUST be explicitly secured.")
        print("       Append .RequireAuthorization(), .RequirePermission(),")
        print("       or explicitly mark .AllowAnonymous() on the MapGroup or MapGet.\n")
        sys.exit(1)

    print(f"\n✅ ALL CHECKS PASSED — {len(endpoint_files)} file(s), no implicitly public endpoints.\n")
    print(f"{'='*60}\n")
    sys.exit(0)


if __name__ == "__main__":
    main()
