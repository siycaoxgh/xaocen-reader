<##
XAOCEN Windows build selector.

This is the single build-time switch for the Windows engine:

  .\tool\build_windows_engine.ps1 -Engine Standard
  .\tool\build_windows_engine.ps1 -Engine Patched

The default is Standard.  Patched is staged only after the revision and
artifact guards pass.  The Flutter SDK and its global cache are never edited.
The selected bundle is always staged at one canonical path:
  artifacts\windows\current\<Configuration>
The engine-selection.json beside the executable is the only build-selection
truth; older standard/patched staging directories are not authoritative.
##>
[CmdletBinding()]
param(
    [ValidateSet('Standard', 'Patched')]
    [string]$Engine = 'Standard',

    [ValidateSet('Release', 'Debug')]
    [string]$Configuration = 'Release',

    [switch]$Smoke
)

$ErrorActionPreference = 'Stop'
$Root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$Flutter = $null
$flutterCandidates = @(
    (Join-Path $env:USERPROFILE 'develop\flutter\bin\flutter.bat'),
    (Join-Path $env:USERPROFILE 'flutter\bin\flutter.bat')
)
foreach ($candidate in $flutterCandidates) {
    if (Test-Path -LiteralPath $candidate -PathType Leaf) {
        $Flutter = $candidate
        break
    }
}
if ($null -eq $Flutter) {
    $flutterCommand = Get-Command flutter.bat -ErrorAction SilentlyContinue
    if ($null -eq $flutterCommand) {
        $flutterCommand = Get-Command flutter -ErrorAction SilentlyContinue
    }
    if ($null -ne $flutterCommand) {
        $Flutter = if ($flutterCommand.Source) {
            $flutterCommand.Source
        } else {
            $flutterCommand.Path
        }
    }
}
if ($null -eq $Flutter -or -not (Test-Path -LiteralPath $Flutter -PathType Leaf)) {
    throw 'Flutter SDK not found. Add flutter to PATH or place it under %USERPROFILE%\flutter or %USERPROFILE%\develop\flutter.'
}

$ManifestPath = Join-Path $Root 'windows_engine_patches\patched_engine_artifact.json'
$FlutterJson = (& $Flutter --version --machine | Out-String).Trim()
if ([string]::IsNullOrWhiteSpace($FlutterJson)) {
    throw 'Unable to read Flutter engine revision.'
}
$FlutterInfo = $FlutterJson | ConvertFrom-Json
$FlutterEngineRevision = [string]$FlutterInfo.engineRevision
$SourceCommit = (& git -C $Root rev-parse HEAD 2>$null | Out-String).Trim()
if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($SourceCommit)) {
    throw 'Unable to resolve the XAOCEN source commit for the build manifest.'
}
$SourceStatus = (& git -C $Root status --porcelain --untracked-files=normal 2>$null | Out-String).Trim()
if ($LASTEXITCODE -ne 0) {
    throw 'Unable to read XAOCEN source status for the build manifest.'
}
$SourceDirty = -not [string]::IsNullOrWhiteSpace($SourceStatus)

function Invoke-Flutter {
    param([Parameter(Mandatory = $true)][string[]]$Arguments)
    & $Flutter @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw "Flutter command failed with exit code ${LASTEXITCODE}: flutter $($Arguments -join ' ')"
    }
}

function Get-Sha256 {
    param([Parameter(Mandatory = $true)][string]$Path)
    return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToUpperInvariant()
}

function Assert-PatchedArtifact {
    if (-not (Test-Path -LiteralPath $ManifestPath)) {
        throw "Patched artifact manifest is missing: $ManifestPath"
    }
    $manifest = Get-Content -LiteralPath $ManifestPath -Raw | ConvertFrom-Json
    if ([string]$manifest.engineRevision -ne $FlutterEngineRevision) {
        throw "Patched Engine revision mismatch. Flutter=$FlutterEngineRevision Patched=$($manifest.engineRevision)"
    }

    $artifact = [string]$manifest.artifactPath
    if (-not (Test-Path -LiteralPath $artifact -PathType Leaf)) {
        throw "Patched Engine artifact is missing: $artifact"
    }
    $actualHash = Get-Sha256 $artifact
    if ($actualHash -ne ([string]$manifest.artifactSha256).ToUpperInvariant()) {
        throw "Patched Engine artifact hash mismatch. Expected=$($manifest.artifactSha256) Actual=$actualHash"
    }
    if ($Configuration -eq 'Release' -and
        $artifact -match '\\host_debug(?:_unopt)?(?:\\|$)') {
        throw "Patched Release requires an AOT-compatible release Engine artifact; refusing host_debug artifact: $artifact"
    }

    $patchObject = [string]$manifest.patchObjectPath
    if (-not (Test-Path -LiteralPath $patchObject -PathType Leaf)) {
        throw "Patched object is missing: $patchObject"
    }
    $patchSources = @($manifest.patchSourcePaths)
    foreach ($source in $patchSources) {
        if (-not (Test-Path -LiteralPath ([string]$source) -PathType Leaf)) {
            throw "Patched source is missing: $source"
        }
    }

    $ninja = [string]$manifest.ninjaPath
    $outDir = [string]$manifest.gnOutputDir
    if (-not (Test-Path -LiteralPath $ninja -PathType Leaf)) {
        throw "Ninja is missing: $ninja"
    }
    if (-not (Test-Path -LiteralPath (Join-Path $outDir 'build.ninja') -PathType Leaf)) {
        throw "Patched GN output is missing build.ninja: $outDir"
    }
    # This is the link-graph guard: the patched object must be an input of the
    # actual flutter_windows.dll target, not merely present on disk.
    $query = (& $ninja -C $outDir -t query flutter_windows.dll 2>&1 | Out-String)
    if ($query -notmatch [regex]::Escape((Split-Path -Leaf $patchObject))) {
        throw 'Patched object is not present in the flutter_windows.dll build graph.'
    }

    return [pscustomobject]@{
        ArtifactPath = $artifact
        ArtifactSha256 = $actualHash
        EngineRevision = $FlutterEngineRevision
        PatchObjectPath = $patchObject
        ManifestPath = $ManifestPath
    }
}

