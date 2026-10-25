#requires -Version 7.0
# Install the PowerShell 7+ profile into the current user's $PROFILE.
$ErrorActionPreference = 'Stop'
$Root = Split-Path -Parent $MyInvocation.MyCommand.Path
$Source = Join-Path $Root 'Microsoft.PowerShell_profile.ps1'
$Dest = $PROFILE

New-Item -ItemType Directory -Force -Path (Split-Path -Parent $Dest) | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $HOME 'projects/terminal-logs') | Out-Null

if ((Test-Path -LiteralPath $Dest) -and -not (Test-Path -LiteralPath "$Dest.bak")) {
    Copy-Item -LiteralPath $Dest -Destination "$Dest.bak"
}

Copy-Item -LiteralPath $Source -Destination $Dest -Force

$example = Join-Path $Root 'local.ps1.example'
$local = Join-Path (Split-Path -Parent $Dest) 'local.ps1'
if ((Test-Path $example) -and -not (Test-Path $local)) {
    Copy-Item $example $local
}

Write-Host "Installed PowerShell profile:"
Write-Host "  $Dest"
Write-Host "Open a new pwsh session to load it. Stop-Transcript is built in."
