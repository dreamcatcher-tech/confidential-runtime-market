# System design

## Layers

```text
User authority layer
  -> phone Secure Enclave / Android Keystore / StrongBox approval key
  -> optional synced passkey for sign-in and recovery UX
  -> optional Ethereum wallet for SIWE/EIP-712 intent, payment, and continuity
  -> optional hardware key / recovery phrase / trustee threshold

StateVault / KMS / quorum custody layer
  -> stores or threshold-holds root DEKs and wrapped DEK records where policy allows
  -> serves scoped object/file/mount leases over attested channels
  -> handles vault-to-vault migration, export, and exceptional bootstrap
  -> never stores secrets on a public chain

Reality Ledger
  -> provider-neutral append-only domain object log
  -> UserAuthority, UnlockPolicy, RecoveryEnrollment, WrappedDEKRecord, StateVaultRecord, StateVaultAccessLease, AgentEpoch, MutationRecord, HostEpoch, HostOffer, BootLeaseRequest, RuntimeClaim, RuntimeClaimClosureReceipt, StateCommitment, AttestationRecord, receipts

Settlement Adapters
  -> Ethereum/L2, GraphFS app-chain, internal fiat/stable-credit ledger
  -> anchors, escrow, payments, dispute windows, public evidence commitments

Host Foundry substrate
  -> minimal bare-metal bootstrap/hypervisor/device layer
  -> launches Bastion CVM first

Bastion CVM
  -> attested host supervisor and watchdog
  -> gathers telemetry, hoists TPM evidence, launches Agent CVMs, participates in KMS/watchdog under policy

Agent CVM
  -> measured base guest + OCI workload runtime
  -> one active AgentIdentity per RuntimeClaim
  -> consumes scoped StateVault access rather than durable root DEK by default
```

## Why Bastion

The host needs a trusted management plane, but the user Agent CVM should not own host-control devices or peer reputation authority. **Bastion** is a good name because it is the fortified boundary between untrusted host substrate and user runtimes. It supervises and reports; it does not become the user agent.

## User authority model

The phone is the default approval root, but recovery is a product tier rather than an implementation accident.

```text
local-only:
  one device-bound phone key; if lost, no recovery except prior export

multi-device:
  two or more enrolled phones/hardware keys can replace a lost device

passkey-assisted:
  synced Apple/Google/credential-provider passkey helps login and re-enrollment
  but does not by itself become the root DEK

wallet-gated:
  Ethereum wallet signs SIWE/EIP-712 intents for ownership/payment/approval
  wallet signing is not treated as general-purpose encryption

threshold:
  phone + hardware key + recovery phrase/trustees/server escrow under explicit policy
```

Passkeys improve UX because users can recover account/session continuity through Apple/Google/password-manager ecosystems, but that is also their trust tradeoff. A passkey should authorize recovery enrollment or scoped unlock intent; it should not silently decrypt old state without current policy, attestation, and latest-state checks.

Ethereum wallets are excellent for a well-trodden custody story, ownership continuity, payments, and signed policy intents. They are not the preferred place to derive storage encryption keys. MetaMask exposes deprecated `eth_getEncryptionPublicKey` / `eth_decrypt` methods, so wallet decryption is specified only as an optional legacy adapter. The default wallet path is SIWE/EIP-712 signature -> policy check -> phone/vault/KMS action.

## StateVault custody model

The cleanest design is to keep root DEKs out of working Hermes/Agent CVMs whenever possible.

```text
encrypted data plane + StateVault mesh
  -> holds DEK shares / wrapped DEK records / per-object keys
  -> verifies RuntimeClaim + AttestationRecord + StateCommitment + UnlockPolicy
  -> serves scoped reads/writes or a mount namespace over an attested channel

Agent CVM
  -> gets least-privilege StateVaultAccessLease
  -> can read/write only scoped state for this claim/epoch
  -> does not persist the root DEK
```

The phone still matters: it approves runtime claims, re-enrollment, export, and policy changes. The user can prove authority and export their data if they leave, but normal operation need not carry the DEK around on the phone or the working VM.

## Market flows

### Supply-first

```text
publisher posts ImageStream digest
host Bastion subscribes
Bastion pre-warms Agent CVM
Bastion posts HostOffer
user claims HostOffer
phone/StateVault/KMS grants scoped state access
```

### Demand-first

```text
user/business posts BootLeaseRequest with prepaid budget
Bastion boots/assigns Agent CVM matching image and policy
host submits claimLease
contract/adapter auto-claims if predicates match
phone/StateVault/KMS grants scoped state access
```

### Spot

```text
price/balance threshold breached
  -> warning/grace period
  -> quiesce or migrate
  -> final StateCommitment
  -> release/closure receipt
  -> unlock/access lease expiry
```

## Provider-neutral first

Ethereum is not the root model. It is a settlement adapter over the Reality Ledger. This preserves migration freedom toward GraphFS app-chain, Ethereum L2, internal ledger, or hybrid settlement.

## Security boundary

- Public ledger: hashes, commitments, receipts, balances, policy references, roots.
- Phone/user authorities: approval, recovery enrollment, export, and scoped unlock intent.
- Passkey: UX/account continuity and approval input, not silent root DEK recovery by default.
- Ethereum wallet: SIWE/EIP-712 intent/payment/ownership proof; optional deprecated decrypt adapter only.
- StateVault/KMS: scoped custody and state-access release; not an unconstrained master-key service.
- Attested tunnel: encrypted lease or state stream to Agent CVM transport key.
- Bastion: host supervision and evidence, not unilateral key release.
- Agent CVM: user workload and state consumer, not host control or durable root DEK owner by default.

## MVP recommendation

1. Implement primitive schemas and deterministic validators.
2. Build a private Reality Ledger segment store first.
3. Prototype user authority tiers with simulated phone key, passkey assertion, and wallet signature.
4. Prototype one StateVault service and one Agent CVM using scoped leases.
5. Prototype a single Bastion-like supervisor and one Agent CVM using one TEE stack.
6. Anchor only batch roots and escrow receipts to Ethereum/L2 after the object model works.
