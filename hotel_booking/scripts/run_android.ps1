param(
    [string]$ApiBaseUrl = '',
    [string]$DeviceId = '',
    [string]$ClientConfig = '',
    [switch]$Usb,
    [switch]$BuildApk,
    [switch]$DryRun
)
$ErrorActionPreference = 'Stop'
$projectPath = Split-Path -Parent $PSScriptRoot
$pythonPath = Join-Path $projectPath 'backend\.venv\Scripts\python.exe'
if ($ClientConfig -and -not (Test-Path -LiteralPath $ClientConfig)) {
    throw 'The requested client configuration file does not exist.'
}
if (-not $ClientConfig) { $ClientConfig = Join-Path $projectPath 'config\flutter.local.json' }
if (-not (Test-Path -LiteralPath $ClientConfig)) {
    # An empty example disables integrations until real public settings exist.
    $ClientConfig = Join-Path $projectPath 'config\flutter.example.json'
    Write-Output 'Using empty public service settings. See docs/service_configuration.md to enable integrations.'
}
$ClientConfig = (Resolve-Path -LiteralPath $ClientConfig).Path
& $pythonPath (Join-Path $projectPath 'backend\check_configuration.py') --client-config $ClientConfig --client-only
if ($LASTEXITCODE -ne 0) { throw 'Client configuration check failed. Nothing was built or installed.' }
$config = Get-Content -Raw -LiteralPath $ClientConfig -Encoding UTF8 | ConvertFrom-Json
if ($Usb) {
    if ($ApiBaseUrl -and $ApiBaseUrl.TrimEnd('/') -ne 'http://127.0.0.1:8000') {
        throw '-Usb requires http://127.0.0.1:8000. Omit -ApiBaseUrl or use that address.'
    }
    $ApiBaseUrl = 'http://127.0.0.1:8000'
}
if (-not $ApiBaseUrl) { throw 'Supply -ApiBaseUrl http://<CURRENT_LAN_IP>:8000, or use -Usb.' }
$apiUri = $null
if (-not [Uri]::TryCreate($ApiBaseUrl, [UriKind]::Absolute, [ref]$apiUri) -or
    $apiUri.Scheme -notin @('http','https') -or $apiUri.UserInfo -or $apiUri.Query -or $apiUri.Fragment) {
    throw 'API URL must be HTTP/HTTPS without credentials, query or fragment.'
}
$ApiBaseUrl = $ApiBaseUrl.TrimEnd('/')
if ($DryRun) {
    Write-Output 'Configuration valid. Dry run: no backend requests, device changes, build or installation performed.'
    return
}
$adbPath = Join-Path $env:LOCALAPPDATA 'Android\Sdk\platform-tools\adb.exe'
if (-not $BuildApk) {
    if (-not (Test-Path -LiteralPath $adbPath)) { throw 'Android SDK platform-tools/adb.exe not found.' }
    if (-not $DeviceId) {
        $output = & $adbPath devices
        if ($LASTEXITCODE -ne 0) { throw 'Unable to list Android devices.' }
        $devices = @($output | Where-Object { $_ -match '^\S+\s+device$' } | ForEach-Object { ($_ -split '\s+')[0] })
        if ($devices.Count -ne 1) { throw 'Connect and authorize one Android device, or supply -DeviceId when multiple devices are connected.' }
        $DeviceId = $devices[0]
    }
    if ($Usb) {
        & $adbPath -s $DeviceId reverse tcp:8000 tcp:8000
        if ($LASTEXITCODE -ne 0) { throw 'USB API forwarding failed.' }
    }
    $healthUrl = if ($Usb) { 'http://127.0.0.1:8000/health/db' } else { "$ApiBaseUrl/health/db" }
    $health = Invoke-RestMethod $healthUrl -TimeoutSec 8
    if ($health.status -ne 'ok' -or $health.database -ne 'connected') {
        throw 'Backend database health is unavailable. Start the backend before running the app.'
    }
}
$native = @{
    'TTTP_FACEBOOK_APP_ID' = [string]$config.TTTP_FACEBOOK_APP_ID
    'TTTP_FACEBOOK_CLIENT_TOKEN' = [string]$config.TTTP_FACEBOOK_CLIENT_TOKEN
    'TTTP_FIREBASE_API_KEY' = [string]$config.FIREBASE_API_KEY
    'TTTP_FIREBASE_APP_ID' = [string]$config.FIREBASE_APP_ID
    'TTTP_FIREBASE_MESSAGING_SENDER_ID' = [string]$config.FIREBASE_MESSAGING_SENDER_ID
    'TTTP_FIREBASE_PROJECT_ID' = [string]$config.FIREBASE_PROJECT_ID
}
$previous = @{}
Push-Location $projectPath
try {
    foreach ($key in $native.Keys) {
        $previous[$key] = [Environment]::GetEnvironmentVariable($key, 'Process')
        [Environment]::SetEnvironmentVariable($key, $native[$key], 'Process')
    }
    $flutterArgs = if ($BuildApk) { @('build','apk','--debug') } else { @('run','-d',$DeviceId,'--debug') }
    $flutterArgs += @("--dart-define-from-file=$ClientConfig", '--dart-define=DEMO_MODE=false', "--dart-define=API_BASE_URL=$ApiBaseUrl")
    & flutter @flutterArgs
    if ($LASTEXITCODE -ne 0) { throw 'Flutter failed. Review the build output above.' }
} finally {
    foreach ($key in $previous.Keys) { [Environment]::SetEnvironmentVariable($key, $previous[$key], 'Process') }
    Pop-Location
}
