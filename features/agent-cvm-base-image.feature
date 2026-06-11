@cvm @packaging @unlock @state @mvp
Feature: Agent CVM base image
  Agent CVMs run user workloads with encrypted state and attested transport keys.
  They must be minimal enough to measure, but flexible enough to run OCI workloads.

  Background:
    Given an Agent CVM is distinct from Bastion
    And exactly one live AgentIdentity may run inside one active Agent CVM
    And the Agent CVM should receive only scoped unlock or StateVault access material for the lease

  Scenario: Agent CVM boots a measured base image
    Given Bastion starts an Agent CVM
    When the Agent CVM initializes
    Then it boots a measured kernel, initrd/rootfs, runtime agent, and policy bundle
    And it generates a fresh transport key inside the confidential boundary
    And its attestation binds the transport public key, nonce, image/policy digests, and TEE evidence

  Scenario: Agent CVM waits locked until phone, StateVault, or KMS release
    Given the Agent CVM has started and attested
    When no valid unlock or StateVaultAccessLease payload has arrived
    Then it can serve only attestation, health, and claim endpoints
    And it cannot mount or request encrypted state
    And it cannot perform mutating external actions as the AgentIdentity

  Scenario: Agent CVM accesses only the latest permitted state
    Given phone, StateVault, or KMS releases a scoped storage access lease
    When the Agent CVM attempts to mount or request encrypted state
    Then it checks the state_id, expected AgentEpoch, StateCommitment root, expiry, and associated attestation data
    And it refuses old state unless rollback policy was explicitly approved
    And it does not require durable possession of the root DEK in the normal StateVault path

  Scenario: Agent CVM records final state before shutdown or migration
    Given a spot eviction, upgrade, reboot, or migration begins
    When the Agent CVM has unlocked state
    Then it quiesces mutating work where possible
    And it commits a final StateCommitment root and release/closure receipt
    And it destroys or expires scoped key material before shutdown
