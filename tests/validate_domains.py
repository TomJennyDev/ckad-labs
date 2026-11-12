#!/usr/bin/env python3
"""Validate all completed Domain 1 lab packages against STATUS.json."""
from pathlib import Path
import json
import sys
import yaml

ROOT = Path(__file__).resolve().parents[1]
status = json.loads((ROOT / "domains/STATUS.json").read_text())
base = ROOT / "domains/01-application-design-build/labs"
errors = []
completed = status["completed_ids"]
if sum(item["planned_labs"] for item in status["domain_order"]) != 60:
    errors.append("Domain target count must be 60")
if len(completed) != len(set(completed)):
    errors.append("Duplicate completed IDs")
expected = [f"D1-{i:03d}" for i in range(1, len(completed) + 1)]
if completed != expected:
    errors.append(f"Completed IDs not sequential: {completed}")
if status["next_planned_id"] != f"D1-{len(completed)+1:03d}":
    errors.append("Next planned ID does not follow completed IDs")
for lab_id in completed:
    dirs = list(base.glob(lab_id[-3:] + "-*"))
    if len(dirs) != 1:
        errors.append("Expected exactly one directory for " + lab_id)
        continue
    directory = dirs[0]
    for part in ("README.md", "setup.yaml", "solution.yaml", "solution.sh", "verify.sh"):
        if not (directory / part).is_file():
            errors.append(f"{directory}/{part} missing")
    if not all((directory / part).is_file() for part in ("README.md", "setup.yaml", "solution.yaml")):
        continue
    readme = (directory / "README.md").read_text()
    if "flowchart" not in readme or "sequenceDiagram" not in readme:
        errors.append(lab_id + " missing two Mermaid diagrams")
    if "Negative test" not in readme and "negative test" not in readme.lower():
        errors.append(lab_id + " missing negative test")
    for part in ("setup.yaml", "solution.yaml"):
        try:
            documents = list(yaml.safe_load_all((directory / part).read_text()))
            if part == "solution.yaml" and not any(isinstance(doc, dict) and doc.get("kind") for doc in documents):
                errors.append(lab_id + " has no Kubernetes resource")
            for doc in documents:
                if isinstance(doc, dict) and doc.get("kind"):
                    if not doc.get("apiVersion") or not doc.get("metadata", {}).get("name"):
                        errors.append(lab_id + " missing apiVersion/metadata.name")
                    if doc.get("metadata", {}).get("namespace"):
                        errors.append(lab_id + " hardcodes namespace")
        except yaml.YAMLError as exc:
            errors.append(f"{lab_id} invalid {part}: {exc}")
if errors:
    print("\n".join(errors))
    sys.exit(1)
print(f"PASS: {len(completed)} Domain-1 packages and 60-lab registry validated")
