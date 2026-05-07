"""Rewrite hvlab-03 workflow - use Invoke-AsAdmin.ps1 with KV-sourced creds."""
import pathlib

repo = pathlib.Path(r'E:\git\thisismydemo\hybrid-infra-toolkit')
wf   = repo / '.github' / 'workflows' / 'hvlab-03-deploy-nested-vms.yml'

content = wf.read_text(encoding='utf-8')
idx = content.find('    runs-on: [self-hosted, hvlab-host01]')
header = content[:idx]

H = r'$env:GITHUB_WORKSPACE\src\deployments\powershell-azurecli\common\Invoke-AsAdmin.ps1'
PF = r'C:\Windows\Temp\hvlab-admin.pass'
AU = 'hvlabadmin'

def step(name, script_rel):
    sp = r'$env:GITHUB_WORKSPACE\src\deployments\powershell-azurecli\nested-vms' + '\\' + script_rel
    lines = [
        f'      - name: "{name}"',
        '        shell: powershell',
        '        run: |',
        f'          $helper = "{H}"',
        f'          $script = "{sp}"',
        f'          $adminPass = Get-Content "{PF}" -Raw',
        f'          & $helper -ScriptPath $script -AdminPassword $adminPass -AdminUser {AU}',
        '          if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }',
        '',
    ]
    return '\n'.join(lines) + '\n'


setup_step = '''\
      - name: "Setup - retrieve admin password from Key Vault via IMDS"
        shell: powershell
        run: |
          $passFile = "C:\\Windows\\Temp\\hvlab-admin.pass"
          try {
            $tok = (Invoke-RestMethod `
              -Uri "http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=https://vault.azure.net" `
              -Headers @{Metadata="true"} -Method Get -EA Stop).access_token
            $sec = (Invoke-RestMethod `
              -Uri "https://kv-tplabs-platform.vault.azure.net/secrets/hvlab-host01-admin-password?api-version=7.0" `
              -Headers @{Authorization="Bearer $tok"} -EA Stop).value
            $sec | Set-Content $passFile -Encoding UTF8 -NoNewline
            Write-Host "::add-mask::$sec"
            Write-Host "Password retrieved from Key Vault"
          } catch {
            Write-Host "KV retrieval failed: $_  - using default"
            "HVLab@2026!" | Set-Content $passFile -Encoding UTF8 -NoNewline
          }
          $helper = "''' + H + r'''"
          $ts = "$env:GITHUB_WORKSPACE\src\deployments\powershell-azurecli\common\test-id.ps1"
          "[System.Security.Principal.WindowsIdentity]::GetCurrent().Name" | Set-Content $ts -Encoding UTF8
          $adminPass = Get-Content $passFile -Raw
          & $helper -ScriptPath $ts -AdminPassword $adminPass -AdminUser ''' + AU + '''
          Remove-Item $ts -Force -EA SilentlyContinue
          if ($LASTEXITCODE -ne 0) { throw "Start-Process -Credential test failed (exit $LASTEXITCODE)" }
          Write-Host "Start-Process -Credential as ''' + AU + ''' OK."

'''

summary_step = '''\
      - name: Summary
        shell: powershell
        run: |
          $helper = "''' + H + r'''"
          $sumScript = "$env:GITHUB_WORKSPACE\src\deployments\powershell-azurecli\common\get-vms-csv.ps1"
          "Get-VM -EA SilentlyContinue | Select-Object Name,State,ProcessorCount | Export-Csv -Path C:\\Windows\\Temp\\hvlab-vms.csv -NoTypeInformation" | Set-Content $sumScript -Encoding UTF8
          $adminPass = Get-Content "C:\\Windows\\Temp\\hvlab-admin.pass" -Raw
          & $helper -ScriptPath $sumScript -AdminPassword $adminPass -AdminUser ''' + AU + '''
          Remove-Item $sumScript, "C:\\Windows\\Temp\\hvlab-admin.pass" -Force -EA SilentlyContinue
          $vms = if (Test-Path C:\\Windows\\Temp\\hvlab-vms.csv) { Import-Csv C:\\Windows\\Temp\\hvlab-vms.csv; Remove-Item C:\\Windows\\Temp\\hvlab-vms.csv -Force } else { @() }
          $vms | Format-Table | Out-String | Write-Host
          "## Nested VMs Created" | Out-File $env:GITHUB_STEP_SUMMARY -Append
          "| VM | State | vCPU |" | Out-File $env:GITHUB_STEP_SUMMARY -Append
          "|---|---|---|" | Out-File $env:GITHUB_STEP_SUMMARY -Append
          foreach ($vm in $vms) {
            "| $($vm.Name) | $($vm.State) | $($vm.ProcessorCount) |" | Out-File $env:GITHUB_STEP_SUMMARY -Append
          }
          "`n**Next:** HVLab 04 - Configure Failover Cluster" | Out-File $env:GITHUB_STEP_SUMMARY -Append
'''

new_body = (
    '    runs-on: [self-hosted, hvlab-host01]\n'
    '    steps:\n'
    '      - uses: actions/checkout@v4\n'
    '\n'
    + setup_step
    + step('Create forest root DC (hvdc01 - azrl.mgmt)', '01-create-dc.ps1')
    + step('Create iSCSI target server (hviscsi01)', '02-create-iscsi.ps1')
    + step('Create Hyper-V cluster nodes (hvnode01-04)', '03-create-cluster-nodes.ps1')
    + step('Create WAC vmode server (hvwac01 - WS2025)', '04-create-wac-vmode.ps1')
    + step('Create SCVMM server (hvscvmm01)', '05-create-scvmm.ps1')
    + summary_step
)

wf.write_text(header + new_body + '\n', encoding='utf-8')
print('Done, length:', len(header + new_body))
