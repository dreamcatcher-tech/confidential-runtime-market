# ADR 0001: Name the host supervisor CVM Bastion

Status: accepted

## Context

The design needs a first confidential VM on each host that supervises user Agent CVMs, gathers host evidence, hoists TPM/boot evidence where possible, measures peers, and participates in watchdog/KMS policy. It must be distinct from the user agent runtime.

## Decision

Name this component **Bastion CVM**.

## Consequences

- Bastion is the trusted host supervisor boundary.
- Bastion can report, supervise, nominate, and participate in quorum under policy.
- Bastion does not unilaterally release user storage keys.
- User workloads run in separate Agent CVMs.
