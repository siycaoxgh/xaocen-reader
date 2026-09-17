<#
.SYNOPSIS
Checks whether the canonical XAOCEN Android and Windows artifacts are suitable
for a formal release hand-off.

.DESCRIPTION
This script is read-only. A formal artifact must be built from a clean source
tree, use the validated Patched Windows Engine, and carry a non-debug platform
signature. Missing signing keys are reported as blockers; the script never
creates or imports credentials.
#>
[CmdletBinding()]
param(
    [string]$AndroidApk,
    [string]$WindowsReleaseDirectory,
    [switch]$AllowUnsignedVerification
)

$ErrorActionPreference = 'Stop'
$Root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
if ([string]::IsNullOrWhiteSpace($AndroidApk)) {
    $AndroidApk = Join-Path $Root 'build\app\outputs\flutter-apk\app-release.apk'
}
if ([string]::IsNullOrWhiteSpace($WindowsReleaseDirectory)) {
    $WindowsReleaseDirectory = Join-Path $Root 'artifacts\windows\current\Release'
}

$issues = [Collections.Generic.List[string]]::new()
$warnings = [Collections.Generic.List[string]]::new()
$pubspec = Get-Content -LiteralPath (Join-Path $Root 'pubspec.yaml') -Raw
$versionMatch = [regex]::Match($pubspec, '(?m)^version:\s*([^\s]+)\s*$')
$version = if ($versionMatch.Success) { $versionMatch.Groups[1].Value } else { 'UNKNOWN' }

Write-Host "APP_VERSION=$version"

$windowsExe = Join-Path $WindowsReleaseDirectory 'xaocen_reader.exe'
$engineManifestPath = Join-Path $WindowsReleaseDirectory 'engine-selection.json'
if (-not (Test-Path -LiteralPath $windowsExe -PathType Leaf)) {
    $issues.Add("Windows executable is missing: $windowsExe")
} else {
    $windowsHash = (Get-FileHash -LiteralPath $windowsExe -Algorithm SHA256).Hash
    Write-Host "WINDOWS_EXE=$windowsExe"
    Write-Host "WINDOWS_SHA256=$windowsHash"

    $signature = Get-AuthenticodeSignature -FilePath $windowsExe
    Write-Host "WINDOWS_SIGNATURE=$($signature.Status)"
    if ($signature.Status -ne 'Valid') {
        $message = 'Windows executable does not have a valid Authenticode signature.'
        if ($AllowUnsignedVerification) { $warnings.Add($message) } else { $issues.Add($message) }
    }
}

if (-not (Test-Path -LiteralPath $engineManifestPath -PathType Leaf)) {
    $issues.Add("Windows engine-selection manifest is missing: $engineManifestPath")
} else {
    $engineManifest = Get-Content -LiteralPath $engineManifestPath -Raw | ConvertFrom-Json
    Write-Host "WINDOWS_ENGINE_SELECTION=$($engineManifest.selection)"
    Write-Host "WINDOWS_ENGINE_REVISION=$($engineManifest.engineRevision)"
    Write-Host "WINDOWS_SOURCE_COMMIT=$($engineManifest.sourceCommit)"
    Write-Host "WINDOWS_SOURCE_DIRTY=$($engineManifest.sourceDirty)"
    if ([string]$engineManifest.selection -ne 'XAOCEN_PATCHED_ENGINE') {
        $issues.Add('Canonical Windows artifact is not the validated Patched Engine build.')
    }
    if ([string]::IsNullOrWhiteSpace([string]$engineManifest.sourceCommit)) {
        $issues.Add('Windows build manifest does not identify a source commit; rebuild it.')
    }
    if ($null -eq $engineManifest.sourceDirty) {
        $issues.Add('Windows build manifest predates source cleanliness tracking; rebuild it.')
    } elseif ([bool]$engineManifest.sourceDirty) {
        $message = 'Windows artifact was built from an uncommitted source tree.'
        if ($AllowUnsignedVerification) { $warnings.Add($message) } else { $issues.Add($message) }
    }
}

if (-not (Test-Path -LiteralPath $AndroidApk -PathType Leaf)) {
    $issues.Add("Android Release APK is missing: $AndroidApk")
} else {
    $androidHash = (Get-FileHash -LiteralPath $AndroidApk -Algorithm SHA256).Hash
    Write-Host "ANDROID_APK=$AndroidApk"
    Write-Host "ANDROID_SHA256=$androidHash"

    $sdk = if ($env:ANDROID_HOME) {
        $env:ANDROID_HOME
    } elseif ($env:ANDROID_SDK_ROOT) {
        $env:ANDROID_SDK_ROOT
    } else {
        Join-Path $env:LOCALAPPDATA 'Android\Sdk'
    }
    $buildTools = Join-Path $sdk 'build-tools'
    $apksigner = Get-ChildItem -LiteralPath $buildTools -Recurse -File -Filter 'apksigner.bat' -ErrorAction SilentlyContinue |
        Sort-Object -Property FullName -Descending |
        Select-Object -First 1 -ExpandProperty FullName
    if ([string]::IsNullOrWhiteSpace($apksigner)) {
        $issues.Add('apksigner was not found; Android signature cannot be verified.')
    } else {
        $certificateOutput = (& $apksigner verify --print-certs $AndroidApk 2>&1 | Out-String)
        if ($LASTEXITCODE -ne 0) {
            $issues.Add('Android APK signature verification failed.')
        } else {
            $signerLine = ($certificateOutput -split "`r?`n" | Where-Object { $_ -like 'Signer #1 certificate DN:*' } | Select-Object -First 1)
            Write-Host "ANDROID_SIGNER=$signerLine"
            if ($certificateOutput -match 'CN=Android Debug') {
                $issues.Add('Android Release APK is signed with the Android Debug certificate.')
            }
        }
    }
}

foreach ($warning in $warnings) {
    Write-Warning $warning
}
foreach ($issue in $issues) {
    Write-Error $issue -ErrorAction Continue
}

if ($issues.Count -gt 0) {
    Write-Host 'FORMAL_RELEASE_ARTIFACTS=FAIL'
    exit 1
}

if ($warnings.Count -gt 0) {
    Write-Host 'FORMAL_RELEASE_ARTIFACTS=VERIFICATION_ONLY'
} else {
    Write-Host 'FORMAL_RELEASE_ARTIFACTS=PASS'
}
