#!/usr/bin/env python3
from pathlib import Path
import json
import re
import sys

root = Path(__file__).resolve().parents[1]
required = [
    root / "site" / "index.html",
    root / "site" / "styles.css",
    root / "site" / "app.js",
    root / "site" / "config.json",
    root / "site" / "ARKRuntimeOrchestrator.abi.json",
    root / ".github" / "workflows" / "pages.yml",
]
missing = [str(p.relative_to(root)) for p in required if not p.exists()]
if missing:
    print("FAIL: missing " + ", ".join(missing))
    sys.exit(1)

index = (root / "site" / "index.html").read_text(encoding="utf-8")
app = (root / "site" / "app.js").read_text(encoding="utf-8")
css = (root / "site" / "styles.css").read_text(encoding="utf-8")
workflow = (root / ".github" / "workflows" / "pages.yml").read_text(encoding="utf-8")
config = json.loads((root / "site" / "config.json").read_text(encoding="utf-8"))
abi = json.loads((root / "site" / "ARKRuntimeOrchestrator.abi.json").read_text(encoding="utf-8"))

checks = {
    "title mentions ARK Runtime Orchestrator": "ARK Runtime Orchestrator" in index,
    "ethers wallet interaction present": "ethers" in app and "window.ethereum" in app,
    "sample IDs present": "sample" in config,
    "contract address field present": "contract" in config,
    "ABI includes registerHost": any(x.get("name") == "registerHost" for x in abi if isinstance(x, dict)),
    "ABI includes mintArkBirthCertificate": any(x.get("name") == "mintArkBirthCertificate" for x in abi if isinstance(x, dict)),
    "workflow deploys pages": "actions/deploy-pages" in workflow and "actions/upload-pages-artifact" in workflow,
    "responsive CSS present": "@media" in css,
    "no obvious secret placeholder": not re.search(r"(PRIVATE_KEY|DEPLOYER_PRIVATE_KEY|GITHUB_TOKEN|FLY_API_TOKEN)\s*[:=]", index + app + css),
}
failed = [name for name, ok in checks.items() if not ok]
if failed:
    print("FAIL:")
    for name in failed:
        print(f" - {name}")
    sys.exit(1)
print(f"PASS: site validation ({len(checks)} checks)")
