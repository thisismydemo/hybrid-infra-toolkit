##############################################################################
# HVLab.Automation.psm1  — Shared helper functions for HVLab nested-VM deploy
# Runs on: vm-hvlab-host01-eus-01 (WS2025, Hyper-V host) via GH Actions runner
##############################################################################

$ErrorActionPreference = 'Stop'

function Get-HVLabStorageRoot {
    param([string]$PreferredRoot = '')
    if ($PreferredRoot -and (Test-Path $PreferredRoot)) { return $PreferredRoot }
    foreach ($drive in @('D:', 'S:', 'C:')) {
        if (Test-Path "${drive}\") {
            $vol = Get-Volume -DriveLetter $drive[0] -ErrorAction SilentlyContinue
            if ($vol -and $vol.SizeRemaining -gt 50GB) { return "${drive}\HyperVStorage" }
        }
    }
    return 'D:\HyperVStorage'
}

function Resolve-HVLabStoragePath {
    param([string]$StorageRoot, [string]$ChildPath)
    $full = Join-Path $StorageRoot $ChildPath
    $dir = Split-Path $full -Parent
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    return $full
}

function New-HVLabBootstrapCredential {
    param(
        [string]$SecretValue = '',
        [string]$VaultName = '',
        [string]$SubscriptionId = ''
    )
    if (-not $SecretValue -and $VaultName) {
        $SecretValue = az keyvault secret show `
            --vault-name $VaultName `
            --subscription $SubscriptionId `
            --name 'hvlab-bootstrap-password' `
            --query value -o tsv 2>$null
    }
    if (-not $SecretValue) {
        throw "Bootstrap password not found. Pass -BootstrapPassword or pre-stage 'hvlab-bootstrap-password' in Key Vault '$VaultName'."
    }
    $secure = ConvertTo-SecureString $SecretValue -AsPlainText -Force
    return New-Object System.Management.Automation.PSCredential('Administrator', $secure)
}

function Get-HVLabHostDnsServers {
    $cfgs = Get-NetIPConfiguration | Where-Object { $_.IPv4DefaultGateway }
    if ($cfgs) {
        $dns = $cfgs[0].DNSServer.ServerAddresses | Where-Object { $_ -match '^\d' } | Select-Object -First 2
        if ($dns) { return @($dns) }
    }
    return @('168.63.129.16')
}

