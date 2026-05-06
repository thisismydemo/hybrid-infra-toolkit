# Migration And Platform Roadmap

This document is the working plan for building Hybrid Infrastructure Toolkit as a new platform project and for selectively bringing in useful reference material, migration inputs, and reusable implementation pieces from existing repositories when appropriate.

## Purpose

This repository should become the long-term home for the platform effort.

The migration needs to preserve what already works while creating room for:

- broader deployment target support
- repeatable environment definitions
- reusable platform modules
- MkDocs-based documentation under `thisismydemo.cloud`

## Positioning

Hybrid Infrastructure Toolkit is not positioned as a rename or successor brand for the MMS 2026 Hyper-V demo.

Instead:

- it is a new project with its own product identity
- existing repos are inputs, references, and possible migration sources
- conference-specific material should not define the long-term platform identity

## Current Working Decisions

- solution name: `Hybrid Infrastructure Toolkit`
- GitHub repository: `https://github.com/thisismydemo/hybrid-infra-toolkit`
- docs URL: `https://www.thisismydemo.cloud/hybrid-infra-toolkit`
- docs stack: MkDocs for now
- existing reference source: `E:\git\mms_2026_hybrid_demo\hyperv-cluster-demo`

## Current Repo State

What exists in the new repo right now:

- MkDocs documentation scaffold
- migration and platform planning docs
- `configs/variables/variables.yml` as an early config artifact

What does not exist yet:

- the full migrated source implementation from `hyperv-cluster-demo`
- the workflow chain migrated from `mms_2026_hybrid_demo`
- the per-tool deployment implementations beyond planning placeholders

Current conclusion:

- the docs are moved into the new repo baseline
- the source files are not fully moved yet
- the repo now needs an explicit `src/` layout so future code has a stable home

## Platform Capability Direction

The platform needs to support the following configuration and roadmap areas.

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

The repository should be prepared to support multiple deployment toolchains without requiring them to be fully implemented now.

Planned categories:

- `bicep`
- `terraform`
- `powershell-azurecli`
- `dsc`
- `ansible`
- `arm`

Design rules for toolchain support:

- all toolchains should map to the same platform concepts and environment manifest
- Bicep and PowerShell or Azure CLI should remain the first operational implementations because they are closest to the current working source
- Terraform, DSC, Ansible, and ARM templates should be planned as parallel deployment paths, not as ad hoc one-off folders
- toolchain parity is a roadmap goal, not a phase 1 requirement
- reference scenarios should be reusable across toolchains wherever possible

## MkDocs Documentation Direction

Documentation will be hosted from this repository using MkDocs for now.

Initial doc responsibilities:

- platform overview
- migration plan
- reference implementation docs
- target profiles and configuration guidance
- roadmap and design decisions

Suggested long-term docs sections:

- overview
- getting started
- planning
- reference implementation
- profiles
- schema
- operations
- roadmap

## Source Inventory To Migrate

The current source implementation includes more than the single `hyperv-cluster-demo` folder. Some critical automation lives in the parent repository workflow layer.

### Current Source Paths

