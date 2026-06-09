@unlock @attestation @state @protocol @mvp
Feature: Phone and KMS scoped unlock
  Secrets move through phone/KMS-controlled attested tunnels, never through public chain state.

  Background:
    Given a phone app or passkey-authorized user is the primary unlock authority
    And KMS/quorum is an availability path, not an unconstrained key owner
    And each Agent CVM has an attested transport key

  Scenario: Phone-first unlock for a claimed runtime
    Given a RuntimeClaim references an Agent CVM attestation and transport public key
    And the claim references the latest StateCommitment for the AgentIdentity
    When the phone app verifies the claim, Bastion evidence, Agent CVM attestation, image digest, policy digest, and state root
    Then it encrypts the scoped unlock material to the Agent CVM transport key
    And the unlock material includes state_id, epoch_id, claim_id, expiry, and associated policy data
    And the chain or Reality Ledger records only a release receipt or commitment hash

  Scenario: KMS mesh handles phone-offline migration under deterministic policy
    Given user policy permits phone-offline migration
    And the current Agent CVM is failed, expired, or intentionally handing off
    When quorum members verify replacement RuntimeClaim, latest state root, accepted attestation, and policy
    Then they release or rewrap only a scoped short-lived unlock lease
    And they publish a KMSReleaseReceipt
    And the release is denied if the latest state root or active claim is ambiguous

  Scenario: User recovery can re-enroll authority without silently unlocking old state
    Given the user loses their phone
    When Apple/Google passkey recovery, hardware key recovery, or trustee recovery re-enrolls a device
    Then the protocol can restore approval authority according to tier policy
    But old state unlock still requires current ledger state, attestation verification, and explicit policy checks

  Scenario: Unlock logs are redacted
    Given an unlock request succeeds or fails
    When logs, receipts, or reports are stored
    Then they include hashes, IDs, timestamps, policy decisions, and attestation references
    And they never include raw DEKs, master keys, provider API keys, or plaintext secrets
