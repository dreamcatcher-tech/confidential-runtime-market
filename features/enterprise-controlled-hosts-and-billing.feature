@enterprise @billing @market @ethereum
Feature: Enterprise controlled-host deployment and billing bridge
  Conservative businesses must be able to run on their own hardware while using the shared proof layer.

  Background:
    Given not every customer will accept arbitrary marketplace hosts
    And businesses may prefer card, invoice, or managed billing instead of direct crypto UX

  Scenario: Enterprise restricts execution to accepted hosts
    Given a business has a registry of company-owned, leased, or approved hosts
    When it creates a BootLeaseRequest or RuntimePolicy
    Then allowed_host_set limits execution to those hosts
    And the proof layer still records attestations, state roots, receipts, and disputes

  Scenario: Credit-card checkout funds protocol settlement
    Given a customer pays an operating company by card or invoice
    When the company allocates stable-credit or stablecoin balance to PaymentEscrow
    Then the marketplace can reserve runtime leases and service bundles
    And customer-facing billing records map to protocol receipts without exposing payment-card data

  Scenario: Private execution can still use public proof
    Given a RuntimeClaim executes on company-controlled hardware
    When Bastion and Agent CVM attestations are archived
    Then third parties can still verify evidence commitments and timestamps
    And the business can compare its private fleet against broader network reliability and price data

  Scenario: Regulatory and provider terms risks are out of MVP scope
    Given external provider services, token packs, or unused account resale are proposed
    When the MVP scope is evaluated
    Then first-party or provider-authorized service credits are allowed
    And raw account sharing or peer resale is deferred until legal, ToS, metering, and fraud controls are specified
