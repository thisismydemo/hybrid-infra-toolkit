# Project Roadmap

This page is the project-facing roadmap summary for Hybrid Infrastructure Toolkit.

For the detailed migration plan, see the planning documentation.

## Phase 0

- initialize the new repository
- establish MkDocs documentation
- define the source layout for shared platform code and deployment categories
- capture platform direction and migration planning

## Phase 1

- move the current Hyper-V reference implementation into this repository
- migrate supporting workflows
- make the reference scenario validate from the new repository

## Phase 2

- extract reusable PowerShell modules and validation logic
- normalize shared platform code under src/platform
- begin separating reusable code from scenario-specific code

## Phase 3

- introduce the environment manifest and profile model
- parameterize targets, cluster shape, storage, identity, and management
- make all deployment categories align to the same shared model

## Phase 4

- support multiple deployment categories in a planned way:
  - Bicep
  - Terraform
  - PowerShell and Azure CLI
  - Desired State Configuration
  - Ansible
  - ARM templates

## Phase 5

- harden support for broader target types
- expand physical hardware and management plane patterns
- evaluate VMware support after the target abstraction is stable

## Phase 6

- add built-in domain support
- add validated S2D support
- add Azure Local as a scenario overlay