$patched = $null
if ($Engine -eq 'Patched') {
    $patched = Assert-PatchedArtifact
}

$mode = $Engine.ToLowerInvariant()
$config = $Configuration.ToLowerInvariant()
$flutterOutput = Join-Path $Root "build\windows\x64\runner\$Configuration"
$stageRoot = Join-Path $Root "artifacts\windows\current\$Configuration"
$stageBoundary = [IO.Path]::GetFullPath((Join-Path $Root 'artifacts\windows'))
$stageFullPath = [IO.Path]::GetFullPath($stageRoot)
if (-not $stageFullPath.StartsWith($stageBoundary + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) {
    throw "Refusing to stage outside the generated artifacts boundary: $stageFullPath"
}

Write-Host "Engine selection: $Engine"
Write-Host "Flutter engine revision: $FlutterEngineRevision"
Write-Host "Building standard Flutter Windows bundle before staging $Engine artifact..."
Invoke-Flutter @('build', 'windows', "--$config")

if (-not (Test-Path -LiteralPath $flutterOutput -PathType Container)) {
    throw "Flutter Windows output is missing: $flutterOutput"
}

if (Test-Path -LiteralPath $stageRoot) {
    # This exact directory is owned by this selector and is never the normal
    # Flutter build output or a user-data directory.
    Remove-Item -LiteralPath $stageRoot -Recurse -Force
}
New-Item -ItemType Directory -Path $stageRoot -Force | Out-Null
Copy-Item -Path (Join-Path $flutterOutput '*') -Destination $stageRoot -Recurse -Force

$stagedDll = Join-Path $stageRoot 'flutter_windows.dll'
if (-not (Test-Path -LiteralPath $stagedDll -PathType Leaf)) {
    throw "Staged Flutter Windows DLL is missing: $stagedDll"
}

$standardHash = Get-Sha256 $stagedDll
$source = 'Flutter SDK build output'
$selectionStatus = 'STANDARD_ENGINE'
if ($Engine -eq 'Patched') {
    Copy-Item -LiteralPath $patched.ArtifactPath -Destination $stagedDll -Force
    $stagedHash = Get-Sha256 $stagedDll
    if ($stagedHash -ne $patched.ArtifactSha256) {
        throw "Staged patched DLL hash mismatch. Expected=$($patched.ArtifactSha256) Actual=$stagedHash"
    }
    $source = $patched.ArtifactPath
    $selectionStatus = 'XAOCEN_PATCHED_ENGINE'
} else {
    $stagedHash = $standardHash
}

$selection = [ordered]@{
    schemaVersion = 1
    selection = $selectionStatus
    engineMode = $Engine
    configuration = $Configuration
    engineRevision = $FlutterEngineRevision
    flutterFrameworkVersion = [string]$FlutterInfo.frameworkVersion
    sourceCommit = $SourceCommit
    sourceDirty = $SourceDirty
    artifactSource = $source
    stagedDll = $stagedDll
    stagedDllSha256 = $stagedHash
    standardDllSha256BeforeStaging = $standardHash
    generatedAtUtc = (Get-Date).ToUniversalTime().ToString('o')
}
$selection | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath (Join-Path $stageRoot 'engine-selection.json') -Encoding UTF8

Write-Host "Staged bundle: $stageRoot"
Write-Host "Staged DLL SHA-256: $stagedHash"

if ($Smoke) {
    $exe = Join-Path $stageRoot 'xaocen_reader.exe'
    if (-not (Test-Path -LiteralPath $exe -PathType Leaf)) {
        throw "Staged executable is missing: $exe"
    }
    $process = Start-Process -FilePath $exe -WorkingDirectory $stageRoot -PassThru
    try {
        Start-Sleep -Seconds 8
        if ($process.HasExited) {
            throw "Smoke process exited with code $($process.ExitCode)."
        }
        Write-Host "Launch smoke: PASS (PID $($process.Id))"
    } finally {
        if (-not $process.HasExited) {
            Stop-Process -Id $process.Id -Force
            $process.WaitForExit()
        }
    }
}

Write-Host "BUILD_SELECTION=$Engine"
Write-Host "BUILD_OUTPUT=$stageRoot"
Write-Host "ENGINE_REVISION=$FlutterEngineRevision"
