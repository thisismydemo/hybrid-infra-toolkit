<#
.SYNOPSIS
    Run a PowerShell script as local Administrator using Start-Process -Credential.
    Works from NT AUTHORITY\NETWORK SERVICE (CreateProcessWithLogonW, no extra privileges needed).

.PARAMETER ScriptPath
    Absolute path to the .ps1 script to run.

.PARAMETER AdminPassword
    Password for the local Administrator account.

.PARAMETER AdminUser
    Local admin username (default: Administrator).
#>
param(
    [Parameter(Mandatory)]
    [string]$ScriptPath,

    [string]$AdminPassword = 'HVLab@2026!',

    [string]$AdminUser = 'Administrator'
)

$ErrorActionPreference = 'Stop'

$pass   = ConvertTo-SecureString $AdminPassword -AsPlainText -Force
$cred   = New-Object System.Management.Automation.PSCredential("$env:COMPUTERNAME\$AdminUser", $pass)

$uid        = [System.Guid]::NewGuid().ToString('N').Substring(0, 8)
$logFile    = "C:\Windows\Temp\hvlab-l-$uid.log"
$wrapperPath = "C:\Windows\Temp\hvlab-w-$uid.ps1"

# Build wrapper content without here-strings (avoids YAML indentation issues at call site)
$wrapperLines = [System.Collections.Generic.List[string]]::new()
$wrapperLines.Add('$env:GITHUB_WORKSPACE = "' + $env:GITHUB_WORKSPACE + '"')
$wrapperLines.Add('$env:HVLAB_BOOTSTRAP_PASSWORD = "' + $AdminPassword + '"')
$wrapperLines.Add('& "' + $ScriptPath + '" 2>&1 | Tee-Object -FilePath "' + $logFile + '"')
$wrapperLines.Add('exit $LASTEXITCODE')
[System.IO.File]::WriteAllLines($wrapperPath, $wrapperLines, [System.Text.Encoding]::UTF8)

Write-Host "Running as ${AdminUser}: $ScriptPath"

$proc = Start-Process powershell.exe `
    -ArgumentList ('-NonInteractive -ExecutionPolicy Bypass -File "' + $wrapperPath + '"') `
    -Credential $cred `
    -WorkingDirectory $env:GITHUB_WORKSPACE `
    -Wait -PassThru

# Brief wait to ensure file writes are flushed
Start-Sleep -Milliseconds 500

if (Test-Path $logFile) {
    Get-Content $logFile
    Remove-Item $logFile -Force -ErrorAction SilentlyContinue
}
Remove-Item $wrapperPath -Force -ErrorAction SilentlyContinue

exit (if ($null -ne $proc.ExitCode) { $proc.ExitCode } else { 1 })
