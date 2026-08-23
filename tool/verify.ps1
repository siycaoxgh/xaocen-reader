# XAOCEN Reader v4 - unified verification gate
# Steps: pub get / format check / analyze / test / integration test /
# canonical Windows release / Android release / git diff --check
# Any failure returns non-zero exit code; stderr is not swallowed.
# -SkipIntegration: skip the integration_test step (used when no device is attached).
param(
    [switch]$SkipIntegration
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

# Prefer the repository user's normal SDK location, then PATH. This also
# supports the common develop\flutter layout used by the XAOCEN build host.
$flutterBin = $null
$dartBin = $null
foreach ($sdkRoot in @(
    (Join-Path $env:USERPROFILE 'develop\flutter'),
    (Join-Path $env:USERPROFILE 'flutter')
)) {
    $candidateFlutter = Join-Path $sdkRoot 'bin\flutter.bat'
    $candidateDart = Join-Path $sdkRoot 'bin\dart.bat'
    if ((Test-Path -LiteralPath $candidateFlutter -PathType Leaf) -and
        (Test-Path -LiteralPath $candidateDart -PathType Leaf)) {
        $flutterBin = $candidateFlutter
        $dartBin = $candidateDart
        break
    }
}
if ($null -eq $flutterBin) {
    $flutterCommand = Get-Command flutter.bat -ErrorAction SilentlyContinue
    if ($null -eq $flutterCommand) {
        $flutterCommand = Get-Command flutter -ErrorAction SilentlyContinue
    }
    $dartCommand = Get-Command dart.bat -ErrorAction SilentlyContinue
    if ($null -eq $dartCommand) {
        $dartCommand = Get-Command dart -ErrorAction SilentlyContinue
    }
    if ($null -eq $flutterCommand -or $null -eq $dartCommand) {
        throw 'Flutter/Dart SDK not found. Add flutter and dart to PATH or place the SDK under %USERPROFILE%\develop\flutter.'
    }
    $flutterBin = if ($flutterCommand.Source) { $flutterCommand.Source } else { $flutterCommand.Path }
    $dartBin = if ($dartCommand.Source) { $dartCommand.Source } else { $dartCommand.Path }
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
    @{ Name = 'canonical Windows Standard Release'; Cmd = { & (Join-Path $root 'tool\build_windows_engine.ps1') -Engine Standard -Configuration Release } },
    # Release is the distributable baseline: it avoids shipping the large
    # debug kernel/validation layer while retaining the same universal ABI
    # coverage for device and emulator smoke installation.
    @{ Name = 'flutter build apk --release';        Cmd = { & $flutterBin build apk --release } },
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
