#!/usr/bin/env python3
"""Static checks of Domain 1 curriculum. Runtime checks require Docker/kind."""
from pathlib import Path
import json
import sys
import yaml

ROOT = Path(__file__).resolve().parents[1]
status = json.loads((ROOT / "domains/STATUS.json").read_text())
base = ROOT / "domains/01-application-design-build/labs"
errors = []
if sum(item["planned_labs"] for item in status["domain_order"]) != 60:
    errors.append("Domain target count must be 60")
if status["next_planned_id"] != "D1-006":
    errors.append("The next planned lab should be D1-006")
for expected in ["D1-001", "D1-002", "D1-003", "D1-004", "D1-005"]:
    if expected not in status["completed_ids"]:
        errors.append("Status missing " + expected)
    lab_id = expected[-3:]
    dirs = list(base.glob(lab_id + "-*"))
    if len(dirs) != 1:
        errors.append("Expected one lab directory for " + expected)
        continue
    directory = dirs[0]
    for part in ["README.md", "setup.yaml", "solution.yaml", "solution.sh", "verify.sh"]:
        if not (directory / part).is_file():
            errors.append(str(directory / part) + " missing")
    readme = (directory / "README.md").read_text()
    if "flowchart" not in readme or "sequenceDiagram" not in readme:
        errors.append(expected + " must have two Mermaid diagrams")
    if "Negative test" not in readme:
        errors.append(expected + " missing negative test")
    for part in ["setup.yaml", "solution.yaml"]:
        try:
            documents = list(yaml.safe_load_all((directory / part).read_text()))
            if part == "solution.yaml" and not any(
                isinstance(doc, dict) and doc.get("kind") for doc in documents
            ):
                errors.append(expected + " has no Kubernetes resource")
            for doc in documents:
                if isinstance(doc, dict) and doc.get("kind"):
                    assert doc.get("apiVersion") and doc.get("metadata", {}).get("name")
                    if doc.get("metadata", {}).get("namespace"):
                        errors.append(expected + " hardcodes namespace")
        except (yaml.YAMLError, AssertionError) as exc:
            errors.append(expected + " invalid " + part + ": " + str(exc))
if errors:
    print("\n".join(errors))
    sys.exit(1)
print("PASS: 5 Domain-1 lab packages + 60-lab status registry validated")
