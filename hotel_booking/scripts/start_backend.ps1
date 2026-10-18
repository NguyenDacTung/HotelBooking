param([switch]$Lan, [switch]$Restart, [string]$InterfaceAlias = 'WiFi', [string]$ExpectedLanAddress = '')
$ErrorActionPreference = 'Stop'
$backendPath = Join-Path (Split-Path -Parent $PSScriptRoot) 'backend'
$bindAddress = if ($Lan) { '0.0.0.0' } else { '127.0.0.1' }
$lanAddress = $null
if ($Lan) {
    $profile = Get-NetConnectionProfile -InterfaceAlias $InterfaceAlias
    if ($profile.NetworkCategory -ne 'Private') { throw 'Use a trusted Private Wi-Fi network first. Network classification was not changed.' }
    $lanAddress = (Get-NetIPAddress -InterfaceAlias $InterfaceAlias -AddressFamily IPv4 | Where-Object {$_.IPAddress -notlike '169.254.*'} | Select-Object -First 1).IPAddress
    if (-not $lanAddress) { throw 'No IPv4 address on the selected Wi-Fi interface.' }
    if ($ExpectedLanAddress -and $lanAddress -ne $ExpectedLanAddress) { throw "Wi-Fi IP changed to $lanAddress. Update API_BASE_URL and rebuild the phone app; or restore the reserved router IP." }
}
function Test-Api {
    try {
        $result = Invoke-RestMethod 'http://127.0.0.1:8000/health/db' -TimeoutSec 3
        return $result.status -eq 'ok' -and $result.database -eq 'connected'
    } catch { return $false }
}
$listener = Get-NetTCPConnection -LocalPort 8000 -State Listen -ErrorAction SilentlyContinue
if ($listener -and $Restart) {
    $pidFile = Join-Path $backendPath '.server.pid'
    if (-not (Test-Path -LiteralPath $pidFile)) { throw 'No project PID file. Refusing to stop an unknown process.' }
    $recordedPid = [int](Get-Content -LiteralPath $pidFile)
    $process = Get-CimInstance Win32_Process -Filter "ProcessId=$($listener[0].OwningProcess)"
    if (($process.ProcessId -ne $recordedPid -and $process.ParentProcessId -ne $recordedPid) -or
        $process.CommandLine -notlike "*$backendPath*" -or $process.CommandLine -notlike '*uvicorn app.main:app*') {
        throw 'Port 8000 is not the recorded project backend. Nothing was stopped.'
    }
    Stop-Process -Id $process.ProcessId -ErrorAction Stop
    Start-Sleep -Milliseconds 500
    $listener = Get-NetTCPConnection -LocalPort 8000 -State Listen -ErrorAction SilentlyContinue
}
if ($listener) {
    if (-not (Test-Api)) { throw 'Port 8000 is occupied but database health is unavailable. Check backend logs.' }
    if ($Lan -and -not ($listener | Where-Object {$_.LocalAddress -in @('0.0.0.0','::',$lanAddress)})) {
        throw 'Backend only listens on localhost. Rerun with -Lan -Restart to restart the verified project process.'
    }
} else {
    $server = Start-Process -FilePath (Join-Path $backendPath '.venv\Scripts\python.exe') `
        -ArgumentList @('-m','uvicorn','app.main:app','--host',$bindAddress,'--port','8000') `
        -WorkingDirectory $backendPath -WindowStyle Hidden -PassThru `
        -RedirectStandardOutput (Join-Path $backendPath 'server.stdout.log') `
        -RedirectStandardError (Join-Path $backendPath 'server.stderr.log')
    $server.Id | Set-Content (Join-Path $backendPath '.server.pid')
    for ($attempt = 0; $attempt -lt 20; $attempt++) {
        if (Test-Api) { break }
        if ($server.HasExited) { break }
        Start-Sleep -Milliseconds 500
    }
    if (-not (Test-Api)) { throw 'Backend/PostgreSQL unavailable. Check backend/server.stderr.log. No database reset was performed.' }
}
Write-Output 'TETRA: PostgreSQL health OK; backend port 8000.'
if ($Lan) {
    Write-Output "Phone API: http://${lanAddress}:8000 (same Wi-Fi; Private firewall rule required)."
    Write-Output 'Phone access does not require adb reverse. PostgreSQL port was not opened.'
}
