function Measure-ParamPascalCase {
  <#
  .SYNOPSIS
  Param block keyword should be PascalCase.
  .DESCRIPTION
  The "p" of "param" should be capitalized.
  .EXAMPLE
  # BAD
  param()

  #GOOD
  Param()

  .INPUTS
  [System.Management.Automation.Language.ScriptBlockAst]
  .OUTPUTS
  [Microsoft.Windows.Powershell.ScriptAnalyzer.Generic.DiagnosticRecord[]]
  .NOTES
  Reference: Personal preference
  Note: Whether you prefer PascalCase or otherwise, consistency is what matters most.
  #>
  [CmdletBinding()]
  [OutputType([Object[]])]
  Param(
    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [System.Management.Automation.Language.ScriptBlockAst] $ScriptBlockAst
  )
  Process {
    [Microsoft.Windows.Powershell.ScriptAnalyzer.Generic.DiagnosticRecord[]]$Results = @()
    try {
      $Predicate = {
        Param(
          [System.Management.Automation.Language.Ast] $Ast
        )
        ($Ast -is [System.Management.Automation.Language.ParamBlockAst]) -and -not ($Ast.Extent.Text -cmatch 'Param\s*\(')
      }
      $Violations = $ScriptBlockAst.FindAll($Predicate, $false)
      $Count = 0
      foreach ($Violation in $Violations) {
        $Results += [Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord[]]@{
          Message  = 'Param block keyword should be PascalCase.'
          RuleName = 'ParamPascalCase'
          Severity = 'Warning'
          Extent   = $Violation.Extent
        }
        $Count++
      }
      return $Results
    } catch {
      $PSCmdlet.ThrowTerminatingError($PSItem)
    }
  }
}
function Measure-UseRequiresDirective {
  <#
  .SYNOPSIS
  Name of your rule.
  .DESCRIPTION
  This would be the description of your rule. Please refer to Rule Documentation for consistent rule messages.
  .EXAMPLE
  .INPUTS
  .OUTPUTS
  .NOTES
  #>
  [CmdletBinding()]
  [OutputType([Microsoft.Windows.Powershell.ScriptAnalyzer.Generic.DiagnosticRecord[]])]
  Param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [System.Management.Automation.Language.ScriptBlockAst] $ScriptBlockAst
  )
  Process {
    $results = @()
    $Message = 'The #Requires statement prevents a script from running unless the Windows PowerShell version, modules, snap-ins, and module and snap-in version prerequisites are met. To fix a violation of this rule, please consider to use #Requires -RunAsAdministrator instead of using Import-Module'
    try {
      [ScriptBlock]$predicate = {
        Param(
          [System.Management.Automation.Language.Ast] $Ast
        )
        [Bool]$returnValue = $false
        if ($Ast -is [System.Management.Automation.Language.CommandAst]) {
          [System.Management.Automation.Language.CommandAst]$cmdAst = $Ast;
          if ($null -ne $cmdAst.GetCommandName()) {
            if ($cmdAst.GetCommandName() -eq "import-module") {
              $returnValue = $true
            }
          }
        }
        return $returnValue
      }
      [System.Management.Automation.Language.Ast[]]$asts = $ScriptBlockAst.FindAll($predicate, $true)
      if ($null -ne $ScriptBlockAst.ScriptRequirements) {
        if (($ScriptBlockAst.ScriptRequirements.RequiredModules.Count -eq 0) -and ($null -ne $asts)) {
          foreach ($ast in $asts) {
            $result = New-Object `
              -Typename "Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord" `
              -ArgumentList $Message,$ast.Extent,'RequireDirective',Information,$null
            $results += $result
          }
        }
      } else {
        if ($null -ne $asts) {
          foreach ($ast in $asts) {
            $result = New-Object `
              -Typename "Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord" `
              -ArgumentList $Message,$ast.Extent,'RequireDirective',Information,$null
            $results += $result
          }
        }
      }
      return $results
    } catch {
      $PSCmdlet.ThrowTerminatingError($PSItem)
    }
  }
}