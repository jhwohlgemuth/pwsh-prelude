#Requires -Modules BuildHelpers,pester
<#
.SYNOPSIS
Build tasks
.PARAMETER Build
Lint code, run tests and build C# link libraries
.PARAMETER BuildOnly
Do not lint code or run tests when used with -Build parameter
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
.\build.ps1 -Test -Platform linux
.EXAMPLE
.\build.ps1 -Test -Filter '*Readability*'
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
    [Switch] $WithCoverage,
    [Switch] $GenerateCoverageReport,
    [Switch] $CI,
    [Switch] $Build,
    [Switch] $BuildOnly,
    [Switch] $Publish,
    [Switch] $Major,
    [Switch] $Minor,
    [Switch] $Benchmark,
    [ValidateSet('windows', 'linux')]
    [String] $Platform = 'windows',
    [ValidateSet('dotnet', 'powershell')]
    [String[]] $Skip,
    [String] $Filter,
    [ValidateSet('Local', 'Remote', 'WindowsOnly', 'LinuxOnly')]
    [String[]] $Tags,
    [ValidateSet('Local', 'Remote', 'WindowsOnly', 'LinuxOnly')]
    [String] $Exclude = '',
    [Switch] $DryRun
)
$Prefix = if ($DryRun) { '[DRYRUN] ' } else { '' }
$SourceDirectory = Join-Path 'Prelude' 'src'
switch ($Platform) {
    'linux' {
        $Exclude += 'WindowsOnly'
    }
    Default {
        $Exclude += 'LinuxOnly'
    }
}
function Get-TaskList {
    [CmdletBinding()]
    Param()
    enum Task {
        benchmark
        lint
        test
        build
        publish
    }
    $Tasks = @()
    if ($Benchmark) {
        $Tasks += [Task]'benchmark'
    }
    if ($Lint) {
        $Tasks += [Task]'lint'
    }
    if ($Test) {
        $Tasks += [Task]'test'
    }
    if ($Build) {
        $Tasks += [Task]'build'
    }
    if ($Publish) {
        $Tasks += [Task]'publish'
    }
    if ($Tasks.Count -eq 0) {
        $Tasks += [Task]'build'
    }
    $Tasks
}
function Invoke-Build {
    [CmdletBinding()]
    Param(
        [String] $Version = '2019',
        [String] $Offering = 'Community'
    )
    $ToolsDirectory = "C:\Program Files (x86)\Microsoft Visual Studio\$Version\$Offering\Common7\Tools"
    $CompilerPath = "C:\Program Files (x86)\Microsoft Visual Studio\$Version\$Offering\MSBuild\Current\Bin\Roslyn\csc.exe"
    if ((Test-Path $ToolsDirectory)) {
        '==> Setting environment variables' | Write-Output
        & (Join-Path $ToolsDirectory 'VsDevCmd.bat') -no_logo
    } else {
        'Could not find VsDevCmd.bat which is needed to set environment variables' | Write-Error
    }
    if ((Test-Path $CompilerPath)) {
        $CsharpDirectory = "$PSScriptRoot/csharp"
        $OutputDirectory = "$PSScriptRoot/Prelude/bin"
        'Geodetic', 'Matrix' | ForEach-Object {
            "==> Building $_ link library" | Write-Output
            & $CompilerPath "$CsharpDirectory/${_}/${_}.cs" -out:"$OutputDirectory/Geodetic.dll" -target:library -optimize -nologo
        }
        'Node', 'Edge', 'Graph' | ForEach-Object {
            "==> Building $_ link library" | Write-Output
            & $CompilerPath "$CsharpDirectory/Graph/${_}.cs" -out:"$OutputDirectory/${_}.dll" -lib:$OutputDirectory -reference:Matrix.dll -reference:Edge.dll -target:library -optimize -nologo
        }
    } else {
        'Could not find C# compiler (csc.exe)' | Write-Error
    }
}
function Invoke-Lint {

    [CmdletBinding()]
    Param(
        [Switch] $CI,
        [Switch] $DryRun,
        [String[]] $Skip
    )
    "==> Formatting C# code`n" | Write-Output
    if (-not ($Skip -contains 'dotnet')) {
        $Format = {
            Param(
                [String] $Name
            )
            $Path = Join-Path "$PSScriptRoot/csharp/$Name" "${Name}.csproj"
            if ($DryRun) {
                dotnet format --check $Path --verbosity diagnostic
            } else {
                dotnet format $Path --verbosity detailed
            }
        }
        if ((Get-Command 'dotnet')) {
            'Matrix', 'Geodetic', 'Graph', 'Tests' | ForEach-Object {
                & $Format -Name $_
            }
        } else {
            'Global dotnet-format tool is required. Please run "./Invoke-Setup.ps1"' | Write-Error
        }
    }
    if (-not ($Skip -contains 'powershell')) {
        $Parameters = @{
            Path = $PSScriptRoot
            Settings = 'PSScriptAnalyzerSettings.psd1'
            Fix = $True
            EnableExit = $CI
            ReportSummary = $True
            Recurse = $True
        }
        "`n==> Linting PowerShell code" | Write-Output
        Invoke-ScriptAnalyzer @Parameters
    }
    "`n" | Write-Output
}
function Invoke-Test {
    [CmdletBinding()]
    Param(
        [Switch] $CI,
        [String] $Exclude = '',
        [String] $Filter,
        [String[]] $Skip,
        [String[]] $Tags,
        [Switch] $WithCoverage
    )
    Set-BuildEnvironment -VariableNamePrefix 'Prelude' -Force
    if (-not ($Skip -contains 'dotnet')) {
        $Message = if ($CI) { "==> Executing C# tests on $Env:PreludeBuildSystem" } else { '==> Executing C# tests' }
        $Message | Write-Output
        $ProjectPath = "$PSScriptRoot/csharp/Tests/Tests.csproj"
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
    Param(
        [Switch] $DryRun,
        [Switch] $Major,
        [Switch] $Minor
    )
    $ModulePath = Join-Path $PSScriptRoot 'Prelude'
    $ProjectManifestPath = Join-Path $ModulePath 'Prelude.psd1'
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
        Publish-Module -Path $ModulePath -NuGetApiKey $Env:NUGET_API_KEY -SkipAutomaticTags -Verbose
        "`n==> DONE`n" | Write-Output
    } else {
        "${Prefix}Updating Module $(${Increment}.ToUpper()) Version..." | Write-Output
        "${Prefix}Publishing module..." | Write-Output
        "${Prefix}==> DONE" | Write-Output
    }
}
switch (Get-TaskList) {
    benchmark {
        '==> Running C# Benchmarks' | Write-Output
        $ProjectPath = "$PSScriptRoot/csharp/Performance/Performance.csproj"
        dotnet run --project $ProjectPath --configuration 'Release'
        Break
    }
    lint {
        $Parameters = @{
            CI = $CI
            DryRun = $DryRun
            Skip = $Skip
        }
        Invoke-Lint @Parameters
    }
    test {
        $Parameters = @{
            CI = $CI
            Exclude = $Exclude
            Filter = $Filter
            Skip = $Skip
            Tags = $Tags
            WithCoverage = $WithCoverage
        }
        Invoke-Test @Parameters
        if ($GenerateCoverageReport) {
            $SourceDirs = "$SourceDirectory"
            $ReportTypes = 'Html;HtmlSummary;HtmlChart'
            reportgenerator.exe -reports:'**/coverage.xml' -targetdir:coverage -sourcedirs:$SourceDirs -historydir:.history -reporttypes:$ReportTypes
        }
    }
    build {
        # Default task
        if (-not $BuildOnly) {
            Invoke-Lint -Skip 'powershell'
            Invoke-Test -Skip 'powershell'
        }
        Invoke-Build
    }
    publish {
        $Parameters = @{
            DryRun = $DryRun
            Major = $Major
            Minor = $Minor
        }
        Invoke-Publish @Parameters
        Break
    }
}