[CmdletBinding()]
param(
  [switch]$SkipAnalyze,
  [switch]$SkipTests
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot
Set-Location $repoRoot

function Write-Step {
  param([string]$Message)
  Write-Host ""
  Write-Host "==> $Message" -ForegroundColor Cyan
}

function Assert-Command {
  param([string]$Name)
  if (-not (Get-Command $Name -ErrorAction SilentlyContinue)) {
    throw "Required command '$Name' was not found in PATH."
  }
}

function Invoke-Checked {
  param(
    [string]$Command,
    [string[]]$Arguments
  )

  & $Command @Arguments
  if ($LASTEXITCODE -ne 0) {
    throw "'$Command $($Arguments -join ' ')' failed with exit code $LASTEXITCODE."
  }
}

Assert-Command flutter

Write-Step 'Enabling Windows desktop support'
Invoke-Checked flutter @('config', '--enable-windows-desktop')

Write-Step 'Installing packages'
Invoke-Checked flutter @('pub', 'get')

if (-not $SkipAnalyze) {
  Write-Step 'Running flutter analyze'
  Invoke-Checked flutter @('analyze')
}

if (-not $SkipTests) {
  Write-Step 'Running flutter test'
  Invoke-Checked flutter @('test')
}

Write-Host ""
Write-Host 'Bootstrap completed successfully.' -ForegroundColor Green
