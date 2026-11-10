[CmdletBinding()]
param([Parameter(Mandatory=$true)][string]$AddonPath, [switch]$Preview)
$ErrorActionPreference='Stop'
$targetRoot=[IO.Path]::GetFullPath($AddonPath).TrimEnd('\','/')
if (-not (Test-Path -LiteralPath $targetRoot -PathType Container) -or
    $targetRoot -notmatch '[\\/]_forever_[\\/]Interface[\\/]AddOns$') { throw 'Choose the _forever_\Interface\AddOns folder.' }
$bridges=@(
    @{Path='GearedForever\Core.lua'; Hash='6684E66BFCE42AFF44B6C6F633C5F2D917289E94AC28519407CDC1FB4D545B62'; Code='ns.NightProClasses = CLASSES; NightProGearData = ns'},
    @{Path='NeedRoll\API.lua'; Hash='45E509A2A569EDDF2F91AE593C44F862DFAF4355C404FD5820135FC6E2E16066'; Code='NightProDungeonData = ns'}
)
$utf8=New-Object Text.UTF8Encoding($false)
$plan=@()
foreach ($bridge in $bridges) {
    $file=Join-Path $targetRoot $bridge.Path
    if (-not (Test-Path -LiteralPath $file)) { Write-Host "Data bridge unavailable: $($bridge.Path)"; continue }
    $bytes=[IO.File]::ReadAllBytes($file)
    $suffix=$utf8.GetBytes("`n-- NightPro data bridge v1. Original authorship and data remain upstream.`n$($bridge.Code)`n")
    $current=$utf8.GetString($bytes)
    if ($current.EndsWith($utf8.GetString($suffix))) {
        $base=New-Object byte[] ($bytes.Length-$suffix.Length)
        [Array]::Copy($bytes,$base,$base.Length)
    } else { $base=$bytes }
    $sha=[Security.Cryptography.SHA256]::Create()
    try { $hash=[BitConverter]::ToString($sha.ComputeHash($base)).Replace('-','') } finally { $sha.Dispose() }
    if ($hash -ne $bridge.Hash) { throw "Unrecognized upstream file: $($bridge.Path). Bridge not applied. Keep your version and report it before patching." }
    if ($base.Length -ne $bytes.Length) { Write-Host "Data bridge verified: $($bridge.Path)"; continue }
    $plan+=@{File=$file; Relative=$bridge.Path; Bytes=$bytes; Suffix=$suffix}
}
if ($Preview) { foreach ($p in $plan) { Write-Host "Add data bridge: $($p.Relative)" }; return }
if ($plan.Count -gt 0) {
    $backupRoot=Join-Path ([IO.Path]::GetDirectoryName($targetRoot)) ('NightProKitBackups\bridges-'+(Get-Date -Format 'yyyyMMdd-HHmmss'))
    foreach ($p in $plan) {
        $backup=Join-Path $backupRoot $p.Relative
        New-Item -ItemType Directory -Path ([IO.Path]::GetDirectoryName($backup)) -Force | Out-Null
        [IO.File]::WriteAllBytes($backup,$p.Bytes)
        [IO.File]::WriteAllBytes($p.File,([byte[]]($p.Bytes+$p.Suffix)))
        Write-Host "Installed data bridge: $($p.Relative)"
    }
    Write-Host "Original source backup: $backupRoot"
}
