# Bicep Deployment Category

Use this area for Bicep-based deployment implementations.

## Scope

- Azure-first infrastructure deployment paths
- reusable Bicep modules for hybrid infrastructure scenarios
- entrypoints aligned with `configs/variables/variables.yml`

## Expected Layout

```text
bicep/
├── main.bicep
├── parameters/
│   └── main.bicepparam
└── modules/
```

## Status

Implementation has not started. New code added here should consume `configs/variables/variables.yml` and follow the standards in `docs/standards/engineering-standards.md`.
