##############################################################################
# 06-bootstrap-phase4-runner.ps1
# PHASE 4 — Install GitHub Actions self-hosted runner on the HVLab host VM.
# Labels: self-hosted, hvlab-host01
# Run via: az vm run-command invoke (from workflow 02, Phase 4 step)
# Parameters: RegistrationToken, RepoUrl
##############################################################################

param(
    [string]$RegistrationToken,
    [string]$RepoUrl = 'https://github.com/thisismydemo/hybrid-infra-toolkit',
    [string]$RunnerLabels = 'self-hosted,hvlab-host01',
    [string]$RunnerName = 'hvlab-host01'
)

$ErrorActionPreference = 'Stop'
$logFile = 'C:\hvlab-bootstrap-phase4.log'

function Write-Log {
    param([string]$Message, [string]$Level = 'INFO')
    $line = "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] [$Level] $Message"
    Add-Content -Path $logFile -Value $line -ErrorAction SilentlyContinue
    Write-Host $line
}

Write-Log "=== HV-Lab Bootstrap Phase 4 — GitHub Actions Runner ==="

$runnerDir = 'C:\actions-runner'

# Idempotency — if runner service already running, done
$svc = Get-Service -Name 'actions.runner.*' -ErrorAction SilentlyContinue | Select-Object -First 1
if ($svc -and $svc.Status -eq 'Running') {
    Write-Log "GitHub Actions runner service already running — Phase 4 skipped."
    exit 0
}

# If runner already configured but service stopped, just start it
if ($svc) {
    Write-Log "Runner service found but not running. Starting..."
    Start-Service -Name $svc.Name
    Write-Log "Runner service started."
    exit 0
}

# Download runner
$runnerVersion = '2.323.0'
$runnerUrl = "https://github.com/actions/runner/releases/download/v$runnerVersion/actions-runner-win-x64-$runnerVersion.zip"
$runnerZip = 'C:\Temp\actions-runner.zip'

New-Item -ItemType Directory -Path 'C:\Temp' -Force | Out-Null
New-Item -ItemType Directory -Path $runnerDir -Force | Out-Null

if (-not (Test-Path "$runnerDir\config.cmd")) {
    Write-Log "Downloading GitHub Actions runner v$runnerVersion..."
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Invoke-WebRequest -Uri $runnerUrl -OutFile $runnerZip -UseBasicParsing
    Write-Log "Extracting runner..."
    Expand-Archive -Path $runnerZip -DestinationPath $runnerDir -Force
    Write-Log "Runner extracted to $runnerDir"
}

if (-not $RegistrationToken) {
    Write-Log "ERROR: RegistrationToken is required." 'ERROR'
    exit 1
}

# Configure runner
Write-Log "Configuring runner: name=$RunnerName labels=$RunnerLabels repo=$RepoUrl"
Push-Location $runnerDir
& .\config.cmd `
    --url $RepoUrl `
    --token $RegistrationToken `
    --name $RunnerName `
    --labels $RunnerLabels `
    --runasservice `
    --windowslogonaccount 'NT AUTHORITY\SYSTEM' `
    --unattended `
    --replace 2>&1 | Tee-Object -Variable configOutput

$configOutput | ForEach-Object { Write-Log $_ }
Pop-Location

if ($LASTEXITCODE -ne 0) {
    Write-Log "Runner configuration failed with exit code $LASTEXITCODE" 'ERROR'
    exit 1
}

Write-Log "Runner configured and installed as Windows service."
Write-Log "=== Phase 4 Complete ==="
