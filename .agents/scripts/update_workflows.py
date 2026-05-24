import os
import re

def clean_workflow_content(content):
    lines = content.splitlines()
    cleaned_lines = []
    for line in lines:
        stripped = line.strip()
        is_empty_row = False
        if stripped.startswith("|") and stripped.endswith("|"):
            # check if there's any alphanumeric or standard characters
            inner = stripped[1:-1]
            if not re.search(r"[a-zA-Z0-9`\[\*\(\_#]", inner):
                # It only contains spaces, pipes, colons, dashes.
                # If it doesn't contain dashes or colons, or if it's completely empty:
                if not re.search(r"[-:]", inner):
                    is_empty_row = True
        if not is_empty_row:
            cleaned_lines.append(line)
    
    # Remove consecutive empty lines (more than 1 empty line in a row)
    final_lines = []
    consec_empty = 0
    for line in cleaned_lines:
        if not line.strip():
            consec_empty += 1
            if consec_empty <= 1:
                final_lines.append(line)
        else:
            consec_empty = 0
            final_lines.append(line)
            
    return "\n".join(final_lines) + "\n"

def update_workflows():
    dir_path = r"C:\Users\HP\Documents\GitHub\Checkly\.agents\workflows"
    
    for filename in os.listdir(dir_path):
        if not filename.endswith(".md"):
            continue
        filepath = os.path.join(dir_path, filename)
        with open(filepath, "r", encoding="utf-8") as f:
            content = f.read()

        # Update dynamic artifact names (e.g. _[topic].md to _[topic]_[ConversationID].md)
        new_content = re.sub(
            r"_\[(topic|time|date|date-time|name)\]\.md", 
            r"_[\1]_[ConversationID].md", 
            content
        )
        
        # Determine if task.md should also be renamed to task_[ConversationID].md
        new_content = re.sub(r"\btask\.md\b", r"task_[ConversationID].md", new_content)
        
        # Apply the empty row and whitespace cleaning
        new_content = clean_workflow_content(new_content)
        
        if new_content != content:
            with open(filepath, "w", encoding="utf-8") as f:
                f.write(new_content)
            print(f"Updated workflows/{filename}")

def update_verify_script():
    verify_path = r"C:\Users\HP\Documents\GitHub\Checkly\.agents\scripts\verify_workflow.py"
    with open(verify_path, "r", encoding="utf-8") as f:
        content = f.read()
    
    new_content = re.sub(
        r'task_path = find_file\(session_dir, "task\.md"\)', 
        r'task_path = next((f for f in find_files_by_prefix(session_dir, "task") if "task" in os.path.basename(f).lower()), None)', 
        content
    )
    
    if new_content != content:
        with open(verify_path, "w", encoding="utf-8") as f:
            f.write(new_content)
        print(f"Updated scripts/verify_workflow.py")

if __name__ == "__main__":
    update_workflows()
    update_verify_script()
