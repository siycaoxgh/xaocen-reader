<#
.SYNOPSIS
Authenticode-signs selected XAOCEN Windows release files with an existing
code-signing certificate from the Windows certificate store.

.DESCRIPTION
This script never creates, imports, or exports a certificate. By default it
signs only the canonical staged XAOCEN executable. Pass -Target explicitly to
sign an installer or another project-owned PE file after it has been built.
#>
[CmdletBinding()]
param(
    [string[]]$Target,

    [string]$CertificateThumbprint = $env:XAOCEN_WINDOWS_CERT_THUMBPRINT,

    [ValidateSet('CurrentUser', 'LocalMachine')]
    [string]$CertificateStore = 'CurrentUser',

    [string]$TimestampUrl = 'http://timestamp.digicert.com',

    [string]$SignToolPath = $env:XAOCEN_SIGNTOOL_PATH
)

$ErrorActionPreference = 'Stop'
$Root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path

if ($null -eq $Target -or $Target.Count -eq 0) {
    $Target = @(
        (Join-Path $Root 'artifacts\windows\current\Release\xaocen_reader.exe')
    )
}

if ([string]::IsNullOrWhiteSpace($CertificateThumbprint)) {
    throw 'Windows signing certificate thumbprint is missing. Pass -CertificateThumbprint or set XAOCEN_WINDOWS_CERT_THUMBPRINT.'
}

$thumbprint = ($CertificateThumbprint -replace '[^0-9A-Fa-f]', '').ToUpperInvariant()
if ($thumbprint.Length -ne 40) {
    throw 'Windows signing certificate thumbprint must contain exactly 40 hexadecimal characters.'
}

$certificatePath = "Cert:\$CertificateStore\My\$thumbprint"
if (-not (Test-Path -LiteralPath $certificatePath -PathType Leaf)) {
    throw "Windows signing certificate was not found at $certificatePath. Import the real code-signing certificate outside this repository first."
}

if (-not [string]::IsNullOrWhiteSpace($SignToolPath)) {
    if (-not (Test-Path -LiteralPath $SignToolPath -PathType Leaf)) {
        throw "signtool.exe was not found at the configured path: $SignToolPath"
    }
    $resolvedSignTool = (Resolve-Path -LiteralPath $SignToolPath).Path
} else {
    $signToolCommand = Get-Command signtool.exe -ErrorAction SilentlyContinue
    if ($null -ne $signToolCommand) {
        $resolvedSignTool = if ($signToolCommand.Source) {
            $signToolCommand.Source
        } else {
            $signToolCommand.Path
        }
    } else {
        $windowsKitsRoot = Join-Path ${env:ProgramFiles(x86)} 'Windows Kits\10\bin'
        $resolvedSignTool = Get-ChildItem -LiteralPath $windowsKitsRoot -Filter signtool.exe -File -Recurse -ErrorAction SilentlyContinue |
            Where-Object { $_.FullName -match '\\x64\\signtool\.exe$' } |
            Sort-Object -Property LastWriteTimeUtc -Descending |
            Select-Object -First 1 -ExpandProperty FullName
    }
}

if ([string]::IsNullOrWhiteSpace($resolvedSignTool)) {
    throw 'signtool.exe was not found. Install the Windows SDK, add signtool.exe to PATH, or set XAOCEN_SIGNTOOL_PATH.'
}

$resolvedTargets = @(
    foreach ($candidate in $Target) {
        if (-not (Test-Path -LiteralPath $candidate -PathType Leaf)) {
            throw "Windows signing target does not exist: $candidate"
        }
        (Resolve-Path -LiteralPath $candidate).Path
    }
)

foreach ($resolvedTarget in $resolvedTargets) {
    $signArguments = @(
        'sign',
        '/sha1', $thumbprint,
        '/fd', 'SHA256',
        '/tr', $TimestampUrl,
        '/td', 'SHA256'
    )
    if ($CertificateStore -eq 'LocalMachine') {
        $signArguments += '/sm'
    }
    $signArguments += $resolvedTarget

    Write-Host "Signing: $resolvedTarget"
    & $resolvedSignTool @signArguments
    if ($LASTEXITCODE -ne 0) {
        throw "signtool sign failed with exit code $LASTEXITCODE for: $resolvedTarget"
    }

    & $resolvedSignTool verify /pa /v $resolvedTarget
    if ($LASTEXITCODE -ne 0) {
        throw "signtool verify failed with exit code $LASTEXITCODE for: $resolvedTarget"
    }
}

Write-Host "WINDOWS_SIGNING=PASS"
Write-Host "SIGNED_FILE_COUNT=$($resolvedTargets.Count)"
