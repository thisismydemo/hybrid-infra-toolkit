# Planning

This document is the internal planning file for Hybrid Infrastructure Toolkit.

Scope of this document is intentionally narrow: **bring this repository to feature parity with the working Hyper-V cluster lab implementation that currently lives in `mms_2026_hybrid_demo/hyperv-cluster-demo`, deployable from this repository alone.**

Anything beyond parity (multi-toolchain, multi-CI provider, broader targets, advanced modes, abstraction work) lives in [docs/project/roadmap.md](../docs/project/roadmap.md) and is out of scope here.

This file is not part of the public documentation site.

## Current Working Decisions

- solution name: `Hybrid Infrastructure Toolkit`
- GitHub repository: `https://github.com/thisismydemo/hybrid-infra-toolkit`
- public docs URL target: `https://www.thisismydemo.cloud/hybrid-infra-toolkit`
- GitHub Pages publish URL: `https://thisismydemo.github.io/hybrid-infra-toolkit/`
- docs stack: MkDocs
- CI provider out of the box: GitHub Actions (other providers are roadmap)
- this repository is standalone — no upstream source is required at runtime
- Phase 1 source option: **Option C** — copy the working Hyper-V cluster lab implementation into `src/` as part of this repository's code, evolve in place
- Phase 1 scenario name: `hyperv-cluster-lab`
- runner label (kept compatible with the source workflows on first pass): `hvlab-host`

## Positioning

Hybrid Infrastructure Toolkit is a new project with its own identity. The MMS 2026 Hyper-V demo is an input source for Phase 1, not the long-term identity of this repository.

## Current Repo State

What exists right now:

- MkDocs documentation scaffold and GitHub Pages publishing workflow
- project, standards, and design documentation
- public demos area at `docs/demos/`
- `configs/variables/{variables.template.yml, variables.yml, README.md, examples/}`
- `src/deployments/{bicep,terraform,powershell-azurecli,dsc,ansible,arm}/` placeholders
- `src/platform/{powershell/modules,validators,orchestration}/` placeholders
- `.vscode/`, `.claude/`, `.github/copilot-instructions.md`, PR + issue templates, workspace file

What does not exist yet:

- self-hosted runner bootstrap (Phase 0.5)
- the Hyper-V cluster lab code in `src/` (Phase 1)
- a green deploy of the lab from this repository

## Source Inventory (Phase 1 Input)

Source repository: `E:\git\mms_2026_hybrid_demo` (`thisismydemo/mms_2026_hybrid_demo`).

Source folders:

- `hyperv-cluster-demo/bicep/` — `main.bicep`, `identity.bicep`, `identity-rg.bicep`, `parameters/`, generated `*.json`
- `hyperv-cluster-demo/config/variables.yml` — current working variables file for the lab
- `hyperv-cluster-demo/scripts/common/` — shared module (`HVLab.Automation.psm1`)
- `hyperv-cluster-demo/scripts/deploy/` — host deploy + bootstrap scripts
- `hyperv-cluster-demo/scripts/configure/` — cluster, AD, WAC, SCVMM configuration
- `hyperv-cluster-demo/scripts/nested-vms/` — nested VM provisioning
- `hyperv-cluster-demo/scripts/demo/` — demo-day reset and helpers
- `hyperv-cluster-demo/scripts/manual-recovery/` — break-glass scripts
- `hyperv-cluster-demo/scripts/validate/` — `Invoke-HVLabPreflight.ps1` and validators
- `hyperv-cluster-demo/docs/` — implementation documentation
- `.github/workflows/hvlab-*.yml` — 10 workflow files (00 preflight through 08 validate)

## Target Repo Structure (Phase 1 End-State)

```text
hybrid-infra-toolkit/
├── README.md
├── mkdocs.yml
├── planning/
│   └── planning.md
├── configs/
│   └── variables/
│       ├── variables.template.yml
│       ├── variables.yml          # populated from the source variables.yml
│       └── examples/
├── docs/
│   ├── index.md
│   ├── demos/
│   │   └── hyperv-cluster-lab/    # public docs for this scenario
│   ├── project/
│   ├── standards/
│   └── design/
├── src/
│   ├── deployments/
│   │   ├── bicep/
│   │   │   ├── bootstrap/         # Phase 0.5 runner bootstrap
│   │   │   ├── main.bicep         # Phase 1 cluster lab
│   │   │   ├── identity.bicep
│   │   │   ├── identity-rg.bicep
│   │   │   ├── parameters/
│   │   │   └── modules/
│   │   └── powershell-azurecli/
│   │       ├── bootstrap/         # Phase 0.5 runner install
│   │       ├── deploy/
│   │       ├── configure/
│   │       ├── nested-vms/
│   │       ├── demo/
│   │       └── manual-recovery/
│   └── platform/
│       ├── powershell/modules/    # HVLab.Automation.psm1 (renamed later)
│       ├── validators/            # Invoke-HVLabPreflight.ps1
│       └── orchestration/
└── .github/
    └── workflows/
        ├── deploy-docs.yml
        ├── bootstrap-runner.yml   # Phase 0.5
        └── hvlab-*.yml            # Phase 1 (10 files)
```

