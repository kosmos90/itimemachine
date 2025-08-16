#!/usr/bin/env python3
import argparse
import json
import os
import sys
from urllib.parse import urljoin
import requests

GITHUB_API = "https://api.github.com"

"""
Fetch minimal metadata from stuffed18/ipa-archive-updated and build catalog/catalog.json
Assumptions:
- The repo has `data/` directories with .plist files describing apps
- We will store only: name, bundle id, min iOS, download URL, icon path (if available)
This is an MVP and may need refinement to match the exact repo layout.
"""

def list_repo_contents(owner, repo, path):
    r = requests.get(f"{GITHUB_API}/repos/{owner}/{repo}/contents/{path}")
    r.raise_for_status()
    return r.json()


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--owner", default="stuffed18")
    ap.add_argument("--repo", default="ipa-archive-updated")
    ap.add_argument("--out", default=os.path.join("catalog", "catalog.json"))
    args = ap.parse_args()

    os.makedirs(os.path.dirname(args.out), exist_ok=True)

    # MVP: look for top-level `data` directory
    try:
        items = list_repo_contents(args.owner, args.repo, "data")
    except Exception as e:
        print(f"Failed to list data/: {e}", file=sys.stderr)
        sys.exit(1)

    catalog = []
    for entry in items:
        if entry.get("type") == "file" and entry.get("name", "").endswith(".plist"):
            # For now, just store pointers; a full implementation would fetch and parse the plist
            catalog.append({
                "name": os.path.splitext(entry["name"])[0],
                "bundle_id": None,
                "min_ios": None,
                "download_url": entry.get("download_url"),
                "icon": None,
            })

    with open(args.out, "w", encoding="utf-8") as f:
        json.dump({"items": catalog}, f, indent=2, ensure_ascii=False)

    print(f"Wrote {args.out} with {len(catalog)} entries")


if __name__ == "__main__":
    main()
