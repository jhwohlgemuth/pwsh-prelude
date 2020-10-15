[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'WithCoverage')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'CI')]
[CmdletBinding()]
Param(
  [Switch] $Lint,
  [Switch] $Test,
  [Switch] $WithCoverage,
  [Switch] $CI,
  [Switch] $SkipTests
)
function Invoke-Lint
{
  [CmdletBinding()]
  Param()
  "==> Linting code" | Write-Host -ForegroundColor Cyan
  $Settings = @{
    ExcludeRules = @(
      'PSAvoidUsingWriteHost'
      'PSAvoidOverwritingBuiltInCmdlets'
      'PSUseProcessBlockForPipelineCommand'
      'PSUseShouldProcessForStateChangingFunctions'
    )
  }
  Invoke-ScriptAnalyzer -Path (Get-Location) -Settings $Settings -Fix -EnableExit:$CI -ReportSummary
  "" | Write-Host
}
function Invoke-Test
{
  [CmdletBinding()]
  Param()
  "==> Executing tests" | Write-Host -ForegroundColor Cyan -NoNewLine
  if (-not (Get-Module -Name Pester)) {
    Import-Module -Name Pester
  }
  $Files = (Get-ChildItem $PSScriptRoot -Recurse -Include "*.psm1").FullName
  if ($WithCoverage) {
    " with coverage" | Write-Host -ForegroundColor Cyan
    $Configuration = [PesterConfiguration]@{
      Run = @{
        PassThru = $true
      }
      CodeCoverage = @{
        Enabled = $true
        Path = $Files
      }
    }
  } elseif ($CI) {
    " on CI" | Write-Host -ForegroundColor Cyan
    $Configuration = [PesterConfiguration]@{
      Run = @{
        Exit = $true
        PassThru = $true
      }
      CodeCoverage = @{
        Enabled = $true
        Path = $Files
      }
      TestResult = @{
        Enabled = $true
      }
    }
  } else {
    "" | Write-Host
    $Configuration = [PesterConfiguration]@{
      Run = @{
        PassThru = $true
      }
      Debug = @{
        ShowNavigationMarkers = $true
        WriteVSCodeMarker = $true
      }
    }
  }
  $Result = Invoke-Pester -Configuration $Configuration
  if ($Result.FailedCount -gt 0) {
    "`nFAILED - $($Result.FailedCount) tests failed.`n" | Write-Host -ForegroundColor Red
  } else {
    "`nSUCCESS`n" | Write-Host -ForegroundColor Green
  }
}
function Invoke-Publish
{
  [CmdletBinding()]
  Param()
  "==> Validating module data..." | Write-Host -ForegroundColor Cyan
  "    Module manifest: " | Write-Host -NoNewline
  if (Test-ModuleManifest -Path (Join-Path (Get-Location) 'pwsh-handy-helpers.psd1')) {
    "VALID" | Write-Host -ForegroundColor Green
  } else {
    "INVALID" | Write-Host -ForegroundColor Red
  }
  "    Nuget API Key: " | Write-Host -NoNewline
  if ((Write-Output $Env:NUGET_API_KEY).Length -eq 46) {
    "VALID`n" | Write-Host -ForegroundColor Green
  } else {
    "INVALID`n" | Write-Host -ForegroundColor Red
  }
  "==> Publishing module..." | Write-Host -ForegroundColor Cyan -NoNewline
  Publish-Module -Path (Get-Location) -NuGetApiKey $Env:NUGET_API_KEY
  "DONE`n" | Write-Host -ForegroundColor Green
}
if ($Lint) {
  Invoke-Lint
}
if ($Test -and -not $SkipTests) {
  Invoke-Test
}
if (-not $Lint -and -not $Test) {
  if (-not $SkipTests) {
    Invoke-Lint
    Invoke-Test
  }
  Invoke-Publish
}