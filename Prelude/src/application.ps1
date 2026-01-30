[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingInvokeExpression', '', Scope = 'Function', Target = 'Invoke-NpmInstall')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingInvokeExpression', '', Scope = 'Function', Target = 'New-Template')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '', Scope = 'Function', Target = 'ConvertTo-PowerShellSyntax')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '', Scope = 'Function', Target = 'New-WebApplication')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '', Scope = 'Function', Target = 'Remove-Indent')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '', Scope = 'Function', Target = 'Test-ApplicationContext')]
param()

class ApplicationState {
    [String] $Id = (New-Guid)
    [Bool] $Continue = $True
    [String] $Name = 'Application Name'
    [String] $Parent = (Get-Location).Path
    [String] $Type = 'Terminal'
    $Data
}
function ConvertFrom-Base64 {
    <#
    .SYNOPSIS
    Deccode a Base64 string
    #>
    [CmdletBinding()]
    [OutputType([String])]
    param(
        [Parameter(Position = 0, ValueFromPipeline = $True)]
        [String] $Value
    )
    process {
        $String = [System.Convert]::FromBase64String($Value)
        [System.Text.Encoding]::Unicode.GetString($String)
    }
}
function ConvertTo-Base64 {
    <#
    .SYNOPSIS
    Encode string in Base64
    #>
    [CmdletBinding()]
    [OutputType([String])]
    param(
        [Parameter(Position = 0, ValueFromPipeline = $True)]
        [String] $Value
    )
    process {
        $Bytes = [System.Text.Encoding]::Unicode.GetBytes($Value)
        [Convert]::ToBase64String($Bytes)
    }
}
function ConvertTo-PowerShellSyntax {
    [OutputType([String])]
    param(
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
    $State = Get-State -Name 'abc-def-ghi'
    .EXAMPLE
    $State = 'abc-def-ghi' | Get-State
    #>
    [CmdletBinding()]
    param(
        [Parameter(Position = 0, ValueFromPipeline = $True)]
        [String] $Name,
        [AllowEmptyString()]
        [String] $Path
    )
    if ($Path.Length -gt 0 -and (Test-Path $Path)) {
        "==> Resolved ${Path}" | Write-Verbose
    } else {
        $TempRoot = Get-TemporaryDirectory
        $Filename = $Name | Get-StateName
        $Path = Join-Path $TempRoot "${Filename}.xml"
    }
    "==> Loading state from ${Path}" | Write-Verbose
    Import-Clixml -Path $Path
}
function Get-StateName {
    <#
    .SYNOPSIS
    Create state name from input ID
    .EXAMPLE
    $Name = 'My-App' | Get-StateName
    #>
    [CmdletBinding()]
    [OutputType([String])]
    param(
        [Parameter(Position = 0, ValueFromPipeline = $True)]
        [String] $Id
    )
    process {
        "prelude-$($Id | ConvertTo-Base64)"
    }
}
function Get-TemporaryDirectory {
    <#
    .SYNOPSIS
    Cross platform way to get temporary directory location
    .EXAMPLE
    $Tmp = Get-TemporaryDirectory
    #>
    [CmdletBinding()]
    [OutputType([String])]
    param()
    if ($IsLinux) {
        '/tmp'
    } else {
        if ($IsMacOS) {
            $Env:TMPDIR
        } else {
            $Env:temp
        }
    }
}
function Format-Json {
    <#
    .SYNOPSIS
    Prettify JSON output
    .EXAMPLE
    Get-Content './foo.json' | Format-Json | Out-File './bar.json' -Encoding ascii
    .EXAMPLE
    './some.json' | Format-Json -InPlace
    #>
    [CmdletBinding()]
    param(
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
    param(
        [Parameter(Mandatory = $True, Position = 0, ValueFromPipeline = $True)]
        [String] $Name,
        [PSObject] $Data
    )
    New-Event -SourceIdentifier $Name -MessageData $Data | Out-Null
}
function Invoke-NpmInstall {
    <#
    .SYNOPSIS
    "npm install"...but as a cmdlet
    .EXAMPLE
    Invoke-NpmInstall
    #>
    [CmdletBinding(SupportsShouldProcess = $True)]
    [OutputType([Bool])]
    param(
        [ValidateScript( { Test-Path $_ })]
        [String] $Parent = (Get-Location).Path,
        [Switch] $Silent
    )
    begin {
        $Command = 'npm install'
        $Context = Test-ApplicationContext -Parent $Parent
        $Location = Get-Location
        if ($PSCmdlet.ShouldProcess("Change location to ${Parent}")) {
            $Success = $True
            Set-Location -Path $Parent
        }
    }
    process {
        if ($Context.Node.Ready) {
            try {
                if ($PSCmdlet.ShouldProcess('Install dependencies with "npm install"')) {
                    if (-not $Silent) {
                        '==> [INFO] Installing dependencies...' | Write-Color -Cyan
                    }
                    Invoke-Expression $Command | Out-Null
                }
            } catch {
                $Success = $False
            }
        } else {
            if (-not $Silent) {
                Write-Status 'fail'
            }
            switch ($Context.Node) {
                { -not $_.PackageManager } {
                    "Could not run `"${Command}.`" Is npm installed?`n" | Write-Color -White
                }
                { -not $_.Manifest } {
                    "Could not find package.json in ${Parent}...`n" | Write-Color -White
                }
                default {
                    "{{#yellow (╯°□°)╯︵ ┻━┻ }}...maybe try again?`n" | Write-Color -White
                }
            }
            $Success = $False
        }
    }
    end {
        if ($PSCmdlet.ShouldProcess("Restore location to ${Location}")) {
            Set-Location -Path $Location
            if (-not $Success) {
                return $Null
            } else {
                return $Success
            }
        }
    }
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
    param(
        [Parameter(Mandatory = $True, Position = 0)]
        [ScriptBlock] $Init,
        [Parameter(Mandatory = $True, Position = 1)]
        [ScriptBlock] $Loop,
        [Parameter(Position = 2)]
        [ApplicationState] $State = @{},
        [String] $Name,
        [ScriptBlock] $ShouldContinue,
        [ScriptBlock] $BeforeNext,
        [Switch] $ClearState,
        [Switch] $SingleRun,
        [Switch] $NoCleanup
    )
    if ($Name.Length -gt 0) {
        $TempRoot = Get-TemporaryDirectory
        $Filename = $Name | Get-StateName
        $Path = Join-Path $TempRoot "${Filename}.xml"
        if ($ClearState -and (Test-Path $Path)) {
            Remove-Item $Path
        }
        if (Test-Path $Path) {
            "==> Resolved state with name: ${Name}" | Write-Verbose
            try {
                [ApplicationState]$State = Get-State $Name
                $State.Name = $Name
            } catch {
                "==> Failed to get state with name: ${Name}" | Write-Verbose
                $State = [ApplicationState]@{ Name = $Name }
            }
        } else {
            $State.Name = $Name
        }
    }
    if (-not $State) {
        $State = [ApplicationState]@{ Name = $Name }
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
    "Application Name: $($State.Name)" | Write-Verbose
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
    param(
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
    param()
    $Snippet = if (-not $IsLinux) {
        '
        {
            Invoke-Speak goodbye
            $Name = $Event.MessageData.State.Name
            "Application name: ${Name}" | Write-Color -Magenta
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
        [String] $Name = ''My-Terminal-App'',
        [Switch] $Clear
    )
    {{ Empty }}
    $InitialState = @{ Data = 0; Type = ''Terminal''; Name = $Name }
    {{ Empty }}
    $Init = {
        Clear-Host
        $State = $Args[0]
        $Id = $State.Id
        ''Application Information:'' | Write-Color
        `"ID = {{#green $Id}}`" | Write-Label -Color Gray -Indent 2 -NewLine
        `"Name = {{#green ${Name}}}`" | Write-Label -Color Gray -Indent 2 -NewLine
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
        $State | Save-State $State.Name -Force | Out-Null
        Start-Sleep 1
    }
    {{ Empty }}
    Invoke-RunApplication $Init $Loop $InitialState -Name $Name -ClearState:$Clear
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
    param(
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
    begin {
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
                default {
                    $Script:TemplateKeyNamesNotPassed += $Variable
                    "`$(`$${Variable})"
                }
            }
        }
    }
    process {
        $PLACEHOLDER = '<<<DOUBLE QUOTES PRELUDE PLACEHOLDER>>>'
        if ($File) {
            $Path = Get-StringPath $File
            $Template = Get-Content $Path -Raw
        }
        $EvaluatedTemplate = [Regex]::Replace(($Template -replace '[$]', '`$'), $Pattern, $Evaluator)
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
    param(
        [Parameter(ValueFromPipeline = $True)]
        [PSObject] $Configuration = @{}
    )
    begin {}
    process {}
    end {}
}
function New-WebApplication {
    <#
    .SYNOPSIS
    Create a new web application.
    .DESCRIPTION
    This function allows you to scaffold a bespoke web application and optionally install dependencies.

    When -NoInstall is not used, dependencies will be installed using npm.

    Before dependencies are installed, application state will be saved using Save-State under the passed application name (or the default, "webapp")

    Application data can be viewed and used using "Get-State <Name>"

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
    } | New-WebApplication -Name 'My-App'
    #>
    [CmdletBinding(DefaultParameterSetName = 'parameter', SupportsShouldProcess = $True)]
    param(
        [Parameter(ParameterSetName = 'pipeline', ValueFromPipeline = $True)]
        [PSObject] $Configuration = @{},
        [ApplicationState] $State = @{ Type = 'Web' },
        [Parameter(Position = 0, ParameterSetName = 'parameter')]
        [ValidateSet('Parcel', 'Snowpack', 'Turbopack', 'Vite', 'Webpack')]
        [String] $Bundler,
        [Parameter(ParameterSetName = 'switch')]
        [Switch] $Webpack,
        [Parameter(ParameterSetName = 'switch')]
        [Switch] $Parcel,
        [Parameter(ParameterSetName = 'switch')]
        [Switch] $Snowpack,
        [Parameter(ParameterSetName = 'switch')]
        [Switch] $Turbopack,
        [Parameter(ParameterSetName = 'switch')]
        [Switch] $Vite,
        [Parameter(Position = 1, ParameterSetName = 'parameter')]
        [AllowNull()]
        [AllowEmptyString()]
        [ValidateSet('', 'Vanilla', 'React', 'Solid')]
        [String] $Library,
        [Parameter(ParameterSetName = 'switch')]
        [Switch] $Vanilla,
        [Parameter(ParameterSetName = 'switch')]
        [Switch] $React,
        [Parameter(ParameterSetName = 'switch')]
        [Switch] $Solid,
        [ValidateSet('Cesium', 'Reason', 'Rust')]
        [String[]] $With,
        [String] $Name = 'webapp',
        [Int] $Port = 4669,
        [ValidateScript( { Test-Path $_ })]
        [String] $Parent = (Get-Location).Path,
        [Parameter(ParameterSetName = 'interactive')]
        [Switch] $Interactive,
        [Switch] $NoInstall,
        [Switch] $Silent,
        [Switch] $Force
    )
    begin {
        $BundlerOptions = @(
            'Webpack'
            'Parcel'
            'Snowpack'
            'Turbopack'
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
            Port = $Port
        }
    }
    process {
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
        $ApplicationDirectory = Join-Path $Data.Parent $Data.Name
        $TemplateDirectory = Join-Path $PSScriptRoot '../src/templates'
        $ResourcesDirectory = Join-Path $PSScriptRoot '../src/resources'
        $RustDirectory = Join-Path $ApplicationDirectory $Data.RustDirectory
        $Data | ConvertTo-Json | Write-Verbose
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
        }
        $ConfigurationFileData = @{
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
                SourceDirectory = $Data.SourceDirectory
                AssetsDirectory = $Data.AssetsDirectory
                ProductionDirectory = $Data.ProductionDirectory
                UseReact = ($Library -eq 'React')
                WithCesium = ($With -contains 'Cesium')
                WithRust = ($With -contains 'Rust')
                Port = $Port
                CesiumConfig = ("
                    new DefinePlugin({CESIUM_BASE_URL: JSON.stringify('/')}),
                    new CopyWebpackPlugin({
                        patterns: [
                            {from: join(source, 'Workers'), to: 'Workers'},
                            {from: join(source, 'ThirdParty'), to: 'ThirdParty'},
                            {from: join(source, 'Assets'), to: 'Assets'},
                            {from: join(source, 'Widgets'), to: 'Widgets'}
                        ]
                    })" | Remove-Indent -Size 12)
            }
        }
        $Dependencies = @{
            Cesium = @{
                'cesium' = '^1.93.0'
            }
            Marionette = @{
                'backbone' = '^1.4.1'
                'backbone.marionette' = '^4.1.3'
                'backbone.radio' = '^2.0.0'
                'jquery' = '^3.6.3'
                'lit-html' = '^2.5.0'
                'lodash-es' = '^4.17.21'
                'marionette.approuter' = '^1.0.2'
                'redux' = '^4.2.0'
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
            BrowserSync = @{
                'browser-sync' = '^2.27.11'
            }
            Cesium = @{}
            Parcel = @{
                'parcel' = '*'
                'parcel-plugin-purgecss' = '*'
            }
            Postcss = @{
                Core = @{
                    'cssnano' = '^5.1.9'
                    'postcss' = '^8.4.14'
                    'postcss-cli' = '^9.1.0'
                    'postcss-import' = '^14.1.0'
                    'postcss-preset-env' = '^7.6.0'
                    'postcss-reporter' = '^7.0.5'
                    'postcss-safe-parser' = '^6.0.0'
                }
                React = @{}
            }
            React = @{
                '@hot-loader/react-dom' = $Data.ReactVersion
                'react-hot-loader' = '*'
            }
            Reason = @{
                'rescript' = '*'
            }
            Rust = @{
                '@wasm-tool/wasm-pack-plugin' = '*'
            }
            Stylelint = @{
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
                'webpackbar' = '*'
                'webpack-bundle-analyzer' = '*'
                'webpack-cli' = '*'
                'webpack-dashboard' = '*'
                'webpack-dev-server' = '*'
                'webpack-jarvis' = '*'
                'webpack-subresource-integrity' = '*'
                'babel-loader' = '*'
                'css-loader' = '*'
                'file-loader' = '*'
                'style-loader' = '*'
                'url-loader' = '*'
                'copy-webpack-plugin' = '*'
                'html-webpack-plugin' = '*'
                'terser-webpack-plugin' = '*'
            }
        }
        $NpmScripts = @{
            Common = @{
                Core = @{
                    'deploy' = "echo `"Not yet implemented - now.sh or surge.sh are supported out of the box`" && exit 1"
                    'serve' = "browser-sync start --server $($Data.ProductionDirectory) --files $($Data.ProductionDirectory) --port $($Data.Port)"
                    'start' = 'npm-run-all --parallel watch:es watch:css serve'
                }
                React = @{}
            }
            Parcel = @{
                Core = @{
                    'start' = 'npm-run-all --parallel watch:assets serve'
                    'clean' = "del-cli $($Data.ProductionDirectory)"
                    'copy' = 'npm-run-all --parallel copy:assets copy:index'
                    'copy:assets' = "cpy `"$($Data.AssetsDirectory)/!(css)/**/*.*`" `"$($Data.AssetsDirectory)/**/[.]*`" $($Data.ProductionDirectory) --parents --recursive"
                    'copy:index' = "cpy `"$($Data.AssetsDirectory)/index.html`" $($Data.ProductionDirectory)"
                    'prebuild:es' = 'npm run clean'
                    'build:es' = "parcel build --dist-dir $($Data.ProductionDirectory) --public-url ./ $($Data.AssetsDirectory)/index.html"
                    'watch:assets' = "watch `"npm run copy`" $($Data.AssetsDirectory)"
                    'prewatch:es' = 'npm run clean'
                    'watch:es' = 'npm run build:es'
                    'serve' = "parcel $($Data.AssetsDirectory)/index.html --dist-dir $($Data.ProductionDirectory) --port $($Data.Port) --open"
                    'predeploy' = 'npm-run-all clean build:es build:css copy:assets'
                }
                React = @{}
            }
            Snowpack = @{
                Core = @{
                    'start' = 'snowpack dev'
                    'build' = 'snowpack build'
                }
                React = @{}
            }
            TurboPack = @{
                Core = @{}
                React = @{}
            }
            Webpack = @{
                Core = @{
                    'clean' = "del-cli $($Data.ProductionDirectory)"
                    'copy' = 'npm-run-all --parallel copy:assets'
                    'copy:assets' = "cpy \`"$($Data.AssetsDirectory)/!(css)/**/*.*\`" \`"$($Data.AssetsDirectory)/**/[.]*\`" $($Data.ProductionDirectory) --parents --recursive"
                    'prebuild:es' = "del-cli $($Data.ProductionDirectory)/$($Data.AssetsDirectory)"
                    'build:es' = 'webpack'
                    'build:stats' = 'webpack --mode production --profile --json > stats.json'
                    'build:analyze' = 'webpack-bundle-analyzer ./stats.json'
                    'postbuild:es' = 'npm run copy'
                    'watch:assets' = "watch \`"npm run copy\`" $($Data.AssetsDirectory)"
                    'watch:es' = "watch \`"npm run build:es\`" $($Data.SourceDirectory)"
                    'dashboard' = 'webpack-dashboard -- webpack serve --config ./webpack.config.js'
                    'predeploy' = "npm-run-all clean `"build:es -- --mode=production`" build:css"
                }
                React = @{
                    'start' = 'npm-run-all build:es --parallel watch:*'
                    'watch:es' = 'webpack serve --hot --open --mode development'
                    'serve' = ''
                }
            }
        }
        if ($PSCmdlet.ShouldProcess('Create application folder structure and common assets')) {
            $Source = $Data.SourceDirectory
            $Assets = $Data.AssetsDirectory
            @(
                ''
                $Source
                $Assets
                "${Assets}/css"
                "${Assets}/fonts"
                "${Assets}/images"
                "${Assets}/library"
                "${Assets}/workers"
                '__tests__'
            ) | ForEach-Object { New-Item -Type Directory -Path (Join-Path $ApplicationDirectory $_) -Force } | Out-Null
        }
        if ($PSCmdlet.ShouldProcess('Copy common assets')) {
            $Data, @{
                UseReact = ($Library -eq 'React')
                WithCesium = ($With -contains 'Cesium')
                NoJavaScriptEnglish = 'Please enable JavaScript in your browser for a better experience.'
                NoJavaScriptFrench = 'Veuillez activer JavaScript dans votre navigateur pour une meilleure expérience.'
                NoJavaScriptJapanese = 'より良い体験のため、ブラウザでJavaScriptを有効にして下さい'
                NoJavaScriptChinese = '请在你的浏览器中启用JavaScript以便享受最佳体验'
            } | Invoke-ObjectMerge -InPlace -Force
            $Assets = Join-Path $ApplicationDirectory $Data.AssetsDirectory
            @(
                @{
                    Filename = 'index.html'
                    Template = 'source/html_index'
                    Parent = $Assets
                }
                @{
                    Filename = 'style.css'
                    Template = 'source/css_style'
                    Parent = (Join-Path $Assets 'css')
                }
                @{
                    Filename = '.gitkeep'
                    Template = 'gitkeep'
                    Parent = (Join-Path $Assets 'fonts')
                }
                @{
                    Filename = '.gitkeep'
                    Template = 'gitkeep'
                    Parent = (Join-Path $Assets 'images')
                }
                @{
                    Filename = '.gitkeep'
                    Template = 'gitkeep'
                    Parent = (Join-Path $Assets 'library')
                }
                @{
                    Filename = '.gitkeep'
                    Template = 'gitkeep'
                    Parent = (Join-Path $Assets 'workers')
                }
            ) | ForEach-Object {
                $Parameters = $_
                $Common = @{
                    Data = $Data
                    Force = $Force
                    TemplateDirectory = $TemplateDirectory
                    Encoding = 'utf8'
                }
                Save-TemplateData @Parameters @Common
            }
        }
        switch ($Bundler) {
            Parcel {
                if ($PSCmdlet.ShouldProcess('Add Parcel dependencies to package.json')) {
                    @(
                        $PackageManifestData.devDependencies
                        $DevelopmentDependencies._workflow
                        $DevelopmentDependencies.$_
                        $DevelopmentDependencies.Stylelint
                    ) | Invoke-ObjectMerge -InPlace
                    $PackageManifestData.scripts, $NpmScripts.Common.Core, $NpmScripts.$_.Core | Invoke-ObjectMerge -InPlace
                    if ($Library -eq 'React') {
                        # Do nothing
                    }
                }
                if ($PSCmdlet.ShouldProcess('Copy Parcel files')) {
                    # TODO: Add code for copying files
                }
                if ($PSCmdlet.ShouldProcess('Save PurgeCSS configuration file')) {
                    # TODO: Add code for copying files
                }
            }
            Snowpack {
                if ($PSCmdlet.ShouldProcess('Add Snowpack dependencies and tasks to package.json')) {
                    @(
                        $PackageManifestData.devDependencies
                        $DevelopmentDependencies._workflow
                        $DevelopmentDependencies.$_
                        $DevelopmentDependencies.Stylelint
                    ) | Invoke-ObjectMerge -InPlace
                    $PackageManifestData.scripts, $NpmScripts.Common.Core, $NpmScripts.$_.Core | Invoke-ObjectMerge -InPlace
                    if ($Library -eq 'React') {
                        # Do nothing
                    }
                }
                if ($PSCmdlet.ShouldProcess('Save Snowpack configuration file')) {
                    # TODO: Add code for copying files
                }
            }
            Turbopack {
                if ($PSCmdlet.ShouldProcess('Add Turbopack dependencies to package.json')) {
                    $PackageManifestData.devDependencies, $DevelopmentDependencies.TurboPack | Invoke-ObjectMerge -InPlace
                }
                if ($PSCmdlet.ShouldProcess('Save Turbopack configuration file')) {
                    # TODO: Add code for copying files
                }
            }
            default {
                if ($PSCmdlet.ShouldProcess('Add Webpack dependencies and tasks to package.json')) {
                    @(
                        $PackageManifestData.devDependencies
                        $DevelopmentDependencies._workflow
                        $DevelopmentDependencies.Webpack
                        $DevelopmentDependencies.Stylelint
                    ) | Invoke-ObjectMerge -InPlace -Force
                    $PackageManifestData.scripts, $NpmScripts.Common.Core, $NpmScripts.Webpack.Core | Invoke-ObjectMerge -InPlace -Force
                    if ($Library -eq 'React') {
                        $PackageManifestData.scripts, $NpmScripts.Webpack.React | Invoke-ObjectMerge -InPlace -Force
                    }
                }
                if ($PSCmdlet.ShouldProcess('Save Webpack configuration file')) {
                    $Parameters = @{
                        Filename = 'webpack.config.js'
                        Template = 'config/webpack'
                        TemplateDirectory = $TemplateDirectory
                        Data = $ConfigurationFileData.Webpack
                        Parent = $ApplicationDirectory
                        Force = $Force
                    }
                    Save-TemplateData @Parameters
                }
            }
        }
        switch ($Library) {
            React {
                if ($PSCmdlet.ShouldProcess('Add React dependencies to package.json')) {
                    $PackageManifestData.dependencies, $Dependencies.React.Core | Invoke-ObjectMerge -InPlace
                    $PackageManifestData.devDependencies, $DevelopmentDependencies.React | Invoke-ObjectMerge -InPlace
                }
                if ($PSCmdlet.ShouldProcess('Copy React files')) {
                    $Source = Join-Path $ApplicationDirectory 'src'
                    $Components = Join-Path $Source 'components'
                    New-Item -Type Directory -Path $Components -Force:$Force | Out-Null
                    @(
                        @{
                            Filename = 'main.jsx'
                            Template = 'source/react/main'
                            Parent = $Source
                        }
                        @{
                            Filename = 'App.jsx'
                            Template = 'source/react/app'
                            Parent = $Components
                        }
                        @{
                            Filename = 'Header.jsx'
                            Template = 'source/react/header'
                            Parent = $Components
                        }
                        @{
                            Filename = 'Body.jsx'
                            Template = 'source/react/body'
                            Parent = $Components
                        }
                        @{
                            Filename = 'Footer.jsx'
                            Template = 'source/react/footer'
                            Parent = $Components
                        }
                    ) | ForEach-Object {
                        $Parameters = $_
                        $Common = @{
                            Data = $Data
                            Force = $Force
                            TemplateDirectory = $TemplateDirectory
                        }
                        Save-TemplateData @Parameters @Common
                    }
                    if ($With -contains 'Cesium') {
                        @(
                            @{
                                Filename = 'ResiumViewer.jsx'
                                Template = 'source/react/viewer'
                                Parent = $Components
                            }
                        ) | ForEach-Object {
                            $Parameters = $_
                            $Common = @{
                                Data = $Data
                                Force = $Force
                                TemplateDirectory = $TemplateDirectory
                            }
                            Save-TemplateData @Parameters @Common
                        }
                    }
                }
                Copy-Item -Path (Join-Path $ResourcesDirectory 'react.png') -Destination (Join-Path $ApplicationDirectory 'public/images')
            }
            Solid {
                if ($PSCmdlet.ShouldProcess('Add Solid dependencies to package.json')) {
                    $PackageManifestData.dependencies, $Dependencies.Solid | Invoke-ObjectMerge -InPlace
                }
                if ($PSCmdlet.ShouldProcess('Copy Solid files')) {
                    # TODO: Add code for copying files
                }
            }
            default {
                if ($PSCmdlet.ShouldProcess('Add JavaScript dependencies to package.json')) {
                    $PackageManifestData.dependencies, $Dependencies.Marionette | Invoke-ObjectMerge -InPlace
                    $PackageManifestData.devDependencies, $DevelopmentDependencies.BrowserSync | Invoke-ObjectMerge -InPlace
                }
                if ($PSCmdlet.ShouldProcess('Copy JavaScript files and assets')) {
                    $Source = Join-Path $ApplicationDirectory 'src'
                    $Components = Join-Path $Source 'components'
                    $Plugins = Join-Path $Source 'plugins'
                    $Shims = Join-Path $Source 'shims'
                    @(
                        $Components
                        $Plugins
                        $Shims
                    ) | ForEach-Object {
                        New-Item -Type Directory -Path $_ -Force:$Force | Out-Null
                    }
                    @(
                        @{
                            Filename = 'main.js'
                            Template = 'source/vanilla/main'
                            Parent = $Source
                        }
                        @{
                            Filename = 'app.js'
                            Template = 'source/vanilla/app'
                            Parent = $Components
                        }
                        @{
                            Filename = 'header.js'
                            Template = 'source/vanilla/header'
                            Parent = $Components
                        }
                        @{
                            Filename = 'body.js'
                            Template = 'source/vanilla/body'
                            Parent = $Components
                        }
                        @{
                            Filename = 'footer.js'
                            Template = 'source/vanilla/footer'
                            Parent = $Components
                        }
                        @{
                            Filename = 'mn.radio.logging.js'
                            Template = 'source/vanilla/mn.radio.logging'
                            Parent = $Plugins
                        }
                        @{
                            Filename = 'mn.redux.state.js'
                            Template = 'source/vanilla/mn.redux.state'
                            Parent = $Plugins
                        }
                        @{
                            Filename = 'mn.renderer.shim.js'
                            Template = 'source/vanilla/mn.renderer.shim'
                            Parent = $Shims
                        }
                    ) | ForEach-Object {
                        $Parameters = $_
                        $Common = @{
                            Data = $Data
                            Force = $Force
                            TemplateDirectory = $TemplateDirectory
                        }
                        Save-TemplateData @Parameters @Common
                    }
                }
                Copy-Item -Path (Join-Path $ResourcesDirectory 'blank.png') -Destination (Join-Path $ApplicationDirectory 'public/images')
            }
        }
        switch ($With) {
            Cesium {
                if ($PSCmdlet.ShouldProcess('Add Cesium dependencies to package.json')) {
                    $PackageManifestData.dependencies, $Dependencies.Cesium | Invoke-ObjectMerge -InPlace
                    if ($Library -eq 'React') {
                        $PackageManifestData.dependencies, $Dependencies.React.Cesium | Invoke-ObjectMerge -InPlace
                    }
                    $PackageManifestData.devDependencies, $DevelopmentDependencies.Cesium | Invoke-ObjectMerge -InPlace
                }
            }
            Reason {
                if ($Library -ne 'React' -and (-not $Silent)) {
                    '==> ReasonML works best with React.  You might consider using -React.' | Write-Warning
                }
                if ($PSCmdlet.ShouldProcess('Add ReasonML dependencies to package.json')) {
                    $PackageManifestData.dependencies, $Dependencies.Reason | Invoke-ObjectMerge -InPlace
                    $PackageManifestData.devDependencies, $DevelopmentDependencies.Reason | Invoke-ObjectMerge -InPlace
                }
                if ($PSCmdlet.ShouldProcess('Save ReasonML configuration file; Add dependencies to package.json')) {
                    $Parameters = @{
                        Filename = 'bsconfig.json'
                        Data = $ConfigurationFileData.Reason
                        Parent = $ApplicationDirectory
                        Force = $Force
                    }
                    Save-JsonData @Parameters
                }
                if ($PSCmdlet.ShouldProcess('Copy ReasonML files')) {
                    $Components = Join-Path $ApplicationDirectory 'src/components'
                    @(
                        @{
                            Filename = 'App.re'
                            Template = 'source/reason/app'
                        }
                        @{
                            Filename = 'Example.re'
                            Template = 'source/reason/example'
                        }
                    ) | ForEach-Object {
                        $Parameters = $_
                        $Common = @{
                            Data = $Data
                            Parent = $Components
                            Force = $Force
                            TemplateDirectory = $TemplateDirectory
                        }
                        Save-TemplateData @Parameters @Common
                    }
                }
            }
            Rust {
                if ($PSCmdlet.ShouldProcess('Add Rust dependencies to package.json')) {
                    $PackageManifestData.devDependencies, $DevelopmentDependencies.Rust | Invoke-ObjectMerge -InPlace
                }
                if ($PSCmdlet.ShouldProcess('Copy Rust files')) {
                    $Source = Join-Path $RustDirectory 'src'
                    $Tests = Join-Path $RustDirectory 'tests'
                    @(
                        $RustDirectory
                        $Source
                        $Tests
                    ) | Get-StringPath | ForEach-Object { New-Item -Type Directory -Path $_ -Force } | Out-Null
                    @(
                        @{
                            Filename = 'Cargo.toml'
                            Template = 'config/rust'
                            Parent = $ApplicationDirectory
                        }
                        @{
                            Filename = 'Cargo.toml'
                            Template = 'config/crate'
                            Parent = $RustDirectory
                        }
                        @{
                            Filename = 'lib.rs'
                            Template = 'source/rust/lib'
                            Parent = $Source
                        }
                        @{
                            Filename = 'utils.rs'
                            Template = 'source/rust/utils'
                            Parent = $Source
                        }
                        @{
                            Filename = 'app.rs'
                            Template = 'source/rust/app'
                            Parent = $Tests
                        }
                        @{
                            Filename = 'web.rs'
                            Template = 'source/rust/web'
                            Parent = $Tests
                        }
                    ) | ForEach-Object {
                        $Parameters = $_
                        $Common = @{
                            Data = $Data
                            Force = $Force
                            TemplateDirectory = $TemplateDirectory
                        }
                        Save-TemplateData @Parameters @Common
                    }
                }
            }
            default {}
        }
        if ($PSCmdlet.ShouldProcess('Save EditorConfig configuration file')) {
            $Parameters = @{
                Filename = '.editorconfig'
                Template = 'config/editor'
                TemplateDirectory = $TemplateDirectory
                Data = @{}
                Parent = $ApplicationDirectory
                Force = $Force
            }
            Save-TemplateData @Parameters
        }
        if ($PSCmdlet.ShouldProcess('Save package.json to application directory')) {
            $PackageManifestData = $PackageManifestData | ConvertTo-OrderedDictionary
            $PackageManifestData.dependencies = $PackageManifestData.dependencies | ConvertTo-OrderedDictionary
            $PackageManifestData.devDependencies = $PackageManifestData.devDependencies | ConvertTo-OrderedDictionary
            $PackageManifestData.scripts = $PackageManifestData.scripts | ConvertTo-OrderedDictionary
            $Parameters = @{
                Filename = 'package.json'
                Data = $PackageManifestData
                Parent = $ApplicationDirectory
                Force = $Force
            }
            Save-JsonData @Parameters
        }
        $Context = if ($PSCmdlet.ShouldProcess('Test application context')) {
            Test-ApplicationContext $ApplicationDirectory
        } else {
            Test-ApplicationContext
        }
        $Data, @{
            Context = $Context
            PackageManifestData = $PackageManifestData
        } | Invoke-ObjectMerge -Force -InPlace
        $State, @{
            Data = $Data
            Name = $Data.Name
            Parent = $Data.Parent
        } | Invoke-ObjectMerge -Force -InPlace
        $Tools = @(
            'Babel'
            'ESLint'
            'PostCSS'
            'Jest'
        )
        if ($PSCmdlet.ShouldProcess("Add development tools - $($Tools | Join-StringsWithGrammar)")) {
            Update-Application -Add $Tools -Parent $ApplicationDirectory -State $State
        }
    }
    end {
        if ($PSCmdlet.ShouldProcess('Save application state')) {
            $State | Save-State -Name $State.Name -Verbose:(-not $Silent) -Force:$Force | Out-Null
        }
        if (-not $NoInstall) {
            if ($PSCmdlet.ShouldProcess('Install dependencies')) {
                $NoErrors = if ($Context.Node.Ready) {
                    $Parameters = @{
                        Parent = $ApplicationDirectory
                        Silent = $Silent
                    }
                    Invoke-NpmInstall @Parameters
                }
            }
            if (($NoErrors -and (-not $Silent)) -or $Interactive) {
                'done' | Write-Status
            }
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
    param(
        [Parameter(Mandatory = $True, ValueFromPipeline = $True)]
        [AllowEmptyString()]
        [String] $From,
        [Int] $Size = 4
    )
    process {
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
    Set-State -Name 'My-App' -State @{ Data = 42 }
    .EXAMPLE
    Set-State 'My-App' @{ Data = 42 }
    .EXAMPLE
    @{ Data = 42 } | Set-State 'My-App'
    #>
    [CmdletBinding(SupportsShouldProcess = $True)]
    [OutputType([String])]
    param(
        [Parameter(Mandatory = $True, Position = 0)]
        [String] $Name,
        [Parameter(Mandatory = $True, Position = 1, ValueFromPipeline = $True)]
        [PSObject] $State,
        [String] $Path,
        [Switch] $Force
    )
    if (-not $Path) {
        $TempRoot = if ($IsLinux) {
            '/tmp'
        } else {
            if ($IsMacOS) {
                $Env:TMPDIR
            } else {
                $Env:temp
            }
        }
        $Filename = $Name | Get-StateName
        $Path = Join-Path $TempRoot "${Filename}.xml"
    }
    if ($PSCmdlet.ShouldProcess($Path)) {
        if ((Test-Path -Path $Path) -and (-not $Force)) {
            "==> ${Path} already exists.  To replace the existing state, use -Force" | Write-Warning
        } else {
            $State.Name = $Name
            $State | Export-Clixml -Path $Path
            "==> Saved state to ${Path}" | Write-Verbose
        }
    } else {
        "==> Would have saved state to ${Path}" | Write-Verbose
    }
    $Path
}
function Save-JsonData {
    <#
    .SYNOPSIS
    Utility function for saving JSON data.
    Provides warning message when file already exists and -Force is not used.
    #>
    [CmdletBinding()]
    param(
        [PSObject] $Data,
        [String] $Parent,
        [String] $Filename,
        [Switch] $Force
    )
    $Path = Join-Path $Parent $Filename
    $Message = "==> [WARN] ${Filename} already exists.  Please either delete ${Filename} or re-run this command with the -Force parameter."
    if (-not (Test-Path -Path $Path) -or $Force) {
        $Data |
            ConvertTo-Json -Depth 100 |
            ForEach-Object { $_ -replace '\\\\\\', '\' } |
            ForEach-Object { $_ -replace '\\u003c', '<' } |
            ForEach-Object { $_ -replace '\\u003e', '>' } |
            ForEach-Object { $_ -replace '\\u0026', '&' } |
            Format-Json |
            Out-File -FilePath $Path -Encoding ascii
    } else {
        $Message | Write-Warning
    }
}
function Save-TemplateData {
    <#
    .SYNOPSIS
    Utility function for copying template file to the application directory.
    Provides warning message when file already exists and -Force is not used.
    .PARAMETER Template
    Name of input template file (located within TemplateDirectory)
    .PARAMETER Parent
    Parent directory of where template file should be saved
    .PARAMETER Filename
    Name of output file
    #>
    [CmdletBinding()]
    param(
        [PSObject] $Data,
        [ValidateScript( { Test-Path $_ })]
        [String] $TemplateDirectory = (Get-Location).Path,
        [String] $Template,
        [String] $Parent,
        [String] $Filename,
        [String] $Encoding = 'ascii',
        [Switch] $Force
    )
    $Path = Join-Path $Parent $Filename
    $Message = "==> [WARN] ${Filename} already exists.  Please either delete ${Filename} or re-run this command with the -Force parameter."
    if (-not (Test-Path -Path $Path) -or $Force) {
        $Parameters = @{
            File = (Join-Path $TemplateDirectory $Template)
            Data = $Data
            NoData = ($Data.Count -eq 0)
        }
        New-Template @Parameters | Out-File -FilePath $Path -Encoding $Encoding
    } else {
        $Message | Write-Warning
    }
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
    param(
        [Parameter(Position = 0, ValueFromPipeline = $True)]
        [ValidateScript( { Test-Path $_ })]
        [String] $Parent = (Get-Location).Path
    )
    begin {
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
    process {
        $Installed = @{
            Cargo = (Test-Command 'cargo' -Silent)
            Rustc = (Test-Command 'rustc' -Silent)
            Npm = (Test-Command 'npm' -Silent)
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
    end {
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
    [CmdletBinding(SupportsShouldProcess = $True)]
    param(
        [Switch] $Web,
        [Switch] $Desktop,
        [ValidateSet(
            'Babel',
            'ESLint',
            'Jest',
            'PostCSS'
        )]
        [String[]] $Add,
        [ValidateSet(
            'Babel',
            'ESLint'
        )]
        [String[]] $Remove,
        [ValidateScript( { Test-Path $_ })]
        [String] $Parent = (Get-Location).Path,
        [ApplicationState] $State,
        [Switch] $Force
    )
    begin {
        $Data = if ($State) {
            $PackageManifestData = $State.Data.PackageManifestData
            $State.Data
        } else {
            $PackageManifestData = Get-Content -Path (Join-Path $Parent 'package.json') -Raw | ConvertFrom-Json
            ($PackageManifestData.name | Get-State).Data
        }
        $UseReact = $Data.Library -eq 'React'
        $ApplicationDirectory = Join-Path $Data.Parent $Data.Name
        $TemplateDirectory = Join-Path $PSScriptRoot '../src/templates'
        $PackageManifestAugment = @{
            Jest = @{
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
            Postcss = @{}
        }
        $ConfigurationFileData = @{
            Babel = @{
                Core = @{
                    plugins = @(
                        '@babel/plugin-transform-runtime'
                        '@babel/plugin-proposal-class-properties'
                        '@babel/plugin-proposal-export-default-from'
                        '@babel/plugin-proposal-optional-chaining'
                    )
                    presets = @(
                        '@babel/preset-env'
                        'babel-preset-minify'
                    )
                }
                React = @{
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
                        , @(
                            '@babel/preset-react'
                            @{
                                runtime = 'automatic'
                            }
                        )
                    )
                }
            }
            Eslint = @{
                Core = @{
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
                        'plugin:jsx-a11y/recommended'
                    )
                    parser = 'babel-eslint'
                }
                React = @{
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
                    rules = @{
                        'react/jsx-uses-react' = 'off'
                        'react/react-in-jsx-scope' = 'off'
                    }
                    settings = @{
                        react = @{
                            version = 'detect'
                        }
                    }
                }
            }
            Jest = @{
                Core = $Data
                React = @{}
            }
            Postcss = @{
                Core = @{
                    map = $True
                    parser = 'postcss-safe-parser'
                    plugins = @(
                        , @(
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
                React = @{}
            }
            Reason = @{
                Core = @{}
                React = @{
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
            }
        }
        $DevelopmentDependencies = @{
            _workflow = @{
                'cpy-cli' = '*'
                'del-cli' = '*'
                'npm-run-all' = '*'
                'watch' = '*'
            }
            Babel = @{
                Core = @{
                    '@babel/cli' = '^7.17.10'
                    '@babel/core' = '^7.18.0'
                    '@babel/plugin-proposal-class-properties' = '^7.17.12'
                    '@babel/plugin-proposal-export-default-from' = '^7.17.12'
                    '@babel/plugin-proposal-optional-chaining' = '^7.17.12'
                    '@babel/plugin-transform-runtime' = '^7.18.0'
                    '@babel/preset-env' = '^7.18.0'
                    '@babel/runtime' = '^7.18.0'
                    'babel-preset-minify' = '^0.5.2'
                }
                React = @{
                    '@babel/preset-react' = '^7.17.12'
                }
            }
            Cesium = @{
                Core = @{}
                React = @{}
            }
            Eslint = @{
                Core = @{
                    'eslint' = '^7.32.0'
                    'babel-eslint' = '^10.1.0'
                    'eslint-config-omaha-prime-grade' = '^14.0.1'
                    'eslint-plugin-import' = '^2.26.0'
                    'eslint-plugin-jsx-a11y' = '^6.5.1'
                    'eslint-plugin-promise' = '*'
                }
                React = @{
                    'eslint-plugin-react' = '^7.30.0'
                }
            }
            Jest = @{
                Core = @{
                    'jest' = '^28.1.0'
                    'babel-jest' = '^28.1.0'
                    'jest-watch-typeahead' = '^1.1.0'
                }
                React = @{}
            }
            Postcss = @{
                Core = @{
                    'cssnano' = '^5.1.9'
                    'postcss' = '^8.4.14'
                    'postcss-cli' = '^9.1.0'
                    'postcss-import' = '^14.1.0'
                    'postcss-preset-env' = '^7.6.0'
                    'postcss-reporter' = '^7.0.5'
                    'postcss-safe-parser' = '^6.0.0'
                }
                React = @{}
            }
            Reason = @{
                Core = @{}
                React = @{
                    'rescript' = '*'
                }
            }
            Stylelint = @{
                Core = @{
                    'style-loader' = '^3.3.1'
                    'stylelint' = '^14.8.3'
                    'stylelint-config-recommended' = '^7.0.0'
                }
                React = @{}
            }
        }
        $NpmScripts = @{
            Babel = @{}
            Eslint = @{
                'lint' = 'eslint . -c ./.eslintrc.json --ext .js,.jsx --fix'
                'lint:ing' = "watch `"npm run lint`" $($Data.SourceDirectory)"
                'lint:tests' = 'eslint __tests__/**/*.js -c ./.eslintrc.json --fix --no-ignore'
            }
            Jest = @{
                'test' = 'jest .*.test.js --coverage'
                'test:ing' = 'npm test -- --watchAll'
            }
            Postcss = @{
                'build:css' = "postcss $($Data.AssetsDirectory)/css/style.css --dir $($Data.ProductionDirectory)"
                'watch:css' = 'npm run build:css -- --watch'
            }
        }
    }
    process {
        switch ($Add) {
            Babel {
                $ToolName = $_
                $ConfigName = 'babel.config.json'
                if ($PSCmdlet.ShouldProcess("Save ${ToolName} configuration file; Add tasks and dependencies to package.json")) {
                    $PackageManifestData.devDependencies, $DevelopmentDependencies.$ToolName.Core | Invoke-ObjectMerge -InPlace
                    $PackageManifestData.scripts, $NpmScripts.$ToolName | Invoke-ObjectMerge -InPlace
                    $Config = if ($UseReact) {
                        $PackageManifestData.devDependencies, $DevelopmentDependencies.$ToolName.React | Invoke-ObjectMerge -InPlace
                        $ConfigurationFileData.$ToolName.React
                    } else {
                        $ConfigurationFileData.$ToolName.Core
                    }
                    $Parameters = @{
                        Data = $Config
                        Force = $Force
                        Filename = $ConfigName
                        Parent = $ApplicationDirectory
                    }
                    Save-JsonData @Parameters
                }
            }
            ESLint {
                $ToolName = $_
                $ConfigName = '.eslintrc.json'
                if ($PSCmdlet.ShouldProcess("Save ${ToolName} configuration file; Add tasks and dependencies to package.json")) {
                    $PackageManifestData.devDependencies, $DevelopmentDependencies.$ToolName.Core | Invoke-ObjectMerge -InPlace
                    $PackageManifestData.scripts, $NpmScripts.$ToolName | Invoke-ObjectMerge -InPlace
                    $Config = if ($UseReact) {
                        $PackageManifestData.devDependencies, $DevelopmentDependencies.$ToolName.React | Invoke-ObjectMerge -InPlace
                        $ConfigurationFileData.$ToolName.React
                    } else {
                        $ConfigurationFileData.$ToolName.Core
                    }
                    $Parameters = @{
                        Data = $Config
                        Force = $Force
                        Filename = $ConfigName
                        Parent = $ApplicationDirectory
                    }
                    Save-JsonData @Parameters
                }
            }
            Jest {
                $Toolname = $_
                if ($PSCmdlet.ShouldProcess('Copy Jest files; Add dependencies and tasks to package.json')) {
                    $Config = $ConfigurationFileData.$ToolName.Core
                    $PackageManifestData, $PackageManifestAugment.$ToolName | Invoke-ObjectMerge -InPlace
                    $PackageManifestData.devDependencies, $DevelopmentDependencies.$ToolName.Core | Invoke-ObjectMerge -InPlace
                    $PackageManifestData.scripts, $NpmScripts.$ToolName | Invoke-ObjectMerge -InPlace
                    if ($UseReact) {
                        # Do nothing
                    }
                    @(
                        @{
                            Filename = 'setup.js'
                            Template = 'source/jest_setup'
                        }
                        @{
                            Filename = 'example.test.js'
                            Template = 'source/jest_example'
                        }
                    ) | ForEach-Object {
                        $Parameters = $_
                        $Common = @{
                            Data = $Config
                            Force = $Force
                            TemplateDirectory = $TemplateDirectory
                            Parent = (Join-Path $ApplicationDirectory '__tests__')
                        }
                        Save-TemplateData @Parameters @Common
                    }
                }
            }
            PostCSS {
                $ToolName = $_
                $ConfigName = 'postcss.config.js'
                if ($PSCmdlet.ShouldProcess("Save ${ToolName} configuration file; Add tasks and dependencies to package.json")) {
                    $Config = $ConfigurationFileData.$ToolName.Core
                    $PackageManifestData, $PackageManifestAugment.$ToolName | Invoke-ObjectMerge -InPlace
                    $PackageManifestData.devDependencies, $DevelopmentDependencies.$ToolName.Core | Invoke-ObjectMerge -InPlace
                    $PackageManifestData.scripts, $NpmScripts.$ToolName | Invoke-ObjectMerge -InPlace
                    $Parent = $ApplicationDirectory
                    if ($UseReact) {
                        $Config, $ConfigurationFileData.$ToolName.React | Invoke-ObjectMerge -InPlace -Force
                    }
                    @(
                        @{
                            Filename = $ConfigName
                            Template = 'config/postcss'
                        }
                    ) | ForEach-Object {
                        $Parameters = $_
                        $Common = @{
                            TemplateDirectory = $TemplateDirectory
                            Data = $Config
                            Parent = $Parent
                            Force = $Force
                        }
                        Save-TemplateData @Parameters @Common
                    }
                }
            }
            default {
                if ($Null -ne $_) {
                    "==> [WARN] Adding ${_} is not currently supported" | Write-Color -Yellow
                }
            }
        }
        switch ($Remove) {
            Babel {
                $ToolName = $_
                $ConfigName = 'babel.config.json'
                if ($PSCmdlet.ShouldProcess("Remove ${ToolName} configuration file; Remove tasks and dependencies from package.json")) {
                    $PackageManifestData.devDependencies = $PackageManifestData.devDependencies | Invoke-Omit $DevelopmentDependencies.$ToolName.Core.Keys
                    $PackageManifestData.scripts = $PackageManifestData.scripts | Invoke-Omit $NpmScripts.$ToolName.Keys
                    if ($UseReact) {
                        $PackageManifestData.devDependencies = $PackageManifestData.devDependencies | Invoke-Omit $DevelopmentDependencies.$ToolName.React.Keys
                    }
                    Remove-Item $ConfigName
                }
            }
            ESLint {
                $ToolName = $_
                $ConfigName = '.eslintrc.json'
                if ($PSCmdlet.ShouldProcess("Remove ${ToolName} configuration file; Remove tasks and dependencies from package.json")) {
                    $PackageManifestData.devDependencies = $PackageManifestData.devDependencies | Invoke-Omit $DevelopmentDependencies.$ToolName.Core.Keys
                    $PackageManifestData.scripts = $PackageManifestData.scripts | Invoke-Omit $NpmScripts.$ToolName.Keys
                    if ($UseReact) {
                        $PackageManifestData.devDependencies = $PackageManifestData.devDependencies | Invoke-Omit $DevelopmentDependencies.$ToolName.React.Keys
                    }
                    Remove-Item $ConfigName
                }
            }
            default {
                if ($Null -ne $_) {
                    "==> [WARN] Removing ${_} is not currently supported" | Write-Color -Yellow
                }
            }
        }
    }
    end {
        if ($PSCmdlet.ShouldProcess('Save package.json to application directory')) {
            $PackageManifestData = $PackageManifestData | ConvertTo-OrderedDictionary
            $PackageManifestData.dependencies = $PackageManifestData.dependencies | ConvertTo-OrderedDictionary
            $PackageManifestData.devDependencies = $PackageManifestData.devDependencies | ConvertTo-OrderedDictionary
            $PackageManifestData.scripts = $PackageManifestData.scripts | ConvertTo-OrderedDictionary
            $Parameters = @{
                Force = $True
                Filename = 'package.json'
                Data = $PackageManifestData
                Parent = $ApplicationDirectory
            }
            Save-JsonData @Parameters
        }
    }
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
    param(
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