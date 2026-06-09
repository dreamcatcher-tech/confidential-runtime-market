@cvm @host @attestation @unlock @state @mvp
Feature: Bastion host supervisor confidential VM
  Bastion is the first host CVM and the attested supervisor/watchdog/control plane
  for Agent CVM offers on a physical host.

  Background:
    Given Bastion runs a pinned standard image digest
    And Bastion is distinct from user Agent CVMs
    And Bastion can publish signed host evidence but must not unilaterally release user storage keys

  Scenario: Bastion publishes host operational evidence
    Given Bastion has attested successfully
    When it builds a BastionReport
    Then the report includes Bastion attestation hash, image digest, optional TPM evidence hash, hardware profile hash, capacity summary, control-surface policy, and timestamp
    And the report can include peer latency measurements, local Agent CVM health checks, and observed peer availability
    And the report digest is available to HostOffer, BootLease claim, and AttestationArchive records

  Scenario: Bastion supervises pre-warmed Agent CVMs
    Given Bastion subscribes to an ImageStream
    When a new approved workload digest appears
    Then Bastion can pre-warm one or more Agent CVMs
    And each Agent CVM produces an attestation binding its own measurement and transport public key
    And Bastion posts HostOffers only for Agent CVMs that pass policy and health checks

  Scenario: Bastion auto-claims a demand lease
    Given a BootLeaseRequest matches this host's allowed policy and price
    When Bastion boots or assigns an Agent CVM for the requested image
    Then Bastion submits the claim with the Agent CVM attestation, transport key, price, and host evidence
    And Bastion records the pending claim locally until phone/KMS unlock succeeds or the claim expires

  Scenario: Bastion participates in watchdog and KMS mesh under policy
    Given user policy permits phone-offline migration or planned reboot handoff
    When Bastion participates in quorum or watchdog activity
    Then it may hold only short-lived RAM-only leases or threshold shares scoped to policy
    And it must publish KMSReleaseReceipt or watchdog evidence for releases, migrations, and failures
    And it may nominate a migration target but cannot alone authorize key release

  Scenario: Bastion evidence can downrank but not slash subjectively
    Given Bastion reports poor latency, missed peer heartbeat, or degraded local health
    When the market updates host reputation
    Then the report can affect ranking, payment windows, or challenge selection
    But slashing requires objective cryptographic evidence accepted by DisputePatch policy
