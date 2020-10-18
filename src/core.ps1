function ConvertTo-PowershellSyntax {
  [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'DataVariableName')]
  [OutputType([String])]
  Param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [String] $Value,
    [String] $DataVariableName = 'Data'
  )
  Write-Output $Value |
    ForEach-Object { $_ -replace '(?<!(}}[\w\s]*))(?<!{{#[\w\s]*)\s*}}', ')' } |
    ForEach-Object { $_ -replace '{{(?!#)\s*', "`$(`$$DataVariableName." }
}
function Invoke-FireEvent {
  [CmdletBinding()]
  [Alias('trigger')]
  Param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [String] $Name,
    [PSObject] $Data
  )
  New-Event -SourceIdentifier $Name -MessageData $Data | Out-Null
}
function Find-FirstIndex {
  <#
  .SYNOPSIS
  Helper function to return index of first array item that returns true for a given predicate
  (default predicate returns true if value is $true)
  .EXAMPLE
  Find-FirstIndex -Values $false,$true,$false
  # Returns 1
  .EXAMPLE
  $Values = 1,1,1,2,1,1
  Find-FirstIndex -Values $Values -Predicate { $args[0] -eq 2 }
  # Returns 3
  .EXAMPLE
  $Values = 1,1,1,2,1,1
  ,$Values | Find-FirstIndex -Predicate { $args[0] -eq 2 }
  # Returns 3

  Note the use of the unary comma operator
  .EXAMPLE
  ,(1,1,1,2,1,1) | Find-FirstIndex -Predicate { $args[0] -eq 2 }
  # Returns 3
  #>
  [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'Predicate')]
  [CmdletBinding()]
  [OutputType([Int])]
  Param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [Array] $Values,
    [ScriptBlock] $Predicate = { $args[0] -eq $true }
  )
  $Indexes = @($Values | ForEach-Object {
    if (& $Predicate $_) {
      [Array]::IndexOf($Values, $_)
    }
  })
  $Indexes.Where({ $_ }, 'First')
}
function Format-MoneyValue {
  <#
  .SYNOPSIS
  Helper function to create human-readable money (USD) values as strings.
  .EXAMPLE
  42 | ConvertTo-MoneyString
  # Returns "$42.00"
  .EXAMPLE
  55000123.50 | ConvertTo-MoneyString -Symbol ¥
  # Returns '¥55,000,123.50'
  .EXAMPLE
  700 | ConvertTo-MoneyString -Symbol £ -Postfix
  # Returns '700.00£'
  #>
  [CmdletBinding()]
  [Alias('money')]
  [OutputType([String])]
  Param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    $Value,
    [String] $Symbol = '$',
    [Switch] $AsNumber,
    [Switch] $Postfix
  )
  $Function:GetMagnitude = { [Math]::Log([Math]::Abs($args[0]), 10) }
  switch -Wildcard ($Value.GetType()) {
    'Int*' {
      $Sign = [Math]::Sign($Value)
      $Output = [Math]::Abs($Value).ToString()
      $OrderOfMagnitude = GetMagnitude $Value
      if ($OrderOfMagnitude -gt 3) {
        $Position = 3
        $Length = $Output.Length
        1..[Math]::Floor($OrderOfMagnitude / 3) | ForEach-Object {
          $Output = ',' | Invoke-InsertString -To $Output -At ($Length - $Position)
          $Position += 3
        }
      }
      if ($Postfix) {
        "$(if ($Sign -lt 0) { '-' } else { '' })${Output}.00$Symbol"
      } else {
        "$(if ($Sign -lt 0) { '-' } else { '' })$Symbol${Output}.00"
      }
    }
    'Double' {
      $Sign = [Math]::Sign($Value)
      $Output = [Math]::Abs($Value).ToString('#.##')
      $OrderOfMagnitude = GetMagnitude $Value
      if (($Output | ForEach-Object { $_ -split '\.' } | Select-Object -Skip 1).Length -eq 1) {
        $Output += '0'
      }
      if (($Value - [Math]::Truncate($Value)) -ne 0) {
        if ($OrderOfMagnitude -gt 3) {
          $Position = 6
          $Length = $Output.Length
          1..[Math]::Floor($OrderOfMagnitude / 3) | ForEach-Object {
            $Output = ',' | Invoke-InsertString -To $Output -At ($Length - $Position)
            $Position += 3
          }
        }
        if ($Postfix) {
          "$(if ($Sign -lt 0) { '-' } else { '' })$Output$Symbol"
        } else {
          "$(if ($Sign -lt 0) { '-' } else { '' })$Symbol$Output"
        }
      } else {
        ($Value.ToString() -as [Int]) | Format-MoneyValue
      }
    }
    'String' {
      $Value = $Value -replace ',', ''
      $Sign = if (([Regex]'\-\$').Match($Value).Success) { -1 } else { 1 }
      if (([Regex]'\$').Match($Value).Success) {
        $Output = (([Regex]'(?<=(\$))[0-9]*\.?[0-9]{0,2}').Match($Value)).Value
      } else {
        $Output = (([Regex]'[\-]?[0-9]*\.?[0-9]{0,2}').Match($Value)).Value
      }
      $Type = if ($Output.Contains('.')) { [Double] } else { [Int] }
      $Output = $Sign * ($Output -as $Type)
      if (-not $AsNumber) {
        $Output = $Output | Format-MoneyValue
      }
      $Output
    }
    Default { throw 'Format-MoneyValue only accepts strings and numbers' }
  }
}
function Invoke-InsertString {
  [CmdletBinding()]
  [Alias('insert')]
  [OutputType([String])]
  Param(
    [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
    [String] $Value,
    [Parameter(Mandatory=$true)]
    [String] $To,
    [Parameter(Mandatory=$true)]
    [Int] $At
  )
  if ($At -le $To.Length -and $At -ge 0) {
    $To.Substring(0, $At) + $Value + $To.Substring($At, $To.length - $At)
  } else {
    $To
  }
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
    [Parameter(ParameterSetName='custom', Mandatory=$true, ValueFromPipeline=$true)]
    [Parameter(ParameterSetName='variable', Mandatory=$true, ValueFromPipeline=$true)]
    [Parameter(ParameterSetName='filesystem', Mandatory=$true, ValueFromPipeline=$true)]
    [scriptblock] $Callback,
    [Parameter(ParameterSetName='custom')]
    [Parameter(ParameterSetName='filesystem')]
    [Switch] $Forward,
    [Parameter(ParameterSetName='filesystem', Mandatory=$true)]
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
    $Watcher.EnableRaisingEvents = $true
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
function Invoke-Once {
  <#
  .SYNOPSIS
  Higher-order function that takes a function and returns a function that can only be executed a certain number of times
  .PARAMETER Times
  Number of times passed function can be called (default is 1, hence the name - Once)
  .EXAMPLE
  $Function:test = Invoke-Once { 'Should only see this once' | Write-Color -Red }
  1..10 | ForEach-Object {
    test
  }
  .EXAMPLE
  $Function:greet = Invoke-Once {
    "Hello $($args[0])" | Write-Color -Red
  }
  greet 'World'
  # no subsequent greet functions are executed
  greet 'Jim'
  greet 'Bob'

  Functions returned by Invoke-Once can accept arguments
  #>
  [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '', Scope='Function')]
  [CmdletBinding()]
  Param(
    [Parameter(Mandatory=$true, Position=0)]
    [ScriptBlock] $Function,
    [Int] $Times = 1
  )
  {
    if ($Script:Count -lt $Times) {
      & $Function @Args
      $Script:Count++
    }
  }.GetNewClosure()
}
function Invoke-Reduce {
  <#
  .SYNOPSIS
  Functional helper function intended to approximate some of the capabilities of Reduce (as used in languages like JavaScript and F#)
  .PARAMETER InitialValue
  Starting value for reduce. The type of InitialValue will change the operation of Invoke-Reduce.
  .PARAMETER FileInfo
  The operation of combining many FileInfo objects into one object is common enough to deserve its own switch (see examples)
  .EXAMPLE
  1,2,3,4,5 | Invoke-Reduce -Callback { $args[0] + $args[1] } -InitialValue 0

  Compute sum of array of integers
  .EXAMPLE
  'a','b','c' | reduce -Callback { $args[0] + $args[1] } -InitialValue ''

  Concatenate array of strings
  .EXAMPLE
  Get-ChildItem -File | Invoke-Reduce -FileInfo | Show-BarChart

  Combining directory contents into single object and visualize with Show-BarChart - in a single line!
  #>
  [CmdletBinding()]
  [Alias('reduce')]
  Param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [Array] $Items,
    [ScriptBlock] $Callback = { $args[0] },
    [Switch] $FileInfo,
    $InitialValue = @{}
  )
  Begin {
    $Result = $InitialValue
    if ($FileInfo) {
      $Callback = { Param($Acc, $Item) $Acc[$Item.Name] = $Item.Length }
    }
  }
  Process {
    $Items | ForEach-Object {
      if ($InitialValue -is [Int] -or $InitialValue -is [String] -or $InitialValue -is [Bool] -or $InitialValue -is [Array]) {
        $Result = & $Callback $Result $_
      } else {
        & $Callback $Result $_
      }
    }
  }
  End {
    $Result
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
    [Parameter(ValueFromPipeline=$true)]
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
function Join-StringsWithGrammar {
  <#
  .SYNOPSIS
  Helper function that creates a string out of a list that properly employs commands and "and"
  .EXAMPLE
  Join-StringsWithGrammar @('a', 'b', 'c')

  Returns "a, b, and c"
  #>
  [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'Delimiter')]
  [CmdletBinding()]
  [OutputType([String])]
  Param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [String[]] $Items,
    [String] $Delimiter = ','
  )

  Begin {
    function Join-StringArray {
      Param(
        [Parameter(Mandatory=$true, Position=0)]
        [AllowNull()]
        [AllowEmptyCollection()]
        [String[]] $Items
      )
      $NumberOfItems = $Items.Length
      if ($NumberOfItems -gt 0) {
        switch ($NumberOfItems) {
          1 {
            $Items -join ''
          }
          2 {
            $Items -join ' and '
          }
          Default {
            @(
              ($Items[0..($NumberOfItems - 2)] -join ', ') + ','
              'and'
              $Items[$NumberOfItems - 1]
            ) -join ' '
          }
        }
      }
    }
    Join-StringArray $Items
  }
  End {
    Join-StringArray $Input
  }
}
function New-Template {
  <#
  .SYNOPSIS
  Create render function that interpolates passed object values
  .PARAMETER Data
  Pass template data to New-Template when using New-Template within pipe chain (see examples)
  .EXAMPLE
  $Function:render = New-Template '<div>Hello {{ name }}!</div>'
  render @{ name = 'World' }
  # '<div>Hello World!</div>'

  Use mustache template syntax! Just like Handlebars.js!
  .EXAMPLE
  $Function:render = 'hello {{ name }}' | New-Template
  @{ name = 'world' } | render
  # 'hello world'

  New-Template supports idiomatic powershell pipeline syntax
  .EXAMPLE
  $Function:render = New-Template '<div>Hello $($Data.name)!</div>'
  render @{ name = 'World' }
  # '<div>Hello World!</div>'

  Or stick to plain Powershell syntax...this is a little more verbose ($Data is required)
  .EXAMPLE
  $title = New-Template -Template '<h1>{{ text }}</h1>' -DefaultValues @{ text = 'Default' }
  & $title
  # '<h1>Default</h1>'
  & $title @{ text = 'Hello World' }
  # '<h1>Hello World</h1>'

  Provide default values for your templates!
  .EXAMPLE
  $div = New-Template -Template '<div>{{ text }}</div>'
  $section = New-Template "<section>
      <h1>{{ title }}</h1>
      $(& $div @{ text = 'Hello World!' })
  </section>"

  Templates can even be nested!
  .EXAMPLE
  '{{#green Hello}} {{ name }}' | tpl -Data @{ name = 'World' } | Write-Color

  Use -Data parameter cause template to return formatted string instead of template function
  #>
  [CmdletBinding(DefaultParameterSetName='template')]
  [Alias('tpl')]
  [OutputType([ScriptBlock], ParameterSetName='template')]
  [OutputType([String], ParameterSetName='inline')]
  Param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [String] $Template,
    [Parameter(ParameterSetName='inline')]
    [PSObject] $Data,
    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [PSObject] $DefaultValues
  )
  $Script:__template = $Template # This line is super important
  $Script:__defaults = $DefaultValues # This line is also super important
  $Renderer = {
    Param(
      [Parameter(Position=0, ValueFromPipeline=$true)]
      [PSObject] $Data,
      [Switch] $PassThru
    )
    if ($PassThru) {
      $StringToRender = $__template
    } else {
      $DataVariableName = Get-Variable -Name Data | ForEach-Object { $_.Name }
      $StringToRender = $__template | ConvertTo-PowershellSyntax -DataVariableName $DataVariableName
    }
    if (-not $Data) {
      $Data = $__defaults
    }
    $StringToRender = $StringToRender -replace '"', '`"'
    $ImportDataVariable = "`$Data = '$(ConvertTo-Json ([System.Management.Automation.PSObject]$Data))' | ConvertFrom-Json"
    $Powershell = [Powershell]::Create()
    [Void]$Powershell.AddScript($ImportDataVariable).AddScript("Write-Output `"$StringToRender`"")
    $Powershell.Invoke()
    [Void]$Powershell.Dispose()
  }
  if ($Data) {
    & $Renderer $Data
  } else {
    $Renderer
  }
}
function Remove-Character {
  [CmdletBinding()]
  [Alias('remove')]
  [OutputType([String])]
  Param(
    [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
    [String] $Value,
    [Int] $At,
    [Switch] $First,
    [Switch] $Last
  )
  $At = if ($First) { 0 } elseif ($Last) { $Value.Length - 1 } else { $At }
  if ($At -lt $Value.Length -and $At -ge 0) {
    $Value.Substring(0, $At) + $Value.Substring($At + 1, $Value.length - $At - 1)
  } else {
    $Value
  }
}
function Test-Equal {
  <#
  .SYNOPSIS
  Helper function meant to provide a more robust equality check (beyond just integers and strings)
  .EXAMPLE
  Test-Equal 42 43 # False
  Test-Equal 0 0 # True

  Also works with booleans, strings, objects, and arrays
  .EXAMPLE
  $a = @{a = 1; b = 2; c = 3}
  $b = @{a = 1; b = 2; c = 3}
  Test-Equal $a $b # True
  #>
  [CmdletBinding()]
  [Alias('equal')]
  [OutputType([Bool])]
  Param(
    [Parameter(Position=0, ValueFromPipeline=$true)]
    $Left,
    [Parameter(Position=1)]
    $Right
  )
  if ($null -ne $Left -and $null -ne $Right) {
    try {
      $Type = $Left.GetType().Name
      switch -Wildcard ($Type) {
        'String' { $Left -eq $Right }
        'Int*' { $Left -eq $Right }
        'Double' { $Left -eq $Right }
        'Object*' {
          $Every = { $args[0] -and $args[1] }
          $Index = 0
          $Left | ForEach-Object { Test-Equal $_ $Right[$Index]; $Index++ } | Invoke-Reduce -Callback $Every -InitialValue $true
        }
        'PSCustomObject' {
          $Every = { $args[0] -and $args[1] }
          $LeftKeys = $Left.psobject.properties | Select-Object -ExpandProperty Name
          $RightKeys = $Right.psobject.properties | Select-Object -ExpandProperty Name
          $LeftValues = $Left.psobject.properties | Select-Object -ExpandProperty Value
          $RightValues = $Right.psobject.properties | Select-Object -ExpandProperty Value
          $Index = 0
          $HasSameKeys = $LeftKeys |
            ForEach-Object { Test-Equal $_ $RightKeys[$Index]; $Index++ } |
            Invoke-Reduce -Callback $Every -InitialValue $true
          $Index = 0
          $HasSameValues = $LeftValues |
            ForEach-Object { Test-Equal $_ $RightValues[$Index]; $Index++ } |
            Invoke-Reduce -Callback $Every -InitialValue $true
          $HasSameKeys -and $HasSameValues
        }
        'Hashtable' {
          $Every = { $args[0] -and $args[1] }
          $Index = 0
          $RightKeys = $Right.GetEnumerator() | Select-Object -ExpandProperty Name
          $HasSameKeys = $Left.GetEnumerator() |
            ForEach-Object { Test-Equal $_.Name $RightKeys[$Index]; $Index++ } |
            Invoke-Reduce -Callback $Every -InitialValue $true
          $Index = 0
          $RightValues = $Right.GetEnumerator() | Select-Object -ExpandProperty Value
          $HasSameValues = $Left.GetEnumerator() |
            ForEach-Object { Test-Equal $_.Value $RightValues[$Index]; $Index++ } |
            Invoke-Reduce -Callback $Every -InitialValue $true
          $HasSameKeys -and $HasSameValues
        }
        Default { $Left -eq $Right }
      }
    } catch {
      Write-Verbose '==> Failed to match type of -Left item'
      $false
    }
  } else {
    Write-Verbose '==> One or both items are $null'
    $Left -eq $Right
  }
}