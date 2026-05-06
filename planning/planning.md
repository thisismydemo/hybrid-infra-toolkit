# Planning

This document is the internal planning file for Hybrid Infrastructure Toolkit.

This file is for repository planning, migration planning, working assumptions, and internal implementation direction. It is not intended to be part of the public documentation site.

## Purpose

Hybrid Infrastructure Toolkit is a new platform project for building configurable, repeatable hybrid infrastructure labs and reference environments.

This planning document exists to track how the repository should evolve and what inputs from other repositories may be reused or migrated.

## Current Working Decisions

- solution name: `Hybrid Infrastructure Toolkit`
- GitHub repository: `https://github.com/thisismydemo/hybrid-infra-toolkit`
- public docs URL target: `https://www.thisismydemo.cloud/hybrid-infra-toolkit`
- GitHub Pages publish URL: `https://thisismydemo.github.io/hybrid-infra-toolkit/`
- docs stack: MkDocs for now
- this repository is standalone — no upstream source is required

## Positioning

Hybrid Infrastructure Toolkit is not positioned as a rename or successor brand for the MMS 2026 Hyper-V demo.

Instead:

- it is a new project with its own identity
- existing repositories are inputs, references, and possible migration sources
- conference-specific content should not define the long-term platform identity

## Current Repo State

What exists right now:

- MkDocs documentation scaffold
- project, standards, and design documentation
- public demos documentation area under `docs/demos`
- `configs/variables/variables.yml` as an early config artifact
- initial `src/` layout for deployment categories and shared platform code
- GitHub Pages workflow for public docs publishing

What does not exist yet:

- a self-hosted runner bootstrap (Phase 0.5)
- a first end-to-end deployable scenario (Phase 1)
- actual toolchain implementations beyond the current placeholders and planning baseline

## Platform Direction

### Cluster Shape

- configurable node count
- configurable node size or node size profiles
- cluster shape presets for demo, lab, and validation scenarios

Initial direction:

- support `2-node` and `4-node` first
- use profile-based sizing before exposing raw tuning everywhere

### Storage Modes

- `iscsi` for the first portable default
- `s2d` as a later validated mode
- `none` for lightweight or management-only environments

### Deployment Targets

- Azure VM host
- nested Hyper-V host
- nested VMware host
- physical hardware

Recommended support order:

1. Azure VM host
2. nested Hyper-V host
3. physical hardware
4. nested VMware host

### Management Plane Options

- external management services
- cohosted management VMs
- sidecar Hyper-V management host for physical hardware scenarios

Management roles in scope:

- domain controllers
- DNS and supporting identity services
- Windows Admin Center
- SCVMM
- optional jump box or orchestration VM

### Identity Modes

- existing domain
- custom domain
- built-in lab domain
- future workgroup mode if needed

Recommended direction:

- keep `existing-domain` for hybrid-integrated scenarios
- add `built-in-domain` as the default portable mode
- add `custom-domain` after end-to-end bootstrap is parameterized

### Azure Local Overlay

Longer term, the platform may also support a lab-oriented Azure Local mode.

Guardrail:

- Azure Local should be a scenario overlay, not the only product identity

### Deployment Toolchain Categories

The repository should be prepared to support multiple deployment toolchains.

Planned categories:

- `bicep`
- `terraform`
- `powershell-azurecli`
- `dsc`
- `ansible`
- `arm`

Design rules:

- all toolchains should map to the same platform concepts and environment model
- Bicep and PowerShell or Azure CLI remain the first operational baselines
- Terraform, DSC, Ansible, and ARM templates are planned categories until implemented and validated
- toolchain parity is a roadmap goal, not an initial requirement

## Source Inputs

This repository is built standalone. External code is not assumed or required.

If a reference implementation is brought in later (see Phase 1), it will be done as an explicit decision recorded here, not implied. Until that happens, all code in `src/` is to be authored fresh against the configuration model in `configs/variables/variables.yml`.

## Planned Repository Structure

```text
hybrid-infra-toolkit/
├── README.md
├── mkdocs.yml
├── planning/
│   └── planning.md
├── configs/
│   └── variables/
├── docs/
│   ├── index.md
│   ├── demos/
│   ├── project/
│   ├── standards/
│   └── design/
├── examples/
│   └── hyperv-cluster-reference/
├── src/
│   ├── deployments/
│   │   ├── bicep/
│   │   ├── terraform/
│   │   ├── powershell-azurecli/
│   │   ├── dsc/
│   │   ├── ansible/
│   │   └── arm/
│   └── platform/
│       ├── powershell/
│       │   └── modules/
│       ├── validators/
│       └── orchestration/
├── profiles/
├── schemas/
└── .github/
	└── workflows/
```

## Phased Plan

### Phase 0. Bootstrap The Repo

- initialize repository basics
- establish MkDocs for public docs
- create the planning baseline
- create the planned `src/deployments` categories without claiming toolchain parity

### Phase 0.5. Bootstrap The Automation Runner

Deployments in this repository run on a self-hosted CI runner that lives inside the target environment. That runner cannot be assumed to exist. Phase 0.5 is the chicken-and-egg solver.

#### CI Provider Abstraction

The runner-bootstrap pattern is intentionally written so the same Bicep, the same install logic, and the same target host VM can register against any of the supported CI providers.

Out of the box:

- **GitHub Actions** is the default and the only implementation built in Phase 0.5.

Planned (later phases, same pattern):

- **GitLab CI** — register the host as a GitLab Runner with a runner registration token. Bicep, host, and identity are unchanged. Only the install + register step differs.
- **Azure DevOps Pipelines** — register the host as an Azure Pipelines self-hosted agent in an agent pool with a PAT or workload identity. Same Bicep, same host, different install step.

Design rules:

