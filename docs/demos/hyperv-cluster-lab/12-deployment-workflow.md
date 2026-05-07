# 12 — Deployment Workflow

## Overview

Deployment runs from `thisismydemo/hybrid-infra-toolkit` using 10 GitHub Actions workflows.

**Runner split:**

| Phase | Runs On | Workflows |
|---|---|---|
| Cloud infrastructure | GitHub-hosted (`ubuntu-latest` / `windows-latest`) | 00, 01, 02 |
| All in-guest work | Self-hosted on host VM (`hvlab-host`) | 02b, 03–08 |

The self-hosted runner is installed by workflow 02 (via Custom Script Extension) onto `vm-hvlab-host01-eus-01`. Workflows 03–08 run directly on that host, giving them full access to Hyper-V APIs and the nested VM networks.

---

## Prerequisites

Before running any workflow, complete these one-time setup steps:

1. **Azure identity**: run `src/deployments/powershell-azurecli/deploy/00-setup-identity.ps1`
   - Creates managed identity `mi-hvlab-host01-eus-01`
   - Assigns Contributor on the deploy subscription
   - Assigns Key Vault Secrets User on `kv-tplabs-platform`

2. **Key Vault secrets**: run `src/deployments/powershell-azurecli/deploy/03-prestage-kv-secrets.ps1`
   - Pre-stages all secrets listed in `configs/variables/variables.yml` under `key_vault.secrets_required`

3. **GitHub repo secrets** (Settings → Secrets → Actions):
   - `AZURE_CLIENT_ID` — client ID of `mi-hvlab-host01-eus-01`
   - `AZURE_TENANT_ID` — `a9b67171-3fbb-45bf-8394-eb56d02a86e4`
   - `AZURE_SUBSCRIPTION_ID` — `00cd4357-ed45-4efb-bee0-10c467ff994b`

4. **Region check** (optional but recommended): `src/deployments/powershell-azurecli/deploy/01-find-best-region.ps1`

5. **IP availability check**: `src/deployments/powershell-azurecli/deploy/02-verify-ip-availability.ps1`

---

## Run Order

Run workflows **in this order**. Do not skip ahead.

```
00 → 01 → 02 → [wait for runner] → 02b → 03 → 04 → 05 → 06 → 08
```

Workflow 07 (demo-reset) is run-on-demand — not part of the initial deploy sequence.

---

## Workflow 00 — Repo Preflight

**File**: `.github/workflows/hvlab-00-preflight.yml`
**Runs on**: `windows-latest` (GitHub-hosted)

Runs PSScriptAnalyzer on all PowerShell files, validates the Bicep template against the target subscription (ARM validate, not deploy), and checks that the managed identity exists. Safe to run at any time.

**Trigger**: manual (`workflow_dispatch`) — select region and VM size from the dropdowns.

---

## Workflow 01 — Deploy Azure Infrastructure

**File**: `.github/workflows/hvlab-01-deploy-azure.yml`
**Runs on**: `ubuntu-latest` (GitHub-hosted)

Deploys the Azure resource group and host VM via Bicep:

- Template: `src/deployments/bicep/main.bicep`
- Parameters: `src/deployments/bicep/parameters/tplabs.bicepparam`
- Creates: resource group, VNet NIC (3 IPs), NSG, host VM, OS disk, data disk, managed identity attachment
- Host VM: `vm-hvlab-host01-eus-01` in `rg-hvlab-mms26-eus-01`
- Primary IP: `10.250.2.5` (host management)
- Secondary IP: `10.250.2.6` (WAC vmode)
- Tertiary IP: `10.250.2.7` (SCVMM)

**Trigger**: manual — select region and VM size.

---

## Workflow 02 — Bootstrap Host VM

**File**: `.github/workflows/hvlab-02-bootstrap-host.yml`
**Runs on**: `ubuntu-latest` (GitHub-hosted) — uses `az vm run-command invoke` to run scripts on the host

**Phase 1** — installs Hyper-V features (triggers reboot, waits for VM to come back).

