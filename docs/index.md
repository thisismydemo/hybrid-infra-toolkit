# Hybrid Infrastructure Toolkit

Hybrid Infrastructure Toolkit is the planned successor to the current MMS 2026 Hyper-V cluster demo implementation.

The near-term goal is to migrate the working reference implementation into this repository without losing what already works. The longer-term goal is to turn that implementation into a configurable toolkit that supports multiple deployment targets, storage modes, identity models, and scenario overlays.

## Current Decisions

- product name: `Hybrid Infrastructure Toolkit`
- GitHub repository: `thisismydemo/hybrid-infra-toolkit`
- docs path: `https://www.thisismydemo.cloud/hybrid-infra-toolkit`
- documentation stack: MkDocs for now
- GitHub Pages publish URL: `https://thisismydemo.github.io/hybrid-infra-toolkit/`

## What Happens Next

- move the current Hyper-V lab implementation into this repository as the first reference scenario
- reorganize reusable code into `src/platform`
- use `src/deployments` for separate Bicep, Terraform, PowerShell or Azure CLI, DSC, Ansible, and ARM paths
- publish migration, roadmap, and future schema decisions through this docs site

## Publishing Notes

- GitHub Pages is configured for this repository
- the GitHub Pages URL is the first live publish target
- publishing under `thisismydemo.cloud/hybrid-infra-toolkit` still requires website routing outside this repository

## Planning

- [Migration And Roadmap](planning/migration-roadmap.md)