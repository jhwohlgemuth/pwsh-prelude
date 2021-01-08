#Requires -Modules BuildHelpers,pester
<#
.SYNOPSIS
Build tasks
.PARAMETER Lint
Run static analysis on source code with PSScriptAnalyzer. -Lint can be used with -Test
.PARAMETER Test
Run PowerShell unit tests. -Test can be used with -Lint
.PARAMETER Benchmark
Run C# benchmarks using BenchmarkDotNet
.PARAMETER Filter
Only run tests (Describe or It) that match filter string (-like wildcards allowed)
.PARAMETER Tags
Only run tests (Describe or It) with certain tags
.PARAMETER Exclude
Exclude running tests (Describe or It) with certain tags
.EXAMPLE
.\build.ps1 -Test -Filter '*Readability*' -Exclude 'LinuxOnly'
.EXAMPLE
.\build.ps1 -Test -Filter '*Readability*' -Tags 'WindowsOnly'
.EXAMPLE
.\build.ps1 -CI -Test -Tags 'Remote' -Exclude 'LinuxOnly' -WithCoverage
.EXAMPLE
.\build.ps1 -Test -WithCoverage -Skip dotnet
#>
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('AdvancedFunctionHelpContent', '')]
[CmdletBinding()]
Param(
  [Switch] $Lint,
  [Switch] $Test,
  [Switch] $Benchmark,
  [ValidateSet('windows', 'linux')]
  [String] $Platform,
  [Switch] $WithCoverage,
  [Switch] $ShowCoverageReport,
  [Switch] $CI,
  [ValidateSet('dotnet', 'powershell')]
  [String[]] $Skip,
  [Switch] $BuildOnly,
  [String] $Filter,
  [String[]] $Tags,
  [String] $Exclude = '',
  [Switch] $DryRun,
  [Switch] $Major,
  [Switch] $Minor
)
$Prefix = if ($DryRun) { '[DRYRUN] ' } else { '' }
$SourceDirectory = 'src'
switch ($Platform) {
  'linux' { 
    $Exclude += 'WindowsOnly'
  }
  Default {
    $Exclude += 'LinuxOnly'
  }
}
function Invoke-Lint {
  [CmdletBinding()]
  Param()
  '==> Linting code' | Write-Output
  $Parameters = @{
    Path = $PSScriptRoot
    Settings = 'PSScriptAnalyzerSettings.psd1'
    Fix = $True
    EnableExit = $CI
    ReportSummary = $True
    Recurse = $True
  }
  Invoke-ScriptAnalyzer @Parameters
  "`n" | Write-Output
}
function Invoke-Test {
  [CmdletBinding()]
  Param()
  if (-not ($Skip -contains 'dotnet')) {
    $Message = if ($CI) { "==> Executing C# tests on $Env:BuildSystem" } else { '==> Executing C# tests' }
    $Message | Write-Output
    $ProjectPath = "$PSScriptRoot/src/cs/Tests/Tests.csproj"
    if ($WithCoverage) {
      dotnet test $ProjectPath /p:CollectCoverage=true /p:CoverletOutput=coverage.xml /p:CoverletOutputFormat=opencover
    } else {
      dotnet test $ProjectPath --logger:'console;verbosity=detailed'
    }
    "`n`n" | Write-Output
  }
  if (-not ($Skip -contains 'powershell')) {
    $Files = (Get-ChildItem (Join-Path $PSScriptRoot $SourceDirectory) -Recurse -Include '*.ps1').FullName
    $Configuration = [PesterConfiguration]@{
      Run = @{ PassThru = $True }
      Filter = @{ ExcludeTag = $Exclude }
      Debug = @{ ShowNavigationMarkers = $True; WriteVSCodeMarker = $True }
    }
    if ($Filter) {
      $Configuration.Filter.FullName = $Filter
    } elseif ($Tags) {
      $Configuration.Filter.Tag = $Tags
    }
    if ($WithCoverage) {
      $Configuration.CodeCoverage = @{ Enabled = $True; Path = $Files }
      $Configuration.TestResult = @{ Enabled = $False }
    }
    if ($CI) {
      Set-BuildEnvironment -VariableNamePrefix 'Prelude' -Force
      "==> Executing PowerShell tests on $Env:PreludeBuildSystem" | Write-Output
    } else {
      '==> Executing PowerShell tests' | Write-Output
    }
    $Result = Invoke-Pester -Configuration $Configuration
    if ($Result.FailedCount -gt 0) {
      $FailedMessage = "==> FAILED - $($Result.FailedCount) PowerShell test(s) failed"
      throw $FailedMessage
    } else {
      "`nPowerShell SUCCESS`n" | Write-Output
    }
  }
}
function Invoke-Publish {
  [CmdletBinding()]
  Param()
  Set-BuildEnvironment -VariableNamePrefix 'Prelude' -Force
  $ProjectManifestPath = "$Env:PreludeProjectPath/Prelude.psd1"
  $ValidateManifest = if (Test-ModuleManifest -Path $ProjectManifestPath) { 'Manifest is Valid' } else { 'Manifest is NOT Valid' }
  $ValidateApiKey = if ((Write-Output $Env:NUGET_API_KEY).Length -eq 46) { 'API Key is Valid' } else { 'API Key is NOT Valid' }
  "${Prefix}==> $ValidateManifest" | Write-Output
  "${Prefix}==> $ValidateApiKey" | Write-Output
  $Increment = if ($Major) {
    'Major'
  } elseif ($Minor) {
    'Minor'
  } else {
    'Build'
  }
  if (-not $DryRun) {
    "Updating Module $(${Increment}.ToUpper()) Version..." | Write-Output
    Update-Metadata $ProjectManifestPath -Increment $Increment
    'Publishing module...' | Write-Output
    Publish-Module -Path (Get-Location) -NuGetApiKey $Env:NUGET_API_KEY -SkipAutomaticTags -Verbose
    "`n==> DONE`n" | Write-Output
  } else {
    "${Prefix}Updating Module $(${Increment}.ToUpper()) Version..." | Write-Output
    "${Prefix}Publishing module..." | Write-Output
    "${Prefix}==> DONE" | Write-Output
  }
}
if ($Benchmark) {
  '==> Running C# Benchmarks' | Write-Output
  $ProjectPath = "$PSScriptRoot/src/cs/Performance/Performance.csproj"
  dotnet run --project $ProjectPath --configuration 'Release'
} else {
  if ($Lint -and -not $BuildOnly) {
    Invoke-Lint
  }
  if ($Test -and -not $BuildOnly) {
    Invoke-Test
  }
  if ($ShowCoverageReport) {
    $ReportTypes = 'Html;HtmlSummary;HtmlChart'
    if ($Test -and $WithCoverage) {
      $SourceDirs = "$SourceDirectory"
      reportgenerator.exe -reports:'**/coverage.xml' -targetdir:coverage -sourcedirs:$SourceDirs -historydir:.history -reporttypes:$ReportTypes
    } else {
      reportgenerator.exe -reports:'**/coverage.xml' -targetdir:coverage -sourcedirs:$SourceDirs -reporttypes:$ReportTypes
    }
    Invoke-Item './coverage/index.htm'
  }
  if (-not $Lint -and -not $Test -and -not $ShowCoverageReport) {
    if (-not $BuildOnly -and -not $DryRun) {
      Invoke-Lint
      Invoke-Test
    }
    Invoke-Publish
  }
}