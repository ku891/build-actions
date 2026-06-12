# 推送本地提交并触发云编译
# 用法: $env:GH_TOKEN="github_pat_xxx"; .\scripts\push-and-trigger-builds.ps1
# Immortalwrt 三机型: .\scripts\push-and-trigger-builds.ps1 -ImmortalwrtOnly
# 仅触发不推送: 加 -SkipPush

param(
    [string]$Token = $env:GH_TOKEN,
    [string]$Repo = "ku891/build-actions",
    [string]$Branch = "main",
    [switch]$SkipPush,
    [switch]$Mt798xOnly,
    [switch]$ImmortalwrtOnly
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Set-Location $root

if ($Mt798xOnly -and $ImmortalwrtOnly) {
    throw "不能同时指定 -Mt798xOnly 与 -ImmortalwrtOnly"
}

if (-not $Token) {
    $secure = Read-Host "请输入 GitHub Personal Access Token (需 repo + workflow 权限)" -AsSecureString
    $Token = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
        [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)
    )
}

if (-not $Token) { throw "未提供 GitHub Token" }

$headers = @{
    Authorization          = "Bearer $Token"
    Accept                 = "application/vnd.github+json"
    "X-GitHub-Api-Version" = "2022-11-28"
}

$noticeOff = [char]0x5173 + [char]0x95ed  # 关闭

function Invoke-WorkflowBuild {
    param(
        [string]$WorkflowFile,
        [string]$Label,
        [hashtable]$Inputs
    )
    $body = @{
        ref    = $Branch
        inputs = $Inputs
    } | ConvertTo-Json -Depth 5

    $uri = "https://api.github.com/repos/$Repo/actions/workflows/$WorkflowFile/dispatches"
    Write-Host "==> 触发: $Label"
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($body)
    Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -Body $bytes -ContentType "application/json; charset=utf-8"
}

if (-not $SkipPush) {
    Write-Host "==> 推送本地提交到 GitHub ..."
    $pushUrl = "https://x-access-token:${Token}@github.com/${Repo}.git"
    git push $pushUrl "${Branch}:${Branch}"
    if ($LASTEXITCODE -ne 0) { throw "git push 失败" }
} else {
    Write-Host "==> 跳过推送 (-SkipPush)"
}

$immortalwrtCommon = @{
    REPO_BRANCH            = "openwrt-24.10"
    INFORMATION_NOTICE     = $noticeOff
    KEEP_WORKFLOWS         = "50"
    KEEP_RELEASES          = "30"
    SSH_ACTION             = "false"
    UPLOAD_FIRMWARE        = "true"
    UPLOAD_RELEASE         = "false"
    CACHEWRTBUILD_SWITCH   = "true"
    UPDATE_FIRMWARE_ONLINE = "true"
}

$mt798xCommon = @{
    REPO_BRANCH            = "openwrt-24.10-6.6"
    INFORMATION_NOTICE     = $noticeOff
    KEEP_WORKFLOWS         = "50"
    KEEP_RELEASES          = "30"
    SSH_ACTION             = "false"
    UPLOAD_FIRMWARE        = "true"
    UPLOAD_RELEASE         = "false"
    CACHEWRTBUILD_SWITCH   = "true"
    UPDATE_FIRMWARE_ONLINE = "true"
}

Write-Host "==> 创建云编译任务 ..."

if ($ImmortalwrtOnly) {
    foreach ($cfg in @("x86_64", "redmi-ax6000", "cudy-tr3000-256m")) {
        Invoke-WorkflowBuild -WorkflowFile "Immortalwrt.yml" -Label "Immortalwrt / $cfg" -Inputs (@{
            CONFIG_FILE = $cfg
        } + $immortalwrtCommon)
        Start-Sleep -Seconds 3
    }
} elseif ($Mt798xOnly) {
    foreach ($cfg in @("redmi-ax6000", "cudy_tr3000-v1-256mb")) {
        Invoke-WorkflowBuild -WorkflowFile "Mt798x.yml" -Label "Mt798x / $cfg" -Inputs (@{
            CONFIG_FILE = $cfg
        } + $mt798xCommon)
        Start-Sleep -Seconds 3
    }
} else {
    foreach ($cfg in @("redmi-ax6000", "cudy_tr3000-v1-256mb")) {
        Invoke-WorkflowBuild -WorkflowFile "Mt798x.yml" -Label "Mt798x / $cfg" -Inputs (@{
            CONFIG_FILE = $cfg
        } + $mt798xCommon)
        Start-Sleep -Seconds 3
    }
    Invoke-WorkflowBuild -WorkflowFile "Immortalwrt.yml" -Label "Immortalwrt / x86_64" -Inputs (@{
        CONFIG_FILE = "x86_64"
    } + $immortalwrtCommon)
}

Write-Host ""
Write-Host "Done: https://github.com/$Repo/actions"
if ($ImmortalwrtOnly) {
    Write-Host "  Immortalwrt x3: x86_64, redmi-ax6000, cudy-tr3000-256m"
} elseif ($Mt798xOnly) {
    Write-Host "  Mt798x x2: redmi-ax6000, cudy_tr3000-v1-256mb"
} else {
    Write-Host "  Mt798x x2 + Immortalwrt x86_64 (3 jobs total)"
}
