@protocol @state @attestation @mvp
Feature: Provider-neutral Reality Ledger protocol primitives
  The marketplace semantics must be defined independently from Ethereum so that
  Ethereum, an L2, a GraphFS app-chain, or an internal ledger can implement them.

  Background:
    Given the protocol defines BirthCertificate, AgentIdentity, UserAuthority, UnlockPolicy, RecoveryEnrollment, WrappedDEKRecord, StateVaultRecord, StateVaultAccessLease, DataExportReceipt, VaultCustodyReceipt, AgentEpoch, MutationRecord, ImageStream, RuntimePolicy, HostRecord, BastionReport, HostEpoch, HostOffer, BootLeaseRequest, RuntimeClaim, RuntimeClaimClosureReceipt, StateCommitment, AttestationRecord, KMSReleaseReceipt, PaymentReceipt, ServiceOffer, ServiceReceipt, AgentRuntimeBundle, SettlementAnchor, and DisputePatch primitives
    And each primitive has a content-addressed digest and canonical serialization
    And each primitive can be recorded in a provider-neutral Reality Ledger before any settlement adapter is chosen

  Scenario: Canonical live-agent mapping is provider neutral
    Given an AgentIdentity has a latest accepted AgentEpoch
    And the AgentEpoch references a StateCommitment root
    When a RuntimeClaim is accepted for that AgentIdentity
    Then the Reality Ledger records exactly one active RuntimeClaim for the AgentIdentity
    And the RuntimeClaim references exactly one Agent CVM transport key bound into an AttestationRecord
    And any previous active RuntimeClaim is closed by a cutover, eviction, failure, or explicit retirement receipt

  Scenario: Chain adapters publish commitments rather than define the domain model
    Given the Reality Ledger has a batch of BirthCertificate, UserAuthority, UnlockPolicy, RecoveryEnrollment, WrappedDEKRecord, StateVaultRecord, StateVaultAccessLease, DataExportReceipt, VaultCustodyReceipt, ImageStream, HostOffer, BootLeaseRequest, RuntimeClaim, RuntimeClaimClosureReceipt, StateCommitment, AttestationRecord, KMSReleaseReceipt, PaymentReceipt, ServiceReceipt, and DisputePatch objects
    When a Settlement Adapter publishes a batch root
    Then the adapter records the batch digest, settlement metadata, and dispute window
    And the underlying domain objects remain interpretable without Ethereum-specific storage layout
    And a later GraphFS app-chain can re-publish the same domain batch without changing primitive meaning

  Scenario: High-frequency operational facts stay below public settlement
    Given Bastion CVMs emit heartbeats, latency measurements, and health reports more often than public settlement is economical
    When the Reality Ledger batches those facts into an AgentEpoch or HostEpoch segment
    Then the high-frequency layer records detailed signed evidence
    And Ethereum/L2 sees only aggregate roots, dispute evidence, payment receipts, and permanent attestation commitments

  Scenario: Mutating external actions are attached to epochs
    Given an Agent CVM proposes a money-moving, message-sending, account-changing, or private-data-revealing action
    When the action is marked mutating by policy
    Then the action is represented as a MutationRecord referenced by an AgentEpoch
    And the mutation requires orchestrator, phone, or policy approval before external execution
    And failover resumes only from the latest committed epoch root or an explicitly approved rollback point


  Scenario: User authority and storage custody are ledger primitives
    Given a user selects local-only, multi-device, passkey-assisted, wallet-gated, or threshold recovery
    When the choice is committed
    Then the Reality Ledger records UserAuthority, UnlockPolicy, and RecoveryEnrollment objects
    And encrypted storage custody is represented by WrappedDEKRecord, StateVaultRecord, StateVaultAccessLease, DataExportReceipt, and VaultCustodyReceipt objects
    And a settlement adapter can anchor those commitments without learning secrets
