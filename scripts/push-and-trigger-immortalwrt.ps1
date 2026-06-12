# 推送本地提交并触发 Immortalwrt 三个机型云编译：
#   x86_64、redmi-ax6000、cudy-tr3000-256m
# 用法: $env:GH_TOKEN="github_pat_xxx"; .\scripts\push-and-trigger-immortalwrt.ps1

param(
    [string]$Token = $env:GH_TOKEN,
    [string]$Repo = "ku891/build-actions",
    [string]$Branch = "main",
    [switch]$SkipPush
)

& (Join-Path $PSScriptRoot "push-and-trigger-builds.ps1") -Token $Token -Repo $Repo -Branch $Branch -SkipPush:$SkipPush -ImmortalwrtOnly
