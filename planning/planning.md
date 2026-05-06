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
- existing reference source: `E:\git\mms_2026_hybrid_demo\hyperv-cluster-demo`

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

- the full migrated reference implementation
- the workflow chain migrated from `mms_2026_hybrid_demo`
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

## Source Inputs And Migration Candidates

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

## Migration Mapping

| Source | Target | Action | Notes |
|---|---|---|---|
| `hyperv-cluster-demo/README.md` | `docs/reference/` and `examples/hyperv-cluster-reference/README.md` | split and adapt | separate public docs from implementation-specific notes |
| `hyperv-cluster-demo/bicep/*.bicep` | `examples/hyperv-cluster-reference/deployments/bicep/` then `src/deployments/bicep/` as reusable pieces emerge | move first, extract later | preserve working reference before modularization |
| `hyperv-cluster-demo/bicep/*.json` | not migrated by default | leave behind or regenerate | treat as generated artifacts unless explicitly versioned |
| `hyperv-cluster-demo/config/variables.yml` | `examples/hyperv-cluster-reference/config/variables.yml` | move first | later split into reusable profiles and schema-backed values |
| `hyperv-cluster-demo/docs/*.md` | `docs/reference/hyperv-cluster/` | rewrite into MkDocs | preserve technical content, rework navigation |
| `hyperv-cluster-demo/scripts/common/HVLab.Automation.psm1` | `src/platform/powershell/modules/` | promote early | reusable foundation in the current implementation |
| `hyperv-cluster-demo/scripts/deploy/*.ps1` | `examples/hyperv-cluster-reference/scripts/deploy/` and later `src/deployments/powershell-azurecli/` where reusable | move first, extract later | keep current host bootstrap working while shared logic is identified |
| `hyperv-cluster-demo/scripts/configure/*.ps1` | `examples/hyperv-cluster-reference/scripts/configure/` and later `src/deployments/powershell-azurecli/` where reusable | move first, extract later | cluster, AD, WAC, and SCVMM setup need staged modularization |
| `hyperv-cluster-demo/scripts/nested-vms/*.ps1` | `examples/hyperv-cluster-reference/scripts/nested-vms/` and later `src/deployments/powershell-azurecli/` where reusable | move first, extract later | later refactor into target-aware role deployment logic |
| `hyperv-cluster-demo/scripts/demo/*.ps1` | `examples/hyperv-cluster-reference/scripts/demo/` | move first | remains reference-scenario specific |
| `hyperv-cluster-demo/scripts/manual-recovery/*.ps1` | `examples/hyperv-cluster-reference/scripts/manual-recovery/` | move first | keep available until new operational model exists |
| `hyperv-cluster-demo/scripts/validate/Invoke-HVLabPreflight.ps1` | `src/platform/validators/` | promote early | reuse as the first repo-wide validation gate |
| `.github/workflows/hvlab-*.yml` | `.github/workflows/` | migrate in phases | update paths, names, secrets, and repo-specific assumptions |

## Phased Plan

### Phase 0. Bootstrap The Repo

- initialize repository basics
- establish MkDocs for public docs
- create the planning baseline
- create the planned `src/deployments` categories without claiming toolchain parity

### Phase 1. Move A Reference Implementation

- copy the current `hyperv-cluster-demo` implementation into `examples/hyperv-cluster-reference`
- move selected technical documentation into public reference docs
- migrate workflow files into the new repo and update path references
- validate that the migrated reference implementation still passes preflight from the new repo

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

1. Copy the current implementation into `examples/hyperv-cluster-reference`.
2. Copy and re-home the existing Hybrid demo material needed for near-term sessions into public reference or demos docs where appropriate.
3. Migrate `Invoke-HVLabPreflight.ps1` and the related GitHub workflow gates.
4. Decide which Bicep JSON files are source artifacts versus generated output.
5. Establish the `src/deployments` categories for Bicep, Terraform, PowerShell or Azure CLI, DSC, Ansible, and ARM.
6. Create the first manifest draft for target, cluster, storage, identity, and management.
7. Start renaming reusable components away from `hvlab`-specific naming where that improves portability.
8. Build out `docs/demos/` for session-ready scenarios based on the toolkit.
