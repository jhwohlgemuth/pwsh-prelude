function Invoke-FireEvent {
    <#
    .SYNOPSIS
    Create event
    .EXAMPLE
    'eventName' | Invoke-FireEvent
    #>
    [CmdletBinding()]
    [Alias('trigger')]
    Param(
      [Parameter(Mandatory=$True, Position=0, ValueFromPipeline=$True)]
      [String] $Name,
      [PSObject] $Data
    )
    New-Event -SourceIdentifier $Name -MessageData $Data | Out-Null
  }
function Invoke-ListenTo {
  <#
  .SYNOPSIS
  Create an event listener ("subscriber"). Basically a wrapper for Register-EngineEvent.
  .PARAMETER Path
  Path to file or folder that will be watched for changes
  .PARAMETER Exit
  Set event source identifier to Powershell.Exiting
  .PARAMETER Idle
  Set event source identifier to Powershell.OnIdle.
  Warning: It is not advised to write to console in callback of -Idle listeners.
  .EXAMPLE
  { Write-Color 'Event triggered' -Red } | on 'SomeEvent'

  Expressive yet terse syntax for easy event-driven design.
  .EXAMPLE
  Invoke-ListenTo -Name 'SomeEvent' -Callback { Write-Color "Event: $($Event.SourceIdentifier)" }

  Callbacks hae access to automatic variables such as $Event
  .EXAMPLE
  $Callback | on 'SomeEvent' -Once

  Create a listener that automatically destroys itself after one event is triggered
  .EXAMPLE
  $Callback = {
  $Data = $args[1]
  "Name ==> $($Data.Name)" | Write-Color -Magenta
  "Event ==> $($Data.ChangeType)" | Write-Color -Green
  "Fullpath ==> $($Data.FullPath)" | Write-Color -Cyan
  }
  $Callback | listenTo -Path .

  Watch files and folders for changes (create, edit, rename, delete)
  .EXAMPLE
  # Declare a value for boot
  $boot = 42

  # Create a callback
  $Callback = {
  $Data = $Event.MessageData
  say "$($Data.Name) was changed from $($Data.OldValue), to $($Data.Value)"
  }

  # Start the variable listener
  $Callback | listenTo 'boot' -Variable

  # Change the value of boot and have your computer tell you what changed
  $boot = 43

  .EXAMPLE
  { 'EVENT - EXIT' | Out-File ~\dev\MyEvents.txt -Append } | on -Exit

  Execute code when you exit the powershell terminal
  #>
  [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '', Scope='Function')]
  [CmdletBinding(DefaultParameterSetName = 'custom')]
  [Alias('on', 'listenTo')]
  Param(
    [Parameter(ParameterSetName='custom', Position=0)]
    [Parameter(ParameterSetName='variable', Position=0)]
    [String] $Name,
    [Parameter(ParameterSetName='custom')]
    [Parameter(ParameterSetName='variable')]
    [Switch] $Once,
    [Parameter(ParameterSetName='custom')]
    [Switch] $Exit,
    [Parameter(ParameterSetName='custom')]
    [Switch] $Idle,
    [Parameter(ParameterSetName='custom', Mandatory=$True, ValueFromPipeline=$True)]
    [Parameter(ParameterSetName='variable', Mandatory=$True, ValueFromPipeline=$True)]
    [Parameter(ParameterSetName='filesystem', Mandatory=$True, ValueFromPipeline=$True)]
    [scriptblock] $Callback,
    [Parameter(ParameterSetName='custom')]
    [Parameter(ParameterSetName='filesystem')]
    [Switch] $Forward,
    [Parameter(ParameterSetName='filesystem', Mandatory=$True)]
    [String] $Path,
    [Parameter(ParameterSetName='filesystem')]
    [Switch] $IncludeSubDirectories,
    [Parameter(ParameterSetName='filesystem')]
    [Switch] $Absolute,
    [Parameter(ParameterSetName='variable')]
    [Switch] $Variable
  )
  $Action = $Callback
  if ($Path.Length -gt 0) { # file system watcher events
    if (-not $Absolute) {
      $Path = Join-Path (Get-Location) $Path -Resolve
    }
    Write-Verbose "==> Creating file system watcher object for `"$Path`""
    $Watcher = New-Object System.IO.FileSystemWatcher
    $Watcher.Path = $Path
    $Watcher.Filter = '*.*'
    $Watcher.EnableRaisingEvents = $True
    $Watcher.IncludeSubdirectories = $IncludeSubDirectories
    Write-Verbose '==> Creating file system watcher events'
    'Created','Changed','Deleted','Renamed' | ForEach-Object {
      Register-ObjectEvent $Watcher $_ -Action $Action
    }
  } elseif ($Variable) { # variable change events
    $VariableNamespace = New-Guid | Select-Object -ExpandProperty Guid | ForEach-Object { $_ -replace "-", "_" }
    $Global:__NameVariableValue = $Name
    $Global:__VariableChangeEventLabel = "VariableChangeEvent_$VariableNamespace"
    $Global:__NameVariableLabel = "Name_$VariableNamespace"
    $Global:__OldValueVariableLabel = "OldValue_$VariableNamespace"
    New-Variable -Name $Global:__NameVariableLabel -Value $Name -Scope Global
    Write-Verbose "Variable name = $Global:__NameVariableValue"
    if ((Get-Variable | Select-Object -ExpandProperty Name) -contains $Name) {
      New-Variable -Name $Global:__OldValueVariableLabel -Value (Get-Variable -Name $Name -ValueOnly) -Scope Global
      Write-Verbose "Initial value = $(Get-Variable -Name $Name -ValueOnly)"
    } else {
      Write-Error "Variable not found in current scope ==> `"$Name`""
    }
    $UpdateValue = {
      $Name = Get-Variable -Name $Global:__NameVariableLabel -Scope Global -ValueOnly
      $NewValue = Get-Variable -Name $Global:__NameVariableValue -Scope Global -ValueOnly
      $OldValue = Get-Variable -Name $Global:__OldValueVariableLabel -Scope Global -ValueOnly
      if (-not (Test-Equal $NewValue $OldValue)) {
        Invoke-FireEvent $Global:__VariableChangeEventLabel -Data @{ Name = $Name; Value = $NewValue; OldValue = $OldValue }
        Set-Variable -Name $Global:__OldValueVariableLabel -Value $NewValue -Scope Global
      }
    }
    $UpdateValue | Invoke-ListenTo -Idle | Out-Null
    $Action | Invoke-ListenTo $Global:__VariableChangeEventLabel | Out-Null
  } else { # custom and Powershell engine events
    if ($Exit) {
      $SourceIdentifier = ([System.Management.Automation.PsEngineEvent]::Exiting)
    } elseif ($Idle) {
      $SourceIdentifier = ([System.Management.Automation.PsEngineEvent]::OnIdle)
    } else {
      $SourceIdentifier = $Name
    }
    if ($Once) {
      Write-Verbose "==> Creating one-time event listener for $SourceIdentifier event"
      $_Event = Register-EngineEvent -SourceIdentifier $SourceIdentifier -MaxTriggerCount 1 -Action $Action -Forward:$Forward
    } else {
      Write-Verbose "==> Creating event listener for `"$SourceIdentifier`" event"
      $_Event = Register-EngineEvent -SourceIdentifier $SourceIdentifier -Action $Action -Forward:$Forward
    }
    $_Event
  }
}
function Invoke-StopListen {
  <#
  .SYNOPSIS
  Remove event subscriber(s)
  .EXAMPLE
  $Callback | on 'SomeEvent'
  'SomeEvent' | Invoke-StopListen

  Remove events using the event "source identifier" (Name)
  .EXAMPLE
  $Callback | on -Name 'Namespace:foo'
  $Callback | on -Name 'Namespace:bar'
  'Namespace:' | Invoke-StopListen

  Remove multiple events using an event namespace
  .EXAMPLE
  $Listener = $Callback | on 'SomeEvent'
  Invoke-StopListen -EventData $Listener

  Selectively remove a single event by passing its event data
  #>
  [CmdletBinding()]
  Param(
    [Parameter(ValueFromPipeline=$True)]
    [String] $Name,
    [PSObject] $EventData
  )
  if ($EventData) {
    Unregister-Event -SubscriptionId $EventData.Id
  } else {
    if ($Name) {
      $Events = Get-EventSubscriber | Where-Object { $_.SourceIdentifier -match "^$Name" }
    } else {
      $Events = Get-EventSubscriber
    }
    $Events | ForEach-Object { Unregister-Event -SubscriptionId $_.SubscriptionId }
  }
}