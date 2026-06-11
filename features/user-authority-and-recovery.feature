@unlock @recovery @wallet @mvp
Feature: User authority and recovery tiers
  The phone is the default approval root, but each user must be able to choose
  whether their agent state is unrecoverable, platform-recoverable, wallet-gated,
  or threshold-recoverable.

  Background:
    Given a UserAuthority belongs to an AgentIdentity
    And every UserAuthority has a class such as device_bound_phone, platform_passkey, ethereum_wallet, hardware_security_key, recovery_phrase, server_escrow, or trusted_quorum
    And an UnlockPolicy references one or more UserAuthorities with threshold and freshness rules
    And public ledgers store only authority commitments, policy hashes, signatures, and receipts

  Scenario: Device-only phone tier is deliberately unrecoverable
    Given the user chooses local_hardware_only recovery policy
    And the only enrolled authority is a phone Secure Enclave, Android Keystore, or StrongBox key
    When that phone is lost or wiped
    Then no Apple, Google, wallet, KMS, or server recovery path silently unwraps existing state
    And the user can recover only data that was previously exported or independently backed up under another authority

  Scenario: Passkeys improve sign-in and approval UX without becoming the DEK root
    Given the user enrolls a synced platform passkey
    When the user signs in, approves device enrollment, or approves a low-risk unlock intent
    Then the passkey can prove account continuity and improve recovery UX
    But the passkey credential itself must not be the only cryptographic material that decrypts existing encrypted state
    And recovery through the passkey creates or authorizes a new UserAuthority according to UnlockPolicy

  Scenario: Multiple phones and hardware security keys form a recoverable threshold
    Given the user enrolls two device-bound phones and one hardware security key
    And UnlockPolicy requires any two of those authorities for recovery enrollment
    When one phone is lost
    Then the remaining authorities can approve a replacement phone enrollment
    And the replacement receives only a new device-local wrap or StateVaultAccessLease capability
    And old lost-device authorities are revoked or downscoped in the Reality Ledger

  Scenario: Ethereum wallet gates authority by signing intent, not by holding the data key
    Given the user binds an Ethereum address to a UserAuthority
    When the wallet signs a SIWE or EIP-712 UnlockIntent containing agent_id, state_id, claim_id, attestation hash, policy digest, chain id, nonce, and expiry
    Then the signature can prove user intent, payment authority, and wallet continuity
    But the wallet private key is not assumed to be a general-purpose data-encryption key
    And any wallet decryption adapter, such as MetaMask eth_decrypt, is optional, legacy, and never the only recovery route

  Scenario: Recovery tier choices are explicit product commitments
    Given a new user is onboarding
    When the app offers recovery choices
    Then it presents at least local-only, multi-device, passkey-assisted, wallet-gated, and threshold recovery tiers
    And each tier states who can recover data after all phones are lost
    And tier changes create signed RecoveryEnrollment or RecoveryRevocation records before affecting unlock policy
