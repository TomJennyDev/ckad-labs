#!/usr/bin/env python3
from pathlib import Path
import sys
try:
    import yaml
except ImportError:
    sys.exit("pip install pyyaml")
root=Path(__file__).resolve().parents[1]
labs=sorted((root/"labs").glob("[0-9][0-9][0-9]-*"))
errors=[]
for lab in labs:
    for part in ("README.md","setup.yaml","solution.yaml","verify.sh"):
        if not (lab/part).is_file(): errors.append(f"{lab.name} missing {part}")
    readme=(lab/"README.md").read_text()
    if "flowchart" not in readme or "sequenceDiagram" not in readme:
        errors.append(f"{lab.name} missing diagrams")
    for part in ("setup.yaml","solution.yaml"):
        try:
            items=list(yaml.safe_load_all((lab/part).read_text()))
            if part=="solution.yaml" and not any(isinstance(i,dict) and i.get("kind") for i in items):
                errors.append(f"{lab.name} no solution resource")
            for item in items:
                if isinstance(item,dict) and item.get("metadata",{}).get("namespace"):
                    errors.append(f"{lab.name} hard-coded namespace")
        except Exception as exc: errors.append(f"{lab.name} {part} invalid: {exc}")
print("\n".join(errors) if errors else f"Static validation passed: {len(labs)} labs")
sys.exit(bool(errors))
