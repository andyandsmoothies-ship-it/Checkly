"""
verify_workflow.py — Universal AI Workflow Hard Gate
====================================================
Usage:
    python .agents/scripts/verify_workflow.py "<absolute-path-to-session-brain-dir>"

Example:
    python .agents/scripts/verify_workflow.py "C:\\Users\\HP\\.gemini\\antigravity\\brain\\7d2416ce-c706-49f4-ad77-deb9f4b0fc32"

Exit Codes:
    0  — All checks passed. Workflow is complete.
    1  — One or more checks failed. AI must fix and re-run.

Design Rules:
    - Stateless: knows nothing until the path is passed in.
    - Agent-Friendly: every error message names the exact file, line, and fix.
    - Forgiving: case-insensitive file lookup; flexible header regex.
    - 2-Strike rule enforced by workflow macros, NOT by this script.
"""

import sys
import os
import re

# ─────────────────────────────────────────────────────────────────────────────
# CONFIGURATION — mandatory section headers per artifact type
# Add new artifact types here as the project evolves.
# ─────────────────────────────────────────────────────────────────────────────
REQUIRED_SECTIONS = {
    "task": [],  # task.md is structural; sections checked via checkbox logic below
    "research": [
        r"##\s+handoff\s+block",
        r"blind\s+spots",
        r"downsides\s+&\s+risks"
    ],
    "implementation_plan": [
        r"##\s+proposed\s+changes",
        r"##\s+risk\s+assessment",
        r"##\s+verification\s+plan",
    ],
    "walkthrough": [
        r"##\s+decision\s+log",
        r"##\s+verification\s+handoff",
    ],
    "analysis_epic": [
        r"##\s+exec\s+summary|executive\s+summary",
        r"##\s+decision\s+matrix",
        r"##\s+risk\s+assessment",
    ],
}

# ─────────────────────────────────────────────────────────────────────────────
# HELPERS
# ─────────────────────────────────────────────────────────────────────────────

def find_file(directory: str, basename: str) -> str | None:
    """Case-insensitive file lookup in a flat directory."""
    try:
        for name in os.listdir(directory):
            if name.lower() == basename.lower():
                return os.path.join(directory, name)
    except FileNotFoundError:
        pass
    return None


def find_files_by_prefix(directory: str, prefix: str) -> list[str]:
    """Find all files whose names start with a given prefix (case-insensitive)."""
    try:
        return [
            os.path.join(directory, name)
            for name in os.listdir(directory)
            if name.lower().startswith(prefix.lower()) and name.lower().endswith(".md")
        ]
    except FileNotFoundError:
        return []


def get_active_artifacts(session_dir: str) -> list[str]:
    """Extracts explicit, scoped artifact paths from the active task.md Inventory."""
    task_path = find_file(session_dir, "task.md")
    if not task_path:
        return []
    
    with open(task_path, encoding="utf-8") as f:
        content = f.read()

    inventory_match = re.search(
        r"##\s+artifact\s+inventory.*?(\|.*?\n)+",
        content,
        re.IGNORECASE | re.DOTALL,
    )
    if not inventory_match:
        return []

    # Find [NEW], [MOD], or [DEL] entries
    rows = re.findall(
        r"\|\s*\[(?:NEW|MOD|DEL)\]\s*\|\s*([^\|]+)\|",
        inventory_match.group(0),
        re.IGNORECASE,
    )
    
    active_files = []
    norm_session = os.path.normcase(os.path.abspath(session_dir))

    for raw_path in rows:
        file_path = raw_path.strip()
        if not file_path.lower().endswith(".md"):
            continue
            
        norm_file = os.path.normcase(os.path.abspath(file_path))
        # Ensure it is a valid brain artifact inside this specific session folder
        if norm_session in norm_file and os.path.isfile(file_path):
            active_files.append(file_path)
            
    return active_files


errors: list[str] = []
warnings: list[str] = []


def fail(msg: str) -> None:
    errors.append(f"  ❌ ERROR: {msg}")


def warn(msg: str) -> None:
    warnings.append(f"  ⚠️  WARN:  {msg}")


# ─────────────────────────────────────────────────────────────────────────────
# CHECK 1 — task.md completeness (no unchecked or in-progress items)
# ─────────────────────────────────────────────────────────────────────────────

