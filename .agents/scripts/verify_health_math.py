"""
verify_health_math.py — Health Check Report Card Validator
===========================================================
Usage:
    python .agents/scripts/verify_health_math.py <path_to_report.md>

Arguments:
    path_to_report.md  Absolute or relative path to the generated health
                       check Markdown report.

Exit Codes:
    0  — GPA is mathematically correct and all 8 dimensions are graded.
    1  — GPA is wrong, dimensions are missing, or grades are invalid.

Design Rules:
    - Never crashes: file I/O and regex are fully guarded.
    - Validates presence of all 8 required dimensions.
    - Cross-checks the numeric GPA against the extracted letter grades.
    - Reports the exact delta if the GPA is wrong.
"""

import sys
import os
import re

# ─────────────────────────────────────────────────────────────────────────────
# CONFIGURATION
# ─────────────────────────────────────────────────────────────────────────────

GRADE_TO_GPA = {
    "A": 4.0,
    "B": 3.0,
    "C": 2.0,
    "D": 1.0,
    "F": 0.0,
}

# The 8 required health check dimensions (matched case-insensitively)
REQUIRED_DIMENSIONS = [
    "Build Health",
    "Code Quality",
    "Architecture",
    "Test Coverage",
    "Dead Code",
    "API Surface",
    "Security",
    "Documentation",
]

# Tolerance for floating point GPA comparison
GPA_EPSILON = 0.05

# Regex to find a row in the grades markdown table
# e.g. | Build Health | A | 95 | 0 errors ... |
TABLE_ROW_PATTERN = re.compile(
    r"\|\s*(?P<dimension>[^|]+?)\s*\|\s*(?P<grade>[ABCDF][+-]?)\s*\|",
    re.IGNORECASE,
)

# Regex to find the GPA line: "Overall GPA: 3.0"
GPA_LINE_PATTERN = re.compile(
    r"Overall\s+GPA\s*[:\-]\s*(?P<gpa>[\d.]+)",
    re.IGNORECASE,
)


# ─────────────────────────────────────────────────────────────────────────────
# HELPERS
# ─────────────────────────────────────────────────────────────────────────────

def normalize_grade(raw: str) -> str | None:
    """Strips +/- modifiers and returns the base letter, or None if invalid."""
    clean = raw.strip().upper().rstrip("+-")
    return clean if clean in GRADE_TO_GPA else None


def load_report(path: str) -> str | None:
    """Reads report file content safely. Returns None on any I/O error."""
    try:
        with open(path, encoding="utf-8", errors="replace") as f:
            return f.read()
    except OSError as exc:
        print(f"❌ FATAL: Cannot open report file: {exc}")
        return None


def extract_grades(content: str) -> dict[str, str]:
    """
    Parses all table rows and returns {dimension_lower: grade_letter}.
    Only rows where the grade column is a valid letter are kept.
    """
    grades: dict[str, str] = {}
    for match in TABLE_ROW_PATTERN.finditer(content):
        grade = normalize_grade(match.group("grade"))
        if grade:
            dim = match.group("dimension").strip().lower()
            grades[dim] = grade
    return grades


def extract_reported_gpa(content: str) -> float | None:
    """Returns the GPA value stated in the report, or None if not found."""
    match = GPA_LINE_PATTERN.search(content)
    if match:
        try:
            return float(match.group("gpa"))
        except ValueError:
            pass
    return None


def calculate_gpa(grades: dict[str, str]) -> float:
    """Computes the arithmetic mean of grade points."""
    if not grades:
        return 0.0
    total = sum(GRADE_TO_GPA.get(g, 0.0) for g in grades.values())
    return round(total / len(grades), 2)


# ─────────────────────────────────────────────────────────────────────────────
# MAIN
# ─────────────────────────────────────────────────────────────────────────────

def main() -> None:
    if len(sys.argv) < 2:
        print("Usage: python verify_health_math.py <path_to_report.md>")
        sys.exit(1)

    report_path = sys.argv[1].strip().strip('"')

    print(f"\n{'='*60}")
    print(f"  verify_health_math.py — Health Report Validator")
    print(f"  Report: {report_path}")
    print(f"{'='*60}\n")

    content = load_report(report_path)
    if content is None:
        sys.exit(1)

    errors: list[str] = []
    warnings: list[str] = []

    # ── CHECK 1: Extract grades from the table
    grades = extract_grades(content)

    if not grades:
        errors.append(
            "No valid grade rows found in the Markdown table.\n"
            "         Fix: ensure the report contains a table with | Dimension | Grade | columns."
        )

    # ── CHECK 2: All 8 required dimensions must be graded
    graded_dims_lower = set(grades.keys())
    for required in REQUIRED_DIMENSIONS:
        if not any(required.lower() in graded for graded in graded_dims_lower):
            errors.append(
                f"Missing required dimension: '{required}'.\n"
                f"         Fix: add a row for '{required}' to the Grades table."
            )

    # ── CHECK 3: GPA math validation
    if grades:
        reported_gpa = extract_reported_gpa(content)
        computed_gpa = calculate_gpa(grades)

        print(f"  Grades found        : {len(grades)}")
        print(f"  Grade breakdown     :")
        for dim, grade in grades.items():
            print(f"    {dim.title():<25} {grade}  ({GRADE_TO_GPA[grade]:.1f})")
        print(f"\n  Computed GPA        : {computed_gpa}")

        if reported_gpa is None:
            warnings.append(
                "Could not find 'Overall GPA: X.X' line in report.\n"
                "       Recommendation: add the GPA summary line for human reviewers."
            )
        else:
            print(f"  Reported GPA        : {reported_gpa}")
            delta = abs(reported_gpa - computed_gpa)
            if delta > GPA_EPSILON:
                errors.append(
                    f"GPA mismatch detected.\n"
                    f"           Reported   : {reported_gpa}\n"
                    f"           Computed   : {computed_gpa} (from {len(grades)} grades)\n"
                    f"           Delta      : {delta:.2f} (tolerance: ±{GPA_EPSILON})\n"
                    f"           Fix: recalculate the GPA using A=4.0, B=3.0, C=2.0, D=1.0, F=0.0."
                )
            else:
                print(f"  GPA validation      : ✅ within tolerance (delta={delta:.2f})")

    print(f"\n{'='*60}")

    if warnings:
        print("\n⚠️  WARNINGS (non-blocking):")
        for w in warnings:
            print(f"  - {w}")

    if errors:
        print(f"\n❌ FAILED — {len(errors)} error(s):\n")
        for e in errors:
            print(f"  - {e}")
        print(f"\n{'='*60}\n")
        sys.exit(1)

    print("\n✅ ALL CHECKS PASSED — Health report is mathematically valid.\n")
    print(f"{'='*60}\n")
    sys.exit(0)


if __name__ == "__main__":
    main()
