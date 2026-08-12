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
if ($head -ne $manifest.engineRevision) {
  throw "Refusing patch: engine HEAD $head does not match $($manifest.engineRevision)"
}
$patchPath = Join-Path $infra $manifest.patch
$patchHash = (Get-FileHash $patchPath -Algorithm SHA256).Hash.ToLowerInvariant()
if ($patchHash -ne $manifest.patchSha256) { throw 'Refusing patch: patch SHA-256 mismatch' }

foreach ($property in $manifest.upstreamBlobSha1.psobject.Properties) {
  $actual = Invoke-Git @('rev-parse', "$($manifest.engineRevision):$($property.Name)")
  if ($actual -ne $property.Value) { throw "Refusing patch: upstream hash mismatch for $($property.Name)" }
}
$status = @(Invoke-Git @('status', '--porcelain')) | Where-Object {
  # _bad_scm is a bootstrap diagnostic directory outside the pinned engine
  # source; it is intentionally preserved and does not affect patch inputs.
  $_ -and ($_ -notmatch '^\?\? _bad_scm(?:/|\\)?$')
}
if ($status.Count -ne 0) { throw "Refusing patch: engine worktree is not clean`n$($status -join "`n")" }

& git -C $engineRoot apply --check --whitespace=error $patchPath
if ($LASTEXITCODE -ne 0) { throw 'git apply --check failed' }
& git -C $engineRoot apply --whitespace=error $patchPath
if ($LASTEXITCODE -ne 0) { throw 'git apply failed' }
Write-Output "Applied $($manifest.patch) to engine $head"