def check_task_md(session_dir: str) -> None:
    print("\n[CHECK 1] Scanning task.md for incomplete phases...")
    task_path = find_file(session_dir, "task.md")

    if task_path is None:
        fail(
            "task.md not found in session directory.\n"
            "         Fix: call write_to_file to create task.md before running this script."
        )
        return

    with open(task_path, encoding="utf-8") as f:
        lines = f.readlines()

    incomplete_lines = []
    for i, line in enumerate(lines, start=1):
        stripped = line.strip()
        if stripped.startswith("- [ ]") or stripped.startswith("- [/]"):
            incomplete_lines.append((i, stripped))

    if incomplete_lines:
        for lineno, content in incomplete_lines:
            fail(
                f"task.md line {lineno} has an unchecked task: '{content}'\n"
                f"         Fix: mark it '[x]' once the phase is truly complete."
            )
    else:
        print("       ✅ task.md — all phases are marked [x].")


# ─────────────────────────────────────────────────────────────────────────────
# CHECK 2 — Artifact Inventory physicality (every [NEW] file must exist on disk)
# ─────────────────────────────────────────────────────────────────────────────

def check_artifact_inventory(session_dir: str) -> None:
    print("\n[CHECK 2] Scanning Artifact Inventory for missing files on disk...")
    task_path = find_file(session_dir, "task.md")
    if task_path is None:
        warn("Cannot run artifact physicality check — task.md not found.")
        return

    with open(task_path, encoding="utf-8") as f:
        content = f.read()

    # Find the Artifact Inventory table section
    inventory_match = re.search(
        r"##\s+artifact\s+inventory.*?(\|.*?\n)+",
        content,
        re.IGNORECASE | re.DOTALL,
    )
    if not inventory_match:
        warn(
            "No '## Artifact Inventory' table found in task.md.\n"
            "       Fix: add the mandatory Artifact Inventory table to task.md."
        )
        return

    # Extract rows from the markdown table
    # Rows look like: | [NEW]  | C:\path\to\file.md | Type |
    rows = re.findall(
        r"\|\s*\[NEW\]\s*\|\s*([^\|]+)\|",
        inventory_match.group(0),
        re.IGNORECASE,
    )

    if not rows:
        print("       ✅ No [NEW] artifacts declared — nothing to verify.")
        return

    all_present = True
    for raw_path in rows:
        file_path = raw_path.strip()
        if not os.path.isfile(file_path):
            fail(
                f"Declared artifact does not exist on disk:\n"
                f"           Path: {file_path}\n"
                f"           Fix: call write_to_file to physically create this file."
            )
            all_present = False
        else:
            print(f"       ✅ Found: {os.path.basename(file_path)}")

    if all_present:
        print("       ✅ All declared [NEW] artifacts exist on disk.")


# ─────────────────────────────────────────────────────────────────────────────
# CHECK 3 — Mandatory section headers in key artifacts
# ─────────────────────────────────────────────────────────────────────────────

def check_artifact_sections(session_dir: str) -> None:
    print("\n[CHECK 3] Scanning artifact files for mandatory section headers...")
    
    active_artifacts = get_active_artifacts(session_dir)
    if not active_artifacts:
        warn("No active artifacts found in inventory (or missing). Skipping section scan.")
        return

    for prefix, required_patterns in REQUIRED_SECTIONS.items():
        if prefix == "task" or not required_patterns:
            continue

        matching_files = [
            f for f in active_artifacts
            if os.path.basename(f).lower().startswith(prefix.lower())
        ]
        
        if not matching_files:
            continue

        for file_path in matching_files:
            with open(file_path, encoding="utf-8") as f:
                content = f.read().lower()

            basename = os.path.basename(file_path)
            missing = []
            for pattern in required_patterns:
                if not re.search(pattern, content, re.IGNORECASE):
                    missing.append(pattern)

            if missing:
                for pat in missing:
                    fail(
                        f"'{basename}' is missing a required section.\n"
                        f"           Pattern expected: '{pat}'\n"
                        f"           Fix: add the missing section header to the artifact."
                    )
            else:
                print(f"       ✅ {basename} — all required sections present.")


