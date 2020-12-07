function Measure-AdvancedFunctionHelp {
  <#
  .SYNOPSIS
  Named script blocks (Begin, Process, etc...) should be PascalCase.
  .DESCRIPTION
  The first letter of named script block names should be capitalized.
  This rule can auto-fix violations.
  .EXAMPLE
  # BAD
  function Get-Example {
    [CmdletBinding()]
    Param()
    'Bad' | Write-Color -Red
  }

  # GOOD
  function Get-Example {
    < Help Content Goes Here >
    [CmdletBinding()]
    Param()
    'Good' | Write-Color -Green
  }

  .INPUTS
  [System.Management.Automation.Language.ScriptBlockAst]
  .OUTPUTS
  [Microsoft.Windows.Powershell.ScriptAnalyzer.Generic.DiagnosticRecord[]]
  .NOTES
  Reference: Common software standard
  #>
  [CmdletBinding()]
  [OutputType([Object[]])]
  Param(
    [Parameter(Mandatory=$True)]
    [ValidateNotNullOrEmpty()]
    [System.Management.Automation.Language.ScriptBlockAst] $ScriptBlockAst
  )
  Begin {
    $Results = @()
    $IsFunctionDefinition = {
      Param(
        [System.Management.Automation.Language.Ast] $Ast
      )
      $Ast -is [System.Management.Automation.Language.FunctionDefinitionAst]
    }
    $HasCmdletBinding = {
      Param(
        [System.Management.Automation.Language.Ast] $Ast
      )
      $Ast -is [System.Management.Automation.Language.AttributeAst] -and ($Ast.TypeName.Name -eq 'CmdletBinding')
    }
  }
  Process {
    try {
      $Functions = $ScriptBlockAst.FindAll($IsFunctionDefinition, $False)
      foreach ($Function in $Functions) {
        $IsAdvancedFunction = $Function.Find($HasCmdletBinding, $True)
        $Help = $Function.GetHelpContent()
        if (-not $Function.IsWorkflow -and $IsAdvancedFunction -and -not $Help.Synopsis) {
          $Results += [Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord[]]@{
            Message  = "$($Function.Name) should have help content"
            RuleName = 'AdvancedFunctionHelpContent'
            Severity = 'Information'
            Extent   = $Function.Extent
          }
        }
      }
      return $Results
    } catch {
      $PSCmdlet.ThrowTerminatingError($PSItem)
    }
  }
}
function Measure-NamedBlockPascalCase {
  <#
  .SYNOPSIS
  Named script blocks (Begin, Process, etc...) should be PascalCase.
  .DESCRIPTION
  The first letter of named script block names should be capitalized.
  This rule can auto-fix violations.
  .EXAMPLE
  # BAD
  process {...}

  #GOOD
  Process {...}

  .INPUTS
  [System.Management.Automation.Language.ScriptBlockAst]
  .OUTPUTS
  [Microsoft.Windows.Powershell.ScriptAnalyzer.Generic.DiagnosticRecord[]]
  .NOTES
  Reference: Personal preference
  Note: Whether you prefer title case named script blocks or otherwise, consistency is what matters most.
  #>
  [CmdletBinding()]
  [OutputType([Object[]])]
  Param(
    [Parameter(Mandatory=$True)]
    [ValidateNotNullOrEmpty()]
    [System.Management.Automation.Language.ScriptBlockAst] $ScriptBlockAst
  )
  Begin {
    $Results = @()
    $Predicate = {
      Param(
        [System.Management.Automation.Language.Ast] $Ast
      )
      ($Ast -is [System.Management.Automation.Language.NamedBlockAst]) -and -not $Ast.Unnamed -and -not ($Ast.Extent.Text -cmatch '^[A-Z]')
    }
  }
  Process {
    try {
      $Violations = $ScriptBlockAst.FindAll($Predicate, $False)
      foreach ($Violation in $Violations) {
        $Extent = $Violation.Extent
        $Correction = $Extent.Text[0].ToString().ToUpper() + $Extent.Text.SubString(1)
        $CorrectionExtent = [Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.CorrectionExtent]::New(
          $Extent.StartLineNumber,
          $Extent.EndLineNumber,
          $Extent.StartColumnNumber,
          $Extent.EndColumnNumber,
          $Correction,
          ''# optional description - intentionally left blank
        )
        $SuggestedCorrections = New-Object System.Collections.ObjectModel.Collection['Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.CorrectionExtent']
        [Void]$SuggestedCorrections.Add($CorrectionExtent)
        $Results += [Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord[]]@{
          Message  = 'Named script block names should be PascalCase'
          RuleName = 'NamedBlockPascalCase'
          Severity = 'Warning'
          Extent   = $Extent
          SuggestedCorrections = $SuggestedCorrections
        }
      }
      return $Results
    } catch {
      $PSCmdlet.ThrowTerminatingError($PSItem)
    }
  }
}
function Measure-OperatorLowerCase {
  <#
  .SYNOPSIS
  Operators (-join, -split, etc...) should be lowercase.
  .DESCRIPTION
  Operators should not be capitalized.
  This rule can auto-fix violations.
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
  Begin {
    $Results = @()
    $Predicate = {
      Param(
        [System.Management.Automation.Language.Ast] $Ast
      )
      ($Ast -is [System.Management.Automation.Language.BinaryExpressionAst]) -and ($Ast.ErrorPosition.Text -cmatch '[A-Z]')
    }
  }
  Process {
    try {
      $Violations = $ScriptBlockAst.FindAll($Predicate, $False)
      foreach ($Violation in $Violations) {
        $Extent = $Violation.Extent
        $ErrorPosition = $Violation.ErrorPosition
        $StartColumnNumber = $Extent.StartColumnNumber
        $Start = $ErrorPosition.StartColumnNumber - $StartColumnNumber
        $End = $ErrorPosition.EndColumnNumber - $StartColumnNumber
        $Correction = $Extent.Text.SubString(0, $Start) + $ErrorPosition.Text.ToLower() + $Extent.Text.SubString($End)
        $CorrectionExtent = [Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.CorrectionExtent]::New(
          $Extent.StartLineNumber,
          $Extent.EndLineNumber,
          $StartColumnNumber,
          $Extent.EndColumnNumber,
          $Correction,
          ''# optional description - intentionally left blank
        )
        $SuggestedCorrections = New-Object System.Collections.ObjectModel.Collection['Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.CorrectionExtent']
        [Void]$SuggestedCorrections.Add($CorrectionExtent)
        $Results += [Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord[]]@{
          Message  = 'Operators should be lowercase'
          RuleName = 'OperatorLowerCase'
          Severity = 'Warning'
          Extent   = $Extent
          SuggestedCorrections = $SuggestedCorrections
        }
      }
      return $Results
    } catch {
      $PSCmdlet.ThrowTerminatingError($PSItem)
    }
  }
}
function Measure-ParamPascalCaseNoTrailingSpace {
  <#
  .SYNOPSIS
  Param block keyword should be PascalCase.
  .DESCRIPTION
  The "p" of "param" should be capitalized.
  This rule can auto-fix violations.
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
  Begin {
    $Results = @()
    $Predicate = {
      Param(
        [System.Management.Automation.Language.Ast] $Ast
      )
      ($Ast -is [System.Management.Automation.Language.ParamBlockAst]) -and -not ($Ast.Extent.Text -cmatch 'Param\(')
    }
  }
  Process {
    try {
      $Violations = $ScriptBlockAst.FindAll($Predicate, $False)
      foreach ($Violation in $Violations) {
        $Extent = $Violation.Extent
        $Correction = $Extent.Text -replace '^param\s*\(','Param('
        $CorrectionExtent = [Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.CorrectionExtent]::New(
          $Extent.StartLineNumber,
          $Extent.EndLineNumber,
          $Extent.StartColumnNumber,
          $Extent.EndColumnNumber,
          $Correction,
          ''# optional description - intentionally left blank
        )
        $SuggestedCorrections = New-Object System.Collections.ObjectModel.Collection['Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.CorrectionExtent']
        [Void]$SuggestedCorrections.Add($CorrectionExtent)
        $Results += [Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord[]]@{
          Message  = 'Param block keyword should be PascalCase with no trailing spaces'
          RuleName = 'ParamPascalCaseNoTrailingSpace'
          Severity = 'Warning'
          Extent   = $Extent
          SuggestedCorrections = $SuggestedCorrections
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
  Begin {
    $Results = @()
    $Predicate = {
      Param(
        [System.Management.Automation.Language.Ast] $Ast
      )
      $IsApplicable = ($Ast -is [System.Management.Automation.Language.TypeExpressionAst]) -or ($Ast -is [System.Management.Automation.Language.TypeConstraintAst])
      $Text = $Ast.Extent.Text -replace '[\[\]]',''
      $IsViolation = $IsApplicable -and -not ($Text -cmatch '^([A-Z]+[a-z0-9]+)((\d)|([A-Z0-9][a-z0-9]+))*([A-Z])?')
      $IsViolation
    }
  }
  Process {
    try {
      $Violations = $ScriptBlockAst.FindAll($Predicate, $False)
      foreach ($Violation in $Violations) {
        $Results += [Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord[]]@{
          Message  = "Type attribute, `"$($Violation.Extent.Text)`", should be PascalCase"
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
  Begin {
    $Results = @()
    $Predicate = {
      Param(
        [System.Management.Automation.Language.Ast] $Ast
      )
      $IsVariableExpression = $Ast -is [System.Management.Automation.Language.VariableExpressionAst]
      $Name = $Ast.Extent.Text -replace '[{}]',''
      $IsVariableExpression -and -not $Name.StartsWith('$_') -and ($Name -ne '$this') -and ($Name[1] -cnotmatch '[A-Z]')
    }
  }
  Process {
    try {
      $Violations = $ScriptBlockAst.FindAll($Predicate, $False)
      foreach ($Violation in $Violations) {
        $Results += [Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord[]]@{
          Message  = "Variable name, `"$($Violation.Extent.Text)`", should be PascalCase"
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
  Begin {
    $Results = @()
    $RuleName = 'RequireDirective'
    $Message = 'The #Requires statement prevents a script from running unless the Windows PowerShell version, modules, snap-ins, and module and snap-in version prerequisites are met. To fix a violation of this rule, please consider to use #Requires -RunAsAdministrator instead of using Import-Module'
    $Predicate = {
      Param(
        [System.Management.Automation.Language.Ast] $Ast
      )
      ($Ast -is [System.Management.Automation.Language.CommandAst]) -and ($Null -ne $Ast.GetCommandName()) -and ($Ast.GetCommandName() -eq 'import-module')
    }
  }
  Process {
    try {
      $Violations = $ScriptBlockAst.FindAll($Predicate, $True)
      if ($Null -ne $ScriptBlockAst.ScriptRequirements) {
        if ($ScriptBlockAst.ScriptRequirements.RequiredModules.Count -eq 0) {
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
        foreach ($Violation in $Violations) {
          $Results += [Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord[]]@{
            RuleName = $RuleName
            Message  = $Message
            Severity = 'Information'
            Extent   = $Violation.Extent
          }
        }
      }
      return $Results
    } catch {
      $PSCmdlet.ThrowTerminatingError($PSItem)
    }
  }
}