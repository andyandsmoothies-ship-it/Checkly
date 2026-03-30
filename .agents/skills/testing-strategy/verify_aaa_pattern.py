"""
verify_aaa_pattern.py — Testing Strategy AAA Structure Enforcer
================================================================
Usage:
    python .agents/scripts/verify_aaa_pattern.py <path_or_directory>

Arguments:
    path_or_directory  A single *Tests.cs file, or a directory to scan
                       recursively for all *Tests.cs files.

Exit Codes:
    0  — All [Fact] and [Theory] methods contain exactly one // Act comment.
    1  — One or more violations found.

Design Rules:
    - Never crashes: all file I/O is guarded; malformed files are reported.
    - Reports the exact method name, file, and line number for every violation.
    - Handles multi-line methods by scanning within method boundary braces.
    - Does NOT check [Fact] methods marked [Skip] (they are intentionally empty).
"""

import sys
import os
import re
from pathlib import Path

# ─────────────────────────────────────────────────────────────────────────────
# CONFIGURATION
# ─────────────────────────────────────────────────────────────────────────────

# Matches a [Fact] or [Theory] attribute line (ignore [Skip])
FACT_ATTR_PATTERN = re.compile(
    r"^\s*\[(?:Fact|Theory)(?:\((?!.*Skip).*?\))?\]\s*$",
    re.IGNORECASE,
)

# Matches the method signature after [Fact] / [Theory]
METHOD_SIG_PATTERN = re.compile(
    r"^\s*(public|private|internal|protected)?\s*(async\s+)?Task.*?\(|"
    r"^\s*(public|private|internal|protected)?\s*void\s+\w+\s*\(",
    re.IGNORECASE,
)

# Matches // Act comment (with optional extra text like "// Act — call handler")
ACT_COMMENT_PATTERN = re.compile(r"//\s*Act\b", re.IGNORECASE)

# [Skip] attribute — methods marked Skip are intentionally empty
SKIP_PATTERN = re.compile(r'\[(?:Fact|Theory)\s*\(.*?Skip\s*=', re.IGNORECASE)


# ─────────────────────────────────────────────────────────────────────────────
# FILE DISCOVERY
# ─────────────────────────────────────────────────────────────────────────────

def find_test_files(target: str) -> list[Path]:
    """Returns all *Tests.cs files under `target`, or just target if it's a file."""
    p = Path(target)
    if p.is_file():
        return [p] if p.name.endswith("Tests.cs") else []
    if p.is_dir():
        return sorted(p.rglob("*Tests.cs"))
    return []


# ─────────────────────────────────────────────────────────────────────────────
# CORE ANALYSIS
# ─────────────────────────────────────────────────────────────────────────────

def extract_method_body(lines: list[str], start_line: int) -> tuple[list[tuple[int, str]], bool]:
    """
    Starting from `start_line` (0-indexed), scans forward to find the opening
    brace of the method body and collects lines until the matching closing brace.
    Returns (body_lines_with_numbers, found_body).
    body_lines_with_numbers is a list of (1-indexed line number, line text).
    """
    body: list[tuple[int, str]] = []
    depth = 0
    in_body = False

    for i in range(start_line, min(start_line + 200, len(lines))):
        line = lines[i]
        if not in_body:
            if "{" in line:
                in_body = True
                depth += line.count("{") - line.count("}")
                body.append((i + 1, line))
                if depth <= 0:
                    break
        else:
            depth += line.count("{") - line.count("}")
            body.append((i + 1, line))
            if depth <= 0:
                break

    return body, in_body


