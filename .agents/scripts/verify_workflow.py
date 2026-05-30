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

TARGET_TASK_FILE = None


# Force UTF-8 encoding for standard output to prevent crash on emojis in Windows CMD
if hasattr(sys.stdout, 'reconfigure'):
    sys.stdout.reconfigure(encoding='utf-8')

# ─────────────────────────────────────────────────────────────────────────────
# CONFIGURATION — mandatory section headers per artifact type
# Add new artifact types here as the project evolves.
# ─────────────────────────────────────────────────────────────────────────────
REQUIRED_SECTIONS = {
    "task": [],  # task.md is structural; sections checked via checkbox logic below
    "research": [
        r"\[ORIGIN_IDEA\]",
        r"e2e\s+workflow\s+map",
        r"impact\s+spectrum",
        r"blind\s+spots",
        r"conflicts\s+with\s+rules",
        r"##\s+handoff\s+block"
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
    "test_spec": [
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


def get_latest_task_file(session_dir: str) -> str | None:
    if TARGET_TASK_FILE:
        return TARGET_TASK_FILE
        
    task_files = [f for f in find_files_by_prefix(session_dir, "task") if "task" in os.path.basename(f).lower()]
    if not task_files:
        return None
    # Sort alphabetically (which works for YYYYMMDD_HHMMSS) to get the newest file
    return sorted(task_files)[-1]

def get_active_artifacts(session_dir: str) -> list[str]:
    """Extracts explicit, scoped artifact paths from the active task.md Inventory."""
    task_path = get_latest_task_file(session_dir)
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
        if os.path.isfile(file_path):
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
    print("\n[CHECK 1] Scanning task.md for incomplete steps...")
    task_path = get_latest_task_file(session_dir)

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
                f"         Fix: mark it '[x]' once the step is truly complete."
            )
    else:
        print("       ✅ task.md — all steps are marked [x].")


# ─────────────────────────────────────────────────────────────────────────────
# CHECK 2 — Artifact Inventory physicality (every [NEW] file must exist on disk)
# ─────────────────────────────────────────────────────────────────────────────

def check_artifact_inventory(session_dir: str) -> None:
    print("\n[CHECK 2] Scanning Artifact Inventory for missing files on disk...")
    task_path = get_latest_task_file(session_dir)
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
    import time
    rows = re.findall(
        r"\|\s*\[(NEW|MOD|DEL)\]\s*\|\s*([^\|]+)\|",
        inventory_match.group(0),
        re.IGNORECASE,
    )

    if not rows:
        print("       ✅ No active files declared in inventory — nothing to verify.")
        return

    all_present = True
    current_time = time.time()

    for status, raw_path in rows:
        status = status.upper()
        file_path = raw_path.strip()

        if status in ["NEW", "MOD"]:
            if not os.path.isfile(file_path):
                fail(
                    f"Declared [{status}] artifact does not exist on disk:\n"
                    f"           Path: {file_path}\n"
                    f"           Fix: physically create this file."
                )
                all_present = False
            else:
                if status == "MOD":
                    file_mtime = os.path.getmtime(file_path)
                    # Require the file to have been modified in the last 4 hours during this workflow
                    if current_time - file_mtime > (4 * 3600):
                        fail(
                            f"Declared [MOD] artifact is stale. It has not been updated recently:\n"
                            f"           Path: {file_path}\n"
                            f"           Fix: You claimed to edit this file, but MTIME shows no recent saves. Don't hallucinate edits."
                        )
                        all_present = False
                    else:
                        print(f"       ✅ Verified [{status}] recent save: {os.path.basename(file_path)}")
                else:
                    print(f"       ✅ Found [{status}]: {os.path.basename(file_path)}")
                    
        elif status == "DEL":
            if os.path.exists(file_path):
                fail(
                    f"Declared [DEL] artifact still exists on disk:\n"
                    f"           Path: {file_path}\n"
                    f"           Fix: You claimed to delete it, but it is still there."
                )
                all_present = False
            else:
                print(f"       ✅ Verified [DEL] deletion: {os.path.basename(file_path)}")

    if all_present:
        print("       ✅ Artifact Inventory physical verification passed.")


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

            if prefix == "research" or prefix == "analysis":
                blind_spots_match = re.search(r"blind\s+spots(.*?)(?:##|<|\Z)", content, re.IGNORECASE | re.DOTALL)
                if blind_spots_match:
                    bs_text = blind_spots_match.group(1)
                    if not (re.search(r"1\.", bs_text) and re.search(r"2\.", bs_text) and re.search(r"3\.", bs_text)):
                        fail(
                            f"'{basename}' must contain exactly 3 numbered Blind Spots.\n"
                            f"           Fix: Add '1.', '2.', and '3.' under the Blind Spots header."
                        )


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
        lower_name = name.lower()
        if lower_name.startswith("research") or lower_name.startswith("analysis") or lower_name.startswith("audit") or lower_name.startswith("diagnose") or lower_name.startswith("failure_report") or lower_name.startswith("walkthrough") or lower_name.startswith("executed_tests") or lower_name.startswith("test_spec") or lower_name.startswith("red_test_log") or lower_name.startswith("green_test_log"):
            with open(file_path, encoding="utf-8") as f:
                content = f.read().lower()
                
            evidence_match = re.search(r"<forensic_evidence>(.*?)</forensic_evidence>", content, re.DOTALL)
            latent_match = re.search(r"<latent_space_scratchpad>(.*?)</latent_space_scratchpad>", content, re.DOTALL)
            test_trace_match = re.search(r"<test_trace>(.*?)</test_trace>", content, re.DOTALL)
            
            # 1. Enforce Latent Space Scratchpad on generative AI tasks (Discovery/Analysis)
            is_analysis = lower_name.startswith("research") or lower_name.startswith("analysis") or lower_name.startswith("audit") or lower_name.startswith("diagnose")
            if is_analysis:
                if not latent_match:
                    fail(
                        f"'{name}' is missing the '<latent_space_scratchpad>' block.\n"
                        f"           Fix: Use <latent_space_scratchpad> at the top of the artifact to expand test-time compute and think through edge cases before planning."
                    )
                elif len(latent_match.group(1).strip()) < 50:
                    fail(f"'{name}' Latent Scratchpad is too shallow. Expand your computational thinking before concluding.")

            # 2. Enforce Test Trace feedback loop on Execution/QA Tasks
            is_execution = lower_name.startswith("walkthrough") or lower_name.startswith("executed_tests") or lower_name.startswith("test_contracts") or lower_name.startswith("test_spec") or lower_name.startswith("red_test_log") or lower_name.startswith("green_test_log")
            if is_execution:
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
                if is_analysis:
                    if "grep_search" not in evidence_text.lower() and "view_file" not in evidence_text.lower():
                        fail(
                            f"'{name}' Forensic Evidence lacks Proof of Search.\n"
                            f"           Fix: You MUST use 'grep_search' or 'view_file' to audit the Status Quo before proposing architecture."
                        )
                    else:
                        print(f"       ✅ {name} — Forensic Evidence validated ({len(evidence_text)} bytes, Proof of Search found).")
                else:
                    print(f"       ✅ {name} — Forensic Evidence validated ({len(evidence_text)} bytes).")


# ─────────────────────────────────────────────────────────────────────────────
# CHECK 5 — Workspace Visibility Mandate
# ─────────────────────────────────────────────────────────────────────────────
def check_workspace_visibility(session_dir: str) -> None:
    print("\n[CHECK 5] Scanning for Enterprise Artifact Storage Compliance...")
    
    active_artifacts = get_active_artifacts(session_dir)
    
    if not active_artifacts:
        print("       ✅ No artifacts found to check storage compliance.")
        return

    all_compliant = True
    for file_path in active_artifacts:
        name = os.path.basename(file_path)
        norm_path = os.path.normcase(os.path.abspath(file_path))
        
        # Check if the file is in the default Antigravity brain/ directory
        if "\\brain\\" in norm_path or "/brain/" in norm_path:
            fail(
                f"Artifact '{name}' is trapped in the invisible brain/ folder.\n"
                f"           Path: {file_path}\n"
                f"           Fix: You MUST generate artifacts directly in 'docs/' or '.agents/active_tasks/'. Move it."
            )
            all_compliant = False
        else:
            print(f"       ✅ {name} complies with Enterprise Storage (outside brain/).")
            
    if all_compliant:
        print("       ✅ Enterprise Artifact Storage compliance passed.")



def check_modularity_index() -> None:
    print("\n[CHECK 6] Scanning files and functions for size limits (Modularity)...")
    import subprocess
    script_path = os.path.join(os.path.dirname(__file__), "modularity_index.py")
    if os.path.exists(script_path):
        res = subprocess.run([sys.executable, script_path, "--advisory"], capture_output=True, text=True, encoding="utf-8")
        print(res.stdout)
        if res.returncode != 0:
            fail("Modularity Index Checker failed to run.")
    else:
        warn("modularity_index.py script not found.")


def check_sync_contracts() -> None:
    print("\n[CHECK 7] Scanning database and DTO contracts for alignment...")
    import subprocess
    script_path = os.path.join(os.path.dirname(__file__), "verify_sync_contracts.py")
    if os.path.exists(script_path):
        res = subprocess.run([sys.executable, script_path, "--advisory"], capture_output=True, text=True, encoding="utf-8")
        print(res.stdout)
        if res.returncode != 0:
            fail("Sync Contract Checker failed to run.")
    else:
        warn("verify_sync_contracts.py script not found.")



# ─────────────────────────────────────────────────────────────────────────────
# MAIN
# ─────────────────────────────────────────────────────────────────────────────

def main() -> None:
    global TARGET_TASK_FILE
    if len(sys.argv) < 2:
        print(
            "Usage: python .agents/scripts/verify_workflow.py \"<session-brain-dir>\"\n"
            "   OR: python .agents/scripts/verify_workflow.py \"<absolute-path-to-specific-task.md>\"\n"
            "Example: python .agents/scripts/verify_workflow.py "
            "\"C:\\Users\\HP\\.gemini\\antigravity\\brain\\7d2416ce-...\""
        )
        sys.exit(1)

    input_path = sys.argv[1].strip().strip('"')

    if os.path.isfile(input_path) and input_path.endswith('.md'):
        TARGET_TASK_FILE = input_path
        session_dir = os.path.dirname(input_path)
    elif os.path.isdir(input_path):
        session_dir = input_path
    else:
        print(
            f"FATAL: Input path not found or invalid: {input_path}\n"
            f"Fix: Pass the correct absolute path to the brain/<conversation-id>/ folder OR the specific task.md file."
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
    check_workspace_visibility(session_dir)
    check_modularity_index()
    check_sync_contracts()

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
