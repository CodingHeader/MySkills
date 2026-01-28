import os
import sys
import json
import argparse
from pathlib import Path

def create_structure(base_path, structure):
    """
    Recursively creates files and directories.
    
    :param base_path: The root path to create structure in.
    :param structure: A dictionary representing the structure.
    """
    for name, content in structure.items():
        path = base_path / name
        
        if isinstance(content, dict):
            # It's a directory
            path.mkdir(parents=True, exist_ok=True)
            print(f"Created directory: {path}")
            create_structure(path, content)
        else:
            # It's a file
            # Ensure parent exists (in case of "dir/file.txt" keys if we supported them, 
            # but standard is nested dicts. Safe to do anyway.)
            path.parent.mkdir(parents=True, exist_ok=True)
            
            text_content = content if content is not None else ""
            path.write_text(text_content, encoding="utf-8")
            print(f"Created file: {path}")

def main():
    parser = argparse.ArgumentParser(description="Create project structure from JSON.")
    parser.add_argument("--json", help="JSON string defining the structure", required=False)
    parser.add_argument("--file", help="Path to JSON file defining the structure", required=False)
    parser.add_argument("--target", help="Target directory (default: current dir)", default=".")
    
    args = parser.parse_args()
    
    structure = {}
    
    if args.file:
        try:
            with open(args.file, 'r', encoding='utf-8') as f:
                structure = json.load(f)
        except Exception as e:
            print(f"Error reading file: {e}")
            sys.exit(1)
    elif args.json:
        try:
            structure = json.loads(args.json)
        except json.JSONDecodeError as e:
            print(f"Error parsing JSON: {e}")
            sys.exit(1)
    else:
        print("Error: Must provide --json or --file")
        parser.print_help()
        sys.exit(1)
        
    target_path = Path(args.target).resolve()
    print(f"Creating structure in: {target_path}")
    
    try:
        create_structure(target_path, structure)
        print("Structure creation complete.")
    except Exception as e:
        print(f"Error creating structure: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
