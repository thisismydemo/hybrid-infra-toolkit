##############################################################################
# 05-bootstrap-phase2.ps1
# PHASE 2 -- Configure Hyper-V host after reboot:
#   - Create storage pool + D:\ volume from 4 data disks
#   - Create Hyper-V virtual switches
#   - Configure WinNAT for nested VM outbound internet
#   - Configure IP forwarding routes for secondary IPs (.46/.47)
#   - Optionally join the host VM later once the lab-local domain exists
#
# Run via: az vm run-command invoke (from workflow 02, step "Phase 2")
# Parameters passed by workflow: DomainJoinPassword
##############################################################################

param(
    [string]$DomainFqdn = 'azrl.mgmt',
    [string]$DomainJoinUser = 'svc-hvlab-deploy',
    [string]$DomainJoinPassword,
    [string]$JoinOU = 'OU=hvlab-servers,OU=Servers,OU=MGMT,DC=azrl,DC=mgmt',
    [string]$StoragePoolName = 'HVLabStoragePool',
    [string]$VolumeLabel = 'HyperVStorage',
    [string]$VolumeLetter = 'S',
    [string]$NatName = 'HVLabNAT',
    [string]$NatSubnet = '172.16.0.0/12'
)

$ErrorActionPreference = 'Stop'
$logFile = 'C:\hvlab-bootstrap-phase2.log'

function Write-Log {
    param([string]$Message, [string]$Level = 'INFO')
    $line = "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] [$Level] $Message"
    Add-Content -Path $logFile -Value $line
    Write-Host $line
}

function New-SecureStringValue {
    param([string]$Value)

    $secureString = New-Object System.Security.SecureString
    foreach ($character in $Value.ToCharArray()) {
        $secureString.AppendChar($character)
    }
    $secureString.MakeReadOnly()
    return $secureString
}

# Run a scriptblock in a background job with a hard timeout.
# Returns job output, or $null if it timed out or threw.
function Invoke-WithTimeout {
    param(
        [scriptblock]$ScriptBlock,
        [object[]]$ArgumentList = @(),
        [int]$TimeoutSeconds = 60,
        [string]$Description = 'operation'
    )
    $job = Start-Job -ScriptBlock $ScriptBlock -ArgumentList $ArgumentList
    if (Wait-Job $job -Timeout $TimeoutSeconds) {
        try   { $result = Receive-Job $job }
        catch { $result = $null }
        Remove-Job $job -Force -ErrorAction SilentlyContinue
        return $result
    }
    else {
        Write-Log "$Description timed out after ${TimeoutSeconds}s -- continuing" 'WARN'
        Stop-Job  $job -ErrorAction SilentlyContinue
        Remove-Job $job -Force -ErrorAction SilentlyContinue
        return $null
    }
}

Write-Log "=== HV-Lab Bootstrap Phase 2 -- Hyper-V Configuration ==="

# Idempotency check -- skip if Phase 2 already completed
if (Test-Path 'C:\hvlab-phase2-complete.marker') {
    Write-Log "Phase 2 skipped -- already complete (marker found)."
    exit 0
}

# -----------------------------------------------------------------------------
# 1. Storage Pool -- stripe data disks into one pool + S: volume
# -----------------------------------------------------------------------------
# NOTE: The HyperVStorage pool volume is assigned S: to avoid conflicts with
# Azure Temporary Storage (D:) which always has a pagefile that cannot be
# released without a reboot. D: is left as-is.
Write-Log "Storage pool will use $($VolumeLetter): -- Azure Temporary Storage left on D:"

Write-Log "Creating storage pool from data disks..."

$disks = Get-PhysicalDisk | Where-Object {
    $_.CanPool -eq $true -and $_.BusType -in @('SCSI', 'SAS')
}
Write-Log "Found $($disks.Count) poolable disks."