# ─────────────────────────────────────────────────────────────────────────────
# CHECK 4 — Forensic Evidence (Proof of Work)
# ─────────────────────────────────────────────────────────────────────────────
def check_forensic_evidence(session_dir: str) -> None:
    print("\n[CHECK 4] Scanning analytical artifacts for Proof-of-Work logs...")
    
    active_artifacts = get_active_artifacts(session_dir)
    
    artifacts_to_check = [
        f for f in active_artifacts
        if not os.path.basename(f).lower().startswith("task") 
        and not os.path.basename(f).lower().startswith("handoff") 
        and not os.path.basename(f).lower().startswith("preflight")
    ]

    if not artifacts_to_check:
        print("       ✅ No analytical artifacts found to check.")
        return
        
    for file_path in artifacts_to_check:
        name = os.path.basename(file_path)
        if any(k in name.lower() for k in ["research", "analysis", "audit", "diagnose", "failure_report", "walkthrough"]):
            with open(file_path, encoding="utf-8") as f:
                content = f.read().lower()
                
            evidence_match = re.search(r"<forensic_evidence>(.*?)</forensic_evidence>", content, re.DOTALL)
            latent_match = re.search(r"<latent_space_scratchpad>(.*?)</latent_space_scratchpad>", content, re.DOTALL)
            test_trace_match = re.search(r"<test_trace>(.*?)</test_trace>", content, re.DOTALL)
            
            # 1. Enforce Latent Space Scratchpad on generative AI tasks (Discovery/Analysis)
            if any(k in name.lower() for k in ["research", "analysis", "audit", "diagnose"]):
                if not latent_match:
                    fail(
                        f"'{name}' is missing the '<latent_space_scratchpad>' block.\n"
                        f"           Fix: Use <latent_space_scratchpad> at the top of the artifact to expand test-time compute and think through edge cases before planning."
                    )
                elif len(latent_match.group(1).strip()) < 50:
                    fail(f"'{name}' Latent Scratchpad is too shallow. Expand your computational thinking before concluding.")

            # 2. Enforce Test Trace feedback loop on Execution/QA Tasks
            if any(k in name.lower() for k in ["walkthrough", "executed_tests", "test_contracts"]):
                if not test_trace_match:
                    fail(
                        f"'{name}' is missing the '<test_trace>' block.\n"
                        f"           Fix: You cannot self-certify fixes. Provide raw terminal test output (e.g., dotnet test / flutter analyze) as external feedback."
                    )
                elif len(test_trace_match.group(1).strip()) < 30:
                    fail(f"'{name}' Test Trace is too shallow. Provide the actual compiler/test output.")

            # 3. Enforce Forensic Evidence globally
            if not evidence_match:
                fail(
                    f"'{name}' is missing the '<forensic_evidence>' block.\n"
                    f"           Fix: Provide proof of executed commands (e.g. grep_search, test logs)."
                )
                continue
                
            evidence_text = evidence_match.group(1).strip()
            if len(evidence_text) < 30:
                fail(
                    f"'{name}' Forensic Evidence block is too shallow ({len(evidence_text)} chars).\n"
                    f"           Fix: Provide explicit terminal/tool output to prove you did the work."
                )
            else:
                print(f"       ✅ {name} — Forensic Evidence validated ({len(evidence_text)} bytes).")


# ─────────────────────────────────────────────────────────────────────────────
# MAIN
# ─────────────────────────────────────────────────────────────────────────────

def main() -> None:
    if len(sys.argv) < 2:
        print(
            "Usage: python .agents/scripts/verify_workflow.py \"<session-brain-dir>\"\n"
            "Example: python .agents/scripts/verify_workflow.py "
            "\"C:\\Users\\HP\\.gemini\\antigravity\\brain\\7d2416ce-...\""
        )
        sys.exit(1)

    session_dir = sys.argv[1].strip().strip('"')

    if not os.path.isdir(session_dir):
        print(
            f"FATAL: Session directory not found: {session_dir}\n"
            f"Fix: Pass the correct absolute path to the brain/<conversation-id>/ folder."
        )
        sys.exit(1)

    print(f"\n{'='*60}")
    print(f"  verify_workflow.py — AI Workflow Hard Gate")
    print(f"  Session: {session_dir}")
    print(f"{'='*60}")

    check_task_md(session_dir)
    check_artifact_inventory(session_dir)
    check_artifact_sections(session_dir)
    check_forensic_evidence(session_dir)

    print(f"\n{'='*60}")

    if warnings:
        print("\n⚠️  WARNINGS (non-blocking):")
        for w in warnings:
            print(w)

    if errors:
        print(f"\n❌ FAILED — {len(errors)} error(s) found. Fix them before declaring done:\n")
        for e in errors:
            print(e)
        print(f"\n{'='*60}\n")
        sys.exit(1)
    else:
        print("\n✅ ALL CHECKS PASSED — Workflow is officially complete.\n")
        print(f"{'='*60}\n")
        sys.exit(0)


if __name__ == "__main__":
    main()
