[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'CI')]
[CmdletBinding()]
Param(
  [Switch] $Lint,
  [Switch] $Test,
  [Switch] $WithCoverage,
  [Switch] $ShowCoverageReport,
  [Switch] $CI,
  [Switch] $SkipTests
)

$SourceDirectory = 'src'
function Invoke-Lint
{
  [CmdletBinding()]
  Param()
  '==> Linting code' | Write-Output
  $Settings = @{
    ExcludeRules = @(
      'PSAvoidUsingWriteHost'
      'PSUseBOMForUnicodeEncodedFile'
      'PSAvoidOverwritingBuiltInCmdlets'
      'PSUseProcessBlockForPipelineCommand'
      'PSUseShouldProcessForStateChangingFunctions'
    )
  }
  Invoke-ScriptAnalyzer -Path $PSScriptRoot -Settings $Settings -Fix -EnableExit:$CI -ReportSummary -Recurse
  '' | Write-Output
}
function Invoke-Test
{
  [CmdletBinding()]
  Param()
  '==> Executing tests' | Write-Output
  if (-not (Get-Module -Name Pester)) {
    Import-Module -Name Pester
  }
  $Root = Join-Path $PSScriptRoot $SourceDirectory
  $Files = (Get-ChildItem $Root -Recurse -Include '*.ps1').FullName
  if ($WithCoverage) {
    ' with coverage' | Write-Output
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
    ' on CI' | Write-Output
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
    '' | Write-Output
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
    "`nFAILED - $($Result.FailedCount) tests failed.`n" | Write-Output
  } else {
    "`nSUCCESS`n" | Write-Output
  }
}
function Invoke-Publish
{
  [CmdletBinding()]
  Param()
  '==> Validating module data...' | Write-Output
  '    Module manifest: ' | Write-Output
  if (Test-ModuleManifest -Path (Join-Path (Get-Location) 'pwsh-prelude.psd1')) {
    'VALID' | Write-Output
  } else {
    'INVALID' | Write-Output
  }
  '    Nuget API Key: ' | Write-Output
  if ((Write-Output $Env:NUGET_API_KEY).Length -eq 46) {
    "VALID`n" | Write-Output
  } else {
    "INVALID`n" | Write-Output
  }
  '==> Publishing module...' | Write-Output
  Publish-Module -Path (Get-Location) -NuGetApiKey $Env:NUGET_API_KEY -SkipAutomaticTags
  "DONE`n" | Write-Output
}
if ($Lint) {
  Invoke-Lint
}
if ($Test -and -not $SkipTests) {
  Invoke-Test
  if ($WithCoverage -and $ShowCoverageReport) {
    $ReportTypes = 'Html;HtmlSummary;HtmlChart'
    reportgenerator.exe -reports:coverage.xml -targetdir:coverage -sourcedirs:$SourceDirectory -historydir:.history -reporttypes:$ReportTypes
    Invoke-Item '.\coverage\index.htm'
  }
}
if (-not $Lint -and -not $Test) {
  if (-not $SkipTests) {
    Invoke-Lint
    Invoke-Test
  }
  Invoke-Publish
}