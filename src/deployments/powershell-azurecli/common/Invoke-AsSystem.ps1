##############################################################################
# Invoke-AsSystem.ps1
# Runs a PowerShell script as NT AUTHORITY\SYSTEM via a scheduled task.
# Used when the GitHub Actions runner lacks Hyper-V admin rights (NETWORK SERVICE).
##############################################################################
param(
    [Parameter(Mandatory)][string]$ScriptPath,
    [string]$LogFile = "C:\Temp\hvlab-invoke-as-system.log",
    [string]$TaskName = "HVLab-InvokeAsSystem",
    [int]$TimeoutMinutes = 45,
    [hashtable]$EnvVars = @{}
)

$ErrorActionPreference = 'Stop'
New-Item -ItemType Directory -Path (Split-Path $LogFile) -Force | Out-Null

# Build env var setup block
$envBlock = ($EnvVars.GetEnumerator() | ForEach-Object {
    "`$env:$($_.Key) = '$($_.Value)'"
}) -join "`n"

# Write wrapper that sets env vars and calls the target script
$wrapperPath = "C:\Temp\hvlab-system-wrapper-$([System.IO.Path]::GetFileNameWithoutExtension($ScriptPath)).ps1"
Set-Content -Path $wrapperPath -Value @"
`$ErrorActionPreference = 'Stop'
$envBlock
& '$ScriptPath' *>&1 | ForEach-Object { `$_ | Out-String -Width 200 } | Set-Content -Path '$LogFile' -Encoding UTF8
exit `$LASTEXITCODE
"@

# Remove any leftover task with this name
Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false -ErrorAction SilentlyContinue

$action    = New-ScheduledTaskAction -Execute "powershell.exe" `
                -Argument "-NonInteractive -ExecutionPolicy Bypass -File `"$wrapperPath`""
$principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -RunLevel Highest
Register-ScheduledTask -TaskName $TaskName -Action $action -Principal $principal -Force | Out-Null

Write-Host "Starting scheduled task '$TaskName' as SYSTEM..."
Start-ScheduledTask -TaskName $TaskName

$deadline = [DateTime]::UtcNow.AddMinutes($TimeoutMinutes)
do {
    Start-Sleep -Seconds 15
    $state = (Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue).State
    Write-Host "  $(Get-Date -Format 'HH:mm:ss') | task=$state"
    if (-not $state) { break }
    if ([DateTime]::UtcNow -gt $deadline) { throw "Timed out after $TimeoutMinutes minutes." }
} while ($state -eq 'Running')

# Stream log output back to the runner
if (Test-Path $LogFile) {
    Write-Host "--- Output from $ScriptPath ---"
    Get-Content $LogFile | Write-Host
    Write-Host "--- End output ---"
}

$info = Get-ScheduledTaskInfo -TaskName $TaskName -ErrorAction SilentlyContinue
$exitCode = if ($info) { $info.LastTaskResult } else { 0 }
Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false -ErrorAction SilentlyContinue
Remove-Item $wrapperPath -Force -ErrorAction SilentlyContinue

if ($exitCode -ne 0) {
    throw "Script '$ScriptPath' failed with exit code $exitCode"
}
Write-Host "Script completed successfully."