- `E:\git\mms_2026_hybrid_demo\hyperv-cluster-demo\bicep`
- `E:\git\mms_2026_hybrid_demo\hyperv-cluster-demo\config`
- `E:\git\mms_2026_hybrid_demo\hyperv-cluster-demo\docs`
- `E:\git\mms_2026_hybrid_demo\hyperv-cluster-demo\scripts\common`
- `E:\git\mms_2026_hybrid_demo\hyperv-cluster-demo\scripts\deploy`
- `E:\git\mms_2026_hybrid_demo\hyperv-cluster-demo\scripts\configure`
- `E:\git\mms_2026_hybrid_demo\hyperv-cluster-demo\scripts\nested-vms`
- `E:\git\mms_2026_hybrid_demo\hyperv-cluster-demo\scripts\demo`
- `E:\git\mms_2026_hybrid_demo\hyperv-cluster-demo\scripts\manual-recovery`
- `E:\git\mms_2026_hybrid_demo\hyperv-cluster-demo\scripts\validate`
- `E:\git\mms_2026_hybrid_demo\.github\workflows\hvlab-00-preflight.yml`
- `E:\git\mms_2026_hybrid_demo\.github\workflows\hvlab-01-deploy-azure.yml`
- `E:\git\mms_2026_hybrid_demo\.github\workflows\hvlab-02-bootstrap-host.yml`
- `E:\git\mms_2026_hybrid_demo\.github\workflows\hvlab-02b-postbootstrap.yml`
- `E:\git\mms_2026_hybrid_demo\.github\workflows\hvlab-03-deploy-nested-vms.yml`
- `E:\git\mms_2026_hybrid_demo\.github\workflows\hvlab-04-configure-cluster.yml`
- `E:\git\mms_2026_hybrid_demo\.github\workflows\hvlab-05-configure-wac-vmode.yml`
- `E:\git\mms_2026_hybrid_demo\.github\workflows\hvlab-06-configure-scvmm.yml`
- `E:\git\mms_2026_hybrid_demo\.github\workflows\hvlab-07-demo-reset.yml`
- `E:\git\mms_2026_hybrid_demo\.github\workflows\hvlab-08-validate.yml`

## Proposed Target Repository Structure

```text
hybrid-infra-toolkit/
├── README.md
├── mkdocs.yml
├── configs/
│   └── variables/
├── docs/
│   ├── index.md
│   ├── planning/
│   │   └── migration-roadmap.md
│   ├── reference/
│   ├── profiles/
│   ├── schema/
│   └── operations/
├── examples/
│   └── hyperv-cluster-reference/
│       ├── deployments/
│       │   ├── bicep/
│       │   └── powershell-azurecli/
│       ├── config/
│       ├── docs/
│       └── scripts/
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
│   ├── targets/
│   ├── cluster/
│   ├── storage/
│   ├── identity/
│   ├── management/
│   └── scenarios/
├── schemas/
└── .github/
    └── workflows/
```

## Migration Rules

- do not delete or break the original implementation until the new repo can validate and run its reference implementation
- move generated Bicep JSON artifacts only if they are intentionally kept; otherwise rebuild them in CI and treat them as generated output
- keep the current implementation intact as a reference scenario before extracting shared modules
- add the `src/deployments/*` structure now, but do not claim toolchain parity until implementations actually exist
- use the migration to remove conference-specific assumptions from shared code, not to rewrite everything at once
- bring documentation into MkDocs navigation instead of leaving it as an unstructured markdown dump

## Migration Mapping

| Source | Target | Action | Notes |
|---|---|---|---|
| `hyperv-cluster-demo/README.md` | `docs/reference/` and `examples/hyperv-cluster-reference/README.md` | split and adapt | separate public docs from implementation-specific notes |
| `hyperv-cluster-demo/bicep/*.bicep` | `examples/hyperv-cluster-reference/deployments/bicep/` then `src/deployments/bicep/` as reusable pieces emerge | move first, extract later | preserve working reference before modularization |
| `hyperv-cluster-demo/bicep/*.json` | not migrated by default | leave behind or regenerate | treat as generated artifacts unless explicitly versioned |
| `hyperv-cluster-demo/config/variables.yml` | `examples/hyperv-cluster-reference/config/variables.yml` | move first | later split into reusable profiles and schema-backed values |
| `hyperv-cluster-demo/docs/*.md` | `docs/reference/hyperv-cluster/` | rewrite into MkDocs | preserve technical content, rework navigation |
| `hyperv-cluster-demo/scripts/common/HVLab.Automation.psm1` | `src/platform/powershell/modules/` | promote early | this is the strongest reusable foundation in the current implementation |
| `hyperv-cluster-demo/scripts/deploy/*.ps1` | `examples/hyperv-cluster-reference/scripts/deploy/` and later `src/deployments/powershell-azurecli/` where reusable | move first, extract later | keep current host bootstrap working while shared logic is identified |
| `hyperv-cluster-demo/scripts/configure/*.ps1` | `examples/hyperv-cluster-reference/scripts/configure/` and later `src/deployments/powershell-azurecli/` where reusable | move first, extract later | cluster, AD, WAC, and SCVMM setup need staged modularization |
| `hyperv-cluster-demo/scripts/nested-vms/*.ps1` | `examples/hyperv-cluster-reference/scripts/nested-vms/` and later `src/deployments/powershell-azurecli/` where reusable | move first, extract later | later refactor into target-aware role deployment logic |
| `hyperv-cluster-demo/scripts/demo/*.ps1` | `examples/hyperv-cluster-reference/scripts/demo/` | move first | remains reference-scenario specific |
| `hyperv-cluster-demo/scripts/manual-recovery/*.ps1` | `examples/hyperv-cluster-reference/scripts/manual-recovery/` | move first | keep available until new operational model exists |
| `hyperv-cluster-demo/scripts/validate/Invoke-HVLabPreflight.ps1` | `src/platform/validators/` | promote early | reuse as the first repo-wide validation gate |
| `.github/workflows/hvlab-*.yml` | `.github/workflows/` | migrate in phases | update paths, names, secrets, and repo-specific assumptions |

