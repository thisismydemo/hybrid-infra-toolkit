# Hybrid Infrastructure Toolkit

Hybrid Infrastructure Toolkit is a new platform project for building configurable, repeatable hybrid infrastructure labs and reference environments.

The goal is to provide the broader platform we discussed: a toolkit that supports multiple deployment targets, storage modes, identity models, management approaches, deployment categories, and future scenario overlays without tying the product identity to a single conference demo.

## Current Decisions

- product name: `Hybrid Infrastructure Toolkit`
- GitHub repository: `thisismydemo/hybrid-infra-toolkit`
- docs path: `https://www.thisismydemo.cloud/hybrid-infra-toolkit`
- documentation stack: MkDocs for now
- GitHub Pages publish URL: `https://thisismydemo.github.io/hybrid-infra-toolkit/`

## What Happens Next

- define the platform structure and standards in this repository first
- selectively bring over reference material or reusable code from existing repositories where it helps
- reorganize reusable code into `src/platform`
- use `src/deployments` for separate Bicep, Terraform, PowerShell or Azure CLI, DSC, Ansible, and ARM paths
- publish migration, roadmap, and future schema decisions through this docs site

## Publishing Notes

- GitHub Pages is configured for this repository
- the GitHub Pages URL is the first live publish target
- publishing under `thisismydemo.cloud/hybrid-infra-toolkit` still requires website routing outside this repository

## Planning

- [Migration And Roadmap](planning/migration-roadmap.md)