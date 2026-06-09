#!/usr/bin/env python3
from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]
FEATURE_DIR = ROOT / "features"
ALLOWED_TAGS = {
    "@protocol", "@market", "@ethereum", "@host", "@cvm", "@unlock",
    "@state", "@attestation", "@enterprise", "@billing", "@packaging",
    "@reconciliation", "@mvp",
}
REQUIRED_FEATURES = {
    "protocol-domain-ledger.feature",
    "ethereum-settlement-adapter.feature",
    "runtime-marketplace.feature",
    "host-bare-metal-bootstrap.feature",
    "bastion-cvm.feature",
    "agent-cvm-base-image.feature",
    "oci-workload-packaging.feature",
    "phone-kms-unlock.feature",
    "state-epochs-and-storage.feature",
    "attestation-archive-and-watchdog.feature",
    "enterprise-controlled-hosts-and-billing.feature",
    "reconciliation-invariants.feature",
}
REQUIRED_PRIMITIVES = [
    "AgentIdentity", "AgentEpoch", "MutationRecord", "ImageStream", "RuntimePolicy", "HostRecord",
    "BastionReport", "HostEpoch", "HostOffer", "BootLeaseRequest", "RuntimeClaim",
    "RuntimeClaimClosureReceipt", "StateCommitment", "AttestationRecord", "KMSReleaseReceipt",
    "PaymentReceipt", "ServiceOffer", "ServiceReceipt", "AgentRuntimeBundle", "SettlementAnchor",
    "DisputePatch",
]


def fail(msg: str) -> None:
    print(f"FAIL: {msg}")
    sys.exit(1)


def main() -> None:
    if not FEATURE_DIR.exists():
        fail("features/ directory is missing")

    feature_files = sorted(FEATURE_DIR.glob("*.feature"))
    nested = sorted(p for p in FEATURE_DIR.rglob("*.feature") if p.parent != FEATURE_DIR)
    if nested:
        fail("nested feature files are not allowed: " + ", ".join(str(p.relative_to(ROOT)) for p in nested))

    names = {p.name for p in feature_files}
    missing = REQUIRED_FEATURES - names
    extra = names - REQUIRED_FEATURES
    if missing:
        fail("missing required feature files: " + ", ".join(sorted(missing)))
    if extra:
        fail("unexpected feature files: " + ", ".join(sorted(extra)))

    total_scenarios = 0
    for path in feature_files:
        text = path.read_text(encoding="utf-8")
        if not re.search(r"^Feature:", text, re.M):
            fail(f"{path.name} has no Feature line")
        scenario_count = len(re.findall(r"^\s*Scenario:", text, re.M))
        if scenario_count < 2:
            fail(f"{path.name} should have at least 2 scenarios")
        total_scenarios += scenario_count
        for keyword in ["Given", "When", "Then"]:
            if not re.search(rf"^\s*{keyword}\b", text, re.M):
                fail(f"{path.name} lacks {keyword} step")
        for tag in re.findall(r"@[-A-Za-z0-9_]+", text):
            if tag not in ALLOWED_TAGS:
                fail(f"{path.name} uses unknown tag {tag}")

    primitive_text = (ROOT / "manifests" / "primitives.yaml").read_text(encoding="utf-8")
    missing_primitives = [name for name in REQUIRED_PRIMITIVES if f"  {name}:" not in primitive_text]
    if missing_primitives:
        fail("missing primitives: " + ", ".join(missing_primitives))

    reconciliation = (ROOT / "docs" / "spec-reconciliation.md").read_text(encoding="utf-8")
    required_terms = ["Reality Ledger", "Ethereum", "Foundry", "Bastion", "Agent CVM", "BootLeaseRequest", "HostOffer", "RuntimeClaim", "StateCommitment"]
    for term in required_terms:
        if term not in reconciliation:
            fail(f"spec reconciliation missing term: {term}")

    print(f"PASS: {len(feature_files)} feature files, {total_scenarios} scenarios, {len(REQUIRED_PRIMITIVES)} primitives")


if __name__ == "__main__":
    main()
