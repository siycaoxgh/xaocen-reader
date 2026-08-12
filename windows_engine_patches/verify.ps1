param(
  [Parameter(Mandatory = $true)]
  [string]$EngineRoot
)

$ErrorActionPreference = 'Stop'
$infra = Split-Path -Parent $MyInvocation.MyCommand.Path
$manifest = Get-Content (Join-Path $infra 'manifest.json') -Raw | ConvertFrom-Json
$engineRoot = (Resolve-Path $EngineRoot).Path

function Invoke-Git([string[]]$Arguments) {
  $output = & git -C $engineRoot @Arguments
  if ($LASTEXITCODE -ne 0) { throw "git $($Arguments -join ' ') failed" }
  return ($output -join "`n").Trim()
}

$head = Invoke-Git @('rev-parse', 'HEAD')
if ($head -ne $manifest.engineRevision) { throw "Engine revision mismatch: $head" }
$patchPath = Join-Path $infra $manifest.patch
if ((Get-FileHash $patchPath -Algorithm SHA256).Hash.ToLowerInvariant() -ne $manifest.patchSha256) {
  throw 'Patch SHA-256 mismatch'
}

foreach ($path in $manifest.touchedFiles) {
  $absolute = Join-Path $engineRoot $path
  if (-not (Test-Path $absolute)) {
    # Files introduced by the patch are intentionally absent before apply.
    # Existing upstream files must still be present before any verification.
    $patchText = Get-Content $patchPath -Raw
    $escapedPath = [regex]::Escape("b/$path")
    if ($patchText -notmatch "(?ms)new file mode 100644.*?\+\+\+ $escapedPath(?:\r?\n|$)") {
      throw "Missing upstream file: $path"
    }
  }
}
$root = Join-Path $engineRoot 'engine/src/flutter/shell/platform/windows'
$sources = Get-ChildItem $root -Recurse -File | Where-Object {
  $relative = $_.FullName.Substring($engineRoot.Length + 1).Replace('\', '/')
  $manifest.touchedFiles -contains $relative
}
$joined = (($sources | ForEach-Object { Get-Content $_.FullName -Raw }) -join "`n")
foreach ($forbidden in @('UpdateLayeredWindow', 'SetLayeredWindowAttributes', 'glReadPixels', 'CopyResource')) {
  if ($joined.Contains($forbidden)) { throw "Forbidden path/API found: $forbidden" }
}
$build = Get-Content (Join-Path $root 'BUILD.gn') -Raw
$patchText = Get-Content $patchPath -Raw
foreach ($library in @('dcomp.lib', 'd3d11.lib', 'dxgi.lib')) {
  if (-not $build.Contains($library) -and -not $patchText.Contains($library)) {
    throw "Missing native library: $library"
  }
}
Write-Output "Patch verification passed for engine $head"