**Phase 2** — runs `src/deployments/powershell-azurecli/deploy/05-bootstrap-phase2.ps1` via CSE:
- Creates storage pool from data disk
- Creates all vSwitches (External, Mgmt, Storage, Migration, Heartbeat, Workload)
- Configures WinNAT for `172.16.10.0/24`
- Domain join intentionally deferred — `azrl.mgmt` does not exist until workflow 03

**Runner install** — fetches `hvlab-github-pat-full` from `kv-tplabs-platform`, calls the GitHub API to generate an ephemeral runner registration token, runs `06-install-github-runner.ps1` on the host. Runner registers with label `hvlab-host`.

> `hvlab-github-pat-full` must be a classic PAT with `repo`, `workflow`, and `admin:org` scopes.

**Trigger**: automatic after workflow 01 succeeds, or manual.

After this workflow: verify **GitHub → repo Settings → Actions → Runners** shows `hvlab-host01` as **Idle** before proceeding to 02b.

---

## Workflow 02b — Post-Bootstrap (ISOs + Arc)

**File**: `.github/workflows/hvlab-02b-postbootstrap.yml`
**Runs on**: `[self-hosted, hvlab-host]`

Downloads OS ISOs from blob storage to the host data disk. Installs the Azure Arc agent on the host VM.

**Trigger**: automatic after workflow 02, or manual.

---

## Workflow 03 — Deploy Nested VMs

**File**: `.github/workflows/hvlab-03-deploy-nested-vms.yml`
**Runs on**: `[self-hosted, hvlab-host]`

Creates all nested VMs in order:

| Script | VM | Role |
|---|---|---|
| `nested-vms/01-create-dc.ps1` | `hvdc01` | Forest root DC — promotes to `azrl.mgmt` |
| `nested-vms/02-create-iscsi.ps1` | `hviscsi01` | iSCSI target server |
| `nested-vms/03-create-cluster-nodes.ps1` | `hvnode01–04` | Failover cluster nodes |
| `nested-vms/04-create-wac-vmode.ps1` | `hvwac01` | WAC Virtualization Mode (WS2025 required) |
| `nested-vms/05-create-scvmm.ps1` | `hvscvmm01` | SCVMM 2025 |

Each script creates the VM, attaches the correct vSwitches, assigns static IPs, and domain-joins the VM to `azrl.mgmt`. `01-create-dc.ps1` promotes the DC first using `Install-ADDSForest` — all subsequent VMs join against it.

**Trigger**: automatic after workflow 02b, or manual.

---

## Workflow 04 — Configure Failover Cluster

**File**: `.github/workflows/hvlab-04-configure-cluster.yml`
**Runs on**: `[self-hosted, hvlab-host]`

Runs configure scripts in this order (AD must complete before cluster creation):

| Script | What it does |
|---|---|
| `configure/05-configure-ad.ps1` | Create OUs, service accounts (`svc-*`), security groups, KCD — fetches passwords from `kv-tplabs-platform` |
| `configure/01-configure-iscsi.ps1` | Configure iSCSI Target role and 3 × 500 GB LUNs on `hviscsi01` |
| `configure/02-configure-iscsi-initiators.ps1` | Connect iSCSI initiators on `hvnode01–04`, configure MPIO |
| `configure/08-configure-network-atc.ps1` | Configure Network ATC SET switch on cluster nodes |
| `configure/03-configure-cluster.ps1` | Create cluster `hvlab-clus01`, add CSVs, set Cloud Witness |
| `configure/07-configure-dhcp.ps1` | Configure DHCP scopes on `hvdc01` (Mgmt `172.16.10.0/24`, Workload `172.16.50.0/24`) |

**Trigger**: automatic after workflow 03, or manual.

---

## Workflow 05 — Configure WAC Virtualization Mode

**File**: `.github/workflows/hvlab-05-configure-wac-vmode.yml`
**Runs on**: `[self-hosted, hvlab-host]`

