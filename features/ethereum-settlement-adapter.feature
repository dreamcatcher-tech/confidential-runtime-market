@ethereum @protocol @market @state @attestation
Feature: Ethereum and L2 settlement adapter
  Ethereum should implement public settlement, anchoring, escrow, and evidence commitments
  without becoming the secret holder or the only canonical protocol substrate.

  Background:
    Given the provider-neutral Reality Ledger primitives are already defined
    And Ethereum stores public commitments, roots, receipts, indexes, and balances only
    And secret material is never stored in contract state, calldata, blobs, or event logs

  Scenario: Split Ethereum contracts map to provider-neutral primitives
    Given ARKBirthCertificate is an ERC-721-compatible contract for BirthCertificate commitments
    And ARKRuntimeMarketplace records ImageStream, RuntimePolicy, HostRecord, BootLeaseRequest, RuntimeClaim, StateCommitment, KMSReleaseReceipt, and RuntimeClaimClosureReceipt commitments through a small runtime surface
    And ARKRuntimeMarketplace checks birth-certificate ownership through ownerOfAgent(agent_id)
    And PaymentReceipt, AttestationRecord, SettlementAnchor, ServiceReceipt, HostOffer, and DisputePatch details may be anchored as Reality Ledger roots before they need dedicated contract methods
    When a user or host interacts with the Ethereum adapter
    Then the adapter exposes IDs and receipts that map back to the provider-neutral primitives
    And the birth-certificate contract can evolve independently from the runtime marketplace while preserving ownerOfAgent compatibility

  Scenario: Demand-side prepaid runtime request can be claimed
    Given a user or business posts a BootLeaseRequest with agent_id, state_id, image digest, attestation policy, max price, prepaid budget, host predicate, duration, and unlock policy commitment
    And a host Bastion CVM boots or assigns an Agent CVM satisfying that request
    When the host submits claimRuntime with attestation hash, Agent CVM transport public key, and price terms
    Then ARKRuntimeMarketplace accepts the claim only if every public predicate matches
    And the request records the prepaid balance as public settlement evidence
    And ARKRuntimeMarketplace records an active RuntimeClaim with source request reference
    And phone/KMS unlock is still required before secrets reach the Agent CVM

  Scenario: Supply-side pre-warmed host offer stays a compatible ledger primitive
    Given a host subscribes to an ImageStream
    And Bastion pre-warms an Agent CVM for the latest allowed image digest
    And the host posts a HostOffer with Bastion evidence, Agent CVM attestation, transport key, price, and health summary root into the Reality Ledger
    When the MVP Ethereum adapter is evaluated
    Then direct HostOffer claiming may remain a ledger-root or later adapter extension rather than a mandatory runtime-marketplace method
    And the phone/KMS still verifies the manifest before releasing scoped unlock material

  Scenario: Spot pricing causes graceful eviction rather than state loss
    Given a RuntimeClaim has spot terms with user max bid, host minimum ask, prepaid balance, grace period, and final state-root requirement
    When the clearing price or balance violates the spot policy
    Then the adapter opens an eviction or migration window
    And the Agent CVM must quiesce or hand off
    And the latest StateCommitment, KMSReleaseReceipt, and RuntimeClaimClosureReceipt must be recorded before the unlock lease expires
    And abrupt termination without a final receipt is dispute evidence, not a clean close

  Scenario: Slashing is restricted to objective evidence
    Given a host has posted stake or reputation collateral
    When a dispute is opened
    Then the Ethereum adapter slashes only for cryptographic faults such as equivocation, invalid attestation commitment, double-claim, bad state-root proof, or forged receipt
    And timeout, poor latency, or contested liveness causes non-payment, downranking, challenge escalation, or manual dispute instead of automatic slash
