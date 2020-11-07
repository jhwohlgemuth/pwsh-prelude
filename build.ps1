[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '')]
[CmdletBinding()]
Param(
  [Switch] $Lint,
  [Switch] $Test,
  [Switch] $WithCoverage,
  [Switch] $ShowCoverageReport,
  [Switch] $CI,
  [Switch] $SkipChecks,
  [Switch] $DryRun,
  [Switch] $Major,
  [Switch] $Minor
)

Set-BuildEnvironment -VariableNamePrefix '' -Force

$Prefix = if ($DryRun) { '[DRYRUN] ' } else { '' }
$SourceDirectory = 'src'
function Invoke-Lint {
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
function Invoke-Test {
  [CmdletBinding()]
  Param()
  if (-not (Get-Module -Name Pester)) {
    Import-Module -Name Pester
  }
  $Root = Join-Path $PSScriptRoot $SourceDirectory
  $Files = (Get-ChildItem $Root -Recurse -Include '*.ps1').FullName
  if ($WithCoverage) {
    '==> Executing tests with coverage' | Write-Output
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
    '==> Executing tests on CI' | Write-Output
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
    '==> Executing tests' | Write-Output
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
function Invoke-Publish {
  [CmdletBinding()]
  Param()
  "${Prefix}Validating module data..." | Write-Output
  if (Test-ModuleManifest -Path $Env:PSModuleManifest) {
    "${Prefix}==> SUCCESS" | Write-Output
  } else {
    "${Prefix}==> FAIL" | Write-Output
  }
  "${Prefix}Validating Nuget API Key..." | Write-Output
  if ((Write-Output $Env:NUGET_API_KEY).Length -eq 46) {
    "${Prefix}==> SUCCESS" | Write-Output
  } else {
    "${Prefix}==> FAIL" | Write-Output
  }
  $Increment = if ($Major) {
    'Major'
  } elseif ($Minor) {
    'Minor'
  } else {
    'Build'
  }
  if (-not $DryRun) {
    "Updating Module $(${Increment}.ToUpper()) Version..." | Write-Output
    Update-Metadata $Env:PSModuleManifest -Increment $Increment
    'Publishing module...' | Write-Output
    Publish-Module -Path (Get-Location) -NuGetApiKey $Env:NUGET_API_KEY -SkipAutomaticTags -Verbose
    "`n==> DONE`n" | Write-Output
  } else {
    "${Prefix}Updating Module $(${Increment}.ToUpper()) Version..." | Write-Output
    "${Prefix}Publishing module..." | Write-Output
    "${Prefix}==> DONE" | Write-Output
  }
}
if ($Lint) {
  Invoke-Lint
}
if ($Test -and -not $SkipChecks) {
  Invoke-Test
}
if ($ShowCoverageReport -and (Test-Path (Join-Path (Get-Location) 'coverage.xml'))) {
  $ReportTypes = 'Html;HtmlSummary;HtmlChart'
  if ($Test -and $WithCoverage) {
    reportgenerator.exe -reports:coverage.xml -targetdir:coverage -sourcedirs:$SourceDirectory -historydir:.history -reporttypes:$ReportTypes
  } else {
    reportgenerator.exe -reports:coverage.xml -targetdir:coverage -sourcedirs:$SourceDirectory -reporttypes:$ReportTypes
  }
  Invoke-Item '.\coverage\index.htm'
}
if (-not $Lint -and -not $Test -and -not $ShowCoverageReport) {
  if (-not $SkipChecks) {
    Invoke-Lint
    Invoke-Test
  }
  Invoke-Publish
}