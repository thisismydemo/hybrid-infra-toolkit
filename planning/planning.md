# Planning

This document is the internal planning file for Hybrid Infrastructure Toolkit.

There are exactly **two parts**:

- **Part I — Get the code over and working.** Bring this repository to a green deploy of the Hyper-V cluster lab, using its own AD (not the tplabs shared AD).
- **Part II — Everything else.** All feature requests, customizations, abstractions, and broader work. See [docs/project/roadmap.md](../docs/project/roadmap.md).

This file is not part of the public documentation site.

## Current Working Decisions

- solution name: `Hybrid Infrastructure Toolkit`
- GitHub repository: `https://github.com/thisismydemo/hybrid-infra-toolkit`
- public docs URL target: `https://www.thisismydemo.cloud/hybrid-infra-toolkit`
- GitHub Pages publish URL: `https://thisismydemo.github.io/hybrid-infra-toolkit/`
- docs stack: MkDocs
- CI provider out of the box: GitHub Actions
- this repository is standalone — no upstream source is required at runtime
- code-bring-over approach: copy the working Hyper-V cluster lab implementation into `src/` as part of this repository's code, evolve in place
- runner label (kept compatible with the source workflows on first pass): `hvlab-host`

## Source Inventory (Part I Input)

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

## Target Repo Structure (End of Part I)

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
│   │   └── hyperv-cluster-lab/
│   ├── project/
│   ├── standards/
│   └── design/
├── src/
│   ├── deployments/
│   │   ├── bicep/
│   │   │   ├── main.bicep
│   │   │   ├── identity.bicep
│   │   │   ├── identity-rg.bicep
│   │   │   ├── parameters/
│   │   │   └── modules/
│   │   └── powershell-azurecli/
│   │       ├── deploy/            # includes runner install on cluster host
│   │       ├── configure/
│   │       ├── nested-vms/
│   │       ├── demo/
│   │       └── manual-recovery/
│   └── platform/
│       ├── powershell/modules/    # HVLab.Automation.psm1
│       ├── validators/            # Invoke-HVLabPreflight.ps1
│       └── orchestration/
└── .github/
    └── workflows/
        ├── deploy-docs.yml
        └── hvlab-*.yml            # Part I (10 files)
