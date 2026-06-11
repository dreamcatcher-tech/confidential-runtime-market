@unlock @attestation @state @protocol @mvp
Feature: Phone, vault, and KMS scoped unlock
  Secrets move through phone, StateVault, or KMS-controlled attested tunnels, never through public chain state.

  Background:
    Given a phone app is the primary approval authority
    And passkeys, Ethereum wallets, hardware keys, and recovery phrases are UserAuthority inputs to UnlockPolicy
    And StateVault/KMS/quorum is an availability and custody path, not an unconstrained key owner
    And each Agent CVM and StateVault has an attested transport key

  Scenario: Phone-first approval for a claimed runtime
    Given a RuntimeClaim references an Agent CVM attestation and transport public key
    And the claim references the latest StateCommitment for the AgentIdentity
    When the phone app verifies the claim, Bastion evidence, Agent CVM attestation, image digest, policy digest, and state root
    Then it approves a scoped unlock or StateVaultAccessLease for that runtime
    And any payload includes state_id, epoch_id, claim_id, expiry, and associated policy data
    And the chain or Reality Ledger records only a release receipt or commitment hash

  Scenario: StateVault or KMS mesh handles phone-offline migration under deterministic policy
    Given user policy permits phone-offline migration
    And the current Agent CVM is failed, expired, or intentionally handing off
    When quorum members verify replacement RuntimeClaim, latest state root, accepted attestation, and policy
    Then they release, rewrap, or serve only a scoped short-lived unlock or state-access lease
    And they publish a KMSReleaseReceipt or StateVaultAccessLease receipt
    And the release is denied if the latest state root or active claim is ambiguous

  Scenario: User recovery can re-enroll authority without silently unlocking old state
    Given the user loses their phone
    When Apple/Google passkey recovery, hardware key recovery, wallet-gated recovery, or trustee recovery re-enrolls a device
    Then the protocol can restore approval authority according to tier policy
    But old state unlock still requires current ledger state, attestation verification, and explicit policy checks

  Scenario: Wallet-signed unlock intent is bound to attestation and expiry
    Given a user has enrolled an Ethereum wallet authority
    When the wallet signs a SIWE or EIP-712 UnlockIntent
    Then the signed payload includes agent_id, state_id, claim_id, attestation hash, policy digest, chain id, nonce, and expiry
    And the signature authorizes approval only for that scope
    But it does not expose or derive the DEK from the wallet private key

  Scenario: Unlock logs are redacted
    Given an unlock request succeeds or fails
    When logs, receipts, or reports are stored
    Then they include hashes, IDs, timestamps, policy decisions, and attestation references
    And they never include raw DEKs, master keys, provider API keys, or plaintext secrets
