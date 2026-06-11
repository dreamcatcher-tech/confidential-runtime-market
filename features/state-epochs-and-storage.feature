@state @protocol @unlock @mvp
Feature: Agent epochs, encrypted storage, and anti-rollback
  State continuity is enforced through monotonic commitments, not by trusting hosts.

  Background:
    Given each AgentIdentity has encrypted state stored in object storage, GraphFS/TigrisFS, a network block store, StateVault, or another content-addressed substrate
    And each state update produces a StateCommitment root
    And latest state is checked before unlock or state-access lease

  Scenario: AgentEpoch records state root and runtime identity
    Given an Agent CVM has unlocked state for an active RuntimeClaim
    When it completes an epoch
    Then it records an AgentEpoch with agent_id, claim_id, image digest, policy digest, previous state root, new state root, mutating action receipts, and writer attestation reference
    And the Reality Ledger can include the epoch in a host root or global epoch root

  Scenario: Replacement runtime cannot resume stale state by default
    Given a replacement Agent CVM requests unlock for state version N
    And the latest accepted StateCommitment is version N+1
    When phone/KMS evaluates the request
    Then unlock is denied unless rollback policy explicitly permits version N
    And any rollback approval is recorded as a distinct receipt

  Scenario: Host-wide roots preserve per-agent proofs
    Given a host batches many disk roots, health records, image records, and AgentEpoch roots
    When Bastion creates a host_root
    Then each AgentIdentity can obtain an inclusion proof for its own StateCommitment
    And the settlement adapter can anchor the host_root without exposing raw state

  Scenario: Final state receipt is required for clean spot eviction
    Given a RuntimeClaim is evicted under spot terms
    When the Agent CVM is reachable during the grace period
    Then it must produce a final StateCommitment and close receipt before the lease closes cleanly
    And failure to produce one becomes dispute or risk evidence for that host


  Scenario: StateVault custody separates root DEK from working runtime
    Given StateVault has custody of WrappedDEKRecord or DEK threshold shares
    When an Agent CVM needs state access for an active RuntimeClaim
    Then the Agent CVM receives only a scoped StateVaultAccessLease or object lease
    And StateCommitment updates still record the resulting state root
    And the root DEK can remain inside the StateVault mesh unless export policy is satisfied
