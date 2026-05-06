# GitHub Copilot / general AI agent instructions for Hybrid Infrastructure Toolkit

This repository is the Hybrid Infrastructure Toolkit. It is a standalone platform project for building configurable, repeatable hybrid infrastructure labs and reference environments.

It is NOT a successor, rename, or migration target of any other repository.

## Layout

- `docs/` — public MkDocs site (Project, Standards, Design, Demos sections)
- `planning/` — internal planning, not part of the public docs site
- `src/deployments/<toolchain>/` — bicep, terraform, powershell-azurecli, dsc, ansible, arm
- `src/platform/` — shared modules, validators, orchestration
- `configs/variables/` — `variables.template.yml`, `variables.yml`, `examples/`
- `.github/workflows/` — CI/CD including docs publishing

## Rules

- Naming follows Microsoft CAF: `<type>-<workload>-<instance>-<region>-<seq>`. Storage accounts `st<workload><seq>` (lowercase, no hyphens, max 24 chars).
- Secrets must be `keyvault://<vault>/<secret>` URIs only. Never commit plain-text secrets.
- Do not add references to external repositories (e.g. `mms_2026_hybrid_demo`, `hyperv-cluster-demo`). This repo stands alone.
- Public docs and internal planning stay separated.
- See `docs/standards/engineering-standards.md` for engineering standards.
