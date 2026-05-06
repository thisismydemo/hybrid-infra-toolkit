# Hybrid Infrastructure Toolkit

This repository is the new home for the platform work previously incubated in the MMS 2026 Hyper-V cluster demo.

Current status:

- repository initialized
- documentation stack set to MkDocs for now
- migration and platform planning documented before code is moved
- source skeleton created under `src/`
- full reference implementation not migrated yet

## Documentation

The documentation site is planned to publish under:

- `https://www.thisismydemo.cloud/hybrid-infra-toolkit`

GitHub Pages for this repo is configured to publish the docs automatically from `main`.

Initial publish target:

- `https://thisismydemo.github.io/hybrid-infra-toolkit/`

Important note:

- GitHub Pages can publish this repository directly, but it does not by itself make the docs available at `https://thisismydemo.cloud/hybrid-infra-toolkit`
- that custom path still requires your main website or edge routing layer to forward or proxy `/hybrid-infra-toolkit` to the published GitHub Pages site

Local docs commands:

```powershell
python -m pip install mkdocs
mkdocs serve
mkdocs build
```

## Current Planning Focus

- migrate the existing implementation from `E:\git\mms_2026_hybrid_demo\hyperv-cluster-demo`
- separate reusable platform code from the current conference-specific reference implementation
- introduce a configuration-driven model for targets, identity, storage, management, and scenario overlays
- support multiple deployment categories under `src/deployments/`

## Planned Source Layout

- `src/deployments/bicep`
- `src/deployments/terraform`
- `src/deployments/powershell-azurecli`
- `src/deployments/dsc`
- `src/deployments/ansible`
- `src/deployments/arm`
- `src/platform`

See `docs/planning/migration-roadmap.md` for the current migration and platform plan.