function New-HVLabWindowsVhd {
    param(
        [string]$IsoPath,
        [string]$VhdPath,
        [int]$SizeGB = 80,
        [string]$ComputerName,
        [string]$AdminPassword,
        [int]$ImageIndex = 2   # WS2025 Standard Desktop
    )

    if (Test-Path $VhdPath) {
        Write-Host "  VHD already exists: $VhdPath — skipping." -ForegroundColor Yellow
        return $VhdPath
    }

    $vhdDir = Split-Path $VhdPath -Parent
    if (-not (Test-Path $vhdDir)) { New-Item -ItemType Directory -Path $vhdDir -Force | Out-Null }

    Write-Host "  Creating VHDX from $IsoPath (index=$ImageIndex) → $VhdPath" -ForegroundColor DarkGray

    New-VHD -Path $VhdPath -SizeBytes ($SizeGB * 1GB) -Dynamic | Out-Null

    $vhdMount = Mount-VHD -Path $VhdPath -Passthru
    $disk = Get-Disk -Number $vhdMount.DiskNumber

    Initialize-Disk -InputObject $disk -PartitionStyle GPT -PassThru | Out-Null

    $efi = New-Partition -InputObject $disk -Size 100MB `
        -GptType '{c12a7328-f81f-11d2-ba4b-00a0c93ec93b}'
    Format-Volume -Partition $efi -FileSystem FAT32 -Force -Confirm:$false | Out-Null

    New-Partition -InputObject $disk -Size 16MB `
        -GptType '{e3c9e316-0b5c-4db8-817d-f92df00215ae}' | Out-Null

    $os = New-Partition -InputObject $disk -UseMaximumSize `
        -GptType '{ebd0a0a2-b9e5-4433-87c0-68b6b72699c7}'
    Format-Volume -Partition $os -FileSystem NTFS -Force -Confirm:$false | Out-Null

    $efi | Add-PartitionAccessPath -AssignDriveLetter
    $os  | Add-PartitionAccessPath -AssignDriveLetter

    $efi = Get-Partition -DiskNumber $disk.Number |
    Where-Object { $_.GptType -eq '{c12a7328-f81f-11d2-ba4b-00a0c93ec93b}' }
    $os = Get-Partition -DiskNumber $disk.Number |
    Where-Object { $_.GptType -eq '{ebd0a0a2-b9e5-4433-87c0-68b6b72699c7}' }

    $osLetter = "$($os.DriveLetter):"
    $efiLetter = "$($efi.DriveLetter):"

    $isoVol = Mount-DiskImage -ImagePath $IsoPath -PassThru | Get-Volume
    $isoLetter = "$($isoVol.DriveLetter):"

    try {
        $wimPath = Join-Path $isoLetter 'sources\install.wim'
        if (-not (Test-Path $wimPath)) { $wimPath = Join-Path $isoLetter 'sources\install.esd' }

        Write-Host "  Applying WIM index $ImageIndex → $osLetter ..." -ForegroundColor DarkGray
        & dism /Apply-Image /ImageFile:"$wimPath" /Index:$ImageIndex /ApplyDir:"$osLetter\" /Quiet
        if ($LASTEXITCODE -ne 0) { throw "DISM apply failed (exit $LASTEXITCODE)" }

        & bcdboot "$osLetter\Windows" /s "$efiLetter" /f UEFI
        if ($LASTEXITCODE -ne 0) { throw "bcdboot failed (exit $LASTEXITCODE)" }

        # Unattend — sets hostname, admin password, enables RDP
        $panther = "$osLetter\Windows\Panther"
        New-Item -ItemType Directory -Path $panther -Force | Out-Null
        @"
<?xml version="1.0" encoding="utf-8"?>
<unattend xmlns="urn:schemas-microsoft-com:unattend">
  <settings pass="specialize">
    <component name="Microsoft-Windows-Shell-Setup" processorArchitecture="amd64"
               publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS"
               xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State">
      <ComputerName>$ComputerName</ComputerName>
      <RegisteredOrganization>HVLab</RegisteredOrganization>
      <RegisteredOwner>HVLab</RegisteredOwner>
    </component>
    <component name="Microsoft-Windows-TerminalServices-LocalSessionManager"
               processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35"
               language="neutral" versionScope="nonSxS"
               xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State">
      <fDenyTSConnections>false</fDenyTSConnections>
    </component>
  </settings>
  <settings pass="oobeSystem">
    <component name="Microsoft-Windows-Shell-Setup" processorArchitecture="amd64"
               publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS"
               xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State">
      <AutoLogon>
        <Password><Value>$AdminPassword</Value><PlainText>true</PlainText></Password>
        <Enabled>true</Enabled>
        <Username>Administrator</Username>
        <LogonCount>1</LogonCount>
      </AutoLogon>
      <OOBE>
        <HideEULAPage>true</HideEULAPage>
        <HideOEMRegistrationScreen>true</HideOEMRegistrationScreen>
        <HideOnlineAccountScreens>true</HideOnlineAccountScreens>
        <HideWirelessSetupInOOBE>true</HideWirelessSetupInOOBE>
        <ProtectYourPC>3</ProtectYourPC>
        <NetworkLocation>Work</NetworkLocation>
      </OOBE>
      <UserAccounts>
        <AdministratorPassword>
          <Value>$AdminPassword</Value>
          <PlainText>true</PlainText>
        </AdministratorPassword>
      </UserAccounts>
    </component>
  </settings>
</unattend>
"@ | Set-Content -Path "$panther\unattend.xml" -Encoding UTF8

    }
    finally {
        Dismount-DiskImage -ImagePath $IsoPath -ErrorAction SilentlyContinue | Out-Null
    }

    Remove-PartitionAccessPath -DiskNumber $disk.Number `
        -PartitionNumber $os.PartitionNumber  -AccessPath "$osLetter\"  -ErrorAction SilentlyContinue
    Remove-PartitionAccessPath -DiskNumber $disk.Number `
        -PartitionNumber $efi.PartitionNumber -AccessPath "$efiLetter\" -ErrorAction SilentlyContinue
    Dismount-VHD -Path $VhdPath

    Write-Host "  VHD ready: $VhdPath" -ForegroundColor Green
    return $VhdPath
}

function New-HVLabVm {
    param(
        [string]$Name,
        [string]$OSVhdPath,
        [string]$VmPath,
        [int]$MemoryGB = 4,
        [int]$ProcessorCount = 2,
        [array]$AdapterDefinitions = @(),
        [array]$DataVhdPaths = @(),
        [switch]$ExposeVirtualizationExtensions
    )

    if (Get-VM -Name $Name -ErrorAction SilentlyContinue) {
        Write-Host "  VM $Name already exists — skipping." -ForegroundColor Yellow
        return Get-VM -Name $Name
    }

    if (-not (Test-Path $VmPath)) { New-Item -ItemType Directory -Path $VmPath -Force | Out-Null }

    $vm = New-VM -Name $Name -Path $VmPath -Generation 2 `
        -MemoryStartupBytes ($MemoryGB * 1GB) -NoVHD

    Set-VM -VM $vm -ProcessorCount $ProcessorCount -DynamicMemory:$false `
        -AutomaticStartAction Nothing -AutomaticStopAction ShutDown `
        -CheckpointType Production

    if ($ExposeVirtualizationExtensions) {
        Set-VMProcessor -VM $vm -ExposeVirtualizationExtensions $true
    }

    Set-VMFirmware -VM $vm -EnableSecureBoot Off

    Add-VMHardDiskDrive -VM $vm -Path $OSVhdPath -ControllerType SCSI -ControllerNumber 0

    foreach ($dataVhd in $DataVhdPaths) {
        Add-VMHardDiskDrive -VM $vm -Path $dataVhd -ControllerType SCSI
    }

    # Boot order: OS disk first
    $bootDrive = Get-VMHardDiskDrive -VM $vm | Select-Object -First 1
    Set-VMFirmware -VM $vm -BootOrder $bootDrive

    # Remove default NIC, add configured ones
    Get-VMNetworkAdapter -VM $vm | Remove-VMNetworkAdapter
    foreach ($adDef in $AdapterDefinitions) {
        $adapter = Add-VMNetworkAdapter -VM $vm -Name $adDef.Name -SwitchName $adDef.SwitchName -Passthru
        if ($adDef.EnableMacAddressSpoofing) {
            Set-VMNetworkAdapter -VMNetworkAdapter $adapter -MacAddressSpoofing On
        }
    }

    Enable-VMIntegrationService -VM $vm -Name 'Guest Service Interface' -ErrorAction SilentlyContinue

    Start-VM -VM $vm
    Write-Host "  $Name started — waiting for first-boot heartbeat..." -ForegroundColor DarkGray

    $deadline = (Get-Date).AddMinutes(20)
    do {
        Start-Sleep -Seconds 10
        $hb = (Get-VMIntegrationService -VMName $Name -Name 'Heartbeat' -ErrorAction SilentlyContinue).PrimaryStatusDescription
    } while ($hb -ne 'OK' -and (Get-Date) -lt $deadline)

    if ($hb -ne 'OK') { throw "VM $Name did not come up within 20 minutes." }

    Write-Host "  $Name heartbeat OK — settling 90s for first-boot specialize..." -ForegroundColor DarkGray
    Start-Sleep -Seconds 90

    Write-Host "  VM $Name ready." -ForegroundColor Green
    return Get-VM -Name $Name
}

