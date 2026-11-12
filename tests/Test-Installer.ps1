[CmdletBinding()]
param([Parameter(Mandatory=$true)][string]$ArchiveDirectory)
$ErrorActionPreference='Stop'
$pwsh=(Get-Process -Id $PID).Path
& python (Join-Path $PSScriptRoot 'test_distribution_setup.py') --pwsh $pwsh --archives $ArchiveDirectory
if($LASTEXITCODE -ne 0){throw 'Offline distribution setup tests failed.'}
