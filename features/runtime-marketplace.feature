@market @protocol @enterprise @billing @mvp
Feature: Two-sided confidential runtime marketplace
  The market must support both pre-warmed supply and prepaid demand for confidential runtimes.

  Background:
    Given publishers publish OCI image digests and runtime policy digests into ImageStreams
    And ARKBirthCertificate mints ERC-721 agent identity commitments and exposes ownerOfAgent(agent_id)
    And hosts can subscribe to ImageStreams or respond to BootLeaseRequests
    And users can post prepaid demand only for agents whose birth certificate they own

  Scenario: Publisher updates image stream without forcing immediate cutover
    Given a publisher signs a new OCI image digest and RuntimePolicy digest
    When the ImageStream is updated
    Then hosts may pre-warm the new image
    And existing Agent CVMs continue on their current allowed digest until reboot, upgrade, or policy cutover
    And rollback windows are represented by RuntimePolicy rather than mutable Docker tags

  Scenario: Host reacts to demand-first boot requirement
    Given a BootLeaseRequest says "run this image" and includes a prepaid budget
    When a qualified host sees the request
    Then Bastion may boot or assign an Agent CVM for that image
    And the host may auto-claim only if all lease predicates match
    And the user does not need to wait for a subjective scheduler decision

  Scenario: Market can run in permissionless or controlled-host mode
    Given an enterprise customer sets allowed_host_set to company-controlled hosts
    When it posts a BootLeaseRequest
    Then only those hosts may auto-claim execution
    But the broader Reality Ledger and settlement adapter may still archive attestations, state roots, watchdog evidence, payments, and receipts

  Scenario: Billing bridge keeps customer UX ordinary
    Given a business pays by credit card or invoice
    When the operating company funds the ledger-side balance or stable-credit escrow
    Then the RuntimeClaim can still settle through PaymentEscrow
    And receipts map the fiat order to the on-chain or ledger settlement without storing card data in the protocol

  Scenario: Service bundles can attach to runtime leases later
    Given an AgentRuntimeBundle references a RuntimeClaim and latest AgentEpoch
    When first-party service credits such as gateway access, browser pool credits, or model token packs are added
    Then those credits are metered by ServiceReceipt commitments
    And raw provider credentials are released only to attested runtimes through KMS or a confidential broker
