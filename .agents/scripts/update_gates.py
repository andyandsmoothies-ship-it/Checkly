import os
import re

def update_workflow_gates():
    dir_path = r"C:\Users\HP\Documents\GitHub\Checkly\.agents\workflows"
    
    # The pattern matches the old passive gate text up to the end of the Python command line
    pattern = re.compile(
        r">\s*\*\*Script Verification Gate\*\*:\s*\n"
        r">\s*`cmd /c python \.agents/scripts/verify_workflow\.py.*?`",
        re.IGNORECASE | re.MULTILINE
    )
    
    replacement = (
        "> **Script Verification Gate (MANDATORY)**:\n"
        "> You MUST use the `run_command` tool to execute this script before considering the task complete.\n"
        "> // turbo\n"
        '> `cmd /c python .agents/scripts/verify_workflow.py "{App Data Directory}\\brain\\{Conversation ID}"`'
    )
    
    for filename in os.listdir(dir_path):
        if not filename.endswith(".md"):
            continue
            
        filepath = os.path.join(dir_path, filename)
        with open(filepath, "r", encoding="utf-8") as f:
            content = f.read()
            
        # Already updated?
        if "// turbo" in content and "Script Verification Gate" in content:
            continue
            
        if bool(pattern.search(content)):
            new_content = pattern.sub(replacement, content)
            
            # Since some workflows define custom Code 0/1 descriptions after the command, the regex
            # just replaces up to the command itself, leaving the bullet points untouched.
            
            if new_content != content:
                with open(filepath, "w", encoding="utf-8") as f:
                    f.write(new_content)
                print(f"Updated {filename}")

if __name__ == "__main__":
    update_workflow_gates()