if ($disks.Count -lt 2) {
    Write-Log "Not enough disks to pool (need at least 2, found $($disks.Count)). Skipping pool creation." 'WARN'
}
else {
    $existingPool = Get-StoragePool -FriendlyName $StoragePoolName -ErrorAction SilentlyContinue
    if ($existingPool) {
        Write-Log "Storage pool '$StoragePoolName' already exists -- skipping creation."
    }
    else {
        $subsystem = Get-StorageSubSystem | Where-Object { $_.FriendlyName -like '*Windows*' }
        $pool = New-StoragePool `
            -FriendlyName $StoragePoolName `
            -StorageSubSystemUniqueId $subsystem.UniqueId `
            -PhysicalDisks $disks `
            -ResiliencySettingNameDefault Simple

        Write-Log "Storage pool '$StoragePoolName' created."

        $vdisk = New-VirtualDisk `
            -StoragePoolFriendlyName $StoragePoolName `
            -FriendlyName 'HVLabVDisk' `
            -UseMaximumSize `
            -ResiliencySettingName Simple `
            -ProvisioningType Fixed

        $vdisk | Initialize-Disk -PartitionStyle GPT -PassThru |
        New-Partition -DriveLetter $VolumeLetter -UseMaximumSize |
        Format-Volume -FileSystem NTFS -NewFileSystemLabel $VolumeLabel -Confirm:$false | Out-Null

        Write-Log "Volume $($VolumeLetter):\ created and formatted as NTFS ($VolumeLabel)."
    }
}

$dirs = @(
    "$($VolumeLetter):\HyperVStorage\VMs",
    "$($VolumeLetter):\HyperVStorage\ISOs",
    "$($VolumeLetter):\HyperVStorage\VHDs"
)
foreach ($dir in $dirs) {
    New-Item -ItemType Directory -Path $dir -Force | Out-Null
}
Write-Log "HyperV storage directories created on $($VolumeLetter):\"

# -----------------------------------------------------------------------------
# 2. Hyper-V Virtual Switches
# -----------------------------------------------------------------------------
Write-Log "Creating Hyper-V virtual switches..."

# Wait for VMMS to be responsive -- Get-VMSwitch and New-VMSwitch can hang
# indefinitely if the Hyper-V management service is not fully initialized.
Write-Log "Waiting for VMMS to become responsive..."
$vmmsReady = $false
for ($attempt = 1; $attempt -le 12; $attempt++) {
    $svc = Get-Service -Name vmms -ErrorAction SilentlyContinue
    if ($svc -and $svc.Status -eq 'Running') {
        # Use a sentinel return to distinguish "VMMS responded (empty list)" from "timed out"
        $probeJob = Start-Job -ScriptBlock {
            Get-VMSwitch -ErrorAction SilentlyContinue | Out-Null
            return 'VMMS_OK'
        }
        if (Wait-Job $probeJob -Timeout 15) {
            Remove-Job $probeJob -Force -ErrorAction SilentlyContinue
            $vmmsReady = $true
            Write-Log "VMMS responding (attempt $attempt)."
            break
        }
        Stop-Job  $probeJob -ErrorAction SilentlyContinue
        Remove-Job $probeJob -Force -ErrorAction SilentlyContinue
    }
    Write-Log "VMMS not ready yet (attempt $attempt/12) -- waiting 10s..." 'WARN'
    Start-Sleep -Seconds 10
}
if (-not $vmmsReady) {
    Write-Log "VMMS did not respond after 12 attempts -- attempting service restart..." 'WARN'
    Restart-Service -Name vmms -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 30
}

$mgmtAdapter = Get-NetAdapter | Where-Object {
    $_.Status -eq 'Up' -and $_.InterfaceDescription -notlike '*Hyper-V*'
} | Sort-Object -Property LinkSpeed -Descending | Select-Object -First 1

Write-Log "Binding vSwitch-External to adapter: $($mgmtAdapter.Name)"
$extExists = Invoke-WithTimeout `
    -ScriptBlock    { param($n) Get-VMSwitch -Name $n -ErrorAction SilentlyContinue } `
    -ArgumentList   'vSwitch-External' `
    -TimeoutSeconds 20 `
    -Description    'Get-VMSwitch vSwitch-External'
if (-not $extExists) {
    Write-Log "Creating vSwitch-External (or existence check timed out -- attempting create)..."
    Invoke-WithTimeout `
        -ScriptBlock    { param($name, $nic) New-VMSwitch -Name $name -NetAdapterName $nic -AllowManagementOS $true | Out-Null } `
        -ArgumentList   'vSwitch-External', $mgmtAdapter.Name `
        -TimeoutSeconds 120 `
        -Description    'New-VMSwitch vSwitch-External'
    Write-Log "vSwitch-External create attempt finished (see WARN above if it timed out)."
}
else {
    Write-Log "vSwitch-External already exists -- skipping."
}

$internalSwitches = @(
    @{ Name = 'vSwitch-Mgmt';      IP = '172.16.10.1'; Prefix = 24 },
    @{ Name = 'vSwitch-Migration'; IP = '172.16.20.1'; Prefix = 24 },
    @{ Name = 'vSwitch-Storage';   IP = '172.16.30.1'; Prefix = 24 },
    @{ Name = 'vSwitch-Heartbeat'; IP = '172.16.40.1'; Prefix = 24 },
    @{ Name = 'vSwitch-Workload';  IP = '172.16.50.1'; Prefix = 24 }
)

foreach ($sw in $internalSwitches) {
    $swExists = Invoke-WithTimeout `
        -ScriptBlock    { param($n) Get-VMSwitch -Name $n -ErrorAction SilentlyContinue } `
        -ArgumentList   $sw.Name `
        -TimeoutSeconds 20 `
        -Description    "Get-VMSwitch $($sw.Name)"
    if (-not $swExists) {
        Invoke-WithTimeout `
            -ScriptBlock    { param($n) New-VMSwitch -Name $n -SwitchType Internal | Out-Null } `
            -ArgumentList   $sw.Name `
            -TimeoutSeconds 60 `
            -Description    "New-VMSwitch $($sw.Name)"
    }
    $adapter = Get-NetAdapter | Where-Object { $_.Name -like "*$($sw.Name)*" }
    if ($adapter) {
        New-NetIPAddress -InterfaceAlias $adapter.Name -IPAddress $sw.IP -PrefixLength $sw.Prefix `
            -ErrorAction SilentlyContinue | Out-Null
    }
    Write-Log "Configured internal switch: $($sw.Name) ($($sw.IP)/$($sw.Prefix))"
}

