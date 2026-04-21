[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot
Set-Location $repoRoot

function Write-Step {
  param([string]$Message)
  Write-Host ""
  Write-Host "==> $Message" -ForegroundColor Cyan
}

Write-Step 'Stopping running money_trace.exe processes'
Get-Process -Name money_trace -ErrorAction SilentlyContinue |
  Stop-Process -Force -ErrorAction SilentlyContinue

$candidateDirectories = @(
  [System.IO.Path]::Combine($env:APPDATA, 'money_trace'),
  [System.IO.Path]::Combine($env:LOCALAPPDATA, 'money_trace'),
  [System.IO.Path]::Combine($env:APPDATA, 'MoneyTrace'),
  [System.IO.Path]::Combine($env:LOCALAPPDATA, 'MoneyTrace'),
  [System.IO.Path]::Combine($env:APPDATA, 'com.example', 'money_trace'),
  [System.IO.Path]::Combine($env:LOCALAPPDATA, 'com.example', 'money_trace'),
  [System.IO.Path]::Combine($env:APPDATA, 'com.example.money_trace'),
  [System.IO.Path]::Combine($env:LOCALAPPDATA, 'com.example.money_trace')
) | Select-Object -Unique

$deletedPaths = New-Object System.Collections.Generic.List[string]

foreach ($directory in $candidateDirectories) {
  if ([string]::IsNullOrWhiteSpace($directory)) {
    continue
  }

  if (-not (Test-Path -LiteralPath $directory)) {
    continue
  }

  $databaseFiles = Get-ChildItem -LiteralPath $directory -Filter 'money_trace.db*' -File -ErrorAction SilentlyContinue
  foreach ($databaseFile in $databaseFiles) {
    Remove-Item -LiteralPath $databaseFile.FullName -Force
    $deletedPaths.Add($databaseFile.FullName)
  }
}

Write-Step 'Reset summary'
if ($deletedPaths.Count -eq 0) {
  Write-Host 'No local MoneyTrace database files were found in the usual Windows app-data locations.'
} else {
  Write-Host 'Deleted local database files:' -ForegroundColor Green
  foreach ($deletedPath in $deletedPaths) {
    Write-Host " - $deletedPath"
  }
}
