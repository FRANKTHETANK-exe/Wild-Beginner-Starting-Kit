[CmdletBinding()]
param([string]$OutputPath = (Join-Path $PSScriptRoot '..\Wild-Beginner-Starting-Kit-1.5.3-beta.zip'))
$ErrorActionPreference='Stop'
$stage=Join-Path ([IO.Path]::GetTempPath()) ('WildBeginnerRelease-'+[guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $stage | Out-Null
foreach($addon in @('NightProController','NightProAdventureHub')) {
    Copy-Item -LiteralPath (Join-Path $PSScriptRoot ('AddOns\'+$addon)) -Destination $stage -Recurse
    foreach($doc in @('LICENSE','CREDITS.md')) {
        Copy-Item -LiteralPath (Join-Path $PSScriptRoot $doc) -Destination (Join-Path $stage $addon)
    }
}
foreach($file in @('Install.ps1','Install-Bridges.ps1','curseforge-dependencies.json','DEPENDENCIES.md','README.md','INSTALL.md','SETUP-DETAILS.md','AI-SETUP.txt','CHANGELOG.md')) {
    Copy-Item -LiteralPath (Join-Path $PSScriptRoot $file) -Destination (Join-Path $stage 'NightProController')
}
Compress-Archive -Path (Join-Path $stage '*') -DestinationPath $OutputPath -Force
Get-FileHash -LiteralPath $OutputPath -Algorithm SHA256
