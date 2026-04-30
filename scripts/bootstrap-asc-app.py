#!/usr/bin/env python3
"""One-shot bootstrap: register the bundle id and create the App Store Connect app
record for June. Idempotent — safe to re-run; existing resources are reused.

Usage:
    scripts/bootstrap-asc-app.py
"""
import json
import os
import sys
import time
import urllib.error
import urllib.parse
import urllib.request

try:
    import jwt
except ImportError:
    sys.stderr.write("error: PyJWT not installed. run: pip3 install --user 'pyjwt[crypto]'\n")
    sys.exit(1)

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
CONFIG_PATH = os.path.join(SCRIPT_DIR, "asc-config.env")
API_BASE = "https://api.appstoreconnect.apple.com"

BUNDLE_ID = "com.divinedavis.june"
APP_NAME = "June"
SKU = "june"
PRIMARY_LOCALE = "en-US"


def load_env():
    if not os.path.exists(CONFIG_PATH):
        sys.exit(f"missing {CONFIG_PATH}. copy asc-config.env.example and fill in values.")
    env = {}
    with open(CONFIG_PATH) as f:
        for raw in f:
            line = raw.strip()
            if not line or line.startswith("#") or "=" not in line:
                continue
            k, v = line.split("=", 1)
            env[k.strip()] = v.strip().strip('"').replace("$HOME", os.path.expanduser("~"))
    for k in ("ASC_KEY_ID", "ASC_ISSUER_ID", "ASC_KEY_PATH"):
        if not env.get(k):
            sys.exit(f"missing {k} in asc-config.env")
    return env


def make_token(env):
    with open(env["ASC_KEY_PATH"]) as f:
        key = f.read()
    now = int(time.time())
    return jwt.encode(
        {"iss": env["ASC_ISSUER_ID"], "iat": now, "exp": now + 20 * 60, "aud": "appstoreconnect-v1"},
        key,
        algorithm="ES256",
        headers={"kid": env["ASC_KEY_ID"], "typ": "JWT"},
    )


def api(method, path, token, body=None):
    url = f"{API_BASE}{path}"
    data = None if body is None else json.dumps(body).encode()
    req = urllib.request.Request(
        url,
        data=data,
        method=method,
        headers={"Authorization": f"Bearer {token}", "Content-Type": "application/json"},
    )
    try:
        with urllib.request.urlopen(req, timeout=30) as r:
            raw = r.read()
            return r.status, (json.loads(raw) if raw else {})
    except urllib.error.HTTPError as e:
        return e.code, {"error": e.read().decode()[:1200]}


def find_bundle_id(token):
    q = urllib.parse.urlencode({"filter[identifier]": BUNDLE_ID, "limit": "5"})
    status, d = api("GET", f"/v1/bundleIds?{q}", token)
    if status != 200:
        sys.exit(f"bundle id lookup failed: {status} {d}")
    # Bundle IDs are case-insensitive on Apple's side — match accordingly.
    for b in d.get("data", []):
        if b.get("attributes", {}).get("identifier", "").lower() == BUNDLE_ID.lower():
            return b["id"]
    return None


def create_bundle_id(token):
    body = {
        "data": {
            "type": "bundleIds",
            "attributes": {
                "identifier": BUNDLE_ID,
                "name": APP_NAME,
                "platform": "IOS",
            },
        }
    }
    status, d = api("POST", "/v1/bundleIds", token, body)
    if status >= 300:
        sys.exit(f"create bundle id failed: {status} {d}")
    return d["data"]["id"]


def find_app(token):
    q = urllib.parse.urlencode({"filter[bundleId]": BUNDLE_ID, "limit": "5"})
    status, d = api("GET", f"/v1/apps?{q}", token)
    if status != 200:
        sys.exit(f"app lookup failed: {status} {d}")
    for a in d.get("data", []):
        if a.get("attributes", {}).get("bundleId", "").lower() == BUNDLE_ID.lower():
            return a["id"]
    return None


def print_manual_create_instructions():
    print("")
    print("─" * 64)
    print("App Store Connect doesn't allow creating apps via the API.")
    print("Create the app manually (one time, ~30 seconds):")
    print("")
    print("  1. https://appstoreconnect.apple.com/apps")
    print("  2. Click the + button → New App")
    print("  3. Fill in:")
    print("        Platform:           iOS")
    print(f"        Name:               {APP_NAME}")
    print(f"        Primary Language:   English (U.S.)")
    print(f"        Bundle ID:          {BUNDLE_ID}  (XC com divinedavis june)")
    print(f"        SKU:                {SKU}")
    print("        User Access:        Full Access")
    print("  4. Click Create.")
    print("")
    print("Then re-run this script:")
    print("  python3 scripts/bootstrap-asc-app.py")
    print("─" * 64)


def upsert_asc_app_id(env, app_id):
    lines = []
    found = False
    with open(CONFIG_PATH) as f:
        for raw in f:
            if raw.startswith("ASC_APP_ID="):
                lines.append(f"ASC_APP_ID={app_id}\n")
                found = True
            else:
                lines.append(raw)
    if not found:
        lines.append(f"ASC_APP_ID={app_id}\n")
    with open(CONFIG_PATH, "w") as f:
        f.writelines(lines)


def main():
    env = load_env()
    token = make_token(env)

    bundle_resource_id = find_bundle_id(token)
    if bundle_resource_id:
        print(f"✓ bundle id {BUNDLE_ID} already registered ({bundle_resource_id})")
    else:
        bundle_resource_id = create_bundle_id(token)
        print(f"✓ created bundle id {BUNDLE_ID} ({bundle_resource_id})")

    app_id = find_app(token)
    if app_id:
        print(f"✓ app {APP_NAME} already exists ({app_id})")
        upsert_asc_app_id(env, app_id)
        print(f"✓ wrote ASC_APP_ID={app_id} to {CONFIG_PATH}")
    else:
        print(f"✗ app {APP_NAME} not yet created in App Store Connect")
        print_manual_create_instructions()
        sys.exit(0)


if __name__ == "__main__":
    main()
