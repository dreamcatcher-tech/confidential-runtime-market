# ADR 0003: Run OCI workloads inside generic Agent CVMs by default

Status: accepted

## Context

Docker images are easy to publish, but confidential runtimes are VMs. The project needs a cheap, simple path from OCI image digest to attested CVM execution.

## Decision

Keep publisher workloads as OCI images. Boot a generic measured Agent CVM base image with a guest runtime agent that pulls/verifies/runs the OCI workload inside the confidential boundary. Bind both base guest digest and OCI workload digest into RuntimePolicy and unlock checks.

## Consequences

- Publisher UX stays Docker/OCI-native.
- The measured base image is reusable.
- Pre-warmed pools remain practical.
- Docker-to-VM conversion remains available only as a fallback for appliance-style workloads or demos.