## Phased Plan

### Phase 0. Repo Bootstrap — DONE

- repo initialized, MkDocs in place, GitHub Pages workflow live
- `src/` and `configs/` placeholders in place
- repo configuration files in place (`.vscode/`, `.claude/`, `.github/`, workspace file)

### Phase 0.5. GitHub Actions Runner Bootstrap

A self-hosted runner cannot be assumed to exist. Phase 0.5 stands one up from a clean subscription using a GitHub-hosted runner.

**Order:** Phase 0.5 runs before Phase 1. Phase 1 workflows assume `runs-on: [self-hosted, hvlab-host]`.

**Scope:**

- `src/deployments/bicep/bootstrap/` — minimal Bicep: resource group, vnet/subnet, NSG, bootstrap host VM, user-assigned managed identity, Key Vault role assignment
- `src/deployments/powershell-azurecli/bootstrap/install-runner-github.ps1` — installs the GitHub Actions runner on the bootstrap host, registers against this repository using a token from Key Vault, configures it as a Windows service with label `hvlab-host`
- `.github/workflows/bootstrap-runner.yml` — GitHub-hosted job that runs the Bicep deploy and triggers the install script via `az vm run-command` or Custom Script Extension

**Required Key Vault secrets (pre-staged):**

- `bootstrap-host-admin-password`
- `github-runner-registration-token`

**Exit criteria:**

- `bootstrap-runner.yml` runs to green from a clean subscription
- runner appears as `Idle` in repo settings → Actions → Runners with label `hvlab-host`
- a trivial test workflow with `runs-on: [self-hosted, hvlab-host]` runs to green

### Phase 1. Land The Hyper-V Cluster Lab (Option C)

**Decision:** Option C — copy the working implementation from `mms_2026_hybrid_demo/hyperv-cluster-demo` into `src/` as this repository's code. Rejected: Option A (fresh build, too slow) and Option B (frozen reference, wrong long-term home).

**Goal:** the same nested Hyper-V cluster lab that currently deploys from `mms_2026_hybrid_demo` deploys from this repository instead, with no functional regressions.

**Out of scope for Phase 1:** renaming, abstraction, CAF normalization, removing `hvlab` identifiers, multi-CI provider support, multi-toolchain support. All of that is roadmap.

#### Step 1 — Copy

Copy from `E:\git\mms_2026_hybrid_demo` into `E:\git\thisismydemo\hybrid-infra-toolkit`:

| Source | Destination |
|---|---|
| `hyperv-cluster-demo/bicep/main.bicep` | `src/deployments/bicep/main.bicep` |
| `hyperv-cluster-demo/bicep/identity.bicep` | `src/deployments/bicep/identity.bicep` |
| `hyperv-cluster-demo/bicep/identity-rg.bicep` | `src/deployments/bicep/identity-rg.bicep` |
| `hyperv-cluster-demo/bicep/parameters/**` | `src/deployments/bicep/parameters/` |
| `hyperv-cluster-demo/bicep/*.json` | not copied (generated artifacts; rebuilt on demand) |
| `hyperv-cluster-demo/scripts/common/HVLab.Automation.psm1` | `src/platform/powershell/modules/HVLab.Automation.psm1` |
| `hyperv-cluster-demo/scripts/validate/Invoke-HVLabPreflight.ps1` | `src/platform/validators/Invoke-HVLabPreflight.ps1` |
| `hyperv-cluster-demo/scripts/deploy/**` | `src/deployments/powershell-azurecli/deploy/` |
| `hyperv-cluster-demo/scripts/configure/**` | `src/deployments/powershell-azurecli/configure/` |
| `hyperv-cluster-demo/scripts/nested-vms/**` | `src/deployments/powershell-azurecli/nested-vms/` |
| `hyperv-cluster-demo/scripts/demo/**` | `src/deployments/powershell-azurecli/demo/` |
| `hyperv-cluster-demo/scripts/manual-recovery/**` | `src/deployments/powershell-azurecli/manual-recovery/` |
| `hyperv-cluster-demo/config/variables.yml` | `configs/variables/variables.yml` (replaces the placeholder) |
| `hyperv-cluster-demo/docs/**` | `docs/demos/hyperv-cluster-lab/` (rewritten to fit MkDocs nav) |
| `.github/workflows/hvlab-00-preflight.yml` | `.github/workflows/hvlab-00-preflight.yml` |
| `.github/workflows/hvlab-01-deploy-azure.yml` | `.github/workflows/hvlab-01-deploy-azure.yml` |
| `.github/workflows/hvlab-02-bootstrap-host.yml` | `.github/workflows/hvlab-02-bootstrap-host.yml` |
| `.github/workflows/hvlab-02b-postbootstrap.yml` | `.github/workflows/hvlab-02b-postbootstrap.yml` |
| `.github/workflows/hvlab-03-deploy-nested-vms.yml` | `.github/workflows/hvlab-03-deploy-nested-vms.yml` |
| `.github/workflows/hvlab-04-configure-cluster.yml` | `.github/workflows/hvlab-04-configure-cluster.yml` |
| `.github/workflows/hvlab-05-configure-wac-vmode.yml` | `.github/workflows/hvlab-05-configure-wac-vmode.yml` |
| `.github/workflows/hvlab-06-configure-scvmm.yml` | `.github/workflows/hvlab-06-configure-scvmm.yml` |
| `.github/workflows/hvlab-07-demo-reset.yml` | `.github/workflows/hvlab-07-demo-reset.yml` |
| `.github/workflows/hvlab-08-validate.yml` | `.github/workflows/hvlab-08-validate.yml` |

