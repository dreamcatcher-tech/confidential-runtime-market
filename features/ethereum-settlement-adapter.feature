@ethereum @protocol @market @state @attestation
Feature: Ethereum and L2 settlement adapter
  Ethereum should implement public settlement, anchoring, escrow, and evidence commitments
  without becoming the secret holder or the only canonical protocol substrate.

  Background:
    Given the provider-neutral Reality Ledger primitives are already defined
    And Ethereum stores public commitments, roots, receipts, indexes, and balances only
    And secret material is never stored in contract state, calldata, blobs, or event logs

  Scenario: Ethereum contract modules map to provider-neutral primitives
    Given an ImageRegistry contract records ImageStream and RuntimePolicy digests
    And a HostRegistry records HostRecord and BastionReport commitments
    And a HostOfferBook records HostOffer commitments
    And a DemandLeaseBook records BootLeaseRequest commitments
    And a RuntimeClaimRegistry records RuntimeClaim commitments
    And an EpochManifestRegistry records AgentEpoch and SettlementAnchor roots
    And a StateRootRegistry records StateCommitment roots and monotonicity rules
    And a PaymentEscrow records prepaid balances, host payouts, refunds, stable-credit settlement, and PaymentReceipt commitments
    And an AttestationArchive records AttestationRecord hashes and pointers
    And a DisputeRegistry records DisputePatch commitments and objective-fault resolution state
    When a user or host interacts with the Ethereum adapter
    Then the adapter exposes IDs and receipts that map back to the provider-neutral primitives

  Scenario: Demand-side prepaid boot lease can be auto-claimed
    Given a user or business posts a BootLeaseRequest with agent_id, state_id, image digest, attestation policy, max price, prepaid budget, host predicate, duration, spot policy, and unlock policy commitment
    And a host Bastion CVM boots or assigns an Agent CVM satisfying that request
    When the host submits claimLease with offer manifest, attestation hash, Agent CVM transport public key, and price terms
    Then the DemandLeaseBook accepts the claim only if every public predicate matches
    And PaymentEscrow locks the lease balance
    And RuntimeClaimRegistry records a pending or active RuntimeClaim with state_commitment_id and source request reference
    And phone/KMS unlock is still required before secrets reach the Agent CVM

  Scenario: Supply-side pre-warmed host offer can be claimed
    Given a host subscribes to an ImageStream
    And Bastion pre-warms an Agent CVM for the latest allowed image digest
    And the host posts a HostOffer with Bastion evidence, Agent CVM attestation, transport key, price, and health summary root
    When a user claims the HostOffer and bonds payment
    Then RuntimeClaimRegistry records the active mapping only after claim acceptance
    And the phone/KMS verifies the manifest before releasing scoped unlock material

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
