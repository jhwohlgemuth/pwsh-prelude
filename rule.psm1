function Measure-OperatorLowerCase {
  <#
  .SYNOPSIS
  Operators (-join, -split, etc...) should be lowercase.
  .DESCRIPTION
  Operators should not be capitalized.
  .EXAMPLE
  # BAD
  $Foo -Join $Bar

  #GOOD
  $Foo -join $Bar

  .INPUTS
  [System.Management.Automation.Language.ScriptBlockAst]
  .OUTPUTS
  [Microsoft.Windows.Powershell.ScriptAnalyzer.Generic.DiagnosticRecord[]]
  .NOTES
  Reference: Personal preference
  Note: Whether you prefer lowercase operators or otherwise, consistency is what matters most.
  #>
  [CmdletBinding()]
  [OutputType([Object[]])]
  Param(
    [Parameter(Mandatory=$True)]
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
        ($Ast -is [System.Management.Automation.Language.BinaryExpressionAst]) -and ($Ast.ErrorPosition.Text -cmatch '[A-Z]')
      }
      $Violations = $ScriptBlockAst.FindAll($Predicate, $False)
      foreach ($Violation in $Violations) {
        $Results += [Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord[]]@{
          Message  = 'Operators should be lowercase.'
          RuleName = 'OperatorLowerCase'
          Severity = 'Warning'
          Extent   = $Violation.Extent
        }
      }
      return $Results
    } catch {
      $PSCmdlet.ThrowTerminatingError($PSItem)
    }
  }
}
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
    [Parameter(Mandatory=$True)]
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
      $Violations = $ScriptBlockAst.FindAll($Predicate, $False)
      foreach ($Violation in $Violations) {
        $Results += [Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord[]]@{
          Message  = 'Param block keyword should be PascalCase.'
          RuleName = 'ParamPascalCase'
          Severity = 'Warning'
          Extent   = $Violation.Extent
        }
      }
      return $Results
    } catch {
      $PSCmdlet.ThrowTerminatingError($PSItem)
    }
  }
}
function Measure-TypeAttributePascalCase {
  <#
  .SYNOPSIS
  Type annotations ([String], [Array], etc...) should be PascalCase.
  .DESCRIPTION
  The first letter of type annotations should be capitalized.
  .EXAMPLE
  # BAD
  [bool]$Foo = $False

  #GOOD
  [Bool]$Foo = $True

  .INPUTS
  [System.Management.Automation.Language.ScriptBlockAst]
  .OUTPUTS
  [Microsoft.Windows.Powershell.ScriptAnalyzer.Generic.DiagnosticRecord[]]
  .NOTES
  Reference: Personal preference
  Note: Whether you prefer PascalCase type names or otherwise, consistency is what matters most.
  #>
  [CmdletBinding()]
  [OutputType([Object[]])]
  Param(
    [Parameter(Mandatory=$True)]
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
        $IsVariableExpression = $Ast -is [System.Management.Automation.Language.VariableExpressionAst]
        $VariableAnnotation = $Ast.Parent.Attribute.Extent.Text
        $IsVariableViolation = $IsVariableExpression -and ($VariableAnnotation -match '^\[.*\]') -and -not ($VariableAnnotation -cmatch '^\[[A-Z]')
        # Check for param block parameter type attributes
        $IsVariableViolation
      }
      $Violations = $ScriptBlockAst.FindAll($Predicate, $False)
      foreach ($Violation in $Violations) {
        $Results += [Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord[]]@{
          Message  = "The type attribute, `"$($Violation.Parent.Attribute.Extent)`", should be PascalCase."
          RuleName = 'TypeAttributePascalCase'
          Severity = 'Warning'
          Extent   = $Violation.Extent
        }
      }
      return $Results
    } catch {
      $PSCmdlet.ThrowTerminatingError($PSItem)
    }
  }
}
function Measure-VariablePascalCase {
  <#
  .SYNOPSIS
  Variables ($Foo, $Bar, etc...) should be PascalCase.
  .DESCRIPTION
  The first letter of a variable names should be capitalized.
  .EXAMPLE
  # BAD
  $foo = 'foo'
  $bar = 'bar'

  #GOOD
  $Foo = 'foo'
  $Bar = 'bar'

  .INPUTS
  [System.Management.Automation.Language.ScriptBlockAst]
  .OUTPUTS
  [Microsoft.Windows.Powershell.ScriptAnalyzer.Generic.DiagnosticRecord[]]
  .NOTES
  Reference: Personal preference
  Note: Whether you prefer PascalCase variable names or otherwise, consistency is what matters most.
  #>
  [CmdletBinding()]
  [OutputType([Object[]])]
  Param(
    [Parameter(Mandatory=$True)]
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
        $IsVariableExpression = $Ast -is [System.Management.Automation.Language.VariableExpressionAst]
        $Name = $Ast.Extent.Text -replace '[{}]',''
        $IsVariableExpression -and -not $Name.StartsWith('$_') -and ($Name -ne '$this') -and ($Name[1] -cnotmatch '[A-Z]')
      }
      $Violations = $ScriptBlockAst.FindAll($Predicate, $False)
      foreach ($Violation in $Violations) {
        $Results += [Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord[]]@{
          Message  = "The variable name, `"$($Violation.Extent.Text)`", should be PascalCase."
          RuleName = 'VariablePascalCase'
          Severity = 'Warning'
          Extent   = $Violation.Extent
        }
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
  "Requires" should be used instead of "Import-Module"
  .DESCRIPTION
  The #Requires statement prevents a script from running unless the Windows PowerShell version, modules, snap-ins, and module and snap-in version prerequisites are met.
  From Windows PowerShell 3.0, the #Requires statement let script developers specify Windows PowerShell modules that the script requires.
  .EXAMPLE
  #BAD
  Import-Module -Name SomeModule

  #GOOD (at top of file)
  #Requires -Modules SomeModule

  .INPUTS
  [System.Management.Automation.Language.ScriptBlockAst]
  .OUTPUTS
  [Microsoft.Windows.Powershell.ScriptAnalyzer.Generic.DiagnosticRecord[]]
  .NOTES
  See https://github.com/PowerShell/PSScriptAnalyzer/blob/development/Tests/Engine/CommunityAnalyzerRules/CommunityAnalyzerRules.psm1
  #>
  [CmdletBinding()]
  [OutputType([Object[]])]
  Param(
    [Parameter(Mandatory=$True)]
    [ValidateNotNullOrEmpty()]
    [System.Management.Automation.Language.ScriptBlockAst] $ScriptBlockAst
  )
  Process {
    $Results = @()
    $RuleName = 'RequireDirective'
    $Message = 'The #Requires statement prevents a script from running unless the Windows PowerShell version, modules, snap-ins, and module and snap-in version prerequisites are met. To fix a violation of this rule, please consider to use #Requires -RunAsAdministrator instead of using Import-Module'
    try {
      $Predicate = {
        Param(
          [System.Management.Automation.Language.Ast] $Ast
        )
        $ReturnValue = $False
        if ($Ast -is [System.Management.Automation.Language.CommandAst]) {
          [System.Management.Automation.Language.CommandAst]$CommandAst = $Ast;
          if ($Null -ne $CommandAst.GetCommandName()) {
            if ($CommandAst.GetCommandName() -eq 'import-module') {
              $ReturnValue = $True
            }
          }
        }
        return $ReturnValue
      }
      [System.Management.Automation.Language.Ast[]]$Violations = $ScriptBlockAst.FindAll($Predicate, $True)
      if ($Null -ne $ScriptBlockAst.ScriptRequirements) {
        if (($ScriptBlockAst.ScriptRequirements.RequiredModules.Count -eq 0) -and ($Null -ne $Violations)) {
          foreach ($Violation in $Violations) {
            $Results += [Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord[]]@{
              Message  = $Message
              RuleName = $RuleName
              Severity = 'Information'
              Extent   = $Violation.Extent
            }
          }
        }
      } else {
        if ($Null -ne $Violations) {
          foreach ($Violation in $Violations) {
            $Results += [Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord[]]@{
              RuleName = $RuleName
              Message  = $Message
              Severity = 'Information'
              Extent   = $Violation.Extent
            }
          }
        }
      }
      return $Results
    } catch {
      $PSCmdlet.ThrowTerminatingError($PSItem)
    }
  }
}