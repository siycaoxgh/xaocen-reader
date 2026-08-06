# XAOCEN Reader v4 — 统一验证脚本
# M0 默认执行：
#   flutter pub get
#   dart format --output=none --set-exit-if-changed .
#   flutter analyze
#   flutter test
#   flutter build windows --release
#   flutter build apk --debug
#   git diff --check
#
# 要求：
#   - 任一步失败返回非零退出码
#   - 不吞 stderr
#   - 输出每一步名称和耗时
#   - 不读取用户外部 TXT
#   - 不修改三份权威规范
#   - 不提交 build 产物
param(
    [switch]$SkipIntegration  # 预留：integration_test 在尚无真实流程时可暂不运行
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

$steps = @(
    @{ Name = 'flutter pub get';            Cmd = { & flutter pub get } },
    @{ Name = 'dart format check';          Cmd = { & dart format --output=none --set-exit-if-changed . } },
    @{ Name = 'flutter analyze';            Cmd = { & flutter analyze } },
    @{ Name = 'flutter test';               Cmd = { & flutter test } },
    @{ Name = 'flutter build windows --release'; Cmd = { & flutter build windows --release } },
    @{ Name = 'flutter build apk --debug';  Cmd = { & flutter build apk --debug } },
    @{ Name = 'git diff --check';           Cmd = { & git diff --check } }
)

$failed = $false
foreach ($step in $steps) {
    $name = $step.Name
    Write-Host "`n=== [$name] ===" -ForegroundColor Cyan
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
    Write-Host "`nVERIFY FAILED" -ForegroundColor Red
    exit 1
}
Write-Host "`nVERIFY PASSED (all steps)" -ForegroundColor Green
exit 0
