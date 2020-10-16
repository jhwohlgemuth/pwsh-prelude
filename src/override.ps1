function Out-Default {
  <#
  .ForwardHelpTargetName Out-Default
  .ForwardHelpCategory Function
  #>
  [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', 'global:LAST')]
  [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', 'LAST')]
  [CmdletBinding(HelpUri='http://go.microsoft.com/fwlink/?LinkID=113362', RemotingCapability='None')]
  [OutputType([System.Diagnostics.Process])]
  Param(
    [Parameter(Position=0, ValueFromPipeline=$true)]
    [PSObject] $InputObject,
    [Switch] $Transcript
  )
  Begin {
    try {
      $OutBuffer = $null
      if ($PSBoundParameters.TryGetValue('OutBuffer', [Ref]$OutBuffer)) {
        $PSBoundParameters['OutBuffer'] = 1
      }
      $WrappedCommand = $ExecutionContext.InvokeCommand.GetCommand('Microsoft.PowerShell.Core\Out-Default', [System.Management.Automation.CommandTypes]::Cmdlet)
      $ScriptCommand = {& $WrappedCommand @PSBoundParameters }
      $SteppablePipeline = $ScriptCommand.GetSteppablePipeline()
      $SteppablePipeline.Begin($PSCmdlet)
    } catch {
      throw
    }
  }
  Process {
    try {
      $DoProcess = $true
      if ($_ -is [System.Management.Automation.ErrorRecord]) {
        if ($_.Exception -is [System.Management.Automation.CommandNotFoundException]) {
          $__Command = $_.Exception.CommandName
          if (Test-Path -Path $__Command -PathType Container) {
            Set-Location $__Command
            $DoProcess = $false
          } elseif ($__Command -match '^https?://|\.(com|org|net|edu|dev|gov|io)$') {
            [System.Diagnostics.Process]::Start($__Command)
            $DoProcess = $false
          }
        }
      }
      if ($DoProcess) {
        $Global:Last = $_;
        $SteppablePipeline.Process($_)
      }
    } catch {
      throw
    }
  }
  End {
    try {
      $SteppablePipeline.End()
    } catch {
      throw
    }
  }
}