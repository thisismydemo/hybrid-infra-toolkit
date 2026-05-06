# Deployment And Implementation Design

This document captures the intended design direction for how Hybrid Infrastructure Toolkit should organize deployment and implementation concerns.

## Goals

- support multiple deployment categories under one platform model
- keep reusable code separate from scenario-specific code
- make reference implementations portable into broader platform patterns

## Design Model

The repository should distinguish between three layers.

### 1. Project Documentation

- project-facing docs
- standards
- design decisions
- roadmap and changelog

### 2. Reference Implementations

- concrete migrated scenarios such as the current Hyper-V cluster lab
- working examples preserved during migration
- implementation-specific docs and scripts that are not yet generalized

### 3. Shared Platform Code

- shared PowerShell modules
- validators and preflight logic
- orchestration primitives
- shared platform concepts used across deployment categories

## Deployment Category Design

The repository is planned to support these deployment categories:

- Bicep
- Terraform
- PowerShell and Azure CLI
- Desired State Configuration
- Ansible
- ARM templates

Each category should:

- consume the same platform concepts
- respect the same configuration model
- avoid redefining core topology semantics independently

## Implementation Guidance

- move the working reference implementation first
- extract reusable code only after the migrated reference implementation still validates
- treat Bicep and PowerShell or Azure CLI as the first working baselines
- delay broad parity goals until the shared model is stable

## Microsoft Design Alignment

Design choices should align with Microsoft guidance where applicable, especially:

- Cloud Adoption Framework for landing zone, naming, governance, and resource organization considerations
- Well-Architected Framework for operational excellence, reliability, security, cost, and performance considerations

## Early Guardrails

- do not over-abstract before the first migrated reference implementation is stable
- do not claim broad toolchain support before validation exists
- do not let planning placeholders get mistaken for complete implementations