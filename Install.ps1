[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$AddonPath,
    [switch]$SkipDependencies,
    [switch]$IncludeNameplates,
    [switch]$Preview
)

$ErrorActionPreference = 'Stop'
$targetRoot = [IO.Path]::GetFullPath($AddonPath).TrimEnd('\', '/')
if (-not (Test-Path -LiteralPath $targetRoot -PathType Container) -or
    [IO.Path]::GetFileName($targetRoot) -ne 'AddOns') {
    throw 'Choose the existing _forever_\Interface\AddOns folder.'
}
if ([IO.Path]::GetFileName([IO.Path]::GetDirectoryName($targetRoot)) -ne 'Interface' -or
    [IO.Path]::GetFileName([IO.Path]::GetDirectoryName([IO.Path]::GetDirectoryName($targetRoot))) -ne '_forever_') {
    throw 'This kit is for the _forever_ client. Retail and Classic are not supported.'
}
$manifest = Get-Content -LiteralPath (Join-Path $PSScriptRoot 'dependencies.json') -Raw | ConvertFrom-Json
$packages = @($manifest.addons | Where-Object { $_.required -or $IncludeNameplates })
$plan = @()
if (-not $SkipDependencies) {
    foreach ($package in $packages) {
        $existing = @($package.folders | Where-Object { Test-Path -LiteralPath (Join-Path $targetRoot $_) })
        if ($existing.Count -eq $package.folders.Count) {
            Write-Host "Keep installed: $($package.id)"
        } elseif ($existing.Count -gt 0) {
            throw "Partial installation of $($package.id). No files were replaced."
        } else { $plan += $package }
    }
}
Write-Host "NightPro menu -> $targetRoot"
foreach ($package in $plan) { Write-Host "Download: $($package.id) - $($package.version)" }
& (Join-Path $PSScriptRoot 'Install-Bridges.ps1') -AddonPath $targetRoot -Preview
if ($Preview) { return }

Add-Type -AssemblyName System.IO.Compression.FileSystem
$sessionRoot = Join-Path ([IO.Path]::GetTempPath()) ('NightProKit-' + [guid]::NewGuid().ToString('N'))
$stageRoot = Join-Path $sessionRoot 'staged'
New-Item -ItemType Directory -Path $stageRoot -Force | Out-Null
foreach ($package in $plan) {
    if ($package.url -notmatch '^https://(edge\.forgecdn\.net|github\.com)/') { throw 'Unexpected download host.' }
    $archive = Join-Path $sessionRoot ($package.id + '.zip')
    Invoke-WebRequest -Uri $package.url -OutFile $archive -UseBasicParsing
    $actualHash = (Get-FileHash -LiteralPath $archive -Algorithm SHA256).Hash
    if ($actualHash -ne $package.sha256) { throw "Download verification failed: $($package.id). Nothing installed." }
    $zip = [IO.Compression.ZipFile]::OpenRead($archive)
    try {
        foreach ($entry in $zip.Entries) {
            $relative = $entry.FullName.Replace('/', '\')
            $parts = $relative.Split('\')
            $resolved = [IO.Path]::GetFullPath((Join-Path $stageRoot $relative))
            if ($relative.Contains(':') -or $relative.StartsWith('\') -or
                ($parts -contains '..') -or -not ($package.folders -contains $parts[0]) -or
                -not $resolved.StartsWith($stageRoot + '\', [StringComparison]::OrdinalIgnoreCase)) {
                throw "Unsafe archive entry in $($package.id). Nothing installed."
            }
            if (($entry.ExternalAttributes -shr 16 -band 0xF000) -eq 0xA000) { throw 'Archive symlinks are not supported.' }
        }
    } finally { $zip.Dispose() }
    [IO.Compression.ZipFile]::ExtractToDirectory($archive, $stageRoot)
}
foreach ($package in $plan) {
    foreach ($folder in $package.folders) {
        $staged = Join-Path $stageRoot $folder
        if (-not (Get-ChildItem -LiteralPath $staged -Filter '*.toc' -File)) { throw "No addon descriptor: $folder" }
        if (Test-Path -LiteralPath (Join-Path $targetRoot $folder)) { throw "Addon appeared during install: $folder. Nothing replaced." }
    }
}
$source = Join-Path $PSScriptRoot 'AddOns\NightProController'
$destination = Join-Path $targetRoot 'NightProController'
$backup = $null
if (Test-Path -LiteralPath $destination) {
    $backupRoot = Join-Path ([IO.Path]::GetDirectoryName($targetRoot)) 'NightProKitBackups'
    $backup = Join-Path $backupRoot ((Get-Date -Format 'yyyyMMdd-HHmmss') + '-' + [guid]::NewGuid().ToString('N').Substring(0,8))
    New-Item -ItemType Directory -Path $backup -Force | Out-Null
    Copy-Item -LiteralPath $destination -Destination $backup -Recurse
}
foreach ($package in $plan) {
    foreach ($folder in $package.folders) {
        Copy-Item -LiteralPath (Join-Path $stageRoot $folder) -Destination $targetRoot -Recurse
    }
}
New-Item -ItemType Directory -Path $destination -Force | Out-Null
Get-ChildItem -LiteralPath $source -File | ForEach-Object {
    Copy-Item -LiteralPath $_.FullName -Destination (Join-Path $destination $_.Name) -Force
}
& (Join-Path $PSScriptRoot 'Install-Bridges.ps1') -AddonPath $targetRoot
Write-Host 'Installed. Reopen WoW through Battle.net if this is a first install; otherwise use /reload outside combat.'
if ($backup) { Write-Host "Previous NightPro menu: $backup" }
Write-Host "Verified download cache: $sessionRoot"
