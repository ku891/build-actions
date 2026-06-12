# 推送本地提交并触发 Mt798x 两个机型云编译
# 三个机型（含 x86_64）请用: .\scripts\push-and-trigger-builds.ps1
# 用法: $env:GH_TOKEN="github_pat_xxx"; .\scripts\push-and-trigger-mt798x.ps1

param(
    [string]$Token = $env:GH_TOKEN,
    [string]$Repo = "ku891/build-actions",
    [string]$Branch = "main"
)

& (Join-Path $PSScriptRoot "push-and-trigger-builds.ps1") -Token $Token -Repo $Repo -Branch $Branch -Mt798xOnly
