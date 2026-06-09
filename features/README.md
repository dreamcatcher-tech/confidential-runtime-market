# Feature specs

Flat, agent-readable `.feature` files. Tags are intentionally small and validated by `scripts/validate_specs.py`.

Allowed tags:

```text
@protocol @market @ethereum @host @cvm @unlock @state @attestation @enterprise @billing @packaging @reconciliation @mvp
```

The specs separate:

- provider-neutral protocol primitives;
- Ethereum/L2 implementation details;
- bare-metal host bootstrap;
- Bastion host supervisor CVM;
- Agent CVM base image and OCI workload packaging;
- phone/KMS unlock and state-root discipline;
- enterprise/controlled-host deployment.
