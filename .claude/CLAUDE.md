# Hybrid Infrastructure Toolkit — Claude Code Instructions

## Repository Purpose

This repository is the Hybrid Infrastructure Toolkit. It is a standalone platform project for building configurable, repeatable hybrid infrastructure labs and reference environments.

It is NOT a successor, rename, or migration target of any other repository. Treat it as its own project.

## Working Rules

- Public docs live under `docs/` and are published via MkDocs to GitHub Pages.
- Internal planning lives under `planning/` at the repo root and is NOT part of the public docs site.
- Reusable implementation code lives under `src/`.
  - `src/deployments/<toolchain>/` for deployment implementations (bicep, terraform, powershell-azurecli, dsc, ansible, arm).
  - `src/platform/` for shared modules, validators, and orchestration.
- Configuration lives under `configs/variables/`.
  - `variables.template.yml` is the canonical schema-shaped template.
  - `variables.yml` is the active working file consumed by deployments.
  - `examples/` holds reference variable sets for specific scenarios.

## Conventions

- Naming: Microsoft Cloud Adoption Framework (CAF) — `<type>-<workload>-<instance>-<region>-<seq>`. Storage accounts: `st<workload><seq>` (lowercase, no hyphens, max 24 chars).
- Secrets: never commit plain-text secrets. Use `keyvault://<vault>/<secret>` URIs and pre-stage secrets in the target Key Vault.
- Standards: see `docs/standards/engineering-standards.md`.
- Design guidance: see `docs/design/`.

## Do Not

- Do not add references in this repository to `mms_2026_hybrid_demo`, `mms_2026_avd_demo`, `hyperv-cluster-demo`, or any external repo path. This repo stands alone.
- Do not commit secrets, real tenant IDs, or real subscription IDs to `variables.template.yml`.
- Do not edit files under `configs/variables/examples/` without explicit instruction — they are reference snapshots.
- Do not move planning documents into `docs/`. Public docs and internal planning stay separated.

## Build / Verify

- Docs: `mkdocs build --strict` from repo root.
- Docs preview: `mkdocs serve`.
