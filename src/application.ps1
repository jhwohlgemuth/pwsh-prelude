function New-ApplicationTemplate {
  <#
  .SYNOPSIS
  Create new application template file for writing a new "scrapp" (script + application)
  #>
  [CmdletBinding()]
  Param(
    [Parameter(Position=0)]
    [String] $Name = 'app',
    [Switch] $Save
  )
  $Data = @{ Name = $Name; Dollar = '$'; Grave = '`' }
  $Template = "  [CmdletBinding()]
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
    'Name = {{#green {{ Name }}}}' | Write-Label -Color Gray -Indent 2 -NewLine
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
  " | New-Template -Data $Data | Remove-Indent
  if ($Save) {
    $Template | Out-File "${Name}.ps1"
  } else {
    $Template
  }
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
    [Parameter(Mandatory=$true, Position=0)]
    [ScriptBlock] $Init,
    [Parameter(Mandatory=$true, Position=1)]
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
    $Path = Join-Path $Env:temp "state-$Id.xml"
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
    $ShouldContinue = { $State.Continue -eq $true }
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
enum ApplicationStatus { Init; Busy; Idle; Done }
class ApplicationState {
  [String] $Id = (New-Guid)
  [ApplicationStatus] $Status = 0
  [Bool] $Continue = $true
  [String] $Name = 'Application Name'
  $Data
}
function Save-State {
  <#
  .SYNOPSIS
  Save state object as CliXml in temp directory
  .EXAMPLE
  Set-State -Id 'abc-def-ghi' -State @{ Data = 0 }

  .EXAMPLE
  Set-State 'abc-def-ghi' @{ Data = 0 }

  #>
  [CmdletBinding(SupportsShouldProcess=$true)]
  Param(
    [Parameter(Mandatory=$true, Position=0)]
    [String] $Id,
    [Parameter(Mandatory=$true, Position=1)]
    [ApplicationState] $State,
    [String] $Path
  )
  if (-not $Path) {
    $Path = Join-Path $Env:temp "state-$Id.xml"
  }
  if ($PSCmdlet.ShouldProcess($Path)) {
    $State | Export-Clixml -Path $Path
    "==> Saved state to $Path" | Write-Verbose
  } else {
    "==> Would have saved state to $Path" | Write-Verbose
  }
  $Path
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
    [Parameter(Position=0, ValueFromPipeline=$true)]
    [String] $Id,
    [AllowEmptyString()]
    [String] $Path
  )
  if ($Path.Length -gt 0 -and (Test-Path $Path)) {
    "==> Resolved $Path" | Write-Verbose
  } else {
    $Path = Join-Path $Env:temp "state-$Id.xml"
  }
  "==> Loading state from $Path" | Write-Verbose
  Import-Clixml -Path $Path
}