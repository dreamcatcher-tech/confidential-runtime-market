@packaging @cvm @attestation @mvp
Feature: OCI workload packaging inside confidential VMs
  Publisher UX should stay Docker/OCI-shaped even though execution is inside CVMs.

  Background:
    Given publishers can produce ordinary OCI/Docker images with immutable digests
    And CVMs require a bootable guest kernel/rootfs rather than directly booting a container tag
    And attestation must bind both the generic guest and the workload digest/policy

  Scenario: Default path keeps OCI image as workload payload
    Given a publisher posts an OCI image digest to an ImageStream
    When Bastion prepares an Agent CVM for that image
    Then Bastion boots a generic measured Agent CVM base image
    And the guest runtime pulls, verifies, decrypts, or unpacks the OCI image inside the confidential boundary
    And the Agent CVM attestation or policy evidence binds the workload digest before unlock

  Scenario: Docker-to-VM conversion is a fallback, not the primary interface
    Given a workload requires appliance-style boot or cannot run cleanly as a container payload
    When the operator chooses to convert an OCI image into a bootable disk image
    Then the conversion artifact becomes a separate measured VM image digest
    And RuntimePolicy records the conversion tool, source OCI digest, output disk digest, kernel/initrd/disk metadata, and reproducibility status
    And the extra artifact burden is treated as a trade-off rather than the default path

  Scenario: CVM overhead is acceptable when runtimes are pre-warmed
    Given microVM/Kata-style runtimes add some kernel and guest-agent overhead compared with raw containers
    When hosts pre-warm Agent CVMs for popular images or posted BootLeaseRequests
    Then user cutover latency is dominated by claim and unlock rather than cold VM boot
    And the market can price memory/CPU overhead explicitly in HostOffer and BootLease terms

  Scenario: Unlock policy checks workload digest, not mutable tag
    Given a publisher updates `latest` or another mutable image tag
    When a RuntimeClaim is evaluated
    Then phone/KMS and the settlement adapter use immutable OCI digest and RuntimePolicy digest
    And mutable tags are display metadata only