function _WaitForPsDirect {
    param(
        [string]$VMName,
        [System.Management.Automation.PSCredential]$Credential,
        [int]$TimeoutMinutes = 10
    )
    $deadline = (Get-Date).AddMinutes($TimeoutMinutes)
    do {
        try {
            Invoke-Command -VMName $VMName -Credential $Credential -ScriptBlock { $true } -ErrorAction Stop | Out-Null
            return $true
        }
        catch { Start-Sleep -Seconds 10 }
    } while ((Get-Date) -lt $deadline)
    throw "Cannot connect to $VMName via PS Direct after $TimeoutMinutes minutes."
}

function Initialize-HVLabGuestNetwork {
    param(
        [string]$VMName,
        [System.Management.Automation.PSCredential]$Credential,
        [array]$AdapterConfigurations
    )

    Write-Host "  Configuring guest networking in $VMName..." -ForegroundColor DarkGray
    _WaitForPsDirect -VMName $VMName -Credential $Credential

    Invoke-Command -VMName $VMName -Credential $Credential `
        -ArgumentList (, $AdapterConfigurations) -ScriptBlock {
        param($AdapterConfigs)

        Enable-PSRemoting -Force -ErrorAction SilentlyContinue
        Set-ItemProperty 'HKLM:\System\CurrentControlSet\Control\Terminal Server' fDenyTSConnections 0
        Enable-NetFirewallRule -DisplayGroup 'Remote Desktop' -ErrorAction SilentlyContinue

        $allAdapters = Get-NetAdapter | Sort-Object InterfaceIndex

        for ($i = 0; $i -lt $AdapterConfigs.Count; $i++) {
            $cfg = $AdapterConfigs[$i]
            $adapter = $allAdapters | Where-Object { $_.Name -eq $cfg.GuestName } | Select-Object -First 1
            if (-not $adapter -and $i -lt $allAdapters.Count) { $adapter = $allAdapters[$i] }
            if (-not $adapter) { continue }

            if ($adapter.Name -ne $cfg.GuestName) {
                Rename-NetAdapter -Name $adapter.Name -NewName $cfg.GuestName -ErrorAction SilentlyContinue
            }

            if ($cfg.IPAddress) {
                Get-NetIPAddress   -InterfaceAlias $cfg.GuestName -ErrorAction SilentlyContinue |
                Remove-NetIPAddress -Confirm:$false -ErrorAction SilentlyContinue
                Get-NetRoute       -InterfaceAlias $cfg.GuestName -DestinationPrefix '0.0.0.0/0' -ErrorAction SilentlyContinue |
                Remove-NetRoute    -Confirm:$false -ErrorAction SilentlyContinue

                New-NetIPAddress -InterfaceAlias $cfg.GuestName `
                    -IPAddress $cfg.IPAddress -PrefixLength $cfg.PrefixLength -ErrorAction SilentlyContinue | Out-Null

                if ($cfg.Gateway) {
                    New-NetRoute -InterfaceAlias $cfg.GuestName `
                        -DestinationPrefix '0.0.0.0/0' -NextHop $cfg.Gateway -ErrorAction SilentlyContinue | Out-Null
                }

                if ($cfg.DnsServers -and $cfg.DnsServers.Count -gt 0) {
                    Set-DnsClientServerAddress -InterfaceAlias $cfg.GuestName `
                        -ServerAddresses $cfg.DnsServers -ErrorAction SilentlyContinue
                }
            }
        }
    }

    Write-Host "  Network configured in $VMName." -ForegroundColor Green
}

