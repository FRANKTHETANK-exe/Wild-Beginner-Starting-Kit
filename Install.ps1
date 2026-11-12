[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)][string]$AddonPath,
    [switch]$SkipDependencies,
    [switch]$IncludeNameplates,
    [switch]$AllowMissingDependencies,
    [switch]$Preview
)
$ErrorActionPreference='Stop'
if (Get-Process -Name 'Wow','WowClassic','WowClassicT' -ErrorAction SilentlyContinue) { throw 'Close WoW before connecting or restoring addon source files. Nothing changed.' }
$sourceRoot=Join-Path $PSScriptRoot 'AddOns'
if (-not (Test-Path -LiteralPath $sourceRoot -PathType Container)) { $sourceRoot=Split-Path $PSScriptRoot -Parent }
$targetRoot=[IO.Path]::GetFullPath($AddonPath).TrimEnd('\','/')
if (-not (Test-Path -LiteralPath $targetRoot -PathType Container) -or $targetRoot -notmatch '[\\/]_forever_[\\/]Interface[\\/]AddOns$') {
    throw 'Choose the existing _forever_\Interface\AddOns folder. Retail and Classic are not supported.'
}
function Assert-UnlinkedPath([string]$Path) {
    $cursor=[IO.Path]::GetFullPath($Path)
    while ($cursor) {
        $item=Get-Item -LiteralPath $cursor -Force -ErrorAction SilentlyContinue
        if ($item -and ($item.Attributes -band [IO.FileAttributes]::ReparsePoint)) { throw "Linked path refused (including junctions): $cursor. Use the real directory path." }
        $parent=[IO.Path]::GetDirectoryName($cursor)
        if ($parent -eq $cursor) { break };$cursor=$parent
    }
}
Assert-UnlinkedPath $targetRoot
$manifest=Get-Content -LiteralPath (Join-Path $PSScriptRoot 'curseforge-dependencies.json') -Raw|ConvertFrom-Json
$missing=@()
foreach ($package in @($manifest.addons|Where-Object {$_.required -or $IncludeNameplates})) {
    foreach ($folder in $package.folders) {
        if (-not(Test-Path -LiteralPath (Join-Path $targetRoot $folder) -PathType Container)) { $missing+=$package;break }
    }
}
Write-Host 'Original addons must be installed through the authors'' CurseForge projects. This script does not download or repackage them.'
foreach ($package in $missing) { Write-Host "Missing original: $($package.name) - $($package.projectUrl)" }
if ($missing.Count -gt 0 -and -not $SkipDependencies -and -not $AllowMissingDependencies) { throw 'Install the listed original Forever addons with CurseForge, close WoW, then rerun. Nothing changed.' }
if ($AllowMissingDependencies) { Write-Host 'Partial setup explicitly requested. Absent original addons stay NOT LOADED; only installed, verified sources are connected.' }
if ($SkipDependencies) { Write-Host 'Dependency presence audit bypassed for an existing setup. The three bridge source files must still be recognized.' }
$ownedAddons=@('NightProController','NightProAdventureHub')
$copyPlan=@()
foreach ($folder in $ownedAddons) {
    $source=Join-Path $sourceRoot $folder;$destination=Join-Path $targetRoot $folder
    if (-not(Test-Path -LiteralPath $source -PathType Container)) { throw "Missing NightPro source folder: $folder. Nothing changed." }
    Assert-UnlinkedPath $source;Assert-UnlinkedPath $destination
    if ((Test-Path -LiteralPath $destination) -and -not(Test-Path -LiteralPath $destination -PathType Container)) { throw "NightPro destination is not a directory: $destination. Nothing changed." }
    if ([IO.Path]::GetFullPath($source) -eq [IO.Path]::GetFullPath($destination)) { continue }
    foreach ($file in Get-ChildItem -LiteralPath $source -File) {
        $target=Join-Path $destination $file.Name
        Assert-UnlinkedPath $file.FullName;Assert-UnlinkedPath $target
        $copyPlan+=@{Source=$file.FullName; File=$target; Folder=$destination; Relative=($folder+'\'+$file.Name)}
    }
}
# Verify every supported original source before staging or changing destinations.
& (Join-Path $PSScriptRoot 'Install-Bridges.ps1') -AddonPath $targetRoot -Preview -AllowMissingDependencies:$AllowMissingDependencies
Write-Host "NightPro-owned folders -> $targetRoot"
if ($Preview) { return }
$utf8=New-Object Text.UTF8Encoding($false)
function Get-OwnedHash([byte[]]$Bytes) {
    $sha=[Security.Cryptography.SHA256]::Create()
    try { [BitConverter]::ToString($sha.ComputeHash($Bytes)).Replace('-','') } finally { $sha.Dispose() }
}
function Set-OwnedFile([string]$Destination,[byte[]]$Bytes,[bool]$Existing) {
    Assert-UnlinkedPath $Destination
    $temp=$Destination+'.nightpro-'+[guid]::NewGuid().ToString('N')+'.tmp'
    try {
        [IO.File]::WriteAllBytes($temp,$Bytes)
        if ($Existing) { [IO.File]::Replace($temp,$Destination,[NullString]::Value) }
        else { [IO.File]::Move($temp,$Destination) }
    } finally { if (Test-Path -LiteralPath $temp) { Remove-Item -LiteralPath $temp -Force } }
}
function Assert-OwnedWritable([string]$Directory) {
    $probeDir=$Directory
    while (-not(Test-Path -LiteralPath $probeDir -PathType Container)) { $probeDir=[IO.Path]::GetDirectoryName($probeDir) }
    Assert-UnlinkedPath $probeDir
    $probe=Join-Path $probeDir ('.nightpro-write-check-'+[guid]::NewGuid().ToString('N')+'.tmp')
    try { $stream=[IO.File]::Open($probe,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None);$stream.Dispose() }
    finally { if (Test-Path -LiteralPath $probe) { Remove-Item -LiteralPath $probe -Force } }
}
$stageRoot=Join-Path ([IO.Path]::GetTempPath()) ('NightPro-owned-stage-'+[guid]::NewGuid().ToString('N'))
$backup=$null;$recordPath=$null;$written=@();$createdFolders=@();$plan=@();$phase='staging'
try {
    Assert-UnlinkedPath $stageRoot
    New-Item -ItemType Directory -Path $stageRoot -Force|Out-Null
    # Read every source into staging before any destination file is changed.
    foreach ($p in $copyPlan) {
        $staged=Join-Path $stageRoot $p.Relative
        New-Item -ItemType Directory -Path ([IO.Path]::GetDirectoryName($staged)) -Force|Out-Null
        [IO.File]::WriteAllBytes($staged,[IO.File]::ReadAllBytes($p.Source))
        $p.After=[IO.File]::ReadAllBytes($staged);$p.AfterHash=Get-OwnedHash $p.After
        Assert-UnlinkedPath $p.File
        $p.Existed=Test-Path -LiteralPath $p.File -PathType Leaf
        if ($p.Existed) {
            $p.Before=[IO.File]::ReadAllBytes($p.File);$p.BeforeHash=Get-OwnedHash $p.Before
            if ($p.BeforeHash -eq $p.AfterHash) { continue }
        } else { $p.Before=$null;$p.BeforeHash=$null }
        $plan+=$p
    }
    $phase='preflight'
    foreach ($folder in @($plan|ForEach-Object {$_.Folder}|Select-Object -Unique)) { Assert-OwnedWritable $folder }
    foreach ($p in $plan) {
        Assert-UnlinkedPath $p.File
        if ($p.Existed) {
            $handle=[IO.File]::Open($p.File,[IO.FileMode]::Open,[IO.FileAccess]::Write,[IO.FileShare]::ReadWrite)
            $handle.Dispose()
        }
    }
    if ($plan.Count) {
        $backup=Join-Path ([IO.Path]::GetDirectoryName($targetRoot)) ('NightProKitBackups\menu-'+(Get-Date -Format 'yyyyMMdd-HHmmss')+'-'+[guid]::NewGuid().ToString('N').Substring(0,8))
        Assert-UnlinkedPath $backup
        New-Item -ItemType Directory -Path $backup -Force|Out-Null
        foreach ($p in $plan) {
            if ($p.Existed) {
                $original=Join-Path $backup $p.Relative
                New-Item -ItemType Directory -Path ([IO.Path]::GetDirectoryName($original)) -Force|Out-Null
                [IO.File]::WriteAllBytes($original,$p.Before)
            }
        }
        $record=@{State='prepared'; Files=@($plan|ForEach-Object {@{Path=$_.Relative; Existed=$_.Existed; BeforeSHA256=$_.BeforeHash; AfterSHA256=$_.AfterHash}})}
        $recordPath=Join-Path $backup 'installation-record.json'
        [IO.File]::WriteAllText($recordPath,($record|ConvertTo-Json -Depth 6),$utf8)
        Write-Host "NightPro backup and recovery record: $backup"
    }
    $phase='owned-file commit'
    foreach ($p in $plan) {
        Assert-UnlinkedPath $p.File
        if ($p.Existed) {
            if ((Get-FileHash -LiteralPath $p.File -Algorithm SHA256).Hash -ne $p.BeforeHash) { throw "NightPro file changed during setup: $($p.Relative)" }
        } elseif (Test-Path -LiteralPath $p.File) { throw "NightPro file appeared during setup: $($p.Relative)" }
        if (-not(Test-Path -LiteralPath $p.Folder -PathType Container)) {
            New-Item -ItemType Directory -Path $p.Folder|Out-Null;$createdFolders+=$p.Folder
        }
        Set-OwnedFile $p.File $p.After $p.Existed
        $written+=$p
        if ((Get-FileHash -LiteralPath $p.File -Algorithm SHA256).Hash -ne $p.AfterHash) { throw "NightPro write verification failed: $($p.Relative)" }
    }
    $phase='bridge connection'
    & (Join-Path $PSScriptRoot 'Install-Bridges.ps1') -AddonPath $targetRoot -AllowMissingDependencies:$AllowMissingDependencies
    if ($recordPath) { $record.State='applied';[IO.File]::WriteAllText($recordPath,($record|ConvertTo-Json -Depth 6),$utf8) }
} catch {
    $failure=$_.Exception.Message;$rollbackFailed=@()
    for ($i=$written.Count-1;$i -ge 0;$i--) {
        $p=$written[$i]
        try {
            Assert-UnlinkedPath $p.File
            if ((Get-FileHash -LiteralPath $p.File -Algorithm SHA256).Hash -ne $p.AfterHash) { throw 'Externally changed file left untouched.' }
            if ($p.Existed) { Set-OwnedFile $p.File $p.Before $true }
            else { [IO.File]::Delete($p.File) }
        } catch { $rollbackFailed+=$p.Relative }
    }
    foreach ($folder in @($createdFolders|Select-Object -Unique)) {
        try { Assert-UnlinkedPath $folder;if ((Test-Path -LiteralPath $folder -PathType Container) -and [IO.Directory]::GetFileSystemEntries($folder).Length -eq 0) { [IO.Directory]::Delete($folder) } }
        catch { $rollbackFailed+=$folder }
    }
    $recovery=if($rollbackFailed.Count){'partial_rollback'}elseif($written.Count){'rolled_back'}else{'no_owned_changes'}
    if ($recordPath) {
        try { $record.State=$recovery;[IO.File]::WriteAllText($recordPath,($record|ConvertTo-Json -Depth 6),$utf8) }
        catch { $rollbackFailed+='recovery record write';$recovery='partial_rollback' }
    }
    $location=if($backup){$backup}else{'not needed; no owned files were changed'}
    throw "Setup stopped during $phase : $failure. Owned recovery: $recovery. Backup/recovery location: $location. Files needing review: $($rollbackFailed -join ', ')"
} finally {
    if (Test-Path -LiteralPath $stageRoot) { Remove-Item -LiteralPath $stageRoot -Recurse -Force }
}
if ($AllowMissingDependencies -and $missing.Count -gt 0) { Write-Host 'Partial setup complete. Missing originals remain NOT LOADED; only available verified sources were connected. Reopen WoW through Battle.net.' }
else { Write-Host 'Local connection complete. Reopen WoW through Battle.net. Existing NightPro layout and connected feature paths are preserved.' }
if ($backup) { Write-Host "NightPro backup and recovery record: $backup" }
Write-Host 'CurseForge does not run this script automatically. After an original addon update, rerun while WoW is closed; unknown versions are refused.'
