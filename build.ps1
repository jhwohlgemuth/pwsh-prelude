[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'WithCoverage')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'CI')]
[CmdletBinding()]
Param(
  [Switch] $Lint,
  [Switch] $Test,
  [Switch] $WithCoverage,
  [Switch] $CI
)
function Invoke-Lint
{
  [CmdletBinding()]
  Param()
  "==> Linting code..." | Write-Host -ForegroundColor Green
  $Settings = @{
    ExcludeRules = @(
      'PSAvoidUsingWriteHost'
      'PSAvoidOverwritingBuiltInCmdlets'
      'PSUseProcessBlockForPipelineCommand'
      'PSUseShouldProcessForStateChangingFunctions'
    )
  }
  Invoke-ScriptAnalyzer -Path (Get-Location) -Settings $Settings -Fix -EnableExit:$CI
}
function Invoke-Test
{
  [CmdletBinding()]
  Param()
  "==> Executing tests..." | Write-Host -ForegroundColor Green -NoNewLine
  if (-not (Get-Module -Name Pester)) {
    Import-Module -Name Pester
  }
  if ($WithCoverage) {
    "with coverage" | Write-Host -ForegroundColor Green
    $Files = (Get-ChildItem $PSScriptRoot -Recurse -Include "*.psm1").FullName
    $Configuration = [PesterConfiguration]@{
      CodeCoverage = @{
        Enabled = $true
        Path = $Files
      }
    }
    Invoke-Pester -Configuration $Configuration
  } elseif ($CI) {
    "on CI" | Write-Host -ForegroundColor Green
    $Files = (Get-ChildItem $PSScriptRoot -Recurse -Include "*.psm1").FullName
    $Configuration = [PesterConfiguration]@{
      Run = @{
        Exit = $true
      }
      CodeCoverage = @{
        Enabled = $true
        Path = $Files
      }
      TestResult = @{
        Enabled = $true
      }
    }
    Invoke-Pester -Configuration $Configuration
  } else {
    "" | Write-Host
    $Result = Invoke-Pester -PassThru
    if ($Result.FailedCount -gt 0) {
      "`nFAILED - $($Result.FailedCount) tests failed.`n" | Write-Host -ForegroundColor Red
    } else {
      "`nSUCCESS`n" | Write-Host -ForegroundColor Green
    }
  }
}
if ($Lint) {
  Invoke-Lint
} elseif ($Test) {
  Invoke-Test
} else {
  Invoke-Lint
  Invoke-Test
  Test-ModuleManifest -Path (Join-Path (Get-Location) 'pwsh-handy-helpers.psd1')
  "NUGET_API_KEY ==> " | Write-Host -ForegroundColor Green -NoNewline
  if ((Write-Output $Env:NUGET_API_KEY).Length -eq 46) {
    "VALID" | Write-Host -ForegroundColor Green
  } else {
    "INVALID" | Write-Host -ForegroundColor Red
  }
  "==> Publishing module..." | Write-Host -ForegroundColor Green
  Publish-Module -Path (Get-Location) -NuGetApiKey $Env:NUGET_API_KEY -Verbose
}