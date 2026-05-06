# Hybrid Infrastructure Toolkit

Hybrid Infrastructure Toolkit is a platform project for building configurable, repeatable hybrid infrastructure labs, reference environments, and future demo scenarios.

The project is intended to provide a consistent foundation for designing, documenting, and automating hybrid infrastructure environments without tying the product identity to a single demo, event, or one-off implementation.

## What This Project Is

Hybrid Infrastructure Toolkit is being built as a reusable platform for:

- hybrid infrastructure lab patterns
- reference environment designs
- repeatable deployment workflows
- future session and demo content built on a shared foundation

## What The Project Covers

- configurable hybrid lab and reference environment patterns
- multiple deployment targets, including Azure, nested virtualization, and physical hardware scenarios
- multiple deployment categories, including Bicep, Terraform, PowerShell and Azure CLI, DSC, Ansible, and ARM templates
- shared standards for engineering, automation, naming, documentation, and variable management

## Design Direction

- use a shared platform model across deployment categories
- keep reusable platform code separate from scenario-specific content
- support future demos through a dedicated `docs/demos/` area
- align design and implementation choices with Microsoft CAF and Well-Architected guidance where applicable

## Documentation Areas

- Demos pages for future demo documentation and selective reuse guidance
- Project pages for project identity, roadmap, changelog, open source direction, and contribution guidance
- Standards pages for engineering and operational standards
- Design pages for deployment, implementation, and CI or CD automation direction

## Current Decisions

- product name: `Hybrid Infrastructure Toolkit`
- GitHub repository: `thisismydemo/hybrid-infra-toolkit`
- docs path: `https://www.thisismydemo.cloud/hybrid-infra-toolkit`
- documentation stack: MkDocs for now
- GitHub Pages publish URL: `https://thisismydemo.github.io/hybrid-infra-toolkit/`

## Current Focus

- define platform standards and public documentation first
- organize reusable source areas under `src/`
- prepare the repository for future reference implementations and reusable platform code
- align design decisions with Microsoft CAF and Well-Architected guidance where applicable
- establish a `docs/demos/` area for future session and demo content

## Publishing Notes

- GitHub Pages is configured for this repository
- the GitHub Pages URL is the first live publish target
- publishing under `thisismydemo.cloud/hybrid-infra-toolkit` still requires website routing outside this repository

## Internal Planning

Internal repository planning is intentionally kept outside the published docs tree in `planning/planning.md`.