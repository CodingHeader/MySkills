import os
import json
import argparse
import sys
from pathlib import Path

def create_structure(base_path, structure):
    for name, content in structure.items():
        path = os.path.join(base_path, name)
        
        if isinstance(content, dict):
            # It's a directory
            os.makedirs(path, exist_ok=True)
            print(f"Created directory: {path}")
            create_structure(path, content)
        elif isinstance(content, str):
            # It's a file
            if content == "file":
                # Create empty file if not exists
                if not os.path.exists(path):
                    with open(path, 'w', encoding='utf-8') as f:
                        f.write("") # Create empty file
                    print(f"Created file: {path}")
            else:
                # Content is the file content (not used in current schema but good for future)
                with open(path, 'w', encoding='utf-8') as f:
                    f.write(content)
                print(f"Created file with content: {path}")

def load_template(template_name):
    script_dir = os.path.dirname(os.path.abspath(__file__))
    template_path = os.path.join(script_dir, "..", "templates", "project_schema.json")
    
    if not os.path.exists(template_path):
        print(f"Error: Template not found at {template_path}")
        sys.exit(1)
        
    with open(template_path, 'r', encoding='utf-8') as f:
        return json.load(f)

def main():
    parser = argparse.ArgumentParser(description="Project Structure Manager")
    parser.add_argument("action", choices=["generate", "validate"], help="Action to perform")
    parser.add_argument("--template", default="standard", help="Template to use")
    parser.add_argument("--path", default=".", help="Target path (default: current dir)")
    
    args = parser.parse_args()
    
    target_path = os.path.abspath(args.path)
    
    if args.action == "generate":
        print(f"Generating structure in {target_path}...")
        data = load_template(args.template)
        # The schema has a "root" key
        structure = data.get("root", {})
        create_structure(target_path, structure)
        print("Done.")
        
    elif args.action == "validate":
        print("Validation not implemented yet.")

if __name__ == "__main__":
    main()