```

## Runner Note (Part I Shape)

The source repository does not use a separate bootstrap runner host. The GitHub Actions self-hosted runner is installed **on the cluster host VM itself** (`vm-hvlab-host01-eus-01`) by the `hvlab-02-bootstrap-host.yml` workflow via Custom Script Extension, alongside Hyper-V, vSwitches, WinNAT, and domain join. Part I preserves that shape. Separating the runner from the cluster host is Part II.

---

## Part I — Get The Code Over And Working

**Goal:** the Hyper-V cluster lab deploys green from `thisismydemo/hybrid-infra-toolkit`, using its own AD instead of the tplabs shared AD.

**In scope for Part I:**

- stabilize the source so it actually deploys end-to-end (it is not assumed green today)
- copy the working implementation from `mms_2026_hybrid_demo/hyperv-cluster-demo` into this repo
- rewrite paths to match this repo's layout
- switch identity off the tplabs shared AD onto this lab's own AD
- one green end-to-end deploy from this repository

**Out of scope for Part I (all goes to Part II):** renaming, abstraction, CAF normalization, removing `hvlab` identifiers, removing `mms_2026` / `mms26` references, demo prefix option, identity-mode option selector (default-domain / custom-domain / existing-domain), multi-CI provider support, multi-toolchain support, separating the runner from the cluster host.

### Step 0 — Stabilize The Source

The source repository is not assumed green. This work happens in `mms_2026_hybrid_demo` against its current layout, not here.

1. **Map the deployment flow.** Produce an end-to-end sequence of the 10 `hvlab-*` workflows: what each one does, what it depends on (variables, secrets, prior workflow outputs), and the actual current failure points.
2. **Audit scripts for failures.** Walk every PowerShell file under `hyperv-cluster-demo/scripts/` and every Bicep file under `hyperv-cluster-demo/bicep/` for known-broken or stale logic against the current source variables file.
3. **Rewrite broken PowerShell.** Fix what the audit surfaces. Keep changes minimal and behavior-preserving where the script is conceptually correct.
4. **Fix workflow sequencing.** Reconcile the 10 `hvlab-*` workflows so the run order in Step 5 below is actually achievable without manual intervention between steps.
5. **Run static validation.** `bicep build` cleanly, `Invoke-ScriptAnalyzer` on the PowerShell tree, YAML lint on the workflows, and a dry parse of `config/variables.yml`. All clean before Step 1.

**Exit criteria for Step 0:** the source repo deploys the lab end-to-end green at least once.

### Step 1 — Copy

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

### Step 2 — Path Rewrite Rules

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

### Step 3 — Switch Off The tplabs Shared AD

The source implementation depends on the tplabs shared Active Directory for some identity flows. Part I removes that dependency so this lab is self-contained on its own AD.

- the lab continues to deploy `hvdc01` as the forest root DC for the nested `azrl.mgmt` forest (already the case in the source)
- any script, workflow, Bicep parameter, or variable that joins to, authenticates against, or pulls from the tplabs shared AD is changed to use the lab-local `azrl.mgmt` forest instead
- domain join, DNS resolution, Kerberos, and any service account references are pointed at the lab-local DC, not tplabs
- Key Vault `kv-tplabs-platform` is still consumed for secrets at deploy time (changing the secrets store is Part II)
- output: a list of every place the tplabs AD was being referenced and the replacement used, captured in `configs/variables/variables.yml` comments and inline in the affected scripts

**Exit criteria for Step 3:** no runtime workload inside the lab depends on tplabs AD reachability. The lab can deploy and operate even if tplabs AD is unreachable (Key Vault remains a deploy-time dependency).

### Step 4 — Variables And Secrets

- `configs/variables/variables.yml` is the copied, AD-switched source variables file. Tenant ID, subscription ID, region, resource group, and host VM identifiers carry over as-is.
- Required Key Vault secrets carry over as-is. The full list is documented inside `configs/variables/variables.yml` under `key_vault.secrets_required`. They must already exist in `kv-tplabs-platform` before workflows run. This includes `hvlab-github-runner-token`, which is consumed by the cluster-host bootstrap to install the GitHub Actions runner on the host.

### Step 5 — First Green Run

Run in this order from this repository:

1. `hvlab-00-preflight.yml` (GitHub-hosted)
2. `hvlab-01-deploy-azure.yml` (GitHub-hosted) — deploys cluster host VM
3. `hvlab-02-bootstrap-host.yml` (GitHub-hosted) — runs CSE on the host: Hyper-V, vSwitches, WinNAT, domain join, and **installs the self-hosted runner with label `hvlab-host`**
4. `hvlab-02b-postbootstrap.yml` (self-hosted)
5. `hvlab-03-deploy-nested-vms.yml` (self-hosted)
6. `hvlab-04-configure-cluster.yml` (self-hosted)
7. `hvlab-05-configure-wac-vmode.yml` (self-hosted)
8. `hvlab-06-configure-scvmm.yml` (self-hosted)
9. `hvlab-08-validate.yml` (self-hosted)

### Part I Exit Criteria

- all of the above workflows complete green when run from `thisismydemo/hybrid-infra-toolkit` against a clean target subscription
- `Invoke-HVLabPreflight.ps1` passes
- the cluster validates via `hvlab-08-validate.yml`
- WAC vmode and SCVMM are reachable per the source repo's acceptance criteria
- no workload inside the deployed lab depends on tplabs AD
- `mms_2026_hybrid_demo` is no longer required to deploy or operate this lab

### Working Backlog (Part I)

**Step 0 — Stabilize the source (in `mms_2026_hybrid_demo`):**

1. Map the deployment flow across the 10 `hvlab-*` workflows.
2. Audit scripts and Bicep for failures against the current variables file.
3. Rewrite broken PowerShell as the audit surfaces it.
4. Fix workflow sequencing so the documented run order is actually achievable.
5. Run static validation (`bicep build`, `Invoke-ScriptAnalyzer`, YAML lint, variables parse).
6. Achieve one green end-to-end deploy in the source repo.

**Steps 1–5 — Land in this repo:**

7. Execute Step 1 (copy) per the table above.
8. Execute Step 2 (path rewrites) per the rules above.
9. Execute Step 3 (switch off tplabs AD dependency).
10. Update `configs/variables/variables.yml` from the stabilized, AD-switched source.
11. Confirm `hvlab-github-runner-token` and all other secrets in `key_vault.secrets_required` are pre-staged in `kv-tplabs-platform`.
12. Run Step 5 in order, fix any path or secret-name regressions, until all workflows are green.
13. Confirm Part I exit criteria. Close out Part I. All subsequent work is Part II.

---

## Part II — Everything Else

Part II is the full vision for the toolkit: feature requests, customizations, abstractions, multi-target / multi-toolchain / multi-CI provider work, demo prefix option, identity mode selector (existing-domain / default-domain / custom-domain), runner separation, removing `hvlab` and `mms_2026` identifiers, and everything else discussed.

**Part II is tracked in [docs/project/roadmap.md](../docs/project/roadmap.md).**

Do not start Part II work until Part I exit criteria are met.
