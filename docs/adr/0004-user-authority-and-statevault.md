# ADR 0004: User authority tiers and StateVault custody

Date: 2026-06-11 NZST
Status: accepted for specification baseline

## Context

Users need different recovery stories. Some want a phone-only hardware root where losing the phone means losing access. Others want passkey-assisted account recovery, multi-device recovery, Ethereum-wallet continuity, YubiKey-style hardware security keys, recovery phrases, or threshold trustees.

The runtime design also should not unnecessarily place a durable root DEK inside every working Agent CVM. Time-in-process matters: the less often a root key appears in a general worker, the smaller the exposure window.

## Decision

1. Treat the phone as the default approval root, not necessarily the place where the root DEK lives during normal operation.
2. Model recovery as explicit `UnlockPolicy` and `RecoveryEnrollment` primitives.
3. Use passkeys for sign-in, approval UX, and recovery enrollment, but do not treat synced platform passkeys as silent DEK recovery for local-only tiers.
4. Use Ethereum wallets for SIWE/EIP-712 owner intent, payment, and continuity. Do not treat wallet signing keys as general-purpose encryption keys.
5. Treat MetaMask `eth_getEncryptionPublicKey` / `eth_decrypt` as optional legacy adapters because MetaMask documents them as deprecated.
6. Introduce StateVault custody. Root DEKs or threshold shares should stay with an attested storage/vault mesh by default. Agent CVMs receive scoped `StateVaultAccessLease` capabilities.
7. Keep user export possible under policy through `DataExportReceipt`, so users can leave with their data when they prove the configured authority threshold.

## Consequences

- The product can present local-only, multi-device, passkey-assisted, wallet-gated, hardware-key, and threshold recovery tiers without changing the core runtime market.
- The working Hermes/Agent CVM does not need durable root DEK custody for the normal path.
- StateVault becomes a security-critical component and must itself be attested, policy-gated, and receipt-generating.
- Wallet-gated recovery remains compatible with self-custody expectations while avoiding deprecated wallet-decrypt APIs as a core dependency.
- A local-DEK portability tier can still exist for users who explicitly choose phone-held/exportable key material.
