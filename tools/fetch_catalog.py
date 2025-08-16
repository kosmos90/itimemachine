#!/usr/bin/env python3
import argparse
import json
import os
import sys
import time
import requests

GITHUB_API = "https://api.github.com"

"""
Fetch minimal metadata from stuffed18/ipa-archive-updated and build catalog/catalog.json
Assumptions:
- The repo has `data/` directories with .plist files describing apps
- We will store only: name, bundle id, min iOS, download URL, icon path (if available)
This is an MVP and may need refinement to match the exact repo layout.
"""

def auth_headers():
    token = os.environ.get("GH_TOKEN") or os.environ.get("GITHUB_TOKEN")
    headers = {"Accept": "application/vnd.github+json"}
    if token:
        headers["Authorization"] = f"Bearer {token}"
    return headers


def get_repo_tree(owner, repo, ref="main", retries=3):
    url = f"{GITHUB_API}/repos/{owner}/{repo}/git/trees/{ref}?recursive=1"
    headers = auth_headers()
    for attempt in range(retries):
        r = requests.get(url, headers=headers)
        if r.status_code == 403 and attempt < retries - 1:
            # Rate limit/backoff
            time.sleep(2 ** attempt)
            continue
        r.raise_for_status()
        return r.json()
    # If we exit loop without return, raise last error
    r.raise_for_status()


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--owner", default="stuffed18")
    ap.add_argument("--repo", default="ipa-archive-updated")
    ap.add_argument("--out", default=os.path.join("catalog", "catalog.json"))
    args = ap.parse_args()

    os.makedirs(os.path.dirname(args.out), exist_ok=True)

    # Use a single recursive tree call; then filter paths under data/ ending with .plist
    try:
        tree = get_repo_tree(args.owner, args.repo, ref="main")
    except Exception as e:
        print(f"Failed to fetch git tree: {e}", file=sys.stderr)
        sys.exit(1)

    catalog = []
    for node in tree.get("tree", []):
        if node.get("type") == "blob":
            path = node.get("path", "")
            if path.startswith("data/") and path.endswith(".plist"):
                base = os.path.basename(path)
                name, _ = os.path.splitext(base)
                download_url = f"https://raw.githubusercontent.com/{args.owner}/{args.repo}/main/{path}"
                catalog.append({
                    "name": name,
                    "bundle_id": None,
                    "min_ios": None,
                    "download_url": download_url,
                    "icon": None,
                })

    with open(args.out, "w", encoding="utf-8") as f:
        json.dump({"items": catalog}, f, indent=2, ensure_ascii=False)

    print(f"Wrote {args.out} with {len(catalog)} entries")


if __name__ == "__main__":
    main()
