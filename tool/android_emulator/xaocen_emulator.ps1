param(
  [ValidateSet('start','wait','install','launch','logcat','screenshot','status','smoke')]
  [string]$Action = 'status',
  [string]$AvdName = 'xaocen_api35_x86_64',
  [string]$Serial,
  [string]$LogPath,
  [string]$ScreenshotPath
)
$ErrorActionPreference = 'Stop'
$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$SdkRoot = if ($env:ANDROID_SDK_ROOT) { $env:ANDROID_SDK_ROOT } elseif ($env:ANDROID_HOME) { $env:ANDROID_HOME } else { 'C:\Users\TOM\AppData\Local\Android\Sdk' }
$Adb = Join-Path $SdkRoot 'platform-tools\adb.exe'
$Emulator = Join-Path $SdkRoot 'emulator\emulator.exe'
$Package = 'com.xaocen.xaocen_reader'
$Apk = Join-Path $RepoRoot 'build\app\outputs\flutter-apk\app-debug.apk'
function Assert-Tool([string]$Path) { if (-not (Test-Path -LiteralPath $Path)) { throw "Missing Android tool: $Path" } }
function Get-EmulatorSerial {
  Assert-Tool $Adb
  if ($Serial) { return $Serial }
  $line = (& $Adb devices | Select-String '^emulator-\d+\s+device$' | Select-Object -First 1)
  if (-not $line) { throw 'No online emulator-* device. Run -Action start first.' }
  return (($line.ToString() -split '\s+')[0])
}
function Wait-Emulator {
  Assert-Tool $Adb; $deadline = (Get-Date).AddSeconds(180)
  while ((Get-Date) -lt $deadline) {
    $line = (& $Adb devices | Select-String '^emulator-\d+\s+device$' | Select-Object -First 1)
    if ($line) { $found = (($line.ToString() -split '\s+')[0]); if ((& $Adb -s $found shell getprop sys.boot_completed 2>$null).Trim() -eq '1') { return $found } }
    Start-Sleep -Seconds 3
  }
  throw 'Timed out waiting for an online, boot-complete emulator.'
}
switch ($Action) {
  'start' { Assert-Tool $Emulator; if (-not (& $Adb devices | Select-String '^emulator-\d+\s+device$')) { Start-Process -FilePath $Emulator -ArgumentList @('-avd',$AvdName,'-gpu','auto','-no-boot-anim') -WindowStyle Hidden | Out-Null }; Write-Output ("emulator="+(Wait-Emulator)+" avd="+$AvdName) }
  'wait' { Write-Output (Wait-Emulator) }
  'status' { Assert-Tool $Adb; & $Adb devices -l }
  'install' { $s=Get-EmulatorSerial; if (-not (Test-Path -LiteralPath $Apk)) { throw "Debug APK not found: $Apk" }; & $Adb -s $s install -r $Apk }
  'launch' { & $Adb -s (Get-EmulatorSerial) shell monkey -p $Package 1 }
  'logcat' { $s=Get-EmulatorSerial; if (-not $LogPath) { $LogPath=Join-Path $RepoRoot 'artifacts\android-emulator\logcat.txt' }; New-Item -ItemType Directory -Force (Split-Path -Parent $LogPath) | Out-Null; & $Adb -s $s logcat -d | Out-File -Encoding utf8 $LogPath; Write-Output $LogPath }
  'screenshot' { $s=Get-EmulatorSerial; if (-not $ScreenshotPath) { $ScreenshotPath=Join-Path $RepoRoot 'artifacts\android-emulator\screen.png' }; New-Item -ItemType Directory -Force (Split-Path -Parent $ScreenshotPath) | Out-Null; $p=New-Object Diagnostics.Process; $p.StartInfo.FileName=$Adb; $p.StartInfo.Arguments="-s $s exec-out screencap -p"; $p.StartInfo.UseShellExecute=$false; $p.StartInfo.RedirectStandardOutput=$true; $p.Start()|Out-Null; $f=[IO.File]::Create($ScreenshotPath); $p.StandardOutput.BaseStream.CopyTo($f); $f.Dispose(); $p.WaitForExit(); Write-Output $ScreenshotPath }
  'smoke' { $s=Get-EmulatorSerial; & $Adb -s $s shell monkey -p $Package 1; Write-Output "launched=$Package serial=$s" }
}
