#Requires -Modules BuildHelpers,pester
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('AdvancedFunctionHelpContent', '')]
[CmdletBinding()]
Param(
    [Switch] $Lint,
    [Switch] $Test,
    [Switch] $WithCoverage,
    [Switch] $GenerateCoverageReport,
    [Switch] $Show,
    [Switch] $CI,
    [Switch] $Build,
    [Switch] $BuildOnly,
    [Switch] $Check,
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
    [Switch] $DryRun,
    [Switch] $Help
)
$Prefix = if ($DryRun) { '[DRYRUN] ' } else { '' }
$SourceDirectory = Join-Path 'Prelude' 'src'
if ([String]::IsNullOrEmpty($Exclude)) {
    switch ($Platform) {
        'linux' {
            $Exclude = 'WindowsOnly'
        }
        Default {
            $Exclude = 'LinuxOnly'
        }
    }
}
function Write-Message {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $True, Position = 0)]
        [ValidateSet('done', 'pass', 'fail')]
        [String] $Text
    )
    $Message = switch ($Text) {
        pass {
            '
██████╗  █████╗ ███████╗███████╗
██╔══██╗██╔══██╗██╔════╝██╔════╝
██████╔╝███████║███████╗███████╗
██╔═══╝ ██╔══██║╚════██║╚════██║
██║     ██║  ██║███████║███████║
╚═╝     ╚═╝  ╚═╝╚══════╝╚══════╝'
        }
        fail {
            '
  █████▒▄▄▄       ██▓ ██▓
▓██   ▒▒████▄    ▓██▒▓██▒
▒████ ░▒██  ▀█▄  ▒██▒▒██░
░▓█▒  ░░██▄▄▄▄██ ░██░▒██░
░▒█░    ▓█   ▓██▒░██░░██████▒
▒ ░    ▒▒   ▓▒█░░▓  ░ ▒░▓  ░
░       ▒   ▒▒ ░ ▒ ░░ ░ ▒  ░
░ ░     ░   ▒    ▒ ░  ░ ░
            ░  ░ ░      ░  ░'
        }
    }
    $Message | Write-Output
}
function Get-TaskList {
    [CmdletBinding()]
    Param()
    enum Task {
        help
        benchmark
        check
        lint
        test
        build
        publish
    }
    $Tasks = @()
    if ($Help) {
        $Tasks += [Task]'help'
    }
    if ($Benchmark) {
        $Tasks += [Task]'benchmark'
    }
    if ($Check) {
        $Tasks += [Task]'check'
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
    $Tasks
}
function Invoke-Benchmark {
    <#
    .SYNOPSIS
    Run C# benchmarks using BenchmarkDotNet
    .EXAMPLE
    .\Invoke-Task.ps1 -Benchmark
    .NOTES
    When -Benchmark parameter is used, no other tasks will be executed.
    #>
    [CmdletBinding()]
    Param()
    '==> Running C# Benchmarks' | Write-Output
    $ProjectPath = "$PSScriptRoot/csharp/Performance/Performance.csproj"
    dotnet run --project $ProjectPath --configuration 'Release'
}
function Invoke-Build {
    <#
    .SYNOPSIS
    Format C# code, run C# tests, and build link libraries from C# code
    .PARAMETER BuildOnly
    Skip formatting code and running tests
    .EXAMPLE
    .\Invoke-Task.ps1 -Build
    .NOTES
    Build link libraries are saved to ./Prelude/bin directory
    #>
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
            & $CompilerPath "$CsharpDirectory/${_}/${_}.cs" -out:"$OutputDirectory/${_}.dll" -target:library -optimize -nologo
        }
        'Node' | ForEach-Object {
            "==> Building $_ link library" | Write-Output
            & $CompilerPath "$CsharpDirectory/Graph/${_}.cs" -out:"$OutputDirectory/${_}.dll" -lib:$OutputDirectory -target:library -optimize -nologo
        }
        'Edge' | ForEach-Object {
            "==> Building $_ link library" | Write-Output
            & $CompilerPath "$CsharpDirectory/Graph/${_}.cs" -out:"$OutputDirectory/${_}.dll" -lib:$OutputDirectory -reference:Matrix.dll -reference:Node.dll -target:library -optimize -nologo
        }
        'DirectedEdge', 'Graph' | ForEach-Object {
            "==> Building $_ link library" | Write-Output
            & $CompilerPath "$CsharpDirectory/Graph/${_}.cs" -out:"$OutputDirectory/${_}.dll" -lib:$OutputDirectory -reference:Matrix.dll -reference:Node.dll -reference:Edge.dll -target:library -optimize -nologo
        }
        Write-Message done
    } else {
        'Could not find C# compiler (csc.exe)' | Write-Error
    }
}
function Invoke-Check {
    <#
    .SYNOPSIS
    Run series of checks to determine if environment supports Prelude development.
    .DESCRIPTION
    Checks are run against Visual Studio 2019 Community Edition by default. Checks can be performed against other versions and offering using the -Version and -Offering parameters, respectively.
    > Note: VS2019 Community Edition is the ONLY version currently support by the Prelude project.
    .EXAMPLE
    .\Invoke-Task.ps1 -Check
    .NOTES
    When -Benchmark parameter is used, no other tasks will be executed.
    #>
    [CmdletBinding()]
    Param(
        [String] $Version = '2019',
        [String] $Offering = 'Community'
    )
    $VisualStudioRoot = "C:\Program Files (x86)\Microsoft Visual Studio\$Version\$Offering"
    $Results = @()
    $Fails = 0
    if ((Get-Command 'dotnet')) {
        $Results += '[+] dotnet command is available!'
    } else {
        $Results += '[-] Failed to find dotnet command...'
        $Fails++
    }
    if ((Get-Command 'reportgenerator.exe')) {
        $Results += '[+] reportgenerator command is available!'
    } else {
        $Results += '[-] Failed to find reportgenerator command...'
        $Fails++
    }
    if ((Test-Path "$VisualStudioRoot\Common7\Tools\VsDevCmd.bat")) {
        $Results += '[+] Successfully found VsDevCmd.bat!'
    } else {
        $Results += '[-] Failed to find necessary BAT file...'
        $Fails++
    }
    if ((Test-Path "$VisualStudioRoot\MSBuild\Current\Bin\Roslyn\csc.exe")) {
        $Results += '[+] Successfully found csc.exe!'
    } else {
        $Results += '[-] Failed to find C# compiler...'
        $Fails++
    }
    $Results | ForEach-Object { $_ | Write-Output }
    $Result = if ($Fails -eq 0) { 'pass' } else { 'fail' }
    Write-Message $Result
}
function Invoke-Lint {
    <#
    .SYNOPSIS
    Format C# code using dotnet-format and run static analysis on PowerShell code (with auto-fix enabled) using PSScriptAnalyzer
    .PARAMETER CI
    Configure function for running on continuous integration (CI) server (example: AppVeyor)
    .PARAMETER DryRun
    Analyze code without saving any changes
    .PARAMETER Skip
    Skip static analysis powershell and/or dotnet
    .EXAMPLE
    .\Invoke-Task.ps1 -Lint
    .EXAMPLE
    .\Invoke-Task.ps1 -Lint -Skip dotnet
    .EXAMPLE
    .\Invoke-Task.ps1 -Lint -Skip powershell
    .NOTES
    - PSScriptAnalyzer is configured by ./PSScriptAnalyzerSettings.psd1
    - Custom PSScriptAnalyzer rules are added from ./PSScriptAnalyzerCustomRules.psm1
    #>
    [CmdletBinding()]
    Param(
        [Switch] $CI,
        [Alias('noop')]
        [Switch] $DryRun,
        [String[]] $Skip
    )
    if (-not ($Skip -contains 'dotnet')) {
        "==> Formatting C# code`n" | Write-Output
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
            Fix = (-not $DryRun)
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
    <#
    .SYNOPSIS
    Run unit tests for C# using dotnet and PowerShell using Pester
    .PARAMETER Exclude
    Skip PowerShell tests with certain tag (example: LinuxOnly)
    .PARAMETER Filter
    Only run tests (Describe or It) that match filter string (-like wildcards allowed)
    .PARAMETER Skip
    Skip running tests for powershell and/or dotnet
    .PARAMETER Tags
    Only run tests (Describe or It) with certain tags
    .PARAMETER WithCoverage
    Generate code coverage data from unit tests
    .EXAMPLE
    .\Invoke-Task.ps1 -Test -Skip powershell
    .EXAMPLE
    .\Invoke-Task.ps1 -Test -WithCoverage
    .EXAMPLE
    .\Invoke-Task.ps1 -Test -Tags Remote -Platform windows
    .EXAMPLE
    .\Invoke-Task.ps1 -Test -Filter '*Readability*'
    .NOTES
    Coverage report can be opened with "Invoke-Item .\coverage\index.htm"
    #>
    [CmdletBinding()]
    Param(
        [String] $Exclude = '',
        [String] $Filter,
        [String[]] $Skip,
        [String[]] $Tags,
        [Switch] $WithCoverage
    )
    Set-BuildEnvironment -VariableNamePrefix 'Prelude' -Force
    $BuildSystem = if ($Env:PreludeBuildSystem -eq 'Unknown') { 'Local Computer' } else { $Env:PreludeBuildSystem }
    if (-not ($Skip -contains 'dotnet')) {
        $ProjectPath = "$PSScriptRoot/csharp/Tests/Tests.csproj"
        "==> Executing C# tests on $BuildSystem" | Write-Output
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
        "==> Executing PowerShell tests on $BuildSystem" | Write-Output
        $Result = Invoke-Pester -Configuration $Configuration
        if ($Result.FailedCount -gt 0) {
            $FailedMessage = "==> FAILED - $($Result.FailedCount) PowerShell test(s) failed"
            throw $FailedMessage
        } else {
            Write-Message pass
        }
    }
}
function Invoke-Publish {
    <#
    .SYNOPSIS
    Update version and publish module to PowerShell Gallery
    .PARAMETER DryRun
    Go through steps without actually making changes or publishing module
    .PARAMETER Major
    Designate major version bump (i.e. 1.1.1 -> 2.0.0)
    .PARAMETER Minor
    Designate minor version bump (i.e. 1.1.1 -> 1.2.0)
    .EXAMPLE
    .\Invoke-Task.ps1 -Publish
    .EXAMPLE
    .\Invoke-Task.ps1 -Publish -Major
    .EXAMPLE
    .\Invoke-Task.ps1 -Publish -Minor
    .NOTES
    When no version switch is used (-Major or -Minor), "build" version will be used (i.e. 1.1.1 -> 1.1.2)
    #>
    [CmdletBinding()]
    Param(
        [Alias('noop')]
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
function Invoke-Help {
    [CmdletBinding()]
    Param()
    switch (Get-TaskList) {
        benchmark {
            Get-Help Invoke-Benchmark -Full
        }
        check {
            Get-Help Invoke-Check -Full
        }
        lint {
            Get-Help Invoke-Lint -Full
        }
        test {
            Get-Help Invoke-Test -Full
        }
        build {
            Get-Help Invoke-Build -Full
        }
        publish {
            Get-Help Invoke-Publish -Full
        }
    }
}
switch (Get-TaskList) {
    help {
        Invoke-Help
        Break
    }
    benchmark {
        Invoke-Benchmark
        Break
    }
    check {
        Invoke-Check
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
            Exclude = $Exclude
            Filter = $Filter
            Skip = $Skip
            Tags = $Tags
            WithCoverage = $WithCoverage
        }
        Invoke-Test @Parameters
        if ($GenerateCoverageReport) {
            $SourceDirs = $SourceDirectory
            $ReportTypes = 'Html;HtmlSummary;HtmlChart'
            reportgenerator.exe -reports:'**/coverage.xml' -targetdir:coverage -sourcedirs:$SourceDirs -historydir:.history -reporttypes:$ReportTypes
            if ($Show) {
                Invoke-Item ./coverage/index.htm
            }
        }
    }
    build {
        if (-not $BuildOnly) {
            Invoke-Lint -Skip 'powershell'
            Invoke-Test -Skip 'powershell'
        }
        if ($LASTEXITCODE -eq 0) {
            Invoke-Build
        } else {
            Write-Message -Text fail
            break
        }
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
