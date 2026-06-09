# Initial implementation plan

> **For Hermes:** Use subagent-driven-development skill to implement this plan task-by-task.

**Goal:** Turn this spec scaffold into a minimal executable proof of a provider-neutral confidential runtime market.

**Architecture:** Start with local provider-neutral schemas and a deterministic append-only ledger. Add simulated attestations and phone/KMS unlock before touching real Ethereum or hardware TEEs. Then replace simulators with one real attestation/runtime stack.

**Tech Stack:** Python or TypeScript schema/prototype, local append-only JSON/GraphFS-like ledger, later Solidity/Foundry for Ethereum adapter, later Kata/CoCo or cloud CVM for runtime.

---

### Task 1: Define canonical primitive schemas

**Objective:** Create machine-readable schemas for every primitive in `manifests/primitives.yaml`.

**Files:**
- Create: `schemas/*.schema.json`
- Modify: `manifests/primitives.yaml`
- Test: `tests/test_schema_coverage.py`

**Verification:** Every primitive has a schema, required fields, canonical digest test, and append-only receipt shape for closures, mutations, host epochs, and service metering.

### Task 2: Build local Reality Ledger prototype

**Objective:** Append and query provider-neutral objects without Ethereum.

**Files:**
- Create: `src/reality_ledger/`
- Test: `tests/test_reality_ledger.py`

**Verification:** HostOffer, BootLeaseRequest, RuntimeClaim, StateCommitment, and AttestationRecord can be appended and batch-rooted.

### Task 3: Simulate claim and unlock flow

**Objective:** Demonstrate supply-first and demand-first RuntimeClaim paths both reach the same phone/KMS unlock gate.

**Files:**
- Create: `src/sim/claim_unlock.py`
- Test: `tests/test_claim_unlock_sim.py`

**Verification:** Stale state root or missing attestation denies unlock; valid claim releases only scoped ciphertext.

### Task 4: Add Ethereum adapter skeleton

**Objective:** Map Reality Ledger primitives to Solidity interfaces without implementing full business logic.

**Files:**
- Create: `contracts/interfaces/*.sol`
- Create: `docs/ethereum-adapter.md`

**Verification:** Solidity interfaces name the same IDs and commitments as the schemas.

### Task 5: Pick one CVM runtime stack

**Objective:** Choose Kata/CoCo, cloud provider CVM, or Firecracker-based path for the first real attestation prototype.

**Files:**
- Create: `docs/runtime-stack-spike.md`

**Verification:** One stack has a reproducible hello-world workload, attestation evidence, and an identified path to bind a transport key.
