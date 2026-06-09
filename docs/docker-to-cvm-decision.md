# Docker/OCI image to CVM decision

## Question

Docker images are easy, but confidential workloads run inside VMs/CVMs. Should the system convert Docker images into VM images, or is there an easier path?

## Decision

Default to **OCI workloads inside a generic measured Agent CVM base image**.

Do not make every publisher produce a full bootable VM disk. The publisher should publish an OCI image digest. Bastion boots a generic, measured Agent CVM guest that contains a runtime agent. That guest pulls, verifies, decrypts, and runs the OCI workload inside the confidential boundary. Phone/KMS release policy binds both the generic guest digest and the OCI workload digest.

## Why

- Keeps publisher workflow Docker/OCI-native.
- Avoids per-workload bootable disk sprawl.
- Lets one measured guest/runtime image host many workload digests.
- Matches the Confidential Containers/Kata pattern: pod/workload inside a confidential VM, with image handling inside the guest for confidentiality.
- Makes pre-warmed pools practical because the base guest can be common while workload digest and policy remain explicit.

## Source basis

- Confidential Containers design overview: CoCo uses a pod-centric approach, builds on Kata Containers, runs pods inside confidential VMs, and pulls/unpacks images inside the guest because host-side image pulling/filesystem passthrough is unsuitable for confidential workloads.
- Kata Containers: lightweight VMs that plug into the container ecosystem and support OCI/containerd while providing VM isolation.
- firecracker-containerd: containerd can manage containers as Firecracker microVMs, preserving OCI compatibility with fast start/stop and minimal overhead.
- d2vm: Docker-to-VM conversion exists and can build VM images from Docker images/Dockerfiles, but it is a separate artifact path with distro/support/root requirements.

## Answer to overhead concern

The overhead is not zero: an Agent CVM has a guest kernel, guest agent, memory floor, boot time, and attestation work. But it is small enough for the intended model if hosts pre-warm runtimes before claim. The user-visible path becomes claim + unlock, not cold boot + image conversion.

## Fallback conversion path

Use Docker-to-VM conversion only when:

- the workload is an appliance that must boot as a full OS image;
- the TEE provider requires a VM disk image rather than a guest runtime pulling OCI payloads;
- early demo tooling is simpler with one converted qcow2/raw image;
- reproducibility can be proven from source OCI digest to output disk digest.

If used, RuntimePolicy must record:

```yaml
source_oci_digest: sha256:...
conversion_tool: d2vm or equivalent
conversion_tool_version: ...
output_disk_digest: sha256:...
kernel_digest: sha256:...
initrd_digest: sha256:...
boot_policy_digest: sha256:...
reproducibility: reproducible | best_effort | unknown
```

## Practical first implementation choices

1. **Kata/Confidential Containers style** for Kubernetes/pod-shaped experiments.
2. **Firecracker-containerd style** for microVM/containerd experiments where confidential hardware support and attestation path are added separately.
3. **Cloud provider confidential VM + guest runtime** for the quickest provider-specific demo.
4. **d2vm/qcow2 conversion** only for appliance fallback or controlled demo.