Runs `configure/04-configure-wac-vmode.ps1`:
- Verifies `hvwac01` is running Windows Server 2025 (required — WAC vmode does not run on WS2022)
- Fetches `hvwac01-pg-password` from `kv-tplabs-platform`
- Installs Visual C++ Redistributable and downloads WAC vmode from `https://aka.ms/WACDownloadvMode`
- Installs with PostgreSQL on port 5432, HTTPS on port 443
- Access after install: `https://10.250.2.6`

**Trigger**: automatic after workflow 04, or manual.

---

## Workflow 06 — Configure SCVMM 2025

**File**: `.github/workflows/hvlab-06-configure-scvmm.yml`
**Runs on**: `[self-hosted, hvlab-host]`

Runs `configure/06-configure-scvmm.ps1`:
- Downloads SCVMM 2025 installer from blob storage (`sthvlabcontent01`)
- Mounts SQL Server 2022 Developer ISO and installs SQL
  - SQL service account: `AZRL\svc-sql-scvmm` (KV secret: `svc-sql-scvmm-password`)
  - SCVMM service account: `AZRL\svc-scvmm-svc` (KV secret: `svc-scvmm-svc-password`)
- Installs SCVMM 2025 management server
- Adds cluster `hvlab-clus01` and all nodes to SCVMM
- Configures logical networks (Mgmt, Workload) and library share

**Trigger**: automatic after workflow 05, or manual.

---

## Workflow 07 — Demo Reset

**File**: `.github/workflows/hvlab-07-demo-reset.yml`
**Runs on**: `[self-hosted, hvlab-host]`

Restores all nested VMs to the `DEMO-READY` checkpoint. Run on demand before each demo session. After the initial full deploy, run this workflow once to **create** the checkpoint — all subsequent runs **restore** to it.

---

## Workflow 08 — Validate Environment

**File**: `.github/workflows/hvlab-08-validate.yml`
**Runs on**: `[self-hosted, hvlab-host]`

Checks:
- All 8 nested VMs are `Running`
- Cluster `hvlab-clus01` is healthy, all nodes `Up`, all CSVs `Online`
- iSCSI sessions connected on all cluster nodes
- WAC vmode HTTPS (`https://10.250.2.6`) returns 200
- SCVMM service (`SCVMMService`) is `Running` on `hvscvmm01`

**Trigger**: automatic after workflow 06, or manual at any time.

---

## Estimated Total Deployment Time

| Workflow | Approx Time |
|---|---|
| 00 Preflight | 5 min |
| 01 Deploy Azure | 15 min |
| 02 Bootstrap | 20 min |
| 02b Post-bootstrap | 10 min |
| 03 Nested VMs | 45 min |
| 04 Configure Cluster | 30 min |
| 05 WAC vmode | 15 min |
| 06 SCVMM | 60 min |
| 08 Validate | 5 min |
| **Total** | **~3.5 hours** |

---

## Re-running a Failed Workflow

All scripts check for existing state before applying changes and are safe to re-run. If a workflow fails:

1. Review the failing step in the GitHub Actions run log
2. Fix the root cause
3. Re-run the workflow — already-completed steps will skip cleanly

If the runner goes offline mid-run: SSH/RDP to `vm-hvlab-host01-eus-01`, run `Get-Service 'actions.runner.*'`, start it if stopped, then re-trigger the workflow.

---

## Quick Failure Reference

| Symptom | First thing to check |
|---|---|
| Runner not idle after workflow 02 | `Get-Service 'actions.runner.*'` on host; `C:\actions-runner\_diag\` logs |
| DC promotion fails | `hvdc01` WinRM reachable? ISO mounted? 4 GB RAM assigned? |
| iSCSI not connecting | `hviscsi01` domain-joined? iSCSI Target service running? |
| Cluster validation fails | All nodes domain-joined? iSCSI sessions up? Network ATC applied? |
| WAC vmode unreachable | WS2025 confirmed on `hvwac01`? `C:\WACvmode\install.log`? |
| SCVMM install fails | Blob storage accessible? `svc-sql-scvmm` and `svc-scvmm-svc` accounts exist in AD? |
