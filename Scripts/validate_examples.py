#!/usr/bin/env python3
"""Validate the committed JUN example documents against the JUN JSON Schema.

Run from the repository root:

    pip install jsonschema && python3 Scripts/validate_examples.py

The schema is fetched from the JUN repository at the ref the examples are pinned to, so this
checks the reference implementation's fixtures against the specification itself rather than
against a local copy that could drift.
"""

import glob
import json
import os
import subprocess
import sys
import tempfile

JUN_REPO = os.environ.get("JUN_REPO", "https://github.com/ferchmin/JUN.git")
JUN_REF = os.environ.get("JUN_REF", "v1.2.0")
EXAMPLE_GLOB = "Example/JUNSwiftUIApp/Resources/Examples/*.json"


def fetch_schema(directory: str) -> dict:
    for ref in (JUN_REF, None):
        command = ["git", "clone", "--quiet", "--depth", "1"]
        if ref:
            command += ["--branch", ref]
        command += [JUN_REPO, directory]

        if subprocess.call(command, stderr=subprocess.DEVNULL) == 0:
            with open(os.path.join(directory, "schemas", "jun.schema.json")) as handle:
                return json.load(handle)

        print(f"  ref '{ref}' unavailable, falling back to the default branch")

    raise SystemExit(f"error: could not clone {JUN_REPO}")


def main() -> int:
    from jsonschema import Draft7Validator

    with tempfile.TemporaryDirectory() as workdir:
        print(f"Fetching schema from {JUN_REPO} at {JUN_REF}")
        schema = fetch_schema(os.path.join(workdir, "jun"))

    Draft7Validator.check_schema(schema)
    validator = Draft7Validator(schema)

    paths = sorted(glob.glob(EXAMPLE_GLOB))
    if not paths:
        print(f"error: no examples matched {EXAMPLE_GLOB}", file=sys.stderr)
        return 1

    failed = False
    for path in paths:
        try:
            with open(path) as handle:
                document = json.load(handle)
        except json.JSONDecodeError as error:
            print(f"FAIL {path}: not valid JSON: {error}")
            failed = True
            continue

        errors = sorted(validator.iter_errors(document), key=lambda e: list(e.path))
        if errors:
            failed = True
            print(f"FAIL {path}")
            for error in errors:
                location = "/".join(str(part) for part in error.path) or "<root>"
                print(f"       {location}: {error.message}")
        else:
            print(f"OK   {path}")

    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
