# CI And CD Automation Design

This document captures the intended automation approach for Hybrid Infrastructure Toolkit.

## Goals

- validate early and consistently
- separate preflight checks from deployment execution
- support multiple deployment categories without creating pipeline chaos
- keep automation aligned to the same platform model and standards

## Pipeline Principles

- validation before deployment
- narrowly scoped stages with clear ownership
- explicit prerequisites and environment requirements
- reusable pipeline components where practical
- auditable behavior with useful logs and summaries

## Early Pipeline Shape

The initial pipeline design should emphasize:

- documentation validation where practical
- script and infrastructure validation
- reference implementation preflight validation
- deployment category specific execution only for supported implementations

## Expected Automation Layers

### Repository Validation

- docs build validation
- script parsing and linting
- infrastructure compilation or validation where supported
- configuration sanity checks

### Reference Implementation Validation

- preflight validation for the migrated Hyper-V reference implementation
- workflow sequencing checks where practical
- deployment readiness verification before execution

### Future Category Validation

- Bicep validation
- Terraform validation and formatting checks
- DSC compilation or configuration validation
- Ansible linting and syntax validation
- ARM template validation

## Secret And Variable Handling

- use secure secret sources rather than checked-in secret values
- separate environment-specific values from portable configuration defaults
- document variable precedence and injection patterns
- keep local-only secret-bearing files out of source control

## CI Or CD Design Guardrails

- do not add a deployment stage for a category that has only placeholders
- do not let pipeline structure imply support that the codebase does not yet provide
- keep category-specific pipelines aligned to the same standards and naming patterns
- prefer composable workflows over monolithic all-in-one automation

## Microsoft Guidance Alignment

Automation should align with Microsoft guidance where it materially improves design quality, especially:

- Cloud Adoption Framework guidance related to governance, standardization, and repeatable platform operations
- Well-Architected Framework guidance related to operational excellence, reliability, and security