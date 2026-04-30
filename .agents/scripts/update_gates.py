import os

def update_workflow_gates():
    dir_path = r"C:\Users\HP\Documents\GitHub\Checkly\.agents\workflows"
    
    new_command = '`cmd /c python .agents/scripts/verify_workflow.py "{Absolute Path to your task tracker .md file}"`'
    
    old_commands = [
        '`cmd /c python .agents/scripts/verify_workflow.py "{App Data Directory}\\brain\\{Conversation ID}"`',
        '`cmd /c python .agents/scripts/verify_workflow.py "{App Data Directory}\brain\{Conversation ID}"`',
        '`cmd /c python .agents/scripts/verify_workflow.py "{App Data Directory}\\\\brain\\\\{Conversation ID}"`'
    ]
    
    for filename in os.listdir(dir_path):
        if not filename.endswith(".md"):
            continue
            
        filepath = os.path.join(dir_path, filename)
        with open(filepath, "r", encoding="utf-8") as f:
            content = f.read()
            
        new_content = content
        for old_cmd in old_commands:
            new_content = new_content.replace(old_cmd, new_command)
        
        if new_content != content:
            with open(filepath, "w", encoding="utf-8") as f:
                f.write(new_content)
            print(f"Updated {filename}")

if __name__ == "__main__":
    update_workflow_gates()
