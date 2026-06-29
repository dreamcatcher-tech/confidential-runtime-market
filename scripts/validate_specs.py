#!/usr/bin/env python3
from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]
FEATURE_DIR = ROOT / "features"
ALLOWED_TAGS = {
    "@protocol", "@market", "@ethereum", "@host", "@cvm", "@unlock",
    "@state", "@attestation", "@enterprise", "@billing", "@packaging",
    "@reconciliation", "@recovery", "@wallet", "@mvp",
}
REQUIRED_FEATURES = {
    "protocol-domain-ledger.feature",
    "ethereum-settlement-adapter.feature",
    "runtime-marketplace.feature",
    "host-bare-metal-bootstrap.feature",
    "bastion-cvm.feature",
    "agent-cvm-base-image.feature",
    "oci-workload-packaging.feature",
    "user-authority-and-recovery.feature",
    "phone-kms-unlock.feature",
    "state-vault-mesh.feature",
    "state-epochs-and-storage.feature",
    "attestation-archive-and-watchdog.feature",
    "enterprise-controlled-hosts-and-billing.feature",
    "reconciliation-invariants.feature",
}
REQUIRED_PRIMITIVES = [
    "BirthCertificate", "AgentIdentity", "UserAuthority", "UnlockPolicy", "RecoveryEnrollment", "WrappedDEKRecord",
    "StateVaultRecord", "StateVaultAccessLease", "DataExportReceipt", "VaultCustodyReceipt",
    "AgentEpoch", "MutationRecord", "ImageStream", "RuntimePolicy", "HostRecord",
    "BastionReport", "HostEpoch", "HostOffer", "BootLeaseRequest", "RuntimeClaim",
    "RuntimeClaimClosureReceipt", "StateCommitment", "AttestationRecord", "KMSReleaseReceipt",
    "PaymentReceipt", "ServiceOffer", "ServiceReceipt", "AgentRuntimeBundle", "SettlementAnchor",
    "DisputePatch",
]
REQUIRED_CONTRACT_FUNCTIONS = {
    "ARKBirthCertificate.sol": ["mint", "ownerOfAgent"],
    "ARKRuntimeMarketplace.sol": ["registerHost", "publishImage", "requestRuntime", "claimRuntime", "checkpointState", "closeRuntime"],
}
RETIRED_TERMS = [
    "ARKRuntimeOrchestrator",
    "mintArkBirthCertificate",
    "postBootLeaseRequest",
    "claimBootLease",
    "recordReleaseReceipt",
    "commitState(",
    "closeRuntimeClaim",
]
ACTIVE_TEXT_PATHS = [
    ROOT / "README.md",
    ROOT / "docs" / "v0-vertical-slice.md",
    ROOT / "docs" / "spec-reconciliation.md",
    ROOT / "site" / "index.html",
    ROOT / "site" / "app.js",
    ROOT / "scripts" / "deploy.cjs",
]


def fail(msg: str) -> None:
    print(f"FAIL: {msg}")
    sys.exit(1)


def function_names(solidity_text: str) -> set[str]:
    return set(re.findall(r"\bfunction\s+([A-Za-z_][A-Za-z0-9_]*)\s*\(", solidity_text))


def mermaid_blocks(markdown: str) -> list[str]:
    return re.findall(r"```mermaid\s*\n(.*?)```", markdown, re.S)


def validate_github_mermaid_safety(blocks: list[str]) -> None:
    """Guard against Mermaid syntax that GitHub renders as raw error panels.

    GitHub's Mermaid renderer is stricter than many Mermaid playground examples for
    flowchart edge labels and sequence messages. Keep README diagrams simple: core
    operation names, no argument lists, no escaped newlines, and no punctuation that
    the live renderer has rejected in edge/message text.
    """
    unsafe = re.compile(r"[(),+;/]")
    for block_index, block in enumerate(blocks, start=1):
        if "\\n" in block:
            fail(f"README Mermaid block {block_index} uses escaped newlines; use simple one-line labels for GitHub rendering")
        for line_no, raw_line in enumerate(block.splitlines(), start=1):
            line = raw_line.strip()
            if line.count("-->") > 1:
                fail(f"README Mermaid block {block_index} line {line_no} chains flowchart arrows; split into one edge per line")
            for label in re.findall(r"\|([^|]+)\|", line):
                if unsafe.search(label):
                    fail(f"README Mermaid block {block_index} line {line_no} has GitHub-unsafe edge label punctuation: {label}")
            if "->" in line and ":" in line and not line.startswith("participant "):
                message = line.split(":", 1)[1].strip()
                if unsafe.search(message):
                    fail(f"README Mermaid block {block_index} line {line_no} has GitHub-unsafe sequence message punctuation: {message}")


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
    required_terms = ["Reality Ledger", "Ethereum", "Foundry", "Bastion", "Agent CVM", "BootLeaseRequest", "HostOffer", "RuntimeClaim", "StateCommitment", "UserAuthority", "StateVault", "ARKBirthCertificate", "ARKRuntimeMarketplace"]
    for term in required_terms:
        if term not in reconciliation:
            fail(f"spec reconciliation missing term: {term}")

    contracts_dir = ROOT / "contracts"
    if (contracts_dir / "ARKRuntimeOrchestrator.sol").exists():
        fail("retired monolithic ARKRuntimeOrchestrator.sol still exists")
    for contract_name, expected_functions in REQUIRED_CONTRACT_FUNCTIONS.items():
        path = contracts_dir / contract_name
        if not path.exists():
            fail(f"missing contract: contracts/{contract_name}")
        functions = function_names(path.read_text(encoding="utf-8"))
        missing_functions = [name for name in expected_functions if name not in functions]
        if missing_functions:
            fail(f"contracts/{contract_name} missing functions: {', '.join(missing_functions)}")

    readme = (ROOT / "README.md").read_text(encoding="utf-8")
    blocks = mermaid_blocks(readme)
    if not any("flowchart" in block for block in blocks):
        fail("README must include a Mermaid flowchart architecture diagram")
    if not any("sequenceDiagram" in block for block in blocks):
        fail("README must include a Mermaid sequence diagram")
    diagram_text = "\n".join(blocks)
    validate_github_mermaid_safety(blocks)
    diagram_terms = [
        "ARKBirthCertificate", "ARKRuntimeMarketplace", "Reality Ledger", "Bastion", "Agent CVM", "StateVault",
        "mint", "ownerOfAgent", "registerHost", "publishImage", "requestRuntime", "claimRuntime", "checkpointState", "closeRuntime",
    ]
    missing_diagram_terms = [term for term in diagram_terms if term not in diagram_text]
    if missing_diagram_terms:
        fail("README Mermaid diagrams missing terms: " + ", ".join(missing_diagram_terms))

    reconciliation_feature = (FEATURE_DIR / "reconciliation-invariants.feature").read_text(encoding="utf-8")
    if "README Mermaid diagrams stay aligned with executable contracts" not in reconciliation_feature:
        fail("reconciliation feature must require README diagram/code alignment")

    active_text = "\n".join(p.read_text(encoding="utf-8") for p in ACTIVE_TEXT_PATHS if p.exists())
    retired_found = [term for term in RETIRED_TERMS if term in active_text]
    if retired_found:
        fail("active docs/code mention retired monolith terms: " + ", ".join(retired_found))

    print(f"PASS: {len(feature_files)} feature files, {total_scenarios} scenarios, {len(REQUIRED_PRIMITIVES)} primitives, {len(REQUIRED_CONTRACT_FUNCTIONS)} contracts, {len(blocks)} README Mermaid diagrams")


if __name__ == "__main__":
    main()
