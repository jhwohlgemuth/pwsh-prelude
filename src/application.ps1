class ApplicationState {
  [String] $Id = (New-Guid)
  [Bool] $Continue = $True
  [String] $Name = 'Application Name'
  $Data
}
function ConvertTo-PowershellSyntax {
  [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'DataVariableName')]
  [OutputType([String])]
  Param(
    [Parameter(Mandatory=$True, Position=0, ValueFromPipeline=$True)]
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
    [Parameter(Position=0, ValueFromPipeline=$True)]
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
function Invoke-RunApplication {
  <#
  .SYNOPSIS
  Entry point for Powershell CLI application
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
  # Make a simple app

  # Initialize your app - $Init is only run once
  $Init = {
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

  .EXAMPLE
  # Make a simple app with state
  # Note: State is passed to Init, Loop, ShouldContinue, and BeforeNext

  New-ApplicationTemplate -Save

  .EXAMPLE
  # Applications trigger events throughout their lifecycle which can be listened to (most commonly within the Init scriptblock).
  { say 'Hello' } | on 'application:init'
  { say 'Wax on' } | on 'application:loop:before'
  { say 'Wax off' } | on 'application:loop:after'
  { say 'Goodbye' } | on 'application:exit'

  # The triggered event will include State as MessageData
  {

    $Id = $Event.MessageData.State.Id
    "`nApplication ID: $Id" | Write-Color -Green

  } | Invoke-ListenTo 'application:init'
  #>
  [CmdletBinding()]
  Param(
    [Parameter(Mandatory=$True, Position=0)]
    [ScriptBlock] $Init,
    [Parameter(Mandatory=$True, Position=1)]
    [ScriptBlock] $Loop,
    [Parameter(Position=2)]
    [ApplicationState] $State,
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
      $State = [ApplicationState]@{ Id = $Id }
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
      $State.Continue = ('yes','no' | Invoke-Menu) -eq 'yes'
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
    While (& $ShouldContinue $State) {
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
function New-ApplicationTemplate {
  <#
  .SYNOPSIS
  Return boilerplate string of a "scrapp" ("script" + "app")
  .EXAMPLE
  New-ApplicationTemplate | Out-File 'my-app.ps1'

  #>
  [CmdletBinding()]
  Param()
  "  #Requires -Modules pwsh-prelude
  [CmdletBinding()]
  Param(
    [String] {{ Dollar }}Id,
    [Switch] {{ Dollar }}Clear
  )
  $Empty
  {{ Dollar }}InitialState = @{ Data = 0 }
  $Empty
  {{ Dollar }}Init = {
    Clear-Host
    {{ Dollar }}State = {{ Dollar }}args[0]
    {{ Dollar }}Id = {{ Dollar }}State.Id
    'Application Information:' | Write-Color
    `"ID = {{#green {{ Dollar }}Id}}`" | Write-Label -Color Gray -Indent 2 -NewLine
    'Name = {{#green My-App}}' | Write-Label -Color Gray -Indent 2 -NewLine
    {
      Invoke-Speak 'Goodbye'
      {{ Dollar }}Id = {{ Dollar }}Event.MessageData.State.Id
      `"`{{ Grave }}nApplication ID: {{ Dollar }}Id`{{ Grave }}n`" | Write-Color -Magenta
    } | Invoke-ListenTo 'application:exit' | Out-Null
    '' | Write-Color
    Start-Sleep 2
  }
  $Empty
  {{ Dollar }}Loop = {
    Clear-Host
    {{ Dollar }}State = {{ Dollar }}args[0]
    {{ Dollar }}Count = {{ Dollar }}State.Data
    `"Current count is {{#green {{ Dollar }}Count}}`" | Write-Color -Cyan
    {{ Dollar }}State.Data++
    Save-State {{ Dollar }}State.Id {{ Dollar }}State | Out-Null
    Start-Sleep 1
  }
  $Empty
  Invoke-RunApplication {{ Dollar }}Init {{ Dollar }}Loop {{ Dollar }}InitialState -Id {{ Dollar }}Id -ClearState:{{ Dollar }}Clear
  " | New-Template -Data @{ Dollar = '$'; Grave = '`' } | Remove-Indent
}
function New-Template {
  <#
  .SYNOPSIS
  Create render function that interpolates passed object values
  .PARAMETER Data
  Pass template data to New-Template when using New-Template within pipe chain (see examples)
  .EXAMPLE
  $Function:render = New-Template '<div>Hello {{ name }}!</div>'
  render @{ name = 'World' }
  # '<div>Hello World!</div>'

  Use mustache template syntax! Just like Handlebars.js!
  .EXAMPLE
  $Function:render = 'hello {{ name }}' | New-Template
  @{ name = 'world' } | render
  # 'hello world'

  New-Template supports idiomatic powershell pipeline syntax
  .EXAMPLE
  $Function:render = New-Template '<div>Hello $($Data.name)!</div>'
  render @{ name = 'World' }
  # '<div>Hello World!</div>'

  Or stick to plain Powershell syntax...this is a little more verbose ($Data is required)
  .EXAMPLE
  $title = New-Template -Template '<h1>{{ text }}</h1>' -DefaultValues @{ text = 'Default' }
  & $title
  # '<h1>Default</h1>'
  & $title @{ text = 'Hello World' }
  # '<h1>Hello World</h1>'

  Provide default values for your templates!
  .EXAMPLE
  $div = New-Template -Template '<div>{{ text }}</div>'
  $section = New-Template "<section>
      <h1>{{ title }}</h1>
      $(& $div @{ text = 'Hello World!' })
  </section>"

  Templates can even be nested!
  .EXAMPLE
  '{{#green Hello}} {{ name }}' | tpl -Data @{ name = 'World' } | Write-Color

  Use -Data parameter cause template to return formatted string instead of template function
  #>
  [CmdletBinding(DefaultParameterSetName='template')]
  [Alias('tpl')]
  [OutputType([ScriptBlock], ParameterSetName='template')]
  [OutputType([String], ParameterSetName='inline')]
  Param(
    [Parameter(Mandatory=$True, Position=0, ValueFromPipeline=$True)]
    [String] $Template,
    [Parameter(ParameterSetName='inline')]
    [PSObject] $Data,
    [Parameter(ValueFromPipelineByPropertyName=$True)]
    [PSObject] $DefaultValues
  )
  $Script:__template = $Template # This line is super important
  $Script:__defaults = $DefaultValues # This line is also super important
  $Renderer = {
    Param(
      [Parameter(Position=0, ValueFromPipeline=$True)]
      [PSObject] $Data,
      [Switch] $PassThru
    )
    if ($PassThru) {
      $StringToRender = $Script:__template
    } else {
      $DataVariableName = Get-Variable -Name Data | ForEach-Object { $_.Name }
      "`"Data`" variable name = $DataVariableName" | Write-Verbose
      $StringToRender = $Script:__template | ConvertTo-PowershellSyntax -DataVariableName $DataVariableName
    }
    if (-not $Data) {
      "Data = $($Data | ConvertTo-Json)" | Write-Verbose
      $Data = $Script:__defaults
    }
    $StringToRender = $StringToRender -replace '"', '`"'
    "String to render = $StringToRender" | Write-Verbose
    $ImportDataVariable = "`$Data = '$(ConvertTo-Json ([System.Management.Automation.PSObject]$Data))' | ConvertFrom-Json"
    '==> Creating PowerShell sandbox' | Write-Verbose
    $Powershell = [Powershell]::Create()
    "==> Adding script: $ImportDataVariable" | Write-Verbose
    "==> Adding script: Write-Output `"$StringToRender`"" | Write-Verbose
    [Void]$Powershell.AddScript($ImportDataVariable).AddScript("Write-Output `"$StringToRender`"")
    '==> Invoking scripts within PowerShell sandbox' | Write-Verbose
    $Powershell.Invoke()
    '==> Disposing of PowerShell sandbox' | Write-Verbose
    [Void]$Powershell.Dispose()
  }
  if ($Data) {
    & $Renderer $Data
  } else {
    $Renderer
  }
}
function Remove-Indent {
  <#
  .SYNOPSIS
  Remove indentation of multi-line (or single line) strings
  ==> Good for removing spaces added to template strings because of alignment with code.
  #>
  [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'Size')]
  [CmdletBinding()]
  Param(
    [Parameter(Mandatory=$True, ValueFromPipeline=$True)]
    [AllowEmptyString()]
    [String] $From,
    [Int] $Size = 2
  )
  Process {
    $Lines = $From -split '\n'
    $Delimiter = if($Lines.Count -eq 1) { '' } else { "`n" }
    $Callback = { $Args[0],$Args[1] -join $Delimiter }
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
  [CmdletBinding(SupportsShouldProcess=$True)]
  Param(
    [Parameter(Position=0)]
    [String] $Id,
    [Parameter(Mandatory=$True, Position=1, ValueFromPipeline=$True)]
    [PSObject] $State,
    [String] $Path
  )
  if (-not $Path) {
    $TempRoot = if ($IsLinux) { '/tmp' } else { $Env:temp }
    $Path = Join-Path $TempRoot "state-$Id.xml"
  }
  if ($PSCmdlet.ShouldProcess($Path)) {
    $State = [ApplicationState]$State
    if ($Id) {
      $State.Id = $Id
    }
    $State | Export-Clixml -Path $Path
    "==> Saved state to $Path" | Write-Verbose
  } else {
    "==> Would have saved state to $Path" | Write-Verbose
  }
  $Path
}