function Invoke-HVLabPowerShellDirect {
    param(
        [string]$VMName,
        [System.Management.Automation.PSCredential]$Credential,
        [scriptblock]$ScriptBlock,
        [array]$ArgumentList = @()
    )
    _WaitForPsDirect -VMName $VMName -Credential $Credential
    return Invoke-Command -VMName $VMName -Credential $Credential `
        -ScriptBlock $ScriptBlock -ArgumentList $ArgumentList
}

function Restart-HVLabGuest {
    param(
        [string]$VMName,
        [System.Management.Automation.PSCredential]$Credential,
        [int]$DelaySeconds = 15,
        [int]$TimeoutMinutes = 30
    )
    Write-Host "  Restarting $VMName..." -ForegroundColor DarkGray
    try {
        Invoke-Command -VMName $VMName -Credential $Credential `
            -ScriptBlock { Restart-Computer -Force } -ErrorAction SilentlyContinue
    }
    catch {}

    Start-Sleep -Seconds $DelaySeconds

    $deadline = (Get-Date).AddMinutes($TimeoutMinutes)
    do {
        Start-Sleep -Seconds 10
        $hb = (Get-VMIntegrationService -VMName $VMName -Name 'Heartbeat' -ErrorAction SilentlyContinue).PrimaryStatusDescription
    } while ($hb -ne 'OK' -and (Get-Date) -lt $deadline)

    if ($hb -ne 'OK') { throw "$VMName did not come back within $TimeoutMinutes minutes." }

    _WaitForPsDirect -VMName $VMName -Credential $Credential
    Write-Host "  $VMName back up." -ForegroundColor Green
}

function Join-HVLabGuestToDomain {
    param(
        [string]$VMName,
        [System.Management.Automation.PSCredential]$LocalCredential,
        [string]$DomainFqdn,
        [System.Management.Automation.PSCredential]$DomainCredential,
        [string[]]$DnsServers = @()
    )
    Write-Host "  Joining $VMName to $DomainFqdn..." -ForegroundColor DarkGray

    Invoke-HVLabPowerShellDirect -VMName $VMName -Credential $LocalCredential `
        -ArgumentList $DomainFqdn, $DomainCredential, $DnsServers -ScriptBlock {
        param($DomainFqdn, $DomainCredential, $DnsServers)

        if ((Get-WmiObject Win32_ComputerSystem).PartOfDomain) {
            Write-Host "  Already domain-joined."; return
        }

        # Point DNS at the DC
        $primary = Get-NetAdapter | Where-Object { $_.Status -eq 'Up' } | Sort-Object InterfaceIndex | Select-Object -First 1
        if ($primary -and $DnsServers) {
            Set-DnsClientServerAddress -InterfaceAlias $primary.Name -ServerAddresses $DnsServers
        }

        # Wait for DC reachability
        $dc = $DnsServers | Select-Object -First 1
        $deadline = (Get-Date).AddMinutes(10)
        do {
            if (Test-Connection -ComputerName $dc -Count 1 -Quiet -ErrorAction SilentlyContinue) { break }
            Start-Sleep -Seconds 5
        } while ((Get-Date) -lt $deadline)

        Add-Computer -DomainName $DomainFqdn -Credential $DomainCredential -Restart:$false -Force
    }

    Restart-HVLabGuest -VMName $VMName -Credential $LocalCredential -DelaySeconds 20 -TimeoutMinutes 15
    Write-Host "  $VMName joined $DomainFqdn." -ForegroundColor Green
}

Export-ModuleMember -Function *
