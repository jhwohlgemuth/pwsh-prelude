[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingInvokeExpression', '', Scope = 'Function', Target = 'New-Template')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '', Scope = 'Function', Target = 'ConvertTo-PowerShellSyntax')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '', Scope = 'Function', Target = 'New-WebApplication')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '', Scope = 'Function', Target = 'Remove-Indent')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '', Scope = 'Function', Target = 'Test-ApplicationContext')]
Param()

class ApplicationState {
    [String] $Id = (New-Guid)
    [Bool] $Continue = $True
    [String] $Name = 'Application Name'
    [String] $Parent = (Get-Location).Path
    [String] $Type = 'Terminal'
    $Data
}
function ConvertTo-PowerShellSyntax {
    [OutputType([String])]
    Param(
        [Parameter(Mandatory = $True, Position = 0, ValueFromPipeline = $True)]
        [String] $Value,
        [String] $DataVariableName = 'Data'
    )
    Write-Output $Value |
        ForEach-Object { $_ -replace '(?<!(}}[\w\s]*))(?<!{{#[\w\s\-_]*)\s*}}', ')' } |
        ForEach-Object { $_ -replace '{{(?!#)\s*', "`$(`$$DataVariableName." }
}
function Get-State {
    <#
    .SYNOPSIS
    Load state from file
    .EXAMPLE
    $State = Get-State -Id 'abc-def-ghi'
    .EXAMPLE
    $State = 'abc-def-ghi' | Get-State
    #>
    [CmdletBinding()]
    Param(
        [Parameter(Position = 0, ValueFromPipeline = $True)]
        [String] $Id,
        [AllowEmptyString()]
        [String] $Path
    )
    if ($Path.Length -gt 0 -and (Test-Path $Path)) {
        "==> Resolved $Path" | Write-Verbose
    } else {
        $TempRoot = if ($IsLinux) { '/tmp' } else { $Env:temp }
        $Path = Join-Path $TempRoot "state-$Id.xml"
    }
    "==> Loading state from $Path" | Write-Verbose
    Import-Clixml -Path $Path
}
function Format-Json {
    <#
    .SYNOPSIS
    Prettify JSON output
    .EXAMPLE
    Get-Content './foo.json' | Format-Json | Out-File './bar.json' -Encoding utf8
    .EXAMPLE
    './some.json' | Format-Json -InPlace
    #>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $True, ValueFromPipeline = $True)]
        [String] $Value,
        [ValidateSet(2, 4)]
        [Int] $Indentation = 2,
        [Switch] $InPlace
    )
    $Indent = 0
    $NewLine = '\r?\n'
    $Quoted = '(?=([^"]*"[^"]*")*[^"]*$)'
    $IsValidPath = Test-Path -Path $Value
    $Data = if ($InPlace -and $IsValidPath) {
        Get-Content -Path $Value -Raw
    } else {
        $Value
    }
    $Compressed = $Data -notmatch $NewLine
    if ($Compressed) {
        $Data = $Data | ConvertFrom-Json | ConvertTo-Json -Depth 100
    }
    $Lines = $Data -split $NewLine
    $Result = foreach ($Line in $Lines) {
        if ($Line -match "[}\]]${Quoted}") {
            $Indent = ($Indent - $Indentation), 0 | Get-Maximum
        }
        $Temp = (' ' * $Indent) + ($Line.TrimStart() -replace ":\s+${Quoted}", ': ')
        if ($Line -match "[\{\[]${Quoted}") {
            $Indent += $Indentation
        }
        $Temp
    }
    if ($InPlace -and $IsValidPath) {
        $Result | Set-Content -Path $Value | Out-Null
    } else {
        $Result -join [Environment]::NewLine
    }
}
function Invoke-FireEvent {
    <#
    .SYNOPSIS
    Create event
    .EXAMPLE
    'eventName' | Invoke-FireEvent
    #>
    [CmdletBinding()]
    [Alias('trigger')]
    Param(
        [Parameter(Mandatory = $True, Position = 0, ValueFromPipeline = $True)]
        [String] $Name,
        [PSObject] $Data
    )
    New-Event -SourceIdentifier $Name -MessageData $Data | Out-Null
}
function Invoke-RunApplication {
    <#
    .SYNOPSIS
    Entry point for PowerShell CLI application
    .PARAMETER Init
    Function to initialize application, executed when application is started.
    .PARAMETER Loop
    Code to execute during every application loop, executed when ShouldContinue returns True.
    .PARAMETER BeforeNext
    Code to execute at the end of each application loop. It should be used to update the return of ShouldContinue.
    .PARAMETER SingleRun
    As its name implies - use this flag to execute one loop of the application
    .PARAMETER NoCleanup
    Use this switch to disable removing the application event listeners when the application exits.
    Application event listeners can be removed manually with: 'application:' | Invoke-StopListen
    .EXAMPLE
    $Init = {
        # Initialize your app - $Init is only run once
        'Getting things ready...' | Write-Color -Green
    }
    # Define what your app should do every iteration - $Loop is executed until ShouldContinue returns False
    $Loop = {
        Clear-Host
        'Doing something super important...' | Write-Color -Gray
        Start-Sleep 5
    }
    # Start your app
    Invoke-RunApplication $Init $Loop

    # Make a simple app
    .EXAMPLE
    New-TerminalApplicationTemplate -Save

    # Make a simple app with state
    # Note: State is passed to Init, Loop, ShouldContinue, and BeforeNext
    .EXAMPLE
    { say 'Hello' } | on 'application:init'
    { say 'Wax on' } | on 'application:loop:before'
    { say 'Wax off' } | on 'application:loop:after'
    { say 'Goodbye' } | on 'application:exit'

    # Applications trigger events throughout their lifecycle which can be listened to (most commonly within the Init scriptblock).
    # The triggered event will include State as MessageData

    {
        $Id = $Event.MessageData.State.Id
        "`nApplication ID: $Id" | Write-Color -Green
    } | Invoke-ListenTo 'application:init'
    #>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $True, Position = 0)]
        [ScriptBlock] $Init,
        [Parameter(Mandatory = $True, Position = 1)]
        [ScriptBlock] $Loop,
        [Parameter(Position = 2)]
        [ApplicationState] $State = @{},
        [String] $Id,
        [ScriptBlock] $ShouldContinue,
        [ScriptBlock] $BeforeNext,
        [Switch] $ClearState,
        [Switch] $SingleRun,
        [Switch] $NoCleanup
    )
    if ($Id.Length -gt 0) {
        $TempRoot = if ($IsLinux) { '/tmp' } else { $Env:temp }
        $Path = Join-Path $TempRoot "state-$Id.xml"
        if ($ClearState -and (Test-Path $Path)) {
            Remove-Item $Path
        }
        if (Test-Path $Path) {
            "==> Resolved state with ID: $Id" | Write-Verbose
            try {
                [ApplicationState]$State = Get-State $Id
                $State.Id = $Id
            } catch {
                "==> Failed to get state with ID: $Id" | Write-Verbose
                $State = [ApplicationState]@{ Id = $Id }
            }
        } else {
            $State.Id = $Id
        }
    }
    if (-not $State) {
        $State = [ApplicationState]@{}
    }
    if (-not $ShouldContinue) {
        $ShouldContinue = { $State.Continue -eq $True }
    }
    if (-not $BeforeNext) {
        $BeforeNext = {
            "`n`nContinue?" | Write-Label -NewLine
            $State.Continue = ('yes', 'no' | Invoke-Menu) -eq 'yes'
        }
    }
    "Application ID: $($State.Id)" | Write-Verbose
    'application:init' | Invoke-FireEvent
    & $Init $State
    if ($SingleRun) {
        'application:loop:before' | Invoke-FireEvent -Data @{ State = $State }
        & $Loop $State
        'application:loop:after' | Invoke-FireEvent -Data @{ State = $State }
    } else {
        while (& $ShouldContinue $State) {
            'application:loop:before' | Invoke-FireEvent -Data @{ State = $State }
            & $Loop $State
            'application:loop:after' | Invoke-FireEvent -Data @{ State = $State }
            & $BeforeNext $State
        }
    }
    'application:exit' | Invoke-FireEvent -Data @{ State = $State }
    if (-not $NoCleanup) {
        'application:' | Invoke-StopListen
    }
    $State.Id
}
function Invoke-StopListen {
    <#
    .SYNOPSIS
    Remove event subscriber(s)
    .EXAMPLE
    $Callback | on 'SomeEvent'
    'SomeEvent' | Invoke-StopListen

    # Remove events using the event "source identifier" (Name)
    .EXAMPLE
    $Callback | on -Name 'Namespace:foo'
    $Callback | on -Name 'Namespace:bar'
    'Namespace:' | Invoke-StopListen

    # Remove multiple events using an event namespace
    .EXAMPLE
    $Listener = $Callback | on 'SomeEvent'
    Invoke-StopListen -EventData $Listener

    # Selectively remove a single event by passing its event data
    #>
    [CmdletBinding()]
    Param(
        [Parameter(ValueFromPipeline = $True)]
        [String] $Name,
        [PSObject] $EventData
    )
    if ($EventData) {
        Unregister-Event -SubscriptionId $EventData.Id
    } else {
        if ($Name) {
            $Events = Get-EventSubscriber | Where-Object { $_.SourceIdentifier -match "^$Name" }
        } else {
            $Events = Get-EventSubscriber
        }
        $Events | ForEach-Object { Unregister-Event -SubscriptionId $_.SubscriptionId }
    }
}
function New-TerminalApplicationTemplate {
    <#
    .SYNOPSIS
    Return boilerplate string of a Prelude terminal application
    .EXAMPLE
    New-TerminalApplicationTemplate | Out-File 'my-app.ps1'
    #>
    [CmdletBinding()]
    [OutputType([String])]
    Param()
    $Snippet = if (-not $IsLinux) {
        '
        {
            Invoke-Speak goodbye
            $Id = $Event.MessageData.State.Id
            "Application ID: $Id" | Write-Color -Magenta
        } | Invoke-ListenTo ''application:exit'' | Out-Null
        ' | Remove-Indent
    } else {
        ''
    }
    $Data = @{
        Empty = ''
        Snippet = $Snippet
    }
    '    #Requires -Modules Prelude
    [CmdletBinding()]
    Param(
        [String] $Id = ''app'',
        [Switch] $Clear
    )
    {{ Empty }}
    $InitialState = @{ Data = 0; Type = ''Terminal'' }
    {{ Empty }}
    $Init = {
        Clear-Host
        $State = $Args[0]
        $Id = $State.Id
        ''Application Information:'' | Write-Color
        `"ID = {{#green $Id}}`" | Write-Label -Color Gray -Indent 2 -NewLine
        ''Name = {{#green My-App}}'' | Write-Label -Color Gray -Indent 2 -NewLine
        {{ Snippet }}
        Start-Sleep 2
    }
    {{ Empty }}
    $Loop = {
        Clear-Host
        $State = $Args[0]
        $Count = $State.Data
        `"Current count is {{#green $Count}}`" | Write-Color -Cyan
        $State.Data++
        Save-State $State.Id $State | Out-Null
        Start-Sleep 1
    }
    {{ Empty }}
    Invoke-RunApplication $Init $Loop $InitialState -Id $Id -ClearState:$Clear
    ' | Remove-Indent | New-Template -Data $Data
}
function New-Template {
    <#
    .SYNOPSIS
    Create render function that interpolates passed object values
    .PARAMETER Data
    Pass template data to New-Template when using New-Template within pipe chain (see examples)
    .PARAMETER NoData
    For use in tandem with templates that ONLY use external data (e.g. $Env variables)
    .PARAMETER File
    Path to file containing template content
    .EXAMPLE
    $Function:render = New-Template '<div>Hello {{ name }}!</div>'
    render @{ name = 'World' }
    # '<div>Hello World!</div>'

    # Use mustache template syntax! Just like Handlebars.js!
    .EXAMPLE
    $Function:render = 'hello {{ name }}' | New-Template
    @{ name = 'world' } | render
    # 'hello world'

    # New-Template supports idiomatic PowerShell pipeline syntax
    .EXAMPLE
    $title = New-Template -Template '<h1>{{ text }}</h1>' -DefaultValues @{ text = 'Default' }

    & $title
    # '<h1>Default</h1>'

    & $title @{ text = 'Hello World' }
    # '<h1>Hello World</h1>'

    # Provide default values for your templates!
    .EXAMPLE
    $Function:Div = '<div>{{ v }}</div>' | New-Template
    $Function:Span = '<span>{{ v }}</span>' | New-Template
    Div @{ v = Span @{ v = 'Hello World' } } | Write-Output
    # "<div><span>Hello World</span></div>"

    # Templates can even be nested!
    .EXAMPLE
    '{{#green Hello}} {{ name }}' | tpl -Data @{ name = 'World' } | Write-Color

    # Use of the -Data parameter will cause New-Template to return a formatted string instead of template function
    .EXAMPLE
    New-Template -File path/to/file -Data $Data | Write-Color -Cyan

    # Load a template from a file
    .EXAMPLE
    $Function:Element = '<{{ tag }}>{{ text }}</{{ tag }}>' | New-Template
    $Function:Div = Element @{ tag = 'div' } -Partial | New-Template
    Div @{ text = 'Hello World' }
    # '<div>Hello World</div>'

    # Create partial templates using the -Partial parameter
    .EXAMPLE
    'The answer is {{= $Value + 2 }}' | tpl -Data @{ Value = 40 }
    # "The answer is 42"

    # Execute PowerShell code within your templates using the {{= ... }} syntax
    .EXAMPLE
    'The fox says {{= $Env:SomeRandomValue }}!!!' | New-Template -NoData

    # Even access environment variables. Use -NoData when no data needs to be passed.
    .EXAMPLE
    '{{- This is a comment }}Super important stuff' | tpl -NoData

    # Add comments to templates using {{- ... }} syntax
    #>
    [CmdletBinding()]
    [Alias('tpl')]
    [OutputType([String])]
    Param(
        [Parameter(ParameterSetName = 'string', Mandatory = $True, Position = 0, ValueFromPipeline = $True)]
        [String] $Template,
        [Parameter(ParameterSetName = 'file')]
        [String] $File,
        [Alias('Data')]
        [Hashtable] $Binding = @{},
        [Switch] $NoData,
        [Hashtable] $DefaultValues = @{},
        [Switch] $PassThru
    )
    Begin {
        $Script:TemplateKeyNamesNotPassed = @()
        $Pattern = '(?<expression>{{(?<indicator>(=|-|#))?\s+(?<variable>.*?)\s*}})'
        $Renderer = {
            Param(
                [ScriptBlock] $Script,
                [Hashtable] $Binding = @{}
            )
            $Binding.GetEnumerator() | ForEach-Object { New-Variable -Name $_.Key -Value $_.Value }
            try {
                $Script.Invoke()
            } catch {
                throw $_
            }
        }
        $Evaluator = {
            Param($Match)
            $Groups = $Match.Groups
            $Value = $Groups[1].Value
            $Indicator = $Groups | Where-Object { $_.Name -eq 'indicator' } | Get-Property 'Value'
            $Variable = $Groups | Where-Object { $_.Name -eq 'variable' } | Get-Property 'Value'
            switch ($Indicator) {
                '#' { $Value }
                '-' { '' }
                '=' {
                    $Block = [ScriptBlock]::Create('$($(' + ($Variable -replace '`(?=\$)', '') + ') | Write-Output)')
                    $Binding = $DefaultValues, $Binding | Invoke-ObjectMerge -Force
                    try {
                        $PowerShell = [PowerShell]::Create()
                        $PowerShell.AddScript($Renderer).AddParameter('Binding', $Binding).AddParameter('Script', $Block).Invoke()
                    } catch {
                        "==> [ERROR] Something went wrong within the Evaluator when rendering: {{#yellow ${Block} }}`n" | Write-Color -Red
                        "==> [INFO] `$Binding = $($Binding | ConvertTo-Json -Compress)`n" | Write-Color -DarkGray
                        $_ | Write-Error
                    } finally {
                        if ($PowerShell) {
                            $PowerShell.Dispose()
                        }
                    }
                }
                Default {
                    $Script:TemplateKeyNamesNotPassed += $Variable
                    "`${${Variable}}"
                }
            }
        }
    }
    Process {
        $PLACEHOLDER = '<<<DOUBLE QUOTES PRELUDE PLACEHOLDER>>>'
        if ($File) {
            $Path = Get-StringPath $File
            $Template = Get-Content $Path -Raw
        }
        $EvaluatedTemplate = [Regex]::Replace(($Template -replace '[$]', '`$'), $Pattern, $Evaluator)
        if ($File) {
            # $EvaluatedTemplate = ($EvaluatedTemplate -replace '"', '""')
        }
        $TemplateScriptBlock = [ScriptBlock]::Create('$("' + ($EvaluatedTemplate -replace '"', $PLACEHOLDER) + '" | Write-Output)')
        $NotPassed = $Script:TemplateKeyNamesNotPassed
        if (($Binding.Count -gt 0) -or $NoData) {
            if ($PassThru) {
                return $Template
                exit
            }
            $Binding = $DefaultValues, $Binding | Invoke-ObjectMerge -Force
            try {
                $PowerShell = [PowerShell]::Create()
                $PowerShell.AddScript($Renderer).AddParameter('Binding', $Binding).AddParameter('Script', $TemplateScriptBlock).Invoke() -replace $PLACEHOLDER, '"'
            } catch {
                "==> [ERROR] Something went wrong when rendering: {{#yellow ${TemplateScriptBlock} }}`n" | Write-Color -Red
                "==> [INFO] No data passed`n" | Write-Color -DarkGray
                $_ | Write-Error
            } finally {
                if ($PowerShell) {
                    $PowerShell.Dispose()
                }
            }
        } else {
            {
                Param(
                    [Parameter(Position = 0, ValueFromPipeline = $True)]
                    [Alias('Data')]
                    [Hashtable] $Binding = @{},
                    [Array] $NotPassed = $NotPassed,
                    [Switch] $Partial,
                    [Switch] $PassThru
                )
                if ($PassThru) {
                    return $Template
                    exit
                }
                $PartialValues = @{}
                if ($Partial) {
                    foreach ($Key in $NotPassed) {
                        if ([String]::IsNullOrEmpty($Binding[$Key])) {
                            $PartialValues[$Key] = "{{ ${Key} }}"
                        }
                    }
                }
                $Binding = $PartialValues, $DefaultValues, $Binding | Invoke-ObjectMerge -Force
                try {
                    $PowerShell = [PowerShell]::Create()
                    $PowerShell.AddScript($Renderer).AddParameter('Binding', $Binding).AddParameter('Script', $TemplateScriptBlock).Invoke() -replace $PLACEHOLDER, '"'
                } catch {
                    "==> [ERROR] Something went wrong when rendering: {{#yellow ${TemplateScriptBlock} }}`n" | Write-Color -Red
                    "==> [INFO] `$Binding = $($Binding | ConvertTo-Json -Compress)`n" | Write-Color -DarkGray
                    $_ | Write-Error
                } finally {
                    if ($PowerShell) {
                        $PowerShell.Dispose()
                    }
                }
            }.GetNewClosure()
        }
    }
}
function New-DesktopApplication {
    <#
    .SYNOPSIS
    Create a new desktop application.
    #>
    [CmdletBinding()]
    Param(
        [Parameter(ValueFromPipeline = $True)]
        [PSObject] $Configuration = @{}
    )
    Begin {}
    Process {}
    End {}
}
function New-WebApplication {
    <#
    .SYNOPSIS
    Create a new web application.
    .PARAMETER Name
    Name of application folder
    .PARAMETER Parent
    Parent directory in which to create the application directory
    .EXAMPLE
    New-WebApplication
    .EXAMPLE
    New-WebApplication -Bundler Parcel -Library React -With Cesium
    .EXAMPLE
    New-WebApplication -Parcel -React -With Cesium
    .EXAMPLE
    @{
        Bundler = 'Parcel'
        Library = 'React'
        With = 'Cesium'
    } | New-WebApplication
    #>
    [CmdletBinding(DefaultParameterSetName = 'parameter', SupportsShouldProcess = $True)]
    Param(
        [Parameter(ParameterSetName = 'pipeline', ValueFromPipeline = $True)]
        [PSObject] $Configuration = @{},
        [ApplicationState] $State = @{ Type = 'Web' },
        [Parameter(Position = 0, ParameterSetName = 'parameter')]
        [ValidateSet('Parcel', 'Rollup', 'Snowpack', 'Vite', 'Webpack')]
        [String] $Bundler,
        [Parameter(ParameterSetName = 'switch')]
        [Switch] $Webpack,
        [Parameter(ParameterSetName = 'switch')]
        [Switch] $Parcel,
        [Parameter(ParameterSetName = 'switch')]
        [Switch] $Rollup,
        [Parameter(ParameterSetName = 'switch')]
        [Switch] $Snowpack,
        [Parameter(ParameterSetName = 'switch')]
        [Switch] $Vite,
        [Parameter(Position = 1, ParameterSetName = 'parameter')]
        [AllowNull()]
        [AllowEmptyString()]
        [ValidateSet('', 'Vanilla', 'React', 'Solid')]
        [String] $Library = 'Vanilla',
        [Parameter(ParameterSetName = 'switch')]
        [Switch] $Vanilla,
        [Parameter(ParameterSetName = 'switch')]
        [Switch] $React,
        [Parameter(ParameterSetName = 'switch')]
        [Switch] $Solid,
        [Parameter(ParameterSetName = 'parameter')]
        [ValidateSet('Cesium', 'Reason', 'Rust')]
        [String[]] $With,
        [String] $Name = 'webapp',
        [ValidateScript( { Test-Path $_ })]
        [String] $Parent = (Get-Location).Path,
        [Parameter(ParameterSetName = 'interactive')]
        [Switch] $Interactive,
        [Switch] $NoInstall,
        [Switch] $Silent,
        [Switch] $Force
    )
    Begin {
        $TEMPLATE_DIRECTORY = Join-Path $PSScriptRoot '../src/templates'
        function Copy-TemplateData {
            <#
            .SYNOPSIS
            Utility function for copying template file to the application directory.
            Provides warning message when file already exists and -Force is not used.
            #>
            [CmdletBinding()]
            Param(
                [PSObject] $Data,
                [String] $Template,
                [String] $Parent,
                [String] $Filename,
                [Switch] $Force
            )
            $Path = Join-Path $Parent $Filename
            $Message = "==> [WARN] ${Filename} already exists.  Please either delete ${Filename} or re-run this command with the -Force parameter."
            if (-not (Test-Path -Path $Path) -or $Force) {
                $Parameters = @{
                    File = (Join-Path $TEMPLATE_DIRECTORY $Template)
                    Data = $Data
                    NoData = ($Data.Count -eq 0)
                }
                New-Template @Parameters | Out-File -FilePath $Path -Encoding utf8
            } else {
                $Message | Write-Warning
            }
        }
        function Save-JsonData {
            <#
            .SYNOPSIS
            Utility function for saving JSON data.
            Provides warning message when file already exists and -Force is not used.
            #>
            [CmdletBinding()]
            Param(
                [PSObject] $Data,
                [String] $Parent,
                [String] $Filename,
                [Switch] $Force
            )
            $Path = Join-Path $Parent $Filename
            $Message = "==> [WARN] ${Filename} already exists.  Please either delete ${Filename} or re-run this command with the -Force parameter."
            if (-not (Test-Path -Path $Path) -or $Force) {
                $Data |
                    ConvertTo-Json |
                    ForEach-Object { $_ -replace '\\u003c', '<' } |
                    ForEach-Object { $_ -replace '\\u003e', '>' } |
                    Format-Json |
                    Out-File -FilePath $Path -Encoding utf8
            } else {
                $Message | Write-Warning
            }
        }
        $BundlerOptions = @(
            'Webpack'
            'Parcel'
            'Rollup'
            'Snowpack'
            'Vite'
        )
        $LibraryOptions = @(
            'Vanilla'
            'React'
            'Solid'
        )
        $WithOptions = @(
            'Cesium'
            'Reason'
            'Rust'
        )
        $Defaults = @{
            Bundler = 'Webpack'
            Library = 'Vanilla'
            With = @()
            SourceDirectory = 'src'
            AssetsDirectory = 'public'
            ProductionDirectory = 'dist'
            RustDirectory = 'rust-to-wasm'
            Legacy = $False
            ReactVersion = '^17'
            License = 'MIT'
        }
    }
    Process {
        $Data = if ($PsCmdlet.ParameterSetName -eq 'pipeline') {
            $Defaults, $Configuration | Invoke-ObjectMerge -Force
        } else {
            if ($Interactive) {
                'Build a Web Application' | Write-Title -Blue -TextColor White -SubText 'choose wisely'
                '' | Write-Label -NewLine

                'Choose your {{#cyan bundler}}:' | Write-Label -Color 'Gray' -NewLine
                $Bundler = Invoke-Menu $BundlerOptions -SingleSelect -SelectedMarker ' => ' -HighlightColor 'Cyan'
                '' | Write-Label -NewLine

                'Choose your {{#yellow library}}:' | Write-Label -Color 'Gray' -NewLine
                $Library = Invoke-Menu $LibraryOptions -SingleSelect -SelectedMarker ' => ' -HighlightColor 'Yellow'
                '' | Write-Label -NewLine

                'Enhance your application {{#magenta with}}:' | Write-Label -Color 'Gray' -NewLine
                $With = Invoke-Menu $WithOptions -MultiSelect -SelectedMarker ' => ' -HighlightColor 'Magenta'
                '' | Write-Label -NewLine
            } else {
                if (-not $Bundler) {
                    $Bundler = Find-FirstTrueVariable $BundlerOptions
                }
                if (-not $Library) {
                    $Library = Find-FirstTrueVariable $LibraryOptions
                }
            }
            $Defaults, @{
                Bundler = $Bundler
                Library = $Library
                With = $With
            } | Invoke-ObjectMerge -Force
        }
        $Data.Name = if ($Data.Name) { $Data.Name } else { $Name }
        $Data.Parent = if ($Data.Parent) { $Data.Parent } else { $Parent }
        $APPLICATION_DIRECTORY = Join-Path $Data.Parent $Data.Name
        $RUST_DIRECTORY = Join-Path $APPLICATION_DIRECTORY $Data.RustDirectory
        $PackageManifestData = @{
            name = $Data.Name
            version = '0.0.0'
            description = ''
            license = $Data.License
            keywords = @()
            main = "./$($Data.SourceDirectory)/main.js$(if ($Library -eq 'React') { 'x' })"
            scripts = @{}
            dependencies = @{}
            devDependencies = @{}
            jest = @{
                testMatch = @(
                    '**/__tests__/**/*.(e2e|test).[jt]s?(x)'
                )
                setupFilesAfterEnv = @(
                    '<rootDir>/__tests__/setup.js'
                )
                watchPlugins = @(
                    'jest-watch-typeahead/filename'
                    'jest-watch-typeahead/testname'
                )
            }
        }
        $NpmScripts = @{
            Eslint = @{
                'lint' = 'eslint . -c ./.eslintrc.js --ext .js,.jsx --fix'
                'lint:ing' = "watch `"npm run lint`" $($Data.SourceDirectory)"
                'lint:tests' = 'eslint __tests__/**/*.js -c ./.eslintrc.js --fix --no-ignore'
            }
            Jest = @{
                'test' = 'jest .*.test.js --coverage'
                'test:ing' = 'npm test -- --watchAll'
            }
            Parcel = @{}
            Rollup = @{}
            Webpack = @{}
        }
        $Dependencies = @{
            Cesium = @{
                'cesium' = '^1.93.0'
            }
            React = @{
                Core = @{
                    'prop-types' = '*'
                    'react' = $Data.ReactVersion
                    'react-dom' = $Data.ReactVersion
                    'wouter' = '*'
                }
                Cesium = @{
                    'resium' = '^1.14.3'
                }
            }
            Reason = @{
                # 'reason-react' = '*'
                '@rescript/react' = '*'
            }
            Solid = @{}
        }
        $DevelopmentDependencies = @{
            _workflow = @{
                'cpy-cli' = '*'
                'del-cli' = '*'
                'npm-run-all' = '*'
                'watch' = '*'
            }
            Babel = @{
                '@babel/cli' = '^7.17.10'
                '@babel/core' = '^7.18.0'
                '@babel/plugin-proposal-class-properties' = '^7.17.12'
                '@babel/plugin-proposal-export-default-from' = '^7.17.12'
                '@babel/plugin-proposal-optional-chaining' = '^7.17.12'
                '@babel/plugin-transform-runtime' = '^7.18.0'
                '@babel/preset-env' = '^7.18.0'
                '@babel/preset-react' = '^7.17.12'
                '@babel/runtime' = '^7.18.0'
                'babel-preset-minify' = '^0.5.2'
            }
            Cesium = @{
                'copy-webpack-plugin' = '*'
                'url-loader' = '*'
            }
            Eslint = @{
                'eslint' = '^7.32.0'
                'babel-eslint' = '^10.1.0'
                'eslint-config-omaha-prime-grade' = '^14.0.1'
                'eslint-plugin-import' = '^2.26.0'
                'eslint-plugin-jsx-a11y' = '^6.5.1'
                'eslint-plugin-react' = '^7.30.0'
            }
            Jest = @{
                'jest' = '^28.1.0'
                'babel-jest' = '^28.1.0'
                'jest-watch-typeahead' = '^1.1.0'
            }
            Parcel = @{
                'parcel' = '*'
                'parcel-plugin-purgecss' = '*'
            }
            Postcss = @{
                'cssnano' = '^5.1.9'
                'postcss' = '^8.4.14'
                'postcss-cli' = '^9.1.0'
                'postcss-import' = '^14.1.0'
                'postcss-preset-env' = '^7.6.0'
                'postcss-reporter' = '^7.0.5'
                'postcss-safe-parser' = '^6.0.0'
            }
            React = @{
                'react-hot-loader' = '^4.13.0'
            }
            Reason = @{
                # 'bs-platform' = '*'
                'rescript' = '*'
            }
            Rollup = @{
                'rollup' = '*'
                'rollup-plugin-babel' = '*'
                'rollup-plugin-commonjs' = '*'
                'rollup-plugin-node-resolve' = '*'
                'rollup-plugin-replace' = '*'
                'rollup-plugin-terser' = '*'
            }
            Rust = @{
                '@wasm-tool/wasm-pack-plugin' = '*'
            }
            Stylelint = @{
                'style-loader' = '^3.3.1'
                'stylelint' = '^14.8.3'
                'stylelint-config-recommended' = '^7.0.0'
            }
            Snowpack = @{
                'snowpack' = '*'
                '@snowpack/app-scripts-react' = '*'
                '@snowpack/plugin-react-refresh' = '*'
                '@snowpack/plugin-postcss' = '*'
                '@snowpack/plugin-optimize' = '*'
            }
            Webpack = @{
                'webpack' = '*'
                'webpack-cli' = '*'
                'webpack-dashboard' = '*'
                'webpack-jarvis' = '*'
                'webpack-dev-server' = '*'
                'webpack-subresource-integrity' = '*'
                'babel-loader' = '*'
                'css-loader' = '*'
                'file-loader' = '*'
                'style-loader' = '*'
                'html-webpack-plugin' = '*'
                'terser-webpack-plugin' = '*'
                'webpack-bundle-analyzer' = '*'
            }
        }
        $ConfigurationFileData = @{
            Eslint = @{
                env = @{
                    es6 = $True
                    jest = $True
                    browser = $True
                }
                extends = @(
                    'omaha-prime-grade'
                    'plugin:import/errors'
                    'plugin:import/warnings'
                    'plugin:promise/recommended'
                    'plugin:react/recommended'
                    'plugin:jsx-a11y/recommended'
                )
                parser = 'babel-eslint'
                parserOptions = @{
                    ecmaFeatures = @{
                        jsx = $True
                    }
                }
                plugins = @(
                    'jsx-a11y'
                )
                settings = @{
                    react = @{
                        version = 'detect'
                    }
                }
            }
            Babel = @{
                plugins = @(
                    'react-hot-loader/babel'
                    '@babel/plugin-transform-runtime'
                    '@babel/plugin-proposal-class-properties'
                    '@babel/plugin-proposal-export-default-from'
                    '@babel/plugin-proposal-optional-chaining'
                )
                presets = @(
                    '@babel/preset-env'
                    'babel-preset-minify'
                    @(
                        '@babel/preset-react'
                        @{
                            runtime = 'automatic'
                        }
                    )
                )
            }
            Postcss = @{
                map = $True
                parser = 'postcss-safe-parser'
                plugins = @(
                    @(
                        'stylelint'
                        @{
                            config = @{
                                extends = 'stylelint-config-recommended'
                            }
                        }
                    )
                    'postcss-import'
                    'postcss-preset-env'
                    'cssnano'
                    'postcss-reporter'
                )
            }
            Reason = @{
                'name' = $Data.Name
                'bs-dependencies' = @(
                    '@rescript/react'
                )
                'bsc-flags' = @(
                    '-bs-super-errors'
                )
                'namespace' = $True
                'package-specs' = @(
                    @{
                        'module' = 'es6'
                        'in-source' = $True
                    }
                )
                'ppx-flags' = @()
                'reason' = @{
                    'react-jsx' = 3
                }
                'refmt' = 3
                'sources' = @(
                    @{
                        'dir' = $Data.SourceDirectory
                        'subdirs' = $True
                    }
                )
                'suffix' = '.bs.js'
            }
            Webpack = @{
                UseReact = ($Library -eq 'React')
                WithCesium = ($With -contains 'Cesium')
                WithRust = ($With -contains 'Rust')
            }
        }
        if ($PSCmdlet.ShouldProcess('Create application folder structure')) {
            $Source = $Data.SourceDirectory
            $Assets = $Data.AssetsDirectory
            @(
                ''
                $Source
                "${Source}/components"
                $Assets
                "${Assets}/css"
                "${Assets}/fonts"
                "${Assets}/images"
                "${Assets}/library"
                "${Assets}/workers"
                '__tests__'
            ) | ForEach-Object { New-Item -Type Directory -Path (Join-Path $APPLICATION_DIRECTORY $_) -Force } | Out-Null
        }
        switch ($Bundler) {
            Parcel {
                if ($PSCmdlet.ShouldProcess('Add Parcel dependencies to package.json')) {
                    $PackageManifestData.devDependencies += $DevelopmentDependencies.Parcel
                }
                if ($PSCmdlet.ShouldProcess('Copy Parcel files')) {
                    # TODO: Add code for copying files
                }
            }
            Rollup {
                if ($PSCmdlet.ShouldProcess('Add Rollup dependencies to package.json')) {
                    $PackageManifestData.devDependencies += $DevelopmentDependencies.Rollup
                }
                if ($PSCmdlet.ShouldProcess('Save Rollup configuration file')) {
                    # TODO: Add code for copying files
                }
            }
            Snowpack {
                if ($PSCmdlet.ShouldProcess('Add Snowpack dependencies to package.json')) {
                    $PackageManifestData.devDependencies += $DevelopmentDependencies.Snowpack
                }
                if ($PSCmdlet.ShouldProcess('Save Snowpack configuration file')) {
                    # TODO: Add code for copying files
                }
            }
            Default {
                if ($PSCmdlet.ShouldProcess('Add Webpack dependencies to package.json')) {
                    $PackageManifestData.devDependencies += $DevelopmentDependencies.Webpack
                }
                if ($PSCmdlet.ShouldProcess('Save Webpack configuration file')) {
                    $Parameters = @{
                        Filename = 'webpack.config.js'
                        Template = 'config_webpack'
                        Data = $ConfigurationFileData.Webpack
                        Parent = $APPLICATION_DIRECTORY
                        Force = $Force
                    }
                    Copy-TemplateData @Parameters
                }
            }
        }
        switch ($Library) {
            React {
                if ($PSCmdlet.ShouldProcess('Add React dependencies to package.json')) {
                    $PackageManifestData.dependencies += $Dependencies.React.Core
                    $PackageManifestData.devDependencies += $DevelopmentDependencies.React
                }
                if ($PSCmdlet.ShouldProcess('Copy React files')) {
                    $Source = Join-Path $APPLICATION_DIRECTORY 'src'
                    $Components = Join-Path $Source 'components'
                    @(
                        @{
                            Filename = 'main.jsx'
                            Template = 'source_react_main'
                            Parent = $Source
                        }
                        @{
                            Filename = 'App.jsx'
                            Template = 'source_react_app'
                            Parent = $Components
                        }
                        @{
                            Filename = 'Header.jsx'
                            Template = 'source_react_header'
                            Parent = $Components
                        }
                        @{
                            Filename = 'Body.re'
                            Template = 'source_react_body'
                            Parent = $Components
                        }
                        @{
                            Filename = 'Footer.re'
                            Template = 'source_react_footer'
                            Parent = $Components
                        }
                    ) | ForEach-Object {
                        $Parameters = $_
                        Copy-TemplateData @Parameters -Data $Data -Force:$Force
                    }
                }
            }
            Solid {
                if ($PSCmdlet.ShouldProcess('Add Solid dependencies to package.json')) {
                    $PackageManifestData.dependencies += $Dependencies.Solid
                }
                if ($PSCmdlet.ShouldProcess('Copy Solid files')) {
                    # TODO: Add code for copying files
                }
            }
            Default {
                if ($PSCmdlet.ShouldProcess('Copy JavaScript files')) {
                    $Source = Join-Path $APPLICATION_DIRECTORY 'src'
                    $Parameters = @{
                        Filename = 'main.js'
                        Template = 'source_vanilla_main'
                        Data = $Data
                        Parent = $Source
                        Force = $Force
                    }
                    Copy-TemplateData @Parameters
                }
            }
        }
        switch ($With) {
            Cesium {
                if ($PSCmdlet.ShouldProcess('Add Cesium dependencies to package.json')) {
                    $PackageManifestData.dependencies += $Dependencies.Cesium
                    if ($React) {
                        $PackageManifestData.dependencies += $Dependencies.React.Cesium
                    }
                    $PackageManifestData.devDependencies += $DevelopmentDependencies.Cesium
                }
            }
            Reason {
                if ($Library -ne 'React' -and (-not $Silent)) {
                    '==> ReasonML works best with React.  You might consider using -React.' | Write-Warning
                }
                if ($PSCmdlet.ShouldProcess('Add ReasonML dependencies to package.json')) {
                    $PackageManifestData.dependencies += $Dependencies.Reason
                    $PackageManifestData.devDependencies += $DevelopmentDependencies.Reason
                }
                if ($PSCmdlet.ShouldProcess('Save ReasonML configuration file; Add dependencies to package.json')) {
                    $Parameters = @{
                        Filename = 'bsconfig.json'
                        Data = $ConfigurationFileData.Reason
                        Parent = $APPLICATION_DIRECTORY
                        Force = $Force
                    }
                    Save-JsonData @Parameters
                }
                if ($PSCmdlet.ShouldProcess('Copy ReasonML files')) {
                    $Components = Join-Path $APPLICATION_DIRECTORY 'src/components'
                    @(
                        @{
                            Filename = 'App.re'
                            Template = 'source_reason_app'
                        }
                        @{
                            Filename = 'Example.re'
                            Template = 'source_reason_example'
                        }
                    ) | ForEach-Object {
                        $Parameters = $_
                        Copy-TemplateData @Parameters -Data $Data -Parent $Components -Force:$Force
                    }
                }
            }
            Rust {
                if ($PSCmdlet.ShouldProcess('Add Rust dependencies to package.json')) {
                    $PackageManifestData.devDependencies += $DevelopmentDependencies.Rust
                }
                if ($PSCmdlet.ShouldProcess('Copy Rust files')) {
                    $Source = Join-Path $RUST_DIRECTORY 'src'
                    $Tests = Join-Path $RUST_DIRECTORY 'tests'
                    @(
                        $RUST_DIRECTORY
                        $Source
                        $Tests
                    ) | Get-StringPath | ForEach-Object { New-Item -Type Directory -Path $_ -Force } | Out-Null
                    @(
                        @{
                            Filename = 'Cargo.toml'
                            Template = 'config_rust'
                            Parent = $APPLICATION_DIRECTORY
                        }
                        @{
                            Filename = 'Cargo.toml'
                            Template = 'config_rust_crate'
                            Parent = $RUST_DIRECTORY
                        }
                        @{
                            Filename = 'lib.rs'
                            Template = 'source_rust_lib'
                            Parent = $Source
                        }
                        @{
                            Filename = 'utils.rs'
                            Template = 'source_rust_utils'
                            Parent = $Source
                        }
                        @{
                            Filename = 'app.rs'
                            Template = 'source_rust_app'
                            Parent = $Tests
                        }
                        @{
                            Filename = 'web.rs'
                            Template = 'source_rust_web'
                            Parent = $Tests
                        }
                    ) | ForEach-Object {
                        $Parameters = $_
                        Copy-TemplateData @Parameters -Data $Data -Force:$Force
                    }
                }
            }
            Default {}
        }
        if ($PSCmdlet.ShouldProcess('Copy Jest files; Add dependencies and tasks to package.json')) {
            $PackageManifestData.devDependencies += $DevelopmentDependencies.Jest
            $PackageManifestData.scripts += $NpmScripts.Jest
            $Tests = Join-Path $APPLICATION_DIRECTORY '__tests__'
            @(
                @{
                    Filename = 'setup.js'
                    Template = 'source_jest_setup'
                }
                @{
                    Filename = 'example.test.js'
                    Template = 'source_jest_example'
                }
            ) | ForEach-Object {
                $Parameters = $_
                Copy-TemplateData @Parameters -Data $Data -Parent $Tests -Force:$Force
            }
        }
        if ($PSCmdlet.ShouldProcess('Save EditorConfig configuration file')) {
            $Parameters = @{
                Filename = '.editorconfig'
                Template = 'editorconfig'
                Data = @{}
                Parent = $APPLICATION_DIRECTORY
                Force = $Force
            }
            Copy-TemplateData @Parameters
        }
        if ($PSCmdlet.ShouldProcess('Save PostCSS configuration file; Add dependencies to package.json')) {
            $PackageManifestData.devDependencies += $DevelopmentDependencies.Postcss
            $Parameters = @{
                Filename = 'postcss.config.js'
                Template = 'config_postcss'
                Data = $ConfigurationFileData.Postcss
                Parent = $APPLICATION_DIRECTORY
                Force = $Force
            }
            Copy-TemplateData @Parameters
        }
        if ($PSCmdlet.ShouldProcess('Save Babel configuration file; Add dependencies to package.json')) {
            $PackageManifestData.devDependencies += $DevelopmentDependencies.Babel
            $Parameters = @{
                Filename = 'babel.config.json'
                Data = $ConfigurationFileData.Babel
                Parent = $APPLICATION_DIRECTORY
                Force = $Force
            }
            Save-JsonData @Parameters
        }
        if ($PSCmdlet.ShouldProcess('Save ESLint configuration file; Add dependencies and tasks to package.json')) {
            $PackageManifestData.devDependencies += $DevelopmentDependencies.Eslint
            $PackageManifestData.scripts += $NpmScripts.Eslint
            $Parameters = @{
                Filename = '.eslintrc.json'
                Data = $ConfigurationFileData.Eslint
                Parent = $APPLICATION_DIRECTORY
                Force = $Force
            }
            Save-JsonData @Parameters
        }
        if ($PSCmdlet.ShouldProcess('Save package.json to application directory')) {
            $Parameters = @{
                Filename = 'package.json'
                Data = $PackageManifestData
                Parent = $APPLICATION_DIRECTORY
                Force = $Force
            }
            Save-JsonData @Parameters
        }
    }
    End {
        $Context = Test-ApplicationContext $APPLICATION_DIRECTORY
        if (-not $NoInstall) {
            if ($PSCmdlet.ShouldProcess('Install dependencies')) {
                if ($Context.Node.Ready) {
                    if (-not $Silent) {
                        '==> [INFO] Installing Node.js dependencies...' | Write-Color -Cyan
                    }
                    npm install | Out-Null
                }
            }
        }
        if ($PSCmdlet.ShouldProcess('Save application state')) {
            $Data.Context = $Context
            $Data.PackageManifestData = $PackageManifestData
            $State.Data = $Data
            $State.Name = $Data.Name
            $State.Parent = $Data.Parent
            $State | Save-State -Id $State.Name | Out-Null
        }
        if (-not $Silent) {
            'done' | Write-Status
        }
    }
}
function Remove-Indent {
    <#
    .SYNOPSIS
    Remove indentation of multi-line (or single line) strings
    .NOTES
    Good for removing spaces added to template strings because of alignment with code.
    #>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $True, ValueFromPipeline = $True)]
        [AllowEmptyString()]
        [String] $From,
        [Int] $Size = 4
    )
    Process {
        $Lines = $From -split '\n'
        $Delimiter = if ($Lines.Count -eq 1) { '' } else { "`n" }
        $Callback = { $Args[0], $Args[1] -join $Delimiter }
        $Lines |
            Where-Object { $_.Length -ge $Size } |
            ForEach-Object { $_.SubString($Size) } |
            Invoke-Reduce -Callback $Callback -InitialValue ''
    }
}
function Save-State {
    <#
    .SYNOPSIS
    Save state object as CliXml in temp directory
    .EXAMPLE
    Set-State -Id 'my-app -State @{ Data = 42 }
    .EXAMPLE
    Set-State 'my-app' @{ Data = 42 }
    .EXAMPLE
    @{ Data = 42 } | Set-State 'my-app'
    #>
    [CmdletBinding(SupportsShouldProcess = $True)]
    [OutputType([String])]
    Param(
        [Parameter(Mandatory = $True, Position = 0)]
        [String] $Id,
        [Parameter(Mandatory = $True, Position = 1, ValueFromPipeline = $True)]
        [PSObject] $State,
        [String] $Path
    )
    if (-not $Path) {
        $TempRoot = if ($IsLinux) { '/tmp' } else { $Env:temp }
        $Path = Join-Path $TempRoot "state-$Id.xml"
    }
    if ($PSCmdlet.ShouldProcess($Path)) {
        $State.Id = $Id
        $State | Export-Clixml -Path $Path
        "==> Saved state to $Path" | Write-Verbose
    } else {
        "==> Would have saved state to $Path" | Write-Verbose
    }
    $Path
}
function Test-ApplicationContext {
    <#
    .SYNOPSIS
    Test various environment conditions and return an object with the results.
    .EXAMPLE
    $Results = Test-ApplicationContext
    #>
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    Param(
        [Parameter(Position = 0, ValueFromPipeline = $True)]
        [ValidateScript( { Test-Path $_ })]
        [String] $Parent = (Get-Location).Path
    )
    Begin {
        function Test-SomeExist {
            Param(
                [Parameter(Position = 0)]
                [String[]] $PathList
            )
            foreach ($Path in $PathList) {
                if (Test-Path -Path (Join-Path $Parent $Path)) {
                    "==> [INFO] Found ${Path}" | Write-Verbose
                    return $True
                }
            }
            $False
        }
        $BABEL_CONFIG_NAMES = @(
            'babel.config.json'
            'babel.config.js'
            'babel.config.cjs'
            'babel.config.mjs'
            '.babelrc'
            '.babelrc.json'
            '.babelrc.js'
            '.babelrc.cjs'
            '.babelrc.mjs'
        )
        $ESLINT_CONFIG_NAMES = @(
            '',
            '.js',
            '.cjs',
            '.yaml',
            '.yml',
            '.json'
        ) | ForEach-Object { ".eslintrc${_}" }
    }
    Process {
        $Installed = @{
            Cargo = (Test-Command 'cargo')
            Rustc = (Test-Command 'rustc')
            Npm = (Test-Command 'npm')
        }
        $FileExists = @{
            CargoToml = (Test-SomeExist 'Cargo.toml')
            PackageJson = (Test-SomeExist 'package.json')
            BabelConfig = (Test-SomeExist $BABEL_CONFIG_NAMES)
            EslintConfig = (Test-SomeExist $ESLINT_CONFIG_NAMES)
            PostcssConfig = (Test-SomeExist 'postcss.config.js')
            WebpackConfig = (Test-SomeExist 'webpack.config.js')
        }
    }
    End {
        @{
            Rust = @{
                Ready = ($Installed.Cargo -and $Installed.Rustc -and $FileExists.CargoToml)
                Manifest = $FileExists.CargoToml
                PackageManager = $Installed.Cargo
                Compiler = $Installed.Rustc
                Linter = $False
            }
            Node = @{
                Ready = ($Installed.Npm -and $FileExists.PackageJson)
                Manifest = $FileExists.PackageJson
                PackageManager = $Installed.Npm
                Compiler = $FileExists.BabelConfig
                Linter = $FileExists.EslintConfig
            }
            CSS = @{
                Ready = $FileExists.PostcssConfig
                Manifest = $False
                PackageManager = $False
                Compiler = $FileExists.PostcssConfig
                Linter = $False
            }
        }
    }
}
function Update-Application {
    <#
    .SYNOPSIS
    Update a dependency of a web or desktop application created using New-WebApplication or New-DesktopApplication, respectively.
    #>
    [CmdletBinding()]
    Param(
        [Switch] $Web,
        [Switch] $Desktop,
        [ValidateSet('Cesium', 'Reason', 'Rust')]
        [String[]] $Add,
        [ValidateSet('Cesium', 'Reason', 'Rust')]
        [String[]] $Remove
    )
    Begin {}
    Process {}
    End {}
}
function Write-Status {
    <#
    .SYNOPSIS
    Print ASCII status message
    .EXAMPLE
    'pass' | Write-Status
    #>
    [CmdletBinding()]
    [OutputType([String])]
    Param(
        [Parameter(Position = 0, ValueFromPipeline = $True)]
        [ValidateSet('done', 'fail', 'pass')]
        [String] $Status = 'done',
        [String] $Color,
        [Switch] $PassThru
    )
    if (-not $Color) {
        $Color = switch ($Status) {
            'done' { 'Gray' }
            'fail' { 'Red' }
            'pass' { 'Green' }
        }
    }
    $Message = switch ($Status) {
        'done' {
            @(
                '▄▀█ █░░ █░░   █▀▄ █▀█ █▄░█ █▀▀ █'
                '█▀█ █▄▄ █▄▄   █▄▀ █▄█ █░▀█ ██▄ ▄'
            )
        }
        'fail' {
            @(
                '█▀▀ ▄▀█ █ █░░'
                '█▀░ █▀█ █ █▄▄'
            )
        }
        'pass' {
            @(
                '█▀█ ▄▀█ █▀ █▀'
                '█▀▀ █▀█ ▄█ ▄█'
            )
        }
    }
    if ($PassThru) {
        $Message -join "`n"
    } else {
        '' | Write-Host
        $Message | ForEach-Object {
            $_ | Write-Host -ForegroundColor $Color
        }
        '' | Write-Host
    }
}