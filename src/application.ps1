function Invoke-RunApplication {
    <#
    .SYNOPSIS

    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', 'Continue')]
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