## Phased Migration Plan

### Phase 0. Bootstrap The New Repo

- initialize the new repository
- establish MkDocs as the initial documentation stack
- create the migration and platform planning baseline
- create the planned `src/deployments` category structure without implementing all toolchains yet

### Phase 1. Move The Current Reference Implementation

- copy the existing `hyperv-cluster-demo` implementation into `examples/hyperv-cluster-reference`
- copy the current technical markdown into MkDocs reference sections
- move workflow files into the new repo and update path references
- validate that the reference implementation still passes preflight from the new repo

### Phase 2. Extract Reusable Platform Code

- promote shared PowerShell helpers into `src/platform/powershell/modules`
- promote validation into `src/platform/validators`
- identify reusable Bicep modules and move them into `src/deployments/bicep`
- rename and normalize product-specific identifiers where appropriate

### Phase 3. Introduce Configuration And Profiles

- define the environment manifest
- add profile folders for targets, cluster shape, storage, identity, management, and scenarios
- replace hard-coded implementation assumptions with manifest-backed values
- make the toolchain folders consume the same platform model instead of diverging

### Phase 4. Expand Toolchain Coverage

- keep Bicep and PowerShell or Azure CLI as the first-class implementations
- add Terraform support against the shared model
- add DSC support for host and guest desired state layers
- add Ansible support where remote orchestration fits better than PowerShell-only approaches
- add ARM template support for compatibility and legacy Azure deployment paths

### Phase 5. Support Broader Platform Targets

- harden Azure VM as the first supported target
- add nested Hyper-V target support from the same configuration model
- design physical hardware and sidecar management patterns
- defer VMware until the abstraction model is proven

### Phase 6. Add Advanced Modes

- add `built-in-domain`
- add validated `s2d` support
- add Azure Local as a scenario overlay

## First Backlog For The New Repo

1. Copy the current implementation into `examples/hyperv-cluster-reference`.
2. Copy and re-home the existing Hyper-V lab docs into MkDocs under `docs/reference/hyperv-cluster/`.
3. Migrate `Invoke-HVLabPreflight.ps1` and the related GitHub workflow gates.
4. Decide which Bicep JSON files are source artifacts versus generated output.
5. Establish the `src/deployments` categories for Bicep, Terraform, PowerShell or Azure CLI, DSC, Ansible, and ARM.
6. Create the first manifest draft for target, cluster, storage, identity, and management.
7. Start renaming reusable components away from `hvlab`-specific naming where that improves portability.

## Exit Criteria For The First Migration Milestone

The first milestone is complete when:

- the reference implementation exists in this repo
- MkDocs builds successfully from this repo
- the reference preflight validation succeeds from this repo
- workflow orchestration no longer depends on the original repository layout
- the source demo can be treated as legacy incubation rather than the primary home of the platform