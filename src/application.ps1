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
      [Switch] $SingleRun
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
    & $Init
    if ($SingleRun) {
      & $Loop
      $State.Id | Write-Verbose
    } else {
      While (& $ShouldContinue) {
        & $Loop
        $State.Id | Write-Verbose
        & $BeforeNext
      }
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