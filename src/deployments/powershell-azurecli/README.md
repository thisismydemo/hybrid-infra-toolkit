# PowerShell And Azure CLI Deployment Category

Use this area for deployment and orchestration paths driven by PowerShell and Azure CLI.

## Scope

- host bootstrap and configuration
- guest configuration orchestration
- imperative deployment steps that are not cleanly expressed in declarative IaC alone

## Expected Layout

```text
powershell-azurecli/
├── deploy/
├── configure/
└── validate/
```

## Status

Implementation has not started. Scripts added here should consume `configs/variables/variables.yml` and follow the PowerShell standards in `docs/standards/engineering-standards.md`.
