# XAOCEN Reader v4 - unified verification gate (M0 -> M2)
# Steps: pub get / format check / analyze / test / integration test / windows release / apk debug / git diff --check
# Any failure returns non-zero exit code; stderr is not swallowed.
# -SkipIntegration: skip the integration_test step (used when no device is attached).
param(
    [switch]$SkipIntegration
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

# flutter/dart are not on PATH in this environment; use the known SDK location.
$flutterBin = Join-Path $env:USERPROFILE 'flutter\bin\flutter.bat'
$dartBin = Join-Path $env:USERPROFILE 'flutter\bin\dart.bat'
if (-not (Test-Path $flutterBin)) {
    $flutterBin = 'flutter'
    $dartBin = 'dart'
}

$steps = @(
    @{ Name = 'flutter pub get';                   Cmd = { & $flutterBin pub get } },
    @{ Name = 'dart format check';                 Cmd = { & $dartBin format --output=none --set-exit-if-changed lib test integration_test tool } },
    @{ Name = 'flutter analyze';                   Cmd = { & $flutterBin analyze } },
    @{ Name = 'flutter test';                      Cmd = { & $flutterBin test } }
)

# integration_test: only when directory exists and not skipped
# Running multiple files in one command can break the Windows debug connection,
# so each file is executed in its own step.
$itDir = Join-Path $root 'integration_test'
if (-not $SkipIntegration -and (Test-Path $itDir)) {
    $itFiles = Get-ChildItem -Path $itDir -Filter '*_test.dart'
    foreach ($itf in $itFiles) {
        $stepName = "flutter test integration_test/$($itf.Name)"
        # Script blocks capture loop variable values lazily; GetNewClosure snapshots the current iteration.
        $sb = { & $flutterBin test $itf.FullName -d windows }
        $stepCmd = $sb.GetNewClosure()
        $steps += @{ Name = $stepName; Cmd = $stepCmd }
    }
}

$steps += @(
    @{ Name = 'flutter build windows --release';   Cmd = { & $flutterBin build windows --release } },
    @{ Name = 'flutter build apk --debug';         Cmd = { & $flutterBin build apk --debug } },
    @{ Name = 'git diff --check';                  Cmd = { & git diff --check } }
)

$failed = $false
foreach ($step in $steps) {
    $name = $step.Name
    Write-Host ""
    Write-Host "=== [$name] ===" -ForegroundColor Cyan
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    try {
        & $step.Cmd
        if ($LASTEXITCODE -ne 0) {
            throw "exit code $LASTEXITCODE"
        }
        $sw.Stop()
        Write-Host "[$name] PASS ($($sw.ElapsedMilliseconds) ms)" -ForegroundColor Green
    } catch {
        $sw.Stop()
        Write-Host "[$name] FAIL ($($sw.ElapsedMilliseconds) ms): $_" -ForegroundColor Red
        $failed = $true
        break
    }
}

if ($failed) {
    Write-Host ""
    Write-Host "VERIFY FAILED" -ForegroundColor Red
    exit 1
}
Write-Host ""
Write-Host "VERIFY PASSED (all steps)" -ForegroundColor Green
exit 0
