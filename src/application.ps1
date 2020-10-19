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
    .EXAMPLE
    $Init = {
      $Global:Continue = 'yes'
      'Setting up application...' | Write-Color -Green
    }
    $Loop = {
      Clear-Host
      'Doing something super important...' | Write-Color -Gray
      Start-Sleep 5
    }
    Invoke-RunApplication $Init $Loop
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', 'Continue')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', 'Global:Continue')]
    [CmdletBinding()]
    Param(
      [Parameter(Mandatory=$true, Position=0)]
      [ScriptBlock] $Init,
      [Parameter(Mandatory=$true, Position=1)]
      [ScriptBlock] $Loop,
      [ScriptBlock] $ShouldContinue = { $Global:Continue -eq 'yes' },
      [ScriptBlock] $BeforeNext = {
        "`nContinue?" | Write-Label -NewLine
        $Global:Continue = 'yes','no' | Invoke-Menu
      }
    )
    & $Init
    While (& $ShouldContinue) {
      & $Loop
      & $BeforeNext
    }
  }