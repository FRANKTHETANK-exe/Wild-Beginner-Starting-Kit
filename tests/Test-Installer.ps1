$ErrorActionPreference = 'Stop'
$repo = Split-Path $PSScriptRoot -Parent
$testRoot = Join-Path ([IO.Path]::GetTempPath()) ('NightProKitTests-' + [guid]::NewGuid().ToString('N'))
$addons = Join-Path $testRoot '_forever_\Interface\AddOns'
New-Item -ItemType Directory -Force -Path $addons | Out-Null
$installer = Join-Path $repo 'Install.ps1'
& $installer -AddonPath $addons -SkipDependencies -Preview
if (Test-Path (Join-Path $addons 'NightProController')) { throw 'Preview wrote files' }
& $installer -AddonPath $addons -SkipDependencies
$installed = Join-Path $addons 'NightProController\NightProController.lua'
if (-not (Test-Path $installed)) { throw 'Menu was not installed' }
Set-Content -LiteralPath $installed -Value 'previous menu'
$other = Join-Path $addons 'OtherAddon'
New-Item -ItemType Directory -Path $other | Out-Null
Set-Content -LiteralPath (Join-Path $other 'keep.txt') -Value 'keep'
& $installer -AddonPath $addons -SkipDependencies
$backups = @(Get-ChildItem -LiteralPath (Join-Path $testRoot '_forever_\Interface\NightProKitBackups') -Recurse -Filter 'NightProController.lua')
if ($backups.Count -ne 1 -or (Get-Content $backups[0].FullName -Raw).Trim() -ne 'previous menu') { throw 'Backup failed' }
if ((Get-Content -LiteralPath (Join-Path $other 'keep.txt') -Raw).Trim() -ne 'keep') { throw 'Unrelated addon changed' }
$rejected = $false
try { & $installer -AddonPath $testRoot -SkipDependencies } catch { $rejected = $true }
if (-not $rejected) { throw 'Invalid destination accepted' }

$fixture = Join-Path $testRoot 'fixture'
New-Item -ItemType Directory -Path $fixture | Out-Null
Copy-Item -LiteralPath $installer -Destination $fixture
Copy-Item -LiteralPath (Join-Path $repo 'Install-Bridges.ps1') -Destination $fixture
Copy-Item -LiteralPath (Join-Path $repo 'AddOns') -Destination $fixture -Recurse
$global:nightProTestArchive = Join-Path $testRoot 'upstream.zip'
Add-Type -AssemblyName System.IO.Compression.FileSystem
$zip = [IO.Compression.ZipFile]::Open($global:nightProTestArchive, 'Create')
$entry = $zip.CreateEntry('DemoAddon/DemoAddon.toc')
$writer = New-Object IO.StreamWriter($entry.Open())
$writer.Write('## Interface: 16001');$writer.Dispose();$zip.Dispose()
function Invoke-WebRequest { param($Uri, $OutFile, [switch]$UseBasicParsing) Copy-Item -LiteralPath $global:nightProTestArchive -Destination $OutFile }
$package = @{id='demo';version='1';url='https://edge.forgecdn.net/demo.zip';sha256=('0'*64);folders=@('DemoAddon');required=$true}
@{addons=@($package)} | ConvertTo-Json -Depth 6 | Set-Content (Join-Path $fixture 'dependencies.json')
$rejected = $false
try { & (Join-Path $fixture 'Install.ps1') -AddonPath $addons } catch { Write-Host $_.Exception.Message; $rejected = $_.Exception.Message -like '*verification failed*' }
if (-not $rejected -or (Test-Path (Join-Path $addons 'DemoAddon'))) { throw 'Hash mismatch was not blocked' }
$package.sha256 = (Get-FileHash $global:nightProTestArchive).Hash
@{addons=@($package)} | ConvertTo-Json -Depth 6 | Set-Content (Join-Path $fixture 'dependencies.json')
& (Join-Path $fixture 'Install.ps1') -AddonPath $addons
if (-not (Test-Path (Join-Path $addons 'DemoAddon\DemoAddon.toc'))) { throw 'Verified dependency was not installed' }
Set-Content -LiteralPath (Join-Path $addons 'DemoAddon\keep.txt') -Value 'custom'
& (Join-Path $fixture 'Install.ps1') -AddonPath $addons
if (-not (Test-Path (Join-Path $addons 'DemoAddon\keep.txt'))) { throw 'Existing dependency replaced' }
$global:nightProTestArchive = Join-Path $testRoot 'unsafe.zip'
$zip = [IO.Compression.ZipFile]::Open($global:nightProTestArchive, 'Create')
$entry = $zip.CreateEntry('../escaped.txt');$zip.Dispose()
$package.folders=@('UnsafeAddon');$package.sha256=(Get-FileHash $global:nightProTestArchive).Hash
@{addons=@($package)} | ConvertTo-Json -Depth 6 | Set-Content (Join-Path $fixture 'dependencies.json')
$rejected=$false
try { & (Join-Path $fixture 'Install.ps1') -AddonPath $addons } catch { $rejected=$_.Exception.Message -like '*Unsafe archive*' }
if (-not $rejected) { throw 'Archive traversal was not blocked' }
Write-Host 'PASS: preview, installation, backup, preserved addons, path validation, hash verification and archive traversal'
Write-Host "Fixtures: $testRoot"
