# Project Roadmap

This page is the project-facing roadmap for Hybrid Infrastructure Toolkit.

The internal planning document focuses narrowly on reaching feature parity with the existing Hyper-V cluster lab implementation. Everything beyond parity lives here.

## Status

- **Phase 0 — Repo bootstrap:** complete
- **Phase 0.5 — GitHub Actions runner bootstrap:** in progress
- **Phase 1 — Land the Hyper-V cluster lab into this repository:** in progress
- **Beyond parity:** see below

## Beyond Parity

### Extract Reusable Platform Code

- promote shared PowerShell helpers into `src/platform/powershell/modules` with toolkit-neutral names
- promote validation logic into `src/platform/validators`
- identify reusable Bicep modules and lift them out of the cluster-lab implementation
- begin separating reusable code from scenario-specific code

### Configuration And Profiles

- define a formal environment manifest schema
- add profile folders for targets, cluster shape, storage, identity, management, and scenarios
- replace hard-coded implementation assumptions with manifest-backed values
- keep all deployment categories aligned to the same shared model

### Multi-Toolchain Support

The repository is structured to support multiple deployment toolchains. Implementations beyond the initial Bicep + PowerShell baseline are roadmap:

- Terraform against the shared model
- Desired State Configuration for host and guest desired state layers
- Ansible where remote orchestration is the better fit
- ARM templates for compatibility and legacy paths

Toolchain parity is a goal, not a requirement.

### Multi-CI Provider Support

The runner-bootstrap pattern is structured to be CI-provider-pluggable. Implementations beyond GitHub Actions are roadmap:

- GitLab CI — register the bootstrap host as a GitLab Runner using a registration token from Key Vault
- Azure DevOps Pipelines — register the bootstrap host as a self-hosted agent in an agent pool

The Bicep, host VM, and managed identity are the same across providers. Only the install + register step changes. A `ci_provider` value in `configs/variables/variables.yml` selects the install path.

### Broader Deployment Targets

- harden Azure VM as the first supported target (current parity work)
- nested Hyper-V host as a target
- physical hardware patterns and sidecar management
- VMware support, deferred until the target abstraction is stable

### Cluster Shape

- configurable node count (`2-node`, `4-node` first)
- configurable node sizing or sizing profiles
- cluster shape presets for demo, lab, and validation scenarios

### Storage Modes

- `iscsi` as the first portable default
- `s2d` as a later validated mode
- `none` for lightweight or management-only environments

### Identity Modes

- `existing-domain` for hybrid-integrated scenarios (current parity work)
- `built-in-domain` as the default portable mode
- `custom-domain` after end-to-end bootstrap is parameterized
- workgroup mode if needed later

### Management Plane Options

- external management services
- cohosted management VMs
- sidecar Hyper-V management host for physical hardware scenarios

Management roles in scope across modes: domain controllers, DNS, Windows Admin Center, SCVMM, optional jump box / orchestration VM.

### Azure Local Overlay

Longer term the toolkit may support a lab-oriented Azure Local mode. Guardrail: Azure Local is a scenario overlay, not the only product identity.

### Documentation And Versioning

- public docs for each scenario under `docs/demos/<scenario>/`
- versioned documentation via `mike` once a stable release line emerges
- changelog discipline tied to tagged releases
