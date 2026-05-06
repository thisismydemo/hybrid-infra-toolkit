# Engineering Standards

These standards apply to Hybrid Infrastructure Toolkit across source code, documentation, infrastructure definitions, configuration, and automation.

## Principles

- prefer repeatable engineering practices over one-off shortcuts
- align design and implementation with Microsoft Cloud Adoption Framework and Well-Architected Framework guidance where applicable
- keep reusable platform code separate from scenario-specific implementation code
- make standards explicit so every deployment category follows the same operating model

## Scripting Standards

### General

- follow language and ecosystem best practices for the scripting technology in use
- prefer readable, testable, and reviewable scripts over clever shortcuts
- keep side effects explicit
- fail fast on invalid state and invalid inputs
- avoid hidden prompts in automation paths

### PowerShell

- use approved verbs and strong parameter definitions
- use strict mode and stop-on-error behavior in automation scripts
- prefer modules over duplicated helper functions once patterns stabilize
- avoid plaintext secrets and interactive password prompts
- use secure secret retrieval patterns such as Key Vault-backed lookups where appropriate
- validate Azure CLI and external process exit codes explicitly

### Module Use

- prefer official vendor modules and verified modules when possible
- do not introduce niche or unmaintained modules without a documented reason
- document required versions when version drift could affect repeatability
- keep module use minimal and intentional

## Variable Management Standards

Variable handling must be deliberate because this repository will support multiple deployment categories and target types.

### General Rules

- keep variable definitions centralized where practical
- separate environment data from executable logic
- do not hard-code secrets in source files
- do not mix reusable defaults with environment-specific overrides in an undocumented way
- prefer schema-backed configuration over free-form sprawl as the platform matures

### Secrets

- secrets must come from a supported secret source such as Key Vault, secret stores, or pipeline secret injection
- never store plaintext secrets in tracked repository files
- provide examples, not real values, in sample configuration files

### Environment Variables And Config Files

- use clear ownership for each configuration source
- document precedence when multiple layers exist
- keep local-only variable files out of source control when they contain environment-specific values
- use example or template files for checked-in defaults

### Naming And Structure

- variable names should be descriptive and consistent across deployment categories
- shared platform concepts should use the same names in documentation, schema, and automation code
- do not invent new names for the same concept in different toolchains unless the tool forces it

## Documentation Standards

### Structure

- documentation must live in MkDocs-friendly structure under docs
- project-facing material belongs under docs/project
- design material belongs under docs/design
- standards belong under docs/standards
- reference and implementation material should be separated from planning material

### Formatting

- one H1 per document
- use consistent heading levels
- include fenced code blocks with language identifiers
- write for maintainers and operators, not just the original author
- keep pages focused on one purpose

### Content Expectations

- document assumptions and prerequisites explicitly
- document risks, gaps, and incomplete areas honestly
- update changelog and relevant design docs when the architecture changes materially
- do not allow documentation to drift behind major repo structure changes

## Automation Standards

### General

- automation must be repeatable, observable, and idempotent where practical
- use preflight validation before destructive or long-running operations
- prefer deterministic workflows over manually stitched runbooks
- make prerequisites explicit rather than implicit

### CI Or CD Expectations

- validate before deploy
- keep pipeline stages narrowly defined and composable
- surface errors early with actionable messages
- separate reference implementation validation from future cross-toolchain parity goals

### Toolchain Governance

- all deployment categories must align to the same platform model
- Bicep and PowerShell or Azure CLI are the first operational baselines
- Terraform, DSC, Ansible, and ARM templates remain planned categories until implemented and validated
- do not let one toolchain create a competing source of truth for topology and variable semantics

## Naming Standards

### General Naming Rules

- follow Microsoft CAF naming guidance where Azure resource naming is in scope
- consider Microsoft Well-Architected guidance when naming affects operational clarity and governance
- use lowercase kebab-case where target systems allow it
- use clear prefixes and avoid ad hoc abbreviations
- use consistent environment, region, and sequence conventions

### Azure Resource Naming

- use CAF-aligned patterns for Azure resources
- account for resource-specific restrictions such as storage account length and character limits
- document deviations where Microsoft resource rules force exceptions

### Repository And Documentation Naming

- repository slugs, docs paths, and URLs should remain lowercase and hyphenated
- public display names may use title case
- keep GitHub repo naming and docs path naming aligned where practical

## Standards Governance

- update standards when the platform model changes in a durable way
- treat standards as living documentation
- do not create implementation-specific exceptions without documenting them clearly