param([string]$DeviceId = 'R58T801R8BD')
$ErrorActionPreference = 'Stop'
$projectPath = Split-Path -Parent $PSScriptRoot
$backendPath = Join-Path $projectPath 'backend'
$adbPath = Join-Path $env:LOCALAPPDATA 'Android\Sdk\platform-tools\adb.exe'

function Test-Api {
    try {
        $health = Invoke-RestMethod 'http://127.0.0.1:8000/health/db' -TimeoutSec 3
        return $health.status -eq 'ok' -and $health.database -eq 'connected'
    } catch { return $false }
}

if (-not (Test-Api)) {
    $listener = Get-NetTCPConnection -LocalPort 8000 -State Listen -ErrorAction SilentlyContinue
    if ($listener) { throw 'Port 8000 is occupied but /health/db is not healthy. Check backend/server.stderr.log; no process was stopped.' }
    $server = Start-Process -FilePath (Join-Path $backendPath '.venv\Scripts\python.exe') `
        -ArgumentList @('-m','uvicorn','app.main:app','--host','127.0.0.1','--port','8000') `
        -WorkingDirectory $backendPath -WindowStyle Hidden -PassThru `
        -RedirectStandardOutput (Join-Path $backendPath 'server.stdout.log') `
        -RedirectStandardError (Join-Path $backendPath 'server.stderr.log')
    $server.Id | Set-Content (Join-Path $backendPath '.server.pid')
    for ($attempt = 0; $attempt -lt 20; $attempt++) {
        if (Test-Api) { break }
        if ($server.HasExited) { break }
        Start-Sleep -Milliseconds 500
    }
    if (-not (Test-Api)) { throw 'Backend/PostgreSQL is unavailable. Check backend/server.stderr.log. Database was not reset.' }
}
if (-not (Test-Path -LiteralPath $adbPath)) { throw 'Android platform-tools/adb.exe not found.' }
$deviceState = & $adbPath -s $DeviceId get-state 2>$null
if ($LASTEXITCODE -ne 0 -or $deviceState -ne 'device') { throw 'Phone not ready: unlock it and authorize USB debugging, then retry.' }
& $adbPath -s $DeviceId reverse tcp:8000 tcp:8000
if ($LASTEXITCODE -ne 0) { throw 'Unable to forward the phone API port over USB.' }
Write-Output 'TTTP: /health/db OK; phone 127.0.0.1:8000 -> backend 127.0.0.1:8000. No database reset.'
