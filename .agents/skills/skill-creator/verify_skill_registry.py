"""
verify_skill_registry.py — Universal AI Skill Governance Hard Gate
==================================================================
Usage:
    python .agents/scripts/verify_skill_registry.py

Exit Codes:
    0  — All skills pass structural validation.
    1  — One or more skills failed.
"""

import os
import sys
import re

def parse_frontmatter(content: str) -> dict:
    """Extracts YAML frontmatter from the top of the markdown file."""
    match = re.search(r"^---\s*\n(.*?)\n---", content, re.DOTALL)
    if not match:
        return {}
    
    frontmatter_text = match.group(1)
    props = {}
    
    name_match = re.search(r"^name:\s*(.+)$", frontmatter_text, re.MULTILINE)
    if name_match:
        props["name"] = name_match.group(1).strip()
        
    desc_match = re.search(r"^description:\s*(.+?)(?=\n[a-z_]+:|\Z)", frontmatter_text, re.MULTILINE | re.DOTALL)
    if desc_match:
        props["description"] = desc_match.group(1).strip()
        
    return props

def verify_skills():
    # Attempt to resolve the .agents/skills/ directory relative to this script
    script_dir = os.path.dirname(os.path.abspath(__file__))
    agents_dir = os.path.dirname(script_dir)
    skills_dir = os.path.join(agents_dir, "skills")
    
    MAX_SKILL_LINES = 500

    if not os.path.isdir(skills_dir):
        print(f"❌ Error: SKILLS directory not found at {skills_dir}")
        sys.exit(1)

    skill_folders = [f.path for f in os.scandir(skills_dir) if f.is_dir()]
    
    errors = []
    warnings = []
    
    print(f"\n{'='*60}")
    print(f"  verify_skill_registry.py — AI Skill Governance")
    print(f"  Auditing {len(skill_folders)} skill(s)...")
    print(f"{'='*60}\n")
    
    for folder_path in skill_folders:
        folder_name = os.path.basename(folder_path)
        skill_md_path = os.path.join(folder_path, "SKILL.md")
        
        if not os.path.isfile(skill_md_path):
            errors.append(f"[{folder_name}] Missing SKILL.md file. Directory is orphaned.")
            continue
            
        with open(skill_md_path, 'r', encoding='utf-8', errors='replace') as f:
            lines = f.readlines()
            content = "".join(lines)
            
        line_count = len(lines)
        if line_count > MAX_SKILL_LINES:
            warnings.append(f"[{folder_name}] Exceeds line limit ({line_count} / {MAX_SKILL_LINES} lines). Increases context bloat risk.")
            
        frontmatter = parse_frontmatter(content)
        if not frontmatter:
            errors.append(f"[{folder_name}] SKILL.md is missing YAML frontmatter (---) block.")
            continue
            
        if "name" not in frontmatter or not frontmatter["name"]:
            errors.append(f"[{folder_name}] frontmatter is missing the 'name:' property.")
        
        if "description" not in frontmatter or not frontmatter["description"]:
            errors.append(f"[{folder_name}] frontmatter is missing the 'description:' property. The Agent will not trigger this skill.")
            
    if warnings:
        print(f"⚠️  WARNINGS ({len(warnings)}):")
        for w in warnings:
            print(f"  - {w}")
        print("")
            
    if errors:
        print(f"❌ FAILED — {len(errors)} error(s) found:\n")
        for e in errors:
            print(f"  - {e}")
        print(f"\n{'='*60}\n")
        sys.exit(1)
    else:
        print(f"✅ ALL {len(skill_folders)} SKILLS PASSED GOVERNANCE CHECKS.\n")
        print(f"{'='*60}\n")
        sys.exit(0)

if __name__ == "__main__":
    verify_skills()
