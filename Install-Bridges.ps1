[CmdletBinding()]
param([Parameter(Mandatory=$true)][string]$AddonPath, [switch]$Preview, [switch]$Restore, [switch]$AllowMissingDependencies)
$ErrorActionPreference='Stop'
if (Get-Process -Name 'Wow','WowClassic','WowClassicT' -ErrorAction SilentlyContinue) { throw 'Close WoW before connecting or restoring addon source files. Nothing changed.' }
$targetRoot=[IO.Path]::GetFullPath($AddonPath).TrimEnd('\','/')
if (-not (Test-Path -LiteralPath $targetRoot -PathType Container) -or
    $targetRoot -notmatch '[\\/]_forever_[\\/]Interface[\\/]AddOns$') { throw 'Choose the _forever_\Interface\AddOns folder.' }
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
$bridges=@(
    @{Path='GearedForever\Core.lua'; Hashes=@('6684E66BFCE42AFF44B6C6F633C5F2D917289E94AC28519407CDC1FB4D545B62','509B5C52330B7F593415724B039200964B6FAAC180E8001FA03E332FF03620B8'); Code='ns.NightProClasses = CLASSES; NightProGearData = ns'},
    @{Path='NeedRoll\API.lua'; Hashes=@('45E509A2A569EDDF2F91AE593C44F862DFAF4355C404FD5820135FC6E2E16066','8C451495848383E85BB3F7452D6C396A5400F92508834B88C7A256A4AA6929DC'); Code='NightProDungeonData = ns'},
    @{Path='QuestieForeverGamepad\Core.lua'; Hashes=@('B025321099A9702E0CEF17488980A15D0032759FA49FF01236506698BC25F2AA','0D2C0621869E1D46293D0F1FAC3191AC261542A6C24A998270C53ECCA46FCAA1'); Code='NightProQuestVisualData = {}; for _, key in ipairs({"ResolveTrackerTarget", "EntityModelRequest", "ConfigureEntityCamera"}) do local method = key; NightProQuestVisualData[method] = function(_, ...) local p = QFG.QuestPreview; if p and p[method] then return p[method](p, ...) end end end'}
)
$utf8=New-Object Text.UTF8Encoding($false)
function Get-ByteHash([byte[]]$Bytes) {
    $sha=[Security.Cryptography.SHA256]::Create()
    try { [BitConverter]::ToString($sha.ComputeHash($Bytes)).Replace('-','') } finally { $sha.Dispose() }
}
$plan=@()
foreach ($bridge in $bridges) {
    $file=Join-Path $targetRoot $bridge.Path
    if (-not (Test-Path -LiteralPath $file -PathType Leaf)) {
        $addonFolder=Join-Path $targetRoot ($bridge.Path.Split('\')[0])
        Assert-UnlinkedPath $addonFolder
        if ($AllowMissingDependencies -and -not(Test-Path -LiteralPath $addonFolder)) { Write-Host "NOT LOADED - absent original skipped: $($bridge.Path)";continue }
        throw "Missing original addon file: $($bridge.Path). Install its Forever version through the author's CurseForge project, then rerun. An existing incomplete folder is not skipped."
    }
    Assert-UnlinkedPath $file
    $bytes=[IO.File]::ReadAllBytes($file)
    $suffix=$utf8.GetBytes("`n-- NightPro data bridge v1. Original authorship and data remain upstream.`n$($bridge.Code)`n")
    $current=$utf8.GetString($bytes)
    if ($current.EndsWith($utf8.GetString($suffix))) {
        $base=New-Object byte[] ($bytes.Length-$suffix.Length)
        [Array]::Copy($bytes,$base,$base.Length)
    } else {
        if ($current.Contains('-- NightPro data bridge')) { throw "Unrecognized existing bridge: $($bridge.Path). Nothing changed." }
        $base=$bytes
    }
    $sha=[Security.Cryptography.SHA256]::Create()
    try { $hash=[BitConverter]::ToString($sha.ComputeHash($base)).Replace('-','') } finally { $sha.Dispose() }
    if ($bridge.Hashes -notcontains $hash) { throw "Unrecognized upstream file: $($bridge.Path). Bridge not applied. Keep the new original; do not replace it with an old backup. Report its version before connecting it." }
    if ($Restore) {
        if ($base.Length -eq $bytes.Length) { Write-Host "Original already verified: $($bridge.Path)"; continue }
        $after=$base
    } else {
        if ($base.Length -ne $bytes.Length) { Write-Host "Data bridge verified: $($bridge.Path)"; continue }
        $after=[byte[]]($bytes+$suffix)
    }
    $plan+=@{File=$file; Relative=$bridge.Path; Bytes=$bytes; After=$after; BeforeHash=(Get-ByteHash $bytes)}
}
$action=if($Restore){'Restore original'}else{'Connect original'}
foreach ($p in $plan) { Write-Host "$action : $($p.Relative)" }
if ($Preview -or $plan.Count -eq 0) { return }
function Set-AtomicBytes([string]$File,[byte[]]$Bytes) {
    Assert-UnlinkedPath $File
    $temp=$File+'.nightpro-'+[guid]::NewGuid().ToString('N')+'.tmp'
    try {
        [IO.File]::WriteAllBytes($temp,$Bytes)
        [IO.File]::Replace($temp,$File,[NullString]::Value)
    } finally { if (Test-Path -LiteralPath $temp) { Remove-Item -LiteralPath $temp -Force } }
}
$backupRoot=Join-Path ([IO.Path]::GetDirectoryName($targetRoot)) ('NightProKitBackups\bridges-'+(Get-Date -Format 'yyyyMMdd-HHmmss')+'-'+[guid]::NewGuid().ToString('N').Substring(0,8))
Assert-UnlinkedPath $backupRoot
New-Item -ItemType Directory -Path $backupRoot -Force | Out-Null
foreach ($p in $plan) {
    $backup=Join-Path $backupRoot $p.Relative
    New-Item -ItemType Directory -Path ([IO.Path]::GetDirectoryName($backup)) -Force | Out-Null
    [IO.File]::WriteAllBytes($backup,$p.Bytes)
    $p.AfterHash=Get-ByteHash $p.After
}
$record=@{State='prepared'; Action=$action; Created=(Get-Date).ToString('o'); Files=@($plan | ForEach-Object { @{Path=$_.Relative; BeforeSHA256=$_.BeforeHash; AfterSHA256=$_.AfterHash} })}
$recordPath=Join-Path $backupRoot 'bridge-record.json'
[IO.File]::WriteAllText($recordPath,($record|ConvertTo-Json -Depth 6),$utf8)
$written=@()
try {
    foreach ($p in $plan) {
        if ((Get-FileHash -LiteralPath $p.File -Algorithm SHA256).Hash -ne $p.BeforeHash) { throw "Addon changed during setup: $($p.Relative)." }
        Set-AtomicBytes $p.File $p.After
        $written+=$p
        if ((Get-FileHash -LiteralPath $p.File -Algorithm SHA256).Hash -ne $p.AfterHash) { throw "Write verification failed: $($p.Relative)." }
    }
    $record.State='applied'
    [IO.File]::WriteAllText($recordPath,($record|ConvertTo-Json -Depth 6),$utf8)
} catch {
    $failure=$_.Exception.Message;$rollbackFailed=@()
    for ($i=$written.Count-1;$i -ge 0;$i--) {
        $p=$written[$i]
        try {
            Assert-UnlinkedPath $p.File
            if ((Get-FileHash -LiteralPath $p.File -Algorithm SHA256).Hash -ne $p.AfterHash) { throw 'Externally changed file left untouched.' }
            Set-AtomicBytes $p.File $p.Bytes
            if ((Get-FileHash -LiteralPath $p.File -Algorithm SHA256).Hash -ne $p.BeforeHash) { throw 'Rollback verification failed.' }
        } catch { $rollbackFailed+=$p.Relative }
    }
    $record.State=if($rollbackFailed.Count){'partial_rollback'}else{'rolled_back'}
    [IO.File]::WriteAllText($recordPath,($record|ConvertTo-Json -Depth 6),$utf8)
    throw "Bridge setup stopped: $failure. Recovery: $($record.State). Backup: $backupRoot. Files needing manual review: $($rollbackFailed -join ', ')"
}
Write-Host "$action complete. Verified $($written.Count) file(s). Authors' notices and licenses are preserved."
Write-Host "Byte-for-byte backup and recovery record: $backupRoot"
