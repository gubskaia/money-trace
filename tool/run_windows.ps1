[CmdletBinding()]
param(
  [switch]$SkipBootstrap,
  [switch]$ResetData,
  [Parameter(ValueFromRemainingArguments = $true)]
  [string[]]$FlutterArgs
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

if ($ResetData) {
  Write-Step 'Resetting local app data'
  & "$PSScriptRoot\reset_local_data_windows.ps1"
}

if (-not $SkipBootstrap) {
  Write-Step 'Bootstrapping the workspace'
  & "$PSScriptRoot\bootstrap_windows.ps1"
}

Write-Step 'Stopping stale money_trace.exe processes'
Get-Process -Name money_trace -ErrorAction SilentlyContinue |
  Stop-Process -Force -ErrorAction SilentlyContinue

Start-Sleep -Milliseconds 500

$runArguments = @('run', '-d', 'windows') + $FlutterArgs

Write-Step 'Launching MoneyTrace on Windows'
Invoke-Checked flutter $runArguments
