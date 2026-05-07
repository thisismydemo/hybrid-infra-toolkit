# Project Roadmap

This page is the project-facing roadmap for Hybrid Infrastructure Toolkit.

The internal planning document focuses narrowly on reaching feature parity with the existing Hyper-V cluster lab implementation. Everything beyond parity lives here.

## Status

- **Phase 0 — Repo bootstrap:** complete
- **Phase 1 — Land the Hyper-V cluster lab into this repository:** in progress (the self-hosted runner is installed on the cluster host as part of host bootstrap; same shape as the source repo)
- **Beyond parity:** see below

## Beyond Parity

### Generic CI Runner Bootstrap (Needs ADR)

The current shape installs the runner on the cluster host VM. That is fine for a single Azure-hosted lab and matches the source implementation. It is not a long-term design.

A standalone, environment-aware, standards-driven runner bootstrap is required before the toolkit can support targets beyond Azure VMs. Open design questions to be captured in an ADR under `docs/design/adr/`:

- Where does the runner live for each deployment target: Azure VM, nested Hyper-V on another hypervisor, physical hardware?
- Is the runner a dedicated host, a sidecar VM, or co-resident with the workload host?
- How is `ci_provider` (GitHub / GitLab / Azure DevOps) selected from `configs/variables/variables.yml` and how does the install path branch?
- How is runner registration credential lifecycle handled (rotation, scope: repo / org / enterprise)?
- What is the CAF-aligned naming for runner-related resources (resource group, VM, managed identity, NSG)?
- How does this interact with private networking, firewalls, and outbound restrictions in customer environments?

This must be designed before any of the items below ship.

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

> **Non-negotiable constraint for all Part II work:** no hardcoded values. Every environment-specific value (tenant ID, subscription ID, resource name, IP, domain name, service account, secret) must come from `configs/variables/variables.yml`, a Bicep parameter file, a workflow input/variable, or a Key Vault secret URI. Part I code containing hardcoded values must be refactored when the Part II item that touches that file is implemented.

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

The toolkit must support multiple identity paths so demo authors can pick what fits their environment. None of these is a “lab isolation” feature — they are deployment options for the same demo infrastructure.

- **`existing-domain`** — join the demo to an Active Directory domain the user already runs. No new DCs are deployed. (Current parity work uses a variant of this against the nested `azrl.mgmt` forest.)
- **`default-domain`** — a canned, opinionated AD built by the toolkit with sensible defaults (forest name, OU layout, demo accounts, DNS). Zero customization required from the user. This is the portable default for people who don’t care about identity specifics.
- **`custom-domain`** — same shape as `default-domain` but the user supplies their own forest name, NetBIOS name, OU layout, admin account names, and any pre-seeded demo accounts. Built from the default template, customized via `configs/variables/variables.yml`.
- **workgroup** — no domain at all, considered later if a scenario needs it.

Identity mode selection lives in `configs/variables/variables.yml` and drives which deploy/configure scripts run.

### Management Plane Options

- external management services
- cohosted management VMs
- sidecar Hyper-V management host for physical hardware scenarios

Management roles in scope across modes: domain controllers, DNS, Windows Admin Center, SCVMM, optional jump box / orchestration VM.

### Azure Local Overlay

Longer term the toolkit may support a lab-oriented Azure Local mode. Guardrail: Azure Local is a scenario overlay, not the only product identity.

### Demo Prefix Option

All resource names, tags, and identifiers in the parity implementation currently hardcode `mms_2026`, `mms26`, and `hvlab` strings. Part 2 introduces a `demo_prefix` value in `configs/variables/variables.yml` that drives every generated name through the CAF naming convention.

- `demo_prefix` is the workload token in `<type>-<workload>-<instance>-<region>-<seq>`.
- Default value ships with the toolkit but is fully overridable.
- All `mms_2026` / `mms26` / `hvlab` literals are removed from variables, Bicep, scripts, and workflows and replaced with prefix-driven names.
- Workflow file names (`hvlab-*.yml`) are renamed to a neutral, prefix-agnostic scheme.

This enables the same toolkit to deploy multiple independent demo instances side-by-side without name collisions.

### Rename And De-hvlab

Independent of (but related to) the demo prefix work:

- rename `HVLab.Automation.psm1` to a toolkit-neutral module name
- rename `Invoke-HVLabPreflight.ps1` to a scenario-neutral preflight
- remove `hvlab-host` runner label in favor of a label derived from `demo_prefix`
- remove all `hvlab` and `mms_2026` references from documentation

### Documentation And Versioning

- public docs for each scenario under `docs/demos/<scenario>/`
- versioned documentation via `mike` once a stable release line emerges
- changelog discipline tied to tagged releases
