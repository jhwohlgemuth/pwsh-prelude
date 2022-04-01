#Requires -Modules BuildHelpers,pester,PSScriptAnalyzer
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('AdvancedFunctionHelpContent', '')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('RequireDirective', '')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '')]
[CmdletBinding()]
Param(
    [Switch] $Lint,
    [Switch] $Test,
    [Switch] $Mutate,
    [ValidateSet('Geodetic', 'Graph', 'Matrix')]
    [String] $Project,
    [Switch] $Detailed,
    [Switch] $WithCoverage,
    [Switch] $GenerateCoverageReport,
    [Switch] $Show,
    [Switch] $CI,
    [Switch] $Build,
    [Switch] $BuildOnly,
    [ValidateSet('2022', '2019')]
    [String] $Version = '2022',
    [String] $Offering = 'Community',
    [ValidateSet('x64', 'x86')]
    [String] $Architecture = 'x64',
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
$VisualStudioData = @{
    Version = $Version
    Offering = $Offering
    Architecture = $Architecture
}
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
    Param(
        [Parameter(Position = 0, ValueFromPipeline = $True)]
        [String] $Text,
        [Switch] $Success,
        [Switch] $Fail
    )
    if ($Success -and (-not $Fail)) {
        '[+] ' | Write-Host -ForegroundColor Green -NoNewline
        $Text | Write-Host
    } elseif ($Fail) {
        '[-] ' | Write-Host -ForegroundColor Red -NoNewline
        $Text | Write-Host
    } else {
        $Text | Write-Host -ForegroundColor DarkGray
    }
}
function Write-Result {
    [CmdletBinding()]
    Param(
        [Parameter(Position = 0)]
        [ValidateSet('done', 'pass', 'fail')]
        [String] $Result = 'done'
    )
    $Color = switch ($Result) {
        'done' { 'Gray' }
        'pass' { 'Green' }
        'fail' { 'Red' }
    }
    $Message = switch ($Result) {
        pass {
            @(
                '██████╗  █████╗ ███████╗███████╗'
                '██╔══██╗██╔══██╗██╔════╝██╔════╝'
                '██████╔╝███████║███████╗███████╗'
                '██╔═══╝ ██╔══██║╚════██║╚════██║'
                '██║     ██║  ██║███████║███████║'
                '╚═╝     ╚═╝  ╚═╝╚══════╝╚══════╝'
            )
        }
        fail {
            @(
                '  █████▒▄▄▄       ██▓ ██▓    '
                '▓██   ▒▒████▄    ▓██▒▓██▒    '
                '▒████ ░▒██  ▀█▄  ▒██▒▒██░    '
                '░▓█▒  ░░██▄▄▄▄██ ░██░▒██░    '
                '░▒█░    ▓█   ▓██▒░██░░██████▒'
                '▒ ░    ▒▒   ▓▒█░░▓  ░ ▒░▓  ░ '
                '░       ▒   ▒▒ ░ ▒ ░░ ░ ▒  ░ '
                '░ ░     ░   ▒    ▒ ░  ░ ░    '
                '            ░  ░ ░      ░  ░ '
            )
        }
        done {
            @(
                '██████   ██████  ███    ██ ███████ '
                '██   ██ ██    ██ ████   ██ ██      '
                '██   ██ ██    ██ ██ ██  ██ █████   '
                '██   ██ ██    ██ ██  ██ ██ ██      '
                '██████   ██████  ██   ████ ███████ '
            )
        }
    }
    '' | Write-Host
    $Message | ForEach-Object {
        $_ | Write-Host -ForegroundColor $Color
    }
    '' | Write-Host
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
        mutate
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
    if ($Mutate) {
        $Tasks += [Task]'mutate'
    }
    if ($Build) {
        $Tasks += [Task]'build'
    }
    if ($Publish) {
        $Tasks += [Task]'publish'
    }
    $Tasks
}
function Get-VisualStudioRoot {
    [CmdletBinding()]
    [OutputType([String])]
    Param(
        [ValidateSet('2022', '2019')]
        [String] $Version = '2022',
        [String] $Offering = 'Community',
        [ValidateSet('x64', 'x86')]
        [String] $Architecture = 'x64'
    )
    $ProgramFilesPostfix = if ($Architecture -eq 'x86') { ' (x86)' } else { '' }
    "C:\Program Files${ProgramFilesPostfix}\Microsoft Visual Studio\${Version}\${Offering}"
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
    '==> [INFO] Running C# Benchmarks' | Write-Message
    $ProjectPath = "${PSScriptRoot}/csharp/Performance/Performance.csproj"
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
        [ValidateSet('2022', '2019')]
        [String] $Version = '2022',
        [String] $Offering = 'Community',
        [ValidateSet('x64', 'x86')]
        [String] $Architecture = 'x64'
    )
    $VisualStudioData = @{
        Version = $Version
        Offering = $Offering
        Architecture = $Architecture
    }
    $VisualStudioRoot = Get-VisualStudioRoot @VisualStudioData
    $ToolsDirectory = "${VisualStudioRoot}\Common7\Tools"
    $CompilerPath = "${VisualStudioRoot}\MSBuild\Current\Bin\Roslyn\csc.exe"
    if ((Test-Path $ToolsDirectory)) {
        '==> [INFO] Setting environment variables' | Write-Message
        & (Join-Path $ToolsDirectory 'VsDevCmd.bat') -no_logo
    } else {
        '==> [ERROR] Could not find VsDevCmd.bat which is needed to set environment variables' | Write-Error
    }
    if ((Test-Path $CompilerPath)) {
        $CsharpDirectory = "${PSScriptRoot}/csharp"
        $OutputDirectory = "${PSScriptRoot}/Prelude/bin"
        $SystemNumerics = "$([System.Runtime.InteropServices.RuntimeEnvironment]::GetRuntimeDirectory())\System.Numerics.dll"
        'Geodetic' | ForEach-Object {
            "==> [INFO] Building $_ link library" | Write-Message
            & $CompilerPath "$CsharpDirectory/${_}/${_}.cs" -out:"$OutputDirectory/${_}.dll" -optimize -nologo -target:library
        }
        'Matrix' | ForEach-Object {
            "==> [INFO] Building $_ link library" | Write-Message
            & $CompilerPath "$CsharpDirectory/${_}/${_}.cs" -out:"$OutputDirectory/${_}.dll" -optimize -nologo -target:library -reference:$SystemNumerics
        }
        'Node' | ForEach-Object {
            "==> [INFO] Building $_ link library" | Write-Message
            & $CompilerPath "$CsharpDirectory/Graph/${_}.cs" -out:"$OutputDirectory/${_}.dll" -optimize -nologo -target:library -lib:$OutputDirectory
        }
        'Item' | ForEach-Object {
            "==> [INFO] Building $_ link library" | Write-Message
            & $CompilerPath "$CsharpDirectory/Graph/${_}.cs" -out:"$OutputDirectory/${_}.dll" -optimize -nologo -target:library -lib:$OutputDirectory -reference:Node.dll
        }
        'Edge', 'PriorityQueue' | ForEach-Object {
            "==> [INFO] Building $_ link library" | Write-Message
            & $CompilerPath "$CsharpDirectory/Graph/${_}.cs" -out:"$OutputDirectory/${_}.dll" -optimize -nologo -target:library -lib:$OutputDirectory -reference:Matrix.dll -reference:Node.dll -reference:Item.dll
        }
        'DirectedEdge', 'Graph' | ForEach-Object {
            "==> [INFO] Building $_ link library" | Write-Message
            & $CompilerPath "$CsharpDirectory/Graph/${_}.cs" -out:"$OutputDirectory/${_}.dll" -optimize -nologo -target:library -lib:$OutputDirectory -reference:$SystemNumerics -reference:Matrix.dll -reference:Node.dll -reference:Edge.dll -reference:PriorityQueue.dll
        }
        Write-Result done
    } else {
        '==> [ERROR] Could not find C# compiler (csc.exe)' | Write-Error
    }
}
function Invoke-Check {
    <#
    .SYNOPSIS
    Run series of checks to determine if environment supports Prelude development.
    .DESCRIPTION
    Checks are run against Visual Studio 2022 Community Edition by default. Checks can be performed against other versions and offering using the -Version and -Offering parameters, respectively.
    .EXAMPLE
    .\Invoke-Task.ps1 -Check
    .NOTES
    When -Benchmark parameter is used, no other tasks will be executed.
    #>
    [CmdletBinding()]
    Param(
        [ValidateSet('2022', '2019')]
        [String] $Version = '2022',
        [String] $Offering = 'Community',
        [ValidateSet('x64', 'x86')]
        [String] $Architecture = 'x64'
    )
    $VisualStudioData = @{
        Version = $Version
        Offering = $Offering
        Architecture = $Architecture
    }
    $VisualStudioRoot = Get-VisualStudioRoot @VisualStudioData
    $Fails = 0
    "`n==> [INFO] Checking build requirements" | Write-Message
    "==> [INFO] VS Studio Version: ${Version}" | Write-Message
    "==> [INFO] Offering: ${Offering}" | Write-Message
    "==> [INFO] Architecture: ${Architecture}`n" | Write-Message
    if ((Get-Command -Name 'dotnet' -ErrorAction Ignore)) {
        'dotnet command is available!' | Write-Message -Success
    } else {
        'Failed to find dotnet command...' | Write-Message -Fail
        $Fails++
    }
    $ToolList = dotnet tool list
    @('reportgenerator', 'dotnet-stryker') | ForEach-Object {
        $ToolName = $_
        $DotnetToolInstalled = (($ToolList -match $ToolName) -split '\s+') -contains $ToolName
        $CommandName = $ToolName -replace 'dotnet-', ''
        if ($DotnetToolInstalled) {
            "`"dotnet ${CommandName}`" command is available!" | Write-Message -Success
        } else {
            "Failed to find ${CommandName} command..." | Write-Message -Fail
            $Fails++
        }
    }
    if ((Test-Path "$VisualStudioRoot\Common7\Tools\VsDevCmd.bat")) {
        'Successfully found VsDevCmd.bat!' | Write-Message -Success
    } else {
        'Failed to find necessary BAT file...' | Write-Message -Fail
        $Fails++
    }
    if ((Test-Path "$VisualStudioRoot\MSBuild\Current\Bin\Roslyn\csc.exe")) {
        'Successfully found csc.exe!' | Write-Message -Success
    } else {
        'Failed to find C# compiler...' | Write-Message -Fail
        $Fails++
    }
    $Result = if ($Fails -eq 0) { 'pass' } else { 'fail' }
    Write-Result $Result
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
        "==> [INFO] Formatting C# code`n" | Write-Message
        $Format = {
            Param(
                [String] $Name
            )
            $Path = Join-Path "$PSScriptRoot/csharp/$Name" "${Name}.csproj"
            if ($DryRun) {
                dotnet tool run dotnet-format --check $Path --verbosity diagnostic
            } else {
                dotnet tool run dotnet-format $Path --verbosity detailed
            }
        }
        if ((Get-Command -Name 'dotnet' -ErrorAction Ignore)) {
            'Matrix', 'Geodetic', 'Graph', 'Tests' | ForEach-Object {
                & $Format -Name $_
            }
        } else {
            '==> [ERROR] Global dotnet-format tool is required. Please run "./Invoke-Setup.ps1"' | Write-Error
        }
    }
    if (-not ($Skip -contains 'powershell')) {
        $PesterData = Import-Module -Name Pester -PassThru -MinimumVersion 5.0.4
        $PSScriptAnalyzerData = Import-Module -Name PSScriptAnalyzer -PassThru -MinimumVersion 1.20.0
        $Parameters = @{
            Path = $PSScriptRoot
            Settings = 'PSScriptAnalyzerSettings.psd1'
            Fix = (-not $DryRun)
            EnableExit = $CI
            ReportSummary = $True
            Recurse = $True
        }
        "`n==> [INFO] Linting PowerShell code (Path = $($Parameters.Path))" | Write-Message
        "==> [INFO] Using Pester v$($PesterData.Version.ToString())" | Write-Message
        "==> [INFO] Using PSScriptAnalyzer v$($PSScriptAnalyzerData.Version.ToString())`n" | Write-Message
        Invoke-ScriptAnalyzer @Parameters
    }
    "`n" | Write-Host
}
function Invoke-Mutate {
    <#
    .SYNOPSIS
    Execute Stryker mutation tests
    #>
    [CmdletBinding()]
    Param(
        [ValidateSet('Geodetic', 'Graph', 'Matrix')]
        [String] $Project,
        [String] $Configuration = 'stryker-config.json'
    )
    $Path = Join-Path $PSScriptRoot $Configuration
    "`n==> [INFO] Running Stryker mutation tests on ${Project}" | Write-Message
    "==> [INFO] Using Stryker configuration file at ${Path}`n" | Write-Message
    $FileName = switch ($Project) {
        'Geodetic' { 'Geodetic.csproj' }
        'Graph' { 'Graph.csproj' }
        'Matrix' { 'Matrix.csproj' }
    }
    dotnet stryker --config-file $Path --project $FileName --open-report
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
    "${Prefix}==> $ValidateManifest" | Write-Message
    "${Prefix}==> $ValidateApiKey" | Write-Message
    $Increment = if ($Major) {
        'Major'
    } elseif ($Minor) {
        'Minor'
    } else {
        'Build'
    }
    if (-not $DryRun) {
        "==> [INFO] Updating Module $(${Increment}.ToUpper()) Version..." | Write-Message
        Update-Metadata $ProjectManifestPath -Increment $Increment
        '==> [INFO] Publishing module...' | Write-Message
        Publish-Module -Path $ModulePath -NuGetApiKey $Env:NUGET_API_KEY -SkipAutomaticTags -Verbose
        "`n==> DONE`n" | Write-Message
    } else {
        "${Prefix}Updating Module $(${Increment}.ToUpper()) Version..." | Write-Message
        "${Prefix}Publishing module..." | Write-Message
        "${Prefix}==> DONE" | Write-Message
    }
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
        "==> [INFO] Executing C# tests on $BuildSystem" | Write-Message
        if ($WithCoverage) {
            dotnet test $ProjectPath /p:CollectCoverage=true /p:CoverletOutput=coverage.xml /p:CoverletOutputFormat=opencover
        } else {
            dotnet test $ProjectPath --logger:'console;verbosity=detailed'
        }
        "`n`n" | Write-Output
    }
    if (-not ($Skip -contains 'powershell')) {
        $PesterData = Import-Module -Name Pester -PassThru -RequiredVersion 5.3.1
        $Parameters = @{
            Run = @{ PassThru = $True }
            Filter = @{ ExcludeTag = $Exclude }
            Debug = @{
                ShowNavigationMarkers = $True
                WriteVSCodeMarker = $True
            }
        }
        $Configuration = if ($PesterData.Version.Minor -ge 2) {
            New-PesterConfiguration -Hashtable $Parameters
        } else {
            [PesterConfiguration]$Parameters
        }
        if ($Filter) {
            $Configuration.Filter.FullName = $Filter
        } elseif ($Tags) {
            $Configuration.Filter.Tag = $Tags
        }
        if ($WithCoverage) {
            $Configuration.CodeCoverage = @{
                Enabled = $True
                Path = (Get-ChildItem (Join-Path $PSScriptRoot $SourceDirectory) -Recurse -Include '*.ps1').FullName
            }
            $Configuration.TestResult = @{ Enabled = $False }
        }
        if ($Detailed) {
            $Configuration.Output.Verbosity = 'Detailed'
        }
        "`n==> [INFO] Executing PowerShell tests on $BuildSystem" | Write-Message
        "==> [INFO] Using Pester v$($PesterData.Version.ToString())`n" | Write-Message
        $Result = Invoke-Pester -Configuration $Configuration
        if ($Result.FailedCount -gt 0) {
            $FailedMessage = "==> FAILED - $($Result.FailedCount) PowerShell test(s) failed"
            throw $FailedMessage
        } else {
            Write-Result pass
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
        Invoke-Check @VisualStudioData
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
        Set-Location $PSScriptRoot
        if ($GenerateCoverageReport) {
            $SourceDirs = $SourceDirectory
            $ReportTypes = 'Html;HtmlSummary;HtmlChart'
            dotnet reportgenerator -reports:'**/coverage.xml' -targetdir:coverage -sourcedirs:$SourceDirs -historydir:.history -reporttypes:$ReportTypes
            if ($Show) {
                Invoke-Item ./coverage/index.htm
            }
        }
    }
    mutate {
        $Parameters = @{
            Project = $Project
        }
        Invoke-Mutate @Parameters
        Break
    }
    build {
        if (-not $BuildOnly) {
            $Parameters = @{ Skip = 'powershell' }
            Invoke-Lint @Parameters
            Invoke-Test @Parameters
        }
        if ($LASTEXITCODE -eq 0) {
            Invoke-Build @VisualStudioData
        } else {
            Write-Result fail
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
