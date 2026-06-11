@reconciliation @protocol @market @host @cvm @unlock @state @mvp
Feature: Cross-spec reconciliation invariants
  The individual module specs must reconcile into one coherent runtime system.

  Scenario: BootLeaseRequest resolves through the same unlock path as HostOffer
    Given a RuntimeClaim came from a supply-side HostOffer
    And another RuntimeClaim came from a demand-side BootLeaseRequest
    When phone/KMS evaluates each claim
    Then both claims must expose the same required fields: agent_id, state_id, image digest, RuntimePolicy digest, Bastion evidence, Agent CVM attestation, transport key, price terms, and latest StateCommitment
    And neither path bypasses attested unlock

  Scenario: Ethereum adapter cannot mutate provider-neutral primitive meaning
    Given the Ethereum adapter stores a HostOffer, BootLeaseRequest, RuntimeClaim, RuntimeClaimClosureReceipt, AgentEpoch, MutationRecord, HostEpoch, ServiceReceipt, or AttestationRecord commitment
    When the same primitive is replayed through a GraphFS app-chain or internal ledger adapter
    Then IDs, canonical digest, required fields, and validity predicates remain the same
    And only settlement-specific metadata changes

  Scenario: Bastion and Agent CVM are never the same authority
    Given Bastion controls host supervision and Agent CVM runs user workload
    When a host posts evidence or releases secrets
    Then Bastion may attest, supervise, report, nominate, and participate in quorum under policy
    But Agent CVM owns user runtime and encrypted state
    And neither component alone can both approve and receive a user storage unlock

  Scenario: Docker-style publishing reconciles with CVM attestation
    Given a publisher posts an OCI digest
    When an Agent CVM runs that workload
    Then the attestation/policy binds both the generic base guest and the OCI workload digest
    And phone/KMS sees enough evidence to know which workload receives the unlock

  Scenario: Spot eviction reconciles with anti-rollback
    Given a spot RuntimeClaim is being evicted
    When the claim closes
    Then PaymentEscrow, RuntimeClaimRegistry, StateRootRegistry, KMSReleaseReceipt, and RuntimeClaimClosureReceipt agree on final status
    And a replacement claim cannot unlock before the latest state root is unambiguous


  Scenario: User-selected recovery tier reconciles with vault custody
    Given a user chooses local-only, platform-passkey, wallet-gated, multi-device, hardware-key, or threshold recovery
    When phone, StateVault, or KMS evaluates a RuntimeClaim
    Then the selected UnlockPolicy determines which UserAuthority proofs are sufficient
    And StateVaultAccessLease issuance never bypasses the RecoveryPolicy
    And public settlement sees only commitments and receipts

  Scenario: Working Agent CVM does not need durable DEK custody
    Given StateVault mesh holds the root storage DEK or threshold shares
    When an Agent CVM reads or writes state
    Then the Agent CVM receives scoped data access rather than a portable root DEK by default
    And user export still requires phone or recovery authority proof
    And the design remains compatible with an opt-in local-DEK portability tier
