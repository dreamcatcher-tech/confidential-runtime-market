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
    root / "site" / "ARKBirthCertificate.abi.json",
    root / "site" / "ARKRuntimeMarketplace.abi.json",
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
birth_abi = json.loads((root / "site" / "ARKBirthCertificate.abi.json").read_text(encoding="utf-8"))
marketplace_abi = json.loads((root / "site" / "ARKRuntimeMarketplace.abi.json").read_text(encoding="utf-8"))

checks = {
    "title mentions ARK Runtime Marketplace": "ARK Runtime Marketplace" in index,
    "ethers wallet interaction present": "ethers" in app and "window.ethereum" in app,
    "sample IDs present": "sample" in config,
    "split contract addresses present": "contracts" in config and "birthCertificate" in config["contracts"] and "marketplace" in config["contracts"],
    "birth ABI includes ERC721 ownerOf": any(x.get("name") == "ownerOf" for x in birth_abi if isinstance(x, dict)),
    "birth ABI includes ownerOfAgent compatibility": any(x.get("name") == "ownerOfAgent" for x in birth_abi if isinstance(x, dict)),
    "birth ABI includes mint": any(x.get("name") == "mint" for x in birth_abi if isinstance(x, dict)),
    "marketplace ABI includes registerHost": any(x.get("name") == "registerHost" for x in marketplace_abi if isinstance(x, dict)),
    "marketplace ABI includes requestRuntime": any(x.get("name") == "requestRuntime" for x in marketplace_abi if isinstance(x, dict)),
    "marketplace ABI includes claimRuntime": any(x.get("name") == "claimRuntime" for x in marketplace_abi if isinstance(x, dict)),
    "marketplace ABI includes checkpointState": any(x.get("name") == "checkpointState" for x in marketplace_abi if isinstance(x, dict)),
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
