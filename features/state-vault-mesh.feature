@state @unlock @cvm @mvp
Feature: State Vault mesh and DEK custody
  Root data-encryption keys should live with the encrypted state service where
  possible; working Agent CVMs should receive scoped access, not durable DEKs.

  Background:
    Given encrypted user state is stored behind one or more attested StateVault services
    And a StateVault may be a CVM, threshold mesh, or controlled storage enclave separate from Agent CVMs
    And StateVault custody is governed by UnlockPolicy, RuntimeClaim, StateCommitment, and UserAuthority evidence
    And Agent CVMs are consumers of state access leases rather than owners of root storage keys by default

  Scenario: Agent CVM accesses state without receiving the root DEK
    Given an active RuntimeClaim references an Agent CVM attestation and latest StateCommitment
    And StateVault has custody of the relevant WrappedDEKRecord or threshold DEK shares
    When the Agent CVM requests a file, object, or mounted namespace
    Then StateVault verifies the claim, attestation, state version, access scope, and expiry
    And StateVault decrypts, re-encrypts, or streams only the requested data over an attested channel
    And the Agent CVM never persists the root DEK outside the confidential boundary

  Scenario: StateVault replaces a separate always-online key broker for normal access
    Given StateVault holds the DEK next to the encrypted data plane
    When a valid Agent CVM needs ordinary state access
    Then no separate generic key broker is required to hand the DEK to the working VM
    And any KBS or quorum mesh is limited to vault membership, migration, recovery, export, or exceptional bootstrap duties

  Scenario: Phone proves export authority without carrying the DEK during normal operation
    Given the user wants to leave the platform or make an offline backup
    And the selected RecoveryPolicy permits user export
    When the phone, wallet, passkey, hardware key, or threshold authorities satisfy UnlockPolicy
    Then StateVault creates a DataExportReceipt and an encrypted export bundle for the user
    And export can rotate or destroy platform-held WrappedDEKRecords according to policy

  Scenario: Vault-to-vault migration preserves anti-rollback
    Given a replacement StateVault is selected for an AgentIdentity
    When the vault mesh migrates custody
    Then the source and destination vaults verify the latest StateCommitment and RuntimePolicy
    And they publish VaultCustodyReceipt records for source closeout and destination acceptance
    And the migration is denied if state version or active claim is ambiguous

  Scenario: Short-lived access leases minimize key exposure time
    Given an Agent CVM has an approved StateVaultAccessLease
    When the lease expires, the RuntimeClaim closes, or the attestation no longer matches policy
    Then StateVault stops serving state access
    And the Agent CVM must request a fresh lease for any further reads, writes, or mutating actions
    And receipts reveal only hashes, IDs, scopes, and timings, not plaintext data or DEKs
