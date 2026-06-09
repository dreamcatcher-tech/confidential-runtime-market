@attestation @host @state @protocol @mvp
Feature: Permanent attestation archive and watchdog evidence
  Attestations and watchdog observations should be hash-locked for later analysis.

  Background:
    Given full attestation blobs may be too large or provider-specific for direct on-chain storage
    And public permanence is valuable for forensics, reputation, and provider comparison

  Scenario: AttestationRecord stores durable public commitment
    Given Bastion or an Agent CVM produces an attestation
    When the evidence is accepted by an off-chain verifier or policy engine
    Then the Reality Ledger records an AttestationRecord with attestation hash, type, subject, image digest, policy digest, transport key hash, verifier signature hash, timestamp, and optional pointer to full evidence
    And Ethereum/L2 may anchor the AttestationRecord hash or batch root

  Scenario: Watchdog observations are signed and challengeable
    Given Bastion A measures Bastion B latency or reachability
    When Bastion A reports a missed heartbeat or degraded path
    Then the report includes measurement time, challenge nonce, peer identity, observation, signature, and confidence class
    And conflicting observations are retained as evidence rather than collapsed into an unverifiable score

  Scenario: Reputation analytics can be retrospective
    Given historical AttestationRecords, BastionReports, PaymentReceipts, StateCommitments, and DisputePatches exist
    When an analyst, user, or protocol agent reviews a host
    Then it can reconstruct uptime, provider reliability, image rollout history, disputed events, and attestation verifier behavior from hashes and evidence pointers

  Scenario: AI interpretation is not a key-release root
    Given an AI agent ranks hosts or flags suspicious telemetry
    When key release or slashing is evaluated
    Then the AI output is treated as advisory evidence
    And deterministic policy, signatures, attestations, state roots, and user/KMS authority make the final release/slash decision