def analyze_file(file_path: Path) -> list[str]:
    """
    Reads a test file and checks every [Fact] / [Theory] method for exactly
    one // Act comment. Returns a list of violation strings.
    """
    violations: list[str] = []

    try:
        content = file_path.read_text(encoding="utf-8", errors="replace")
    except OSError as exc:
        return [f"Cannot read file {file_path}: {exc}"]

    lines = content.splitlines()
    i = 0

    while i < len(lines):
        line = lines[i]

        # Detect [Fact] or [Theory] attribute
        if FACT_ATTR_PATTERN.match(line):
            attr_line_no = i + 1  # 1-indexed

            # Check for [Skip] on the SAME attribute line
            if SKIP_PATTERN.search(line):
                i += 1
                continue

            # Find the method signature on the next non-blank line(s)
            method_name = "unknown"
            method_start = i + 1
            for j in range(i + 1, min(i + 5, len(lines))):
                sig_match = METHOD_SIG_PATTERN.match(lines[j])
                if sig_match:
                    # Extract method name via a simple word search
                    name_match = re.search(r"\b(\w+)\s*\(", lines[j])
                    if name_match:
                        method_name = name_match.group(1)
                    method_start = j + 1
                    break

            # Extract the method body
            body_lines, found = extract_method_body(lines, method_start - 1)

            if not found or not body_lines:
                # Couldn't parse body — skip gracefully
                i += 1
                continue

            # Count // Act occurrences in the body
            act_count = sum(
                1 for _, bline in body_lines
                if ACT_COMMENT_PATTERN.search(bline)
            )

            if act_count == 0:
                violations.append(
                    f"  MISSING // Act  : {file_path.name}:{attr_line_no} "
                    f"— method '{method_name}' has no // Act comment."
                )
            elif act_count > 1:
                violations.append(
                    f"  MULTIPLE // Act : {file_path.name}:{attr_line_no} "
                    f"— method '{method_name}' has {act_count} // Act comments (expected exactly 1)."
                )
            # else: exactly 1 — passes

        i += 1

    return violations


# ─────────────────────────────────────────────────────────────────────────────
# MAIN
# ─────────────────────────────────────────────────────────────────────────────

def main() -> None:
    if len(sys.argv) < 2:
        print("Usage: python verify_aaa_pattern.py <path_or_directory>")
        print("  Provide a *Tests.cs file or a directory to scan recursively.")
        sys.exit(1)

    target = sys.argv[1].strip().strip('"')

    print(f"\n{'='*60}")
    print(f"  verify_aaa_pattern.py — AAA Pattern Enforcer")
    print(f"  Target : {target}")
    print(f"{'='*60}\n")

    if not os.path.exists(target):
        print(f"❌ FATAL: Path does not exist: {target}")
        sys.exit(1)

    test_files = find_test_files(target)

    if not test_files:
        print("  ⚠️  No *Tests.cs files found at the specified path.")
        print("  This is non-blocking — ensure your test files follow the naming convention.\n")
        sys.exit(0)

    print(f"  Scanning {len(test_files)} test file(s)...\n")

    all_violations: list[str] = []

    for tf in test_files:
        relative = tf.relative_to(Path(target)) if Path(target).is_dir() else tf
        violations = analyze_file(tf)
        if violations:
            print(f"  ❌ {relative}:")
            for v in violations:
                print(v)
            all_violations.extend(violations)
        else:
            print(f"  ✅ {relative.name} — all [Fact]/[Theory] methods have exactly one // Act")

    print(f"\n{'='*60}")

    if all_violations:
        print(f"\n❌ FAILED — {len(all_violations)} violation(s) found.\n")
        print("  Fix: every [Fact] and [Theory] method must contain EXACTLY ONE")
        print("       '// Act' comment marking the single action under test.\n")
        print("  Pattern:")
        print("    // Arrange")
        print("    var sut = new MyService();")
        print("    // Act")
        print("    var result = sut.DoThing();")
        print("    // Assert")
        print("    Assert.Equal(expected, result);\n")
        sys.exit(1)

    print(f"\n✅ ALL CHECKS PASSED — {len(test_files)} file(s), AAA pattern enforced.\n")
    print(f"{'='*60}\n")
    sys.exit(0)


if __name__ == "__main__":
    main()
