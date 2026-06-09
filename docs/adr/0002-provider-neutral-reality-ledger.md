# ADR 0002: Define provider-neutral Reality Ledger before Ethereum

Status: accepted

## Context

A prior design pass concluded the system needs append-only reality, agent epochs, state roots, attestations, receipts, payments, and dispute evidence. Ethereum is valuable for public settlement and finality, but it should not distort the core domain model.

## Decision

Define a provider-neutral **Reality Ledger** and treat Ethereum/L2 as one settlement adapter.

## Consequences

- `AgentEpoch`, `HostOffer`, `BootLeaseRequest`, `RuntimeClaim`, `StateCommitment`, `AttestationRecord`, and `KMSReleaseReceipt` are protocol primitives, not Solidity-only structs.
- Ethereum adapters publish roots, indexes, escrow, and receipts.
- GraphFS app-chain or internal ledger can later implement the same primitives.
