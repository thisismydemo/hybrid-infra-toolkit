# Variables

This directory holds the configuration inputs that drive deployments in this repository.

## Files

- `variables.template.yml` — canonical schema-shaped template. Copy this when starting a new environment.
- `variables.yml` — the active working file consumed by deployments in this repository.
- `examples/` — reference variable sets for specific scenarios.

## Rules

- Do not commit real tenant IDs, subscription IDs, host names, or other tenant-specific identifiers to `variables.template.yml`.
- Do not commit secrets to any file in this directory. All secret values must use `keyvault://<vault-name>/<secret-name>` URIs and be pre-staged in the target Key Vault.
- Naming follows the Microsoft Cloud Adoption Framework: `<type>-<workload>-<instance>-<region>-<seq>` (storage accounts use `st<workload><seq>`, lowercase, no hyphens, max 24 chars).
- Schema changes belong in `variables.template.yml` first. `variables.yml` and the examples should follow the template shape.
