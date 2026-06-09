# System design

## Layers

```text
User phone / passkey / recovery authority
  -> verifies runtime claim and attestation
  -> encrypts scoped unlock payload

KMS / quorum / credential broker
  -> optional phone-offline release path
  -> never public-chain secret storage

Reality Ledger
  -> provider-neutral append-only domain object log
  -> AgentEpoch, MutationRecord, HostEpoch, HostOffer, BootLeaseRequest, RuntimeClaim, RuntimeClaimClosureReceipt, StateCommitment, AttestationRecord, receipts

Settlement Adapters
  -> Ethereum/L2, GraphFS app-chain, internal fiat/stable-credit ledger
  -> anchors, escrow, payments, dispute windows, public evidence commitments

Host Foundry substrate
  -> minimal bare-metal bootstrap/hypervisor/device layer
  -> launches Bastion CVM first

Bastion CVM
  -> attested host supervisor and watchdog
  -> gathers telemetry, hoists TPM evidence, launches Agent CVMs, participates in KMS/watchdog under policy

Agent CVM
  -> measured base guest + OCI workload runtime
  -> one active AgentIdentity per RuntimeClaim
  -> mounts encrypted state only after scoped unlock
```

## Why Bastion

The host needs a trusted management plane, but the user Agent CVM should not own host-control devices or peer reputation authority. **Bastion** is a good name because it is the fortified boundary between untrusted host substrate and user runtimes. It supervises and reports; it does not become the user agent.

## Market flows

### Supply-first

```text
publisher posts ImageStream digest
host Bastion subscribes
Bastion pre-warms Agent CVM
Bastion posts HostOffer
user claims HostOffer
phone/KMS unlocks latest state
```

### Demand-first

```text
user/business posts BootLeaseRequest with prepaid budget
Bastion boots/assigns Agent CVM matching image and policy
host submits claimLease
contract/adapter auto-claims if predicates match
phone/KMS unlocks latest state
```

### Spot

```text
price/balance threshold breached
  -> warning/grace period
  -> quiesce or migrate
  -> final StateCommitment
  -> release/closure receipt
  -> unlock lease expiry
```

## Provider-neutral first

Ethereum is not the root model. It is a settlement adapter over the Reality Ledger. This preserves migration freedom toward GraphFS app-chain, Ethereum L2, internal ledger, or hybrid settlement.

## Security boundary

- Public ledger: hashes, commitments, receipts, balances, policy references, roots.
- Phone/KMS: approval and scoped unlock release.
- Attested tunnel: encrypted secret material to Agent CVM transport key.
- Bastion: host supervision and evidence, not unilateral key release.
- Agent CVM: user workload and encrypted state, not host control.

## MVP recommendation

1. Implement primitive schemas and deterministic validators.
2. Build a private Reality Ledger segment store first.
3. Prototype a single Bastion-like supervisor and one Agent CVM using one TEE stack.
4. Use phone/passkey or simulated phone approval for scoped unlock.
5. Anchor only batch roots and escrow receipts to Ethereum/L2 after the object model works.
