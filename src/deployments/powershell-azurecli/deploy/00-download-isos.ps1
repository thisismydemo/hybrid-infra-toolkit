##############################################################################
# 00-download-isos.ps1  -- ISO provisioning to S:\HyperVStorage\ISOs\
#
# Sources:
#   - Windows Server 2022 Evaluation (180-day, ISO)  -- Microsoft fwlink
#   - Windows Server 2025 Evaluation (180-day, ISO)  -- Azure Blob Storage
#   - SQL Server 2022 Developer Edition (ISO)         -- Microsoft fwlink
#
# WS2025.iso is sourced from sthvlabcontent01/isos in Azure Blob Storage.
# The ISO must be uploaded manually once (see docs/02-iso-upload.md).
# The VM's managed identity (mi-hvlab-host01-eus-01) has Storage Blob Data Reader.
#
# Run: BEFORE workflow 03 (nested VM creation). Must have D:\ volume ready.
# Run from: self-hosted runner on hvlab-host01 (needs S:\HyperVStorage\ISOs\)
##############################################################################

param(
    [string]$ISODir           = 'S:\HyperVStorage\ISOs',
    [string]$BlobAccount      = 'sthvlabcontent01',
    [string]$BlobContainer    = 'isos',
    [switch]$SkipWS2022,
    [switch]$SkipWS2025,
    [switch]$SkipSQL
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'   # massively speeds up Invoke-WebRequest
New-Item -ItemType Directory -Path $ISODir -Force | Out-Null

function Get-FileWithProgress {
    param([string]$Uri, [string]$OutFile, [string]$DisplayName)
    if (Test-Path $OutFile) {
        Write-Host "    $DisplayName already exists, skipping." -ForegroundColor DarkGray
        return
    }
    Write-Host "    Downloading $DisplayName ..." -ForegroundColor Cyan
    $start = Get-Date
    try {
        # Use BITS for large files -- resumable, progress-aware, background-capable
        Start-BitsTransfer -Source $Uri -Destination $OutFile -DisplayName $DisplayName
    }
    catch {
        # Fallback to Invoke-WebRequest if BITS fails (firewall/proxy issues)
        Write-Warning "BITS failed, falling back to Invoke-WebRequest: $($_.Exception.Message)"
        Invoke-WebRequest -Uri $Uri -OutFile $OutFile -UseBasicParsing -MaximumRedirection 10
    }
    $elapsed = (Get-Date) - $start
    $sizeMB = [math]::Round((Get-Item $OutFile).Length / 1MB, 0)
    Write-Host "   $DisplayName -- ${sizeMB} MB in $([int]$elapsed.TotalSeconds)s" -ForegroundColor Green
}

function Get-BlobFile {
    param([string]$AccountName, [string]$Container, [string]$BlobName, [string]$OutFile, [string]$DisplayName)
    if (Test-Path $OutFile) {
        Write-Host "    $DisplayName already exists, skipping." -ForegroundColor DarkGray
        return
    }
    Write-Host "    Downloading $DisplayName from Azure Blob Storage..." -ForegroundColor Cyan
    $start = Get-Date
    az storage blob download `
        --account-name $AccountName `
        --container-name $Container `
        --name $BlobName `
        --file $OutFile `
        --auth-mode login `
        --only-show-errors
    if ($LASTEXITCODE -ne 0) {
        throw "az storage blob download failed for $BlobName. Ensure the ISO is uploaded to $AccountName/$Container and this machine has Storage Blob Data Reader."
    }
    $elapsed = (Get-Date) - $start
    $sizeMB = [math]::Round((Get-Item $OutFile).Length / 1MB, 0)
    Write-Host "   $DisplayName -- ${sizeMB} MB in $([int]$elapsed.TotalSeconds)s" -ForegroundColor Green
}

# -----------------------------------------------------------------------------
# Windows Server 2022 Evaluation ISO
# -----------------------------------------------------------------------------
if (-not $SkipWS2022) {
    Write-Host "`n=== Windows Server 2022 Evaluation ISO ===" -ForegroundColor Yellow
    # Microsoft Evaluation Center direct download (180-day eval, en-US, x64)
    $ws2022Uri = 'https://go.microsoft.com/fwlink/p/?LinkID=2195280&clcid=0x409&culture=en-us&country=US'
    Get-FileWithProgress -Uri $ws2022Uri -OutFile "$ISODir\WS2022.iso" -DisplayName 'WS2022 Eval'
    Write-Host "  ISO path: $ISODir\WS2022.iso"
}

# -----------------------------------------------------------------------------
# Windows Server 2025 Evaluation ISO  -- REQUIRED for hvwac01 (WAC vmode)
# Sourced from Azure Blob Storage: sthvlabcontent01/isos/WS2025.iso
# Upload once: az storage blob upload --account-name sthvlabcontent01 --container-name isos --name WS2025.iso --file <local-path>
# -----------------------------------------------------------------------------
if (-not $SkipWS2025) {
    Write-Host "`n=== Windows Server 2025 Evaluation ISO (required for WAC vmode) ===" -ForegroundColor Yellow
    Get-BlobFile -AccountName $BlobAccount -Container $BlobContainer `
        -BlobName 'WS2025.iso' -OutFile "$ISODir\WS2025.iso" -DisplayName 'WS2025 Eval'
    Write-Host "  ISO path: $ISODir\WS2025.iso"
}

# -----------------------------------------------------------------------------
# SQL Server 2022 Developer Edition ISO -- Free for dev/test, required for SCVMM
# Supported by SCVMM 2022 and SCVMM 2025
# -----------------------------------------------------------------------------
if (-not $SkipSQL) {
    Write-Host "`n=== SQL Server 2022 Developer Edition ISO ===" -ForegroundColor Yellow
    # SQL 2022 Dev ISO direct CDN link
    $sqlUri = 'https://go.microsoft.com/fwlink/?linkid=2215167'

    $sqlDir = "$ISODir\SQL2022Dev"
    New-Item -ItemType Directory -Path $sqlDir -Force | Out-Null
    Get-FileWithProgress -Uri $sqlUri -OutFile "$sqlDir\SQL2022Dev.iso" -DisplayName 'SQL Server 2022 Developer ISO'
    Write-Host "  ISO path: $sqlDir\SQL2022Dev.iso"
}

# -----------------------------------------------------------------------------
# Verify downloads
# -----------------------------------------------------------------------------
Write-Host "`n=== ISO Inventory ===" -ForegroundColor Cyan
Get-ChildItem -Path $ISODir -Recurse -Filter '*.iso' | ForEach-Object {
    $sizeMB = [math]::Round($_.Length / 1MB, 0)
    Write-Host "  $($_.Name.PadRight(30)) $sizeMB MB   $($_.FullName)"
}

Write-Host @"

 ISO downloads complete.

If any download fails (redirect loop, auth required):
  WS2022: https://www.microsoft.com/en-us/evalcenter/evaluate-windows-server-2022
  WS2025: https://www.microsoft.com/en-us/evalcenter/evaluate-windows-server-2025
  SQL Dev: https://www.microsoft.com/en-us/sql-server/sql-server-downloads
           -> Choose 'Developer' edition -> ISO download
"@
