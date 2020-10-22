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
  $Template = "
  {{ Dollar }}State = @{}

  {{ Dollar }}Init = {
    Clear-Host
    'Gettings things ready for `"{{#green {{ Name }}}}`"...' | Write-Color -Gray
    {
      Invoke-Speak 'Goodbye'
      {{ Dollar }}Id = {{ Dollar }}Event.MessageData.State.Id
      `"`{{ Grave }}nApplication ID: {{ Dollar }}Id`{{ Grave }}n`" | Write-Color -Magenta
    } | Invoke-ListenTo 'application:exit' | Out-Null
    '' | Write-Color
    Start-Sleep 1
  }

  {{ Dollar }}Loop = {
    Clear-Host
    'Doing something super {{#magenta awesome}}...' | Write-Color -Cyan
    Start-Sleep 1
  }

  Invoke-RunApplication {{ Dollar }}Init {{ Dollar }}Loop {{ Dollar }}State
  " | New-Template -Data @{ Name = $Name; Dollar = '$'; Grave = '`' } | Remove-Indent
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
    'Setting up application...' | Write-Color -Green
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
  # Make a simple app with state that counts the number of times $Loop is executed.

  $State = @{ Data = 0 }
  $Render = 'Current count is {{#green {{ Data }}}}' | New-Template
  $Init = {
    Clear-Host
    'Getting things ready...' | Write-Color -Gray
    Start-Sleep 1
  }
  $Loop = {
    Clear-Host
    & $Render $State | Write-Color
    $State.Data++
  }
  Invoke-RunApplication $Init $Loop $State

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
    [ScriptBlock] $ShouldContinue,
    [ScriptBlock] $BeforeNext,
    [Switch] $SingleRun,
    [Switch] $NoCleanup
  )
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
  & $Init
  if ($SingleRun) {
    'application:loop:before' | Invoke-FireEvent -Data @{ State = $State }
    & $Loop
    'application:loop:after' | Invoke-FireEvent -Data @{ State = $State }
  } else {
    While (& $ShouldContinue) {
      'application:loop:before' | Invoke-FireEvent -Data @{ State = $State }
      & $Loop
      'application:loop:after' | Invoke-FireEvent -Data @{ State = $State }
      & $BeforeNext
    }
  }
  'application:exit' | Invoke-FireEvent -Data @{ State = $State }
  if (-not $NoCleanup) {
    'application:' | Invoke-StopListen
  }
}
enum ApplicationStatus { Init; Busy; Idle; Done }
class ApplicationState {
  hidden [String] $Id = (New-Guid)
  hidden [ApplicationStatus] $Status = 0
  [Bool] $Continue = $true
  [String] $Name = 'Application Name'
  $Data
}