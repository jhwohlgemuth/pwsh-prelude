#Requires -Modules BuildHelpers,pester
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('AdvancedFunctionHelpContent', '')]
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
    CustomRulePath = (Join-Path $PSScriptRoot 'rule.psm1').ToString()
  }
  $Parameters = @{
    Path = $PSScriptRoot
    Settings = $Settings
    IncludeDefaultRules = $True
    Fix = $True
    EnableExit = $CI
    ReportSummary = $True
    Recurse = $True
  }
  Invoke-ScriptAnalyzer @Parameters
  '' | Write-Output
}
function Invoke-Test {
  [CmdletBinding()]
  Param()
  $Files = (Get-ChildItem (Join-Path $PSScriptRoot $SourceDirectory) -Recurse -Include '*.ps1').FullName
  if ($WithCoverage) {
    '==> Executing tests with coverage' | Write-Output
    $Configuration = [PesterConfiguration]@{
      Run = @{
        PassThru = $True
      }
      CodeCoverage = @{
        Enabled = $True
        Path = $Files
      }
    }
  } elseif ($CI) {
    Set-BuildEnvironment -VariableNamePrefix '' -Force
    "==> Executing tests on $Env:BuildSystem" | Write-Output
    $Configuration = [PesterConfiguration]@{
      Run = @{
        Exit = $False
        PassThru = $True
      }
      CodeCoverage = @{
        Enabled = $True
        Path = $Files
      }
      TestResult = @{
        Enabled = $True
      }
    }
  } else {
    '==> Executing tests' | Write-Output
    $Configuration = [PesterConfiguration]@{
      Run = @{
        PassThru = $True
      }
      Debug = @{
        ShowNavigationMarkers = $True
        WriteVSCodeMarker = $True
      }
    }
  }
  $Result = Invoke-Pester -Configuration $Configuration
  if ($Result.FailedCount -gt 0) {
    $FailedMessage = "==> FAILED - $($Result.FailedCount) test(s) failed"
    throw $FailedMessage
  } else {
    "`nSUCCESS`n" | Write-Output
  }
}
function Invoke-Publish {
  [CmdletBinding()]
  Param()
  Set-BuildEnvironment -VariableNamePrefix '' -Force
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
    $SourceDirs = "$SourceDirectory;src\classes"
    reportgenerator.exe -reports:coverage.xml -targetdir:coverage -sourcedirs:$SourceDirs -historydir:.history -reporttypes:$ReportTypes
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