# -----------------------------------------------------------------------------
# 3. WinNAT
# -----------------------------------------------------------------------------
Write-Log "Configuring WinNAT ($NatSubnet)..."
Get-NetNat -ErrorAction SilentlyContinue | Remove-NetNat -Confirm:$false -ErrorAction SilentlyContinue
try {
    New-NetNat -Name $NatName -InternalIPInterfaceAddressPrefix $NatSubnet | Out-Null
    Write-Log "WinNAT '$NatName' created for $NatSubnet"
}
catch {
    Write-Log "WinNAT creation threw exception: $_ -- may already exist" 'WARN'
}

# -----------------------------------------------------------------------------
# 4. Secondary IP forwarding notes
# -----------------------------------------------------------------------------
Write-Log "IP forwarding is enabled on Azure NIC (set via Bicep). Host routing handles .6/.7 delivery."
Write-Log "  10.250.2.6 -> hvwac01 (assigned to its vNIC on vSwitch-External)"
Write-Log "  10.250.2.7 -> hvscvmm01 (assigned to its vNIC on vSwitch-External)"
Write-Log "  Nested VMs must configure their vNICs with these IPs for this to work."

# -----------------------------------------------------------------------------
# 5. Hyper-V default paths
# -----------------------------------------------------------------------------
Write-Log "Configuring Hyper-V default VM and VHD paths..."
Set-VMHost -VirtualMachinePath "$($VolumeLetter):\HyperVStorage\VMs" `
    -VirtualHardDiskPath "$($VolumeLetter):\HyperVStorage\VHDs"
Set-VMHost -EnableEnhancedSessionMode $true
Write-Log "Hyper-V paths and enhanced session mode configured."

# -----------------------------------------------------------------------------
# 6. Optional Domain Join
# -----------------------------------------------------------------------------
Write-Log "Domain join step for $DomainFqdn..."
if (-not $DomainJoinPassword) {
    Write-Log "DomainJoinPassword not provided -- skipping domain join until the lab-local domain is ready." 'WARN'
}
else {
    $securePassword = New-SecureStringValue -Value $DomainJoinPassword
    $credential = New-Object System.Management.Automation.PSCredential(
        "$DomainJoinUser@$DomainFqdn", $securePassword)

    Add-Computer -DomainName $DomainFqdn -Credential $credential `
        -OUPath $JoinOU -Restart:$false -Force
    Write-Log "Domain join initiated. A reboot is required to complete."
}

New-Item -Path 'C:\hvlab-phase2-complete.marker' -ItemType File -Force | Out-Null
Write-Log "Phase 2 complete marker created."
Write-Log "=== Phase 2 Complete ==="
