#!/usr/bin/env python3
import argparse
import json
import os
import sys
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
    """List contents of a path in a GitHub repo via Contents API."""
    r = requests.get(f"{GITHUB_API}/repos/{owner}/{repo}/contents/{path}")
    r.raise_for_status()
    return r.json()


def gather_plists(owner, repo, path, out_list):
    """Recursively walk `path` and append .plist file entries to out_list.
    Each entry minimally includes name (stem), download_url pointer, and placeholders
    for bundle_id/min_ios/icon.
    """
    items = list_repo_contents(owner, repo, path)
    for entry in items:
        etype = entry.get("type")
        name = entry.get("name", "")
        if etype == "dir":
            gather_plists(owner, repo, entry.get("path"), out_list)
        elif etype == "file" and name.endswith(".plist"):
            out_list.append({
                "name": os.path.splitext(name)[0],
                "bundle_id": None,
                "min_ios": None,
                "download_url": entry.get("download_url"),
                "icon": None,
            })


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--owner", default="stuffed18")
    ap.add_argument("--repo", default="ipa-archive-updated")
    ap.add_argument("--out", default=os.path.join("catalog", "catalog.json"))
    args = ap.parse_args()

    os.makedirs(os.path.dirname(args.out), exist_ok=True)

    # Recursively traverse `data/` and gather .plist files
    catalog = []
    try:
        gather_plists(args.owner, args.repo, "data", catalog)
    except Exception as e:
        print(f"Failed to traverse data/: {e}", file=sys.stderr)
        sys.exit(1)

    with open(args.out, "w", encoding="utf-8") as f:
        json.dump({"items": catalog}, f, indent=2, ensure_ascii=False)

    print(f"Wrote {args.out} with {len(catalog)} entries")


if __name__ == "__main__":
    main()