#### Step 2 — Path Rewrite Rules

Rewrite path references inside the copied files using these rules. Do not change anything else:

- `hyperv-cluster-demo/bicep/...` → `src/deployments/bicep/...`
- `hyperv-cluster-demo/scripts/common/...` → `src/platform/powershell/modules/...`
- `hyperv-cluster-demo/scripts/validate/...` → `src/platform/validators/...`
- `hyperv-cluster-demo/scripts/deploy/...` → `src/deployments/powershell-azurecli/deploy/...`
- `hyperv-cluster-demo/scripts/configure/...` → `src/deployments/powershell-azurecli/configure/...`
- `hyperv-cluster-demo/scripts/nested-vms/...` → `src/deployments/powershell-azurecli/nested-vms/...`
- `hyperv-cluster-demo/scripts/demo/...` → `src/deployments/powershell-azurecli/demo/...`
- `hyperv-cluster-demo/scripts/manual-recovery/...` → `src/deployments/powershell-azurecli/manual-recovery/...`
- `hyperv-cluster-demo/config/variables.yml` → `configs/variables/variables.yml`
- `thisismydemo/mms_2026_hybrid_demo` (workflow `repo` references, runner registration URLs) → `thisismydemo/hybrid-infra-toolkit`

`$PSScriptRoot`-based discovery in scripts is preserved unchanged. Workflow `runs-on`, secret names in Key Vault, and the runner label `hvlab-host` are unchanged. Bicep parameter file paths follow the path rewrite rule above.

#### Step 3 — Variables And Secrets

- `configs/variables/variables.yml` is the copied source variables file. Tenant ID, subscription ID, region, resource group, and host VM identifiers carry over as-is.
- Required Key Vault secrets carry over as-is. The full list is documented inside `configs/variables/variables.yml` under `key_vault.secrets_required`. They must already exist in `kv-tplabs-platform` before workflows run.
- The Phase 0.5 secrets (`bootstrap-host-admin-password`, `github-runner-registration-token`) are added to that list.

#### Step 4 — First Green Run

Run in this order from this repository:

1. `bootstrap-runner.yml` (from Phase 0.5)
2. `hvlab-00-preflight.yml`
3. `hvlab-01-deploy-azure.yml`
4. `hvlab-02-bootstrap-host.yml`
5. `hvlab-02b-postbootstrap.yml`
6. `hvlab-03-deploy-nested-vms.yml`
7. `hvlab-04-configure-cluster.yml`
8. `hvlab-05-configure-wac-vmode.yml`
9. `hvlab-06-configure-scvmm.yml`
10. `hvlab-08-validate.yml`

#### Phase 1 Exit Criteria

- all of the above workflows complete green when run from `thisismydemo/hybrid-infra-toolkit` against a clean target subscription
- `Invoke-HVLabPreflight.ps1` passes
- the cluster validates via `hvlab-08-validate.yml`
- WAC vmode and SCVMM are reachable per the source repo's acceptance criteria
- `mms_2026_hybrid_demo` is no longer required to deploy or operate this lab

## Working Backlog

1. Author Phase 0.5 Bicep under `src/deployments/bicep/bootstrap/`.
2. Author `src/deployments/powershell-azurecli/bootstrap/install-runner-github.ps1`.
3. Author `.github/workflows/bootstrap-runner.yml`.
4. Pre-stage `bootstrap-host-admin-password` and `github-runner-registration-token` in `kv-tplabs-platform`.
5. Run Phase 0.5 to green.
6. Execute Phase 1 Step 1 (copy) per the table above.
7. Execute Phase 1 Step 2 (path rewrites) per the rules above.
8. Update `configs/variables/variables.yml` from the source.
9. Run Phase 1 Step 4 in order, fix any path or secret-name regressions, until all workflows are green.
10. Confirm Phase 1 exit criteria. Close out planning. Subsequent work is roadmap.
