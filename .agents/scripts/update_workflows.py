import os
import re

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
        # The user specifically requested all artifacts. task.md is an artifact.
        new_content = re.sub(r"\btask\.md\b", r"task_[ConversationID].md", new_content)
        
        if new_content != content:
            with open(filepath, "w", encoding="utf-8") as f:
                f.write(new_content)
            print(f"Updated workflows/{filename}")

def update_verify_script():
    verify_path = r"C:\Users\HP\Documents\GitHub\Checkly\.agents\scripts\verify_workflow.py"
    with open(verify_path, "r", encoding="utf-8") as f:
        content = f.read()
    
    # We need to change find_file(session_dir, "task.md") to find task*.md
    # Let's add a helper or modify the task finding logic.
    # Actually, we can replace: task_path = find_file(session_dir, "task.md")
    # with: tasks = find_files_by_prefix(session_dir, "task") \n task_path = tasks[0] if tasks else None
    
    # The safest way is to replace find_file(..., "task.md") calls.
    # I'll just change the string literal "task.md" in `find_file` to support prefix.
    # Wait, `get_active_artifacts` has `task_path = find_file(session_dir, "task.md")`
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
