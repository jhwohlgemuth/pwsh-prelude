[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingInvokeExpression', '', Scope = 'Function', Target = 'New-Template')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '', Scope = 'Function', Target = 'ConvertTo-PowerShellSyntax')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '', Scope = 'Function', Target = 'Remove-Indent')]
Param()

class ApplicationState {
    [String] $Id = (New-Guid)
    [Bool] $Continue = $True
    [String] $Name = 'Application Name'
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
    Param()
    $Snippet = if (-not $IsLinux) {
        "{
            Invoke-Speak 'Goodbye'
            `$Id = `$Event.MessageData.State.Id
            `"``nApplication ID: `$Id``n`" | Write-Color -Magenta
        } | Invoke-ListenTo 'application:exit' | Out-Null"
    } else {
        ''
    }
    "
    #Requires -Modules Prelude
    [CmdletBinding()]
    Param(
        [String] `$Id = 'app',
        [Switch] `$Clear
    )
    $Empty
    `$InitialState = @{ Data = 0 }
    $Empty
    `$Init = {
        Clear-Host
        `$State = `$Args[0]
        `$Id = `$State.Id
        'Application Information:' | Write-Color
        `"ID = {{#green `$Id}}`" | Write-Label -Color Gray -Indent 2 -NewLine
        'Name = {{#green My-App}}' | Write-Label -Color Gray -Indent 2 -NewLine
        $Snippet
        '' | Write-Color
        Start-Sleep 2
    }
    $Empty
    `$Loop = {
        Clear-Host
        `$State = `$Args[0]
        `$Count = `$State.Data
        `"Current count is {{#green `$Count}}`" | Write-Color -Cyan
        `$State.Data++
        Save-State `$State.Id `$State | Out-Null
        Start-Sleep 1
    }
    $Empty
    Invoke-RunApplication `$Init `$Loop `$InitialState -Id `$Id -ClearState:`$Clear
    " | Remove-Indent
}
function New-Template {
    <#
    .SYNOPSIS
    Create render function that interpolates passed object values
    .PARAMETER Data
    Pass template data to New-Template when using New-Template within pipe chain (see examples)
    .PARAMETER NoData
    For use in tandem with templates that ONLY use external data (e.g. $Env variables)
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

    Use of the -Data parameter will cause New-Template to return a formatted string instead of template function
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
                    $Block = [ScriptBlock]::Create('$($(' + $Variable + ') | Write-Output)')
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
        if ($File) {
            $Path = Get-StringPath $File
            $Template = Get-Content $Path -Raw
        }
        $TemplateScriptBlock = [ScriptBlock]::Create('$("' + [Regex]::Replace($Template, $Pattern, $Evaluator) + '" | Write-Output)')
        $NotPassed = $Script:TemplateKeyNamesNotPassed
        if (($Binding.Count -gt 0) -or $NoData) {
            if ($PassThru) {
                return $Template
                exit
            }
            $Binding = $DefaultValues, $Binding | Invoke-ObjectMerge -Force
            try {
                $PowerShell = [PowerShell]::Create()
                $PowerShell.AddScript($Renderer).AddParameter('Binding', $Binding).AddParameter('Script', $TemplateScriptBlock).Invoke()
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
                    $PowerShell.AddScript($Renderer).AddParameter('Binding', $Binding).AddParameter('Script', $TemplateScriptBlock).Invoke()
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