- runner registration credentials are always pulled from Key Vault, never inlined
- the install step is a pluggable script keyed off a `ci_provider` value in `configs/variables/variables.yml` (`github` | `gitlab` | `azure_devops`)
- the host VM is generic Windows Server; it is not specialized for any one provider
- the platform layer (`src/platform/`) does not import provider-specific assumptions; only the install step under `src/deployments/powershell-azurecli/bootstrap/` is provider-aware

#### GitHub Actions Bootstrap (the only one built in Phase 0.5)

Goals:

- a GitHub-hosted runner can deploy the minimum Azure footprint required to host a self-hosted runner
- a small "bootstrap host" VM is created via Bicep and registered as a self-hosted runner for this repository
- after Phase 0.5, all subsequent workflows can target `runs-on: [self-hosted, <label>]`

Scope:

- `src/deployments/bicep/bootstrap/` — minimal Bicep for: resource group, network, NSG, Key Vault access permissions, bootstrap host VM, managed identity
- `src/deployments/powershell-azurecli/bootstrap/install-runner-github.ps1` — installs the GitHub Actions runner, registers against this repository with a token pulled from Key Vault, configures the runner as a Windows service
- `.github/workflows/bootstrap-runner.yml` — GitHub-hosted job that runs the Bicep deployment and the runner-install step
- secrets required (pre-staged in Key Vault):
  - `bootstrap-host-admin-password`
  - `github-runner-registration-token`
- managed identity on the bootstrap host gets `Key Vault Secrets User` on the target Key Vault

Exit criteria:

- workflow `bootstrap-runner.yml` runs to green from a clean subscription
- runner appears as `Idle` under repo settings → Actions → Runners
- a trivial test workflow with `runs-on: [self-hosted, <label>]` runs to green

#### GitLab and Azure DevOps Bootstraps (planned)

When these land:

- `src/deployments/powershell-azurecli/bootstrap/install-runner-gitlab.ps1` and a parallel pipeline definition under `.gitlab-ci.yml`
- `src/deployments/powershell-azurecli/bootstrap/install-runner-azuredevops.ps1` and a parallel pipeline definition under `azure-pipelines.yml`
- secret name conventions documented per provider, all stored in Key Vault
- documentation page under `docs/standards/` explaining how to switch `ci_provider` and what credentials each requires

### Phase 1. First Working Implementation

Phase 1 produces the first end-to-end working scenario in this repository.

#### Decision

**Option C (selected).** The existing nested Hyper-V cluster lab implementation is brought into this repository as part of the platform code, not as a frozen example. It lands in `src/`, paths are rewritten to this repository's layout, and it evolves in place from there.

Rejected:

- Option A (fresh build) — too slow given a working implementation already exists
- Option B (copy as frozen reference) — wrong long-term home; this repo should own the code

#### Phase 1 Steps (Option C)

1. Land the working implementation into `src/`:
   - Bicep → `src/deployments/bicep/`
   - PowerShell deploy/configure/nested-vms/demo/manual-recovery scripts → `src/deployments/powershell-azurecli/`
   - shared automation module → `src/platform/powershell/modules/`
   - preflight validator → `src/platform/validators/`
   - workflows → `.github/workflows/`
   - source `variables.yml` → `configs/variables/variables.yml` (replaces the placeholder)
2. Rewire internal paths inside the copied files to the new repo layout. Workflow `runs-on`, secret names, and runner labels stay the same on first pass.
3. Re-target workflow GitHub references from the source repository to this repository.
4. First green run from this repository: preflight + Azure deploy workflow.
5. Defer all renaming, abstraction, and CAF normalization to Phase 2. Goal is a green deploy from this repo, nothing more.

Common goals regardless of source option:

- one named scenario produces a deployable environment from this repository alone
- the scenario consumes `configs/variables/variables.yml`
- the scenario uses the Phase 0.5 self-hosted runner for any host-internal work
- public documentation for the scenario lives under `docs/demos/<scenario>/`

### Phase 2. Extract Reusable Platform Code

- promote shared PowerShell helpers into `src/platform/powershell/modules`
- promote validation into `src/platform/validators`
- identify reusable Bicep modules and move them into `src/deployments/bicep`
- rename and normalize product-specific identifiers where appropriate

### Phase 3. Introduce Configuration And Profiles

- define the environment manifest
- add profile folders for targets, cluster shape, storage, identity, management, and scenarios
- replace hard-coded implementation assumptions with manifest-backed values
- keep the deployment categories aligned to the same platform model

### Phase 4. Expand Toolchain Coverage

- keep Bicep and PowerShell or Azure CLI as the first working implementations
- add Terraform support against the shared model
- add DSC support for host and guest desired state layers
- add Ansible support where appropriate
- add ARM template support for compatibility and legacy Azure deployment paths

### Phase 5. Support Broader Targets

- harden Azure VM as the first supported target
- add nested Hyper-V target support from the same configuration model
- design physical hardware and sidecar management patterns
- defer VMware until the abstraction model is proven

### Phase 6. Add Advanced Modes

- add `built-in-domain`
- add validated `s2d` support
- add Azure Local as a scenario overlay

## Working Backlog

1. Decide the Phase 1 source option (A fresh build, B copy as reference only, C copy as working implementation) and record the decision in the Phase 1 section.
2. Author the Phase 0.5 bootstrap-runner Bicep and workflow.
3. Pre-stage required Key Vault secrets for the bootstrap runner.
4. Define the first scenario name and put a placeholder under `docs/demos/<scenario>/`.
5. Draft the first concrete `configs/variables/variables.yml` for the chosen scenario.
6. Build the first deployment entrypoint under `src/deployments/bicep/`.
7. Build the first preflight validator under `src/platform/validators/`.
8. Add toolchain parity work to the backlog only after the first scenario is green.
