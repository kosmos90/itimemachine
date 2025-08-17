#!/usr/bin/env python3
import argparse
import json
import os
import sys
import time
import re
import plistlib
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

    # Collect candidate plist paths and sizes from git tree
    candidates = []
    path_size = {}
    for node in tree.get("tree", []):
        if node.get("type") == "blob":
            path = node.get("path", "")
            if path.startswith("data/") and path.endswith(".plist"):
                candidates.append(path)
                size = node.get("size")
                if isinstance(size, int):
                    path_size[path] = size

    # Cap processing to avoid rate limits and giant catalogs
    MAX_ITEMS = int(os.environ.get("ITM_MAX_ITEMS", "800"))
    selected = candidates[:MAX_ITEMS]

    headers = auth_headers()
    catalog = []
    num_only = re.compile(r"^\d+$")
    fetch_size_head = os.environ.get("ITM_FETCH_SIZE_HEAD", "0") == "1"
    head_limit = int(os.environ.get("ITM_HEAD_LIMIT", "200"))
    head_count = 0
    enrich_itunes = os.environ.get("ITM_ENRICH_ITUNES", "0") == "1"
    enrich_limit = int(os.environ.get("ITM_ENRICH_LIMIT", "300"))
    enrich_count = 0
    itunes_cache = {}

    for path in selected:
        raw_url = f"https://raw.githubusercontent.com/{args.owner}/{args.repo}/main/{path}"
        try:
            r = requests.get(raw_url, headers=headers)
            r.raise_for_status()
            # Parse plist (XML or binary)
            pl = plistlib.loads(r.content)
        except Exception:
            pl = {}

        # Try common fields
        name = pl.get("CFBundleDisplayName") or pl.get("CFBundleName") or pl.get("name") or os.path.splitext(os.path.basename(path))[0]
        bundle_id = pl.get("CFBundleIdentifier") or pl.get("bundle_id") or pl.get("bundleId")
        min_ios = pl.get("MinimumOSVersion") or pl.get("min_ios")
        icon = None

        # Skip numeric-only placeholder names
        if isinstance(name, str) and num_only.match(name.strip()):
            continue

        # Try to find a direct IPA URL in the plist (heuristics)
        ipa_url = (
            pl.get("download_url") or pl.get("downloadURL") or pl.get("url") or
            pl.get("ipa") or pl.get("ipa_url") or pl.get("ipaURL") or pl.get("install_url")
        )
        if isinstance(ipa_url, str) and ipa_url.startswith("http"):
            download_url = ipa_url
        else:
            download_url = raw_url

        # Determine size: prefer real IPA size via HEAD if enabled; otherwise fallback to plist blob size
        size_val = path_size.get(path)
        if fetch_size_head and isinstance(download_url, str) and download_url.startswith("http") and head_count < head_limit:
            try:
                hr = requests.head(download_url, allow_redirects=True, timeout=10)
                cl = hr.headers.get("Content-Length")
                if cl and cl.isdigit():
                    size_val = int(cl)
                head_count += 1
            except Exception:
                pass

        # Optionally enrich via iTunes Lookup for description and artwork
        desc_val = None
        icon_val = None
        if enrich_itunes and isinstance(bundle_id, str) and bundle_id and enrich_count < enrich_limit:
            if bundle_id in itunes_cache:
                res = itunes_cache[bundle_id]
            else:
                try:
                    lu = f"https://itunes.apple.com/lookup?bundleId={bundle_id}&country=us"
                    ir = requests.get(lu, timeout=8)
                    if ir.ok:
                        res = ir.json()
                        itunes_cache[bundle_id] = res
                    else:
                        res = None
                except Exception:
                    res = None
                enrich_count += 1
            if res and isinstance(res, dict):
                arr = res.get("results") or []
                if arr and isinstance(arr, list):
                    first = arr[0]
                    if isinstance(first, dict):
                        desc_val = first.get("description")
                        icon_val = first.get("artworkUrl100") or first.get("artworkUrl60")

        catalog.append({
            "name": str(name) if name is not None else "Unknown",
            "bundle_id": str(bundle_id) if bundle_id is not None else "",
            "min_ios": str(min_ios) if min_ios is not None else "",
            "download_url": download_url,
            "icon": icon_val or icon,
            "description": desc_val,
            "size": size_val,
        })

    with open(args.out, "w", encoding="utf-8") as f:
        json.dump({"items": catalog}, f, indent=2, ensure_ascii=False)

    print(f"Wrote {args.out} with {len(catalog)} entries")


if __name__ == "__main__":
    main()
