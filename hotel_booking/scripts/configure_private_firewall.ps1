param([string]$InterfaceAlias = 'WiFi')
$ErrorActionPreference = 'Stop'
$resultPath = Join-Path (Split-Path -Parent $PSScriptRoot) '.local-backups\firewall-result.json'
New-Item -ItemType Directory -Path (Split-Path -Parent $resultPath) -Force | Out-Null
try {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) { throw 'Administrator rights required. Run this script once from an Administrator PowerShell.' }
    if ((Get-NetConnectionProfile -InterfaceAlias $InterfaceAlias).NetworkCategory -ne 'Private') { throw 'Selected Wi-Fi is not Private. No firewall rule was added.' }
    $address = (Get-NetIPAddress -InterfaceAlias $InterfaceAlias -AddressFamily IPv4 | Where-Object {$_.IPAddress -notlike '169.254.*'} | Select-Object -First 1).IPAddress
    if (-not $address) { throw 'No Wi-Fi IPv4 address.' }
    $ruleName = 'TTTP-Local-API-Private-WiFi'
    $old = Get-NetFirewallRule -Name $ruleName -ErrorAction SilentlyContinue
    if ($old) {
        if ($old.Group -ne 'TTTP Local Development') { throw 'Rule name already belongs to another configuration; preserved.' }
        Remove-NetFirewallRule -Name $ruleName
    }
    New-NetFirewallRule -Name $ruleName -DisplayName 'TTTP API 8000 - Private WiFi subnet only' `
        -Group 'TTTP Local Development' -Direction Inbound -Action Allow -Enabled True `
        -Profile Private -InterfaceAlias $InterfaceAlias -Protocol TCP -LocalPort 8000 `
        -LocalAddress $address -RemoteAddress LocalSubnet | Out-Null
    $rule = Get-NetFirewallRule -Name $ruleName
    $port = $rule | Get-NetFirewallPortFilter
    $scope = $rule | Get-NetFirewallAddressFilter
    @{success=$true;profile=$rule.Profile.ToString();port=$port.LocalPort;localAddress=$scope.LocalAddress;remoteAddress=$scope.RemoteAddress;interface=$InterfaceAlias} | ConvertTo-Json | Set-Content -Encoding UTF8 -LiteralPath $resultPath
    Write-Output "TTTP API allowed on Private ${InterfaceAlias} ${address}:8000, LocalSubnet only. No PostgreSQL rule added."
} catch {
    @{success=$false;error=$_.Exception.Message} | ConvertTo-Json | Set-Content -Encoding UTF8 -LiteralPath $resultPath
    throw
}
