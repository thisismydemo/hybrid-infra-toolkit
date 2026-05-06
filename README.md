# Hybrid Infrastructure Toolkit

Hybrid Infrastructure Toolkit is a platform project for building configurable, repeatable hybrid infrastructure labs, reference environments, and future demo scenarios.

The project is being shaped as a reusable foundation for hybrid infrastructure work across multiple deployment targets, deployment categories, identity models, storage approaches, and management patterns.

## What This Project Is For

- defining a consistent platform model for hybrid infrastructure labs
- supporting repeatable deployments across Azure, nested virtualization, and physical hardware scenarios
- separating reusable platform code from demo-specific or scenario-specific content
- documenting standards, design decisions, and future demo guidance in one place
- aligning architecture and implementation choices with Microsoft CAF and Well-Architected guidance where applicable

## Current State

- public documentation is published from MkDocs
- internal repo-management planning lives outside the public docs tree
- source areas have been prepared under `src/`
- deployment categories have been planned for Bicep, Terraform, PowerShell or Azure CLI, DSC, Ansible, and ARM templates
- full reference implementations will be brought in selectively as needed

## Documentation

Public documentation is intended to live at:

- `https://www.thisismydemo.cloud/hybrid-infra-toolkit`

GitHub Pages for this repo is configured to publish the docs automatically from `main`.

Initial publish target:

- `https://thisismydemo.github.io/hybrid-infra-toolkit/`

Important note:

- GitHub Pages can publish this repository directly, but it does not by itself make the docs available at `https://thisismydemo.cloud/hybrid-infra-toolkit`
- that custom path still requires your main website or edge routing layer to forward or proxy `/hybrid-infra-toolkit` to the published GitHub Pages site

## Public Documentation Sections

- `docs/index.md` for the main project landing page
- `docs/demos/` for future demo and session content
- `docs/project/` for roadmap, changelog, contribution, and project-facing information
- `docs/standards/` for engineering and operational standards
- `docs/design/` for deployment, implementation, and automation design guidance

Local docs commands:

```powershell
python -m pip install mkdocs
mkdocs serve
mkdocs build
```

## Repository Structure

- `docs/` contains the public documentation site content
- `planning/` contains internal repository planning and migration notes
- `src/` contains shared platform code and deployment-category source areas
- `configs/` contains early configuration artifacts and future shared configuration inputs

## Internal Planning

Repository planning and migration planning live in `planning/planning.md`.

That file is intentionally kept outside `docs/` so internal repo-management material is not published as part of the public documentation site.

## Planned Source Layout

- `src/deployments/bicep`
- `src/deployments/terraform`
- `src/deployments/powershell-azurecli`
- `src/deployments/dsc`
- `src/deployments/ansible`
- `src/deployments/arm`
- `src/platform`

See `planning/planning.md` for the current repository planning file.