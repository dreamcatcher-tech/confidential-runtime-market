@host @cvm @attestation @mvp
Feature: Foundry bare-metal host bootstrap
  A host must start from a minimal, measurable substrate that launches Bastion CVM
  and keeps untrusted host responsibilities narrow.

  Background:
    Given a physical host may be company-owned, leased, donated, or marketplace-supplied
    And the host may have TPM or measured-boot capability
    And the host must run a minimal substrate before Bastion exists

  Scenario: Host boots the Foundry substrate
    Given the host firmware and bootloader start the Foundry substrate
    When Foundry initializes
    Then it records boot measurements and TPM evidence when available
    And it starts only the hypervisor/device plumbing needed to launch Bastion
    And it must not launch user Agent CVMs before Bastion attestation is available

  Scenario: Foundry launches Bastion as the first confidential VM
    Given Foundry has a pinned Bastion image digest and launch policy
    When it starts Bastion
    Then Bastion receives the host-control devices or control APIs permitted by policy
    And Bastion obtains a fresh attestation report binding its measurement and transport key
    And Foundry publishes no host offer until Bastion has produced an accepted BastionReport

  Scenario: Foundry fails closed when Bastion cannot attest
    Given Bastion fails attestation or cannot bind its transport key
    When Foundry detects the failure
    Then no HostOffer or BootLease claim may be posted for that host
    And the host is marked unavailable or degraded in the Reality Ledger
    And existing unlocked user state is not exposed to Foundry

  Scenario: Foundry keeps user workload control out of the bare-metal substrate
    Given an Agent CVM needs launch, stop, restart, networking, disk attachment, or health check operations
    When that operation is allowed by policy
    Then Bastion requests or performs it through the minimal substrate interface
    And the user Agent CVM never receives direct host-management device authority
