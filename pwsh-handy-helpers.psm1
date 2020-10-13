function ConvertTo-PowershellSyntax
{
  [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'DataVariableName')]
  Param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [String] $Value,
    [String] $DataVariableName = 'Data'
  )
  Write-Output $Value |
    ForEach-Object { $_ -replace '(?<!(}}[\w\s]*))(?<!{{#[\w\s]*)\s*}}', ')' } |
    ForEach-Object { $_ -replace '{{(?!#)\s*', "`$(`$$DataVariableName." }
}
function Enable-Remoting
{
  <#
  .SYNOPSIS
  Function to enable Powershell remoting for workgroup computer
  .PARAMETER TrustedHosts
  Comma-separated list of trusted host names
  example: "RED,WHITE,BLUE"
  .EXAMPLE
  Enable-Remoting
  .EXAMPLE
  Enable-Remoting -TrustedHosts "MARIO,LUIGI"
  #>
  [CmdletBinding()]
  Param(
    [String] $TrustedHosts = "*"
  )
  if (Test-Admin) {
    Write-Verbose "==> Making network private"
    Get-NetConnectionProfile | Set-NetConnectionProfile -NetworkCategory Private
    $Path = "WSMan:\localhost\Client\TrustedHosts"
    Write-Verbose "==> Enabling Powershell remoting"
    Enable-PSRemoting -Force -SkipNetworkProfileCheck
    Write-Verbose "==> Updated trusted hosts"
    Set-Item $Path -Value $TrustedHosts -Force
    Get-Item $Path
  } else {
    Write-Error "==> Enable-Remoting requires Administrator privileges"
  }
}
function Find-Duplicate
{
  <#
  .SYNOPSIS
  Helper function that calculates file hash values to find duplicate files recursively
  .EXAMPLE
  Find-Duplicate <path to folder>
  .EXAMPLE
  pwd | Find-Duplicate
  #>
  [CmdletBinding()]
  Param(
    [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
    [String] $Name
  )
  Get-Item $Name |
    Get-ChildItem -Recurse |
    Get-FileHash |
    Group-Object -Property Hash |
    Where-Object Count -gt 1 |
    ForEach-Object { $_.Group | Select-Object Path, Hash } |
    Write-Output
}
function Find-FirstIndex
{
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
  Param(
    [Parameter(Position=0, ValueFromPipeline=$true)]
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
function Get-File
{
  <#
  .SYNOPSIS
  Download a file from an internet endpoint (ex: http://example.com/file.txt)
  .EXAMPLE
  Get-File http://example.com/file.txt
  .EXAMPLE
  Get-File http://example.com/file.txt -File myfile.txt
  .EXAMPLE
  echo "http://example.com/file.txt" | Get-File
  #>
  [CmdletBinding()]
  Param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [String] $Url,
    [String] $File = 'download.txt'
  )
  $client = New-Object System.Net.WebClient
  $client.DownloadFile($Url, $File)
}
function Home
{
  [CmdletBinding()]
  [Alias('~')]
  Param()
  Set-Location ~
}
function Install-SshServer
{
  <#
  .SYNOPSIS
  Install OpenSSH server
  .LINK
  https://docs.microsoft.com/en-us/windows-server/administration/openssh/openssh_install_firstuse
  #>
  [CmdletBinding(SupportsShouldProcess=$true)]
  Param()
  Write-Verbose '==> Enabling OpenSSH server'
  Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0
  Write-Verbose '==> Starting sshd service'
  Start-Service sshd
  Write-Verbose '==> Setting sshd service to start automatically'
  Set-Service -Name sshd -StartupType 'Automatic'
  Write-Verbose '==> Adding firewall rule for sshd'
  New-NetFirewallRule -Name sshd -DisplayName 'OpenSSH Server (sshd)' -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22
}
function Invoke-DockerInspectAddress
{
  <#
  .SYNOPSIS
  Get IP address of Docker container at given name (or ID)
  .EXAMPLE
  dip <container name | id>
  .EXAMPLE
  echo <container name/id> | dip
  #>
  [CmdletBinding()]
  [Alias('dip')]
  Param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [String] $Name
  )
  docker inspect --format '{{ .NetworkSettings.IPAddress }}' $Name
}
function Invoke-DockerRemoveAll
{
  <#
  .SYNOPSIS
  Remove ALL Docker containers
  .EXAMPLE
  dra <container name | id>
  #>
  [CmdletBinding()]
  [Alias('dra')]
  Param()
  docker stop $(docker ps -a -q); docker rm $(docker ps -a -q)
}
function Invoke-DockerRemoveAllImage
{
  <#
  .SYNOPSIS
  Remove ALL Docker images
  .EXAMPLE
  drai <container name | id>
  #>
  [CmdletBinding()]
  [Alias('drai')]
  Param()
  docker rmi $(docker images -a -q)
}
function Invoke-FireEvent
{
  [CmdletBinding()]
  [Alias('trigger')]
  Param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [String] $Name,
    [PSObject] $Data
  )
  New-Event -SourceIdentifier $Name -MessageData $Data | Out-Null
}
function Invoke-GitCommand { git $args }
function Invoke-GitCommit { git commit -vam $args }
function Invoke-GitDiff { git diff $args }
function Invoke-GitPushMaster { git push origin master }
function Invoke-GitStatus { git status -sb }
function Invoke-GitRebase { git rebase -i $args }
function Invoke-GitLog { git log --oneline --decorate }
function Invoke-Input
{
  <#
  .SYNOPSIS
  A fancy Read-Host replacement meant to be used to make CLI applications.
  .PARAMETER Secret
  Displayed characters are replaced with asterisks
  .PARAMETER Number
  Switch to designate input is numerical
  .EXAMPLE
  $fullname = input "Full Name?"
  $username = input "Username?" -MaxLength 10 -Indent 4
  $age = input "Age?" -Number -MaxLength 2 -Indent 4
  $pass = input "Password?" -Secret -Indent 4
  .EXAMPLE
  $word = input "Favorite Saiya-jin?" -Indent 4 -Autocomplete -Choices `
  @(
      'Goku'
      'Gohan'
      'Goten'
      'Vegeta'
      'Trunks'
  )

  Autocomplete will make suggestions. Press tab once to select suggestion, press tab again to cycle through matches.
  .EXAMPLE
  Invoke-Input "Folder name?" -Autocomplete -Choices (Get-ChildItem -Directory | Select-Object -ExpandProperty Name)

  Leverage autocomplete to input a folder name
  .EXAMPLE
  $name = input 'What is your {{#blue name}}?'

  Input labels can be customized with mustache color helpers
  #>
  [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', 'global:PreviousRegularExpression')]
  [CmdletBinding()]
  [Alias('input')]
  Param(
    [Parameter(Position=0, ValueFromPipeline=$true)]
    [String] $LabelText = 'input:',
    [Switch] $Secret,
    [Switch] $Number,
    [Switch] $Autocomplete,
    [Array] $Choices,
    [Int] $Indent,
    [Int] $MaxLength = 0
  )
  Write-Label -Text $LabelText -Indent $Indent
  $Global:PreviousRegularExpression = $null
  $Result = ""
  $CurrentIndex = 0
  $AutocompleteMatches = @()
  $StartPosition = [Console]::CursorLeft
  function Format-Output
  {
    Param(
      [Parameter(Mandatory=$true, Position=0)]
      [String] $Value
    )
    if ($Secret) {
      "*" * $Value.Length
    } else {
      $Value
    }
  }
  function Invoke-OutputDraw
  {
    Param(
      [Parameter(Mandatory=$true, Position=0)]
      [String] $Output,
      [Int] $Left = 0
    )
    [Console]::SetCursorPosition($StartPosition, [Console]::CursorTop)
    if ($MaxLength -gt 0 -and $Output.Length -gt $MaxLength) {
      Write-Color $Output.Substring(0, $MaxLength) -NoNewLine
      Write-Color $Output.Substring($MaxLength, $Output.Length - $MaxLength) -NoNewLine -Red
    } else {
      Write-Color $Output -NoNewLine
      if ($Autocomplete) {
        Update-Autocomplete -Output $Output
      }
    }
    [Console]::SetCursorPosition($Left + 1, [Console]::CursorTop)
  }
  function Update-Autocomplete
  {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', 'global:PreviousRegularExpression')]
    Param(
      [AllowEmptyString()]
      [String] $Output
    )
    $Global:PreviousRegularExpression = "^${Output}"
    $AutocompleteMatches = $Choices | Where-Object { $_ -match $Global:PreviousRegularExpression }
    if ($null -eq $AutocompleteMatches -or $Output.Length -eq 0) {
      $Left = [Console]::CursorLeft
      [Console]::SetCursorPosition($Left, [Console]::CursorTop)
      Write-Color (' ' * 30) -NoNewLine
      [Console]::SetCursorPosition($Left, [Console]::CursorTop)
    } else {
      if ($AutocompleteMatches -is [String]) {
        $BestMatch = $AutocompleteMatches
      } else {
        $BestMatch = $AutocompleteMatches[0]
      }
      $Left = [Console]::CursorLeft
      [Console]::SetCursorPosition($StartPosition + $Output.Length, [Console]::CursorTop)
      Write-Color $BestMatch.Substring($Output.Length) -NoNewLine -Green
      Write-Color (' ' * 30) -NoNewLine
      [Console]::SetCursorPosition($Left, [Console]::CursorTop)
    }
  }
  Do  {
    $KeyInfo = [Console]::ReadKey($true)
    $KeyChar = $KeyInfo.KeyChar
    switch ($KeyInfo.Key) {
      "Backspace" {
        if (-not $Secret) {
          $Left = [Console]::CursorLeft
          if ($Left -gt $StartPosition) {
            [Console]::SetCursorPosition($StartPosition, [Console]::CursorTop)
            $Updated = $Result | Remove-Character -At ($Left - $StartPosition - 1)
            $Result = $Updated
            if ($MaxLength -eq 0) {
              Write-Color $Updated -NoNewLine
              if ($Autocomplete) {
                Update-Autocomplete -Output $Updated
              } else {
                Write-Color " " -NoNewLine
              }
            } else {
              [Console]::SetCursorPosition($StartPosition, [Console]::CursorTop)
              if ($Result.Length -le $MaxLength) {
                Write-Color "$Updated " -NoNewLine
              } else {
                Write-Color $Updated.Substring(0, $MaxLength) -NoNewLine
                Write-Color ($Updated.Substring($MaxLength, $Updated.Length - $MaxLength) + " ") -NoNewLine -Red
              }
            }
            [Console]::SetCursorPosition([Math]::Max(0, $Left - 1), [Console]::CursorTop)
          }
        }
      }
      "Delete" {
        if (-not $Secret) {
          $Left = [Console]::CursorLeft
          [Console]::SetCursorPosition($StartPosition, [Console]::CursorTop)
          $Updated = $Result | Remove-Character -At ($Left - $StartPosition)
          $Result = $Updated
          if ($MaxLength -eq 0) {
            Write-Color "$Updated " -NoNewLine
          } else {
            [Console]::SetCursorPosition($StartPosition, [Console]::CursorTop)
            if ($Result.Length -le $MaxLength) {
              Write-Color "$Updated " -NoNewLine
            } else {
              Write-Color $Updated.Substring(0, $MaxLength) -NoNewLine
              Write-Color ($Updated.Substring($MaxLength, $Updated.Length - $MaxLength) + " ") -NoNewLine -Red
            }
          }
          if ($Autocomplete) {
            Update-Autocomplete -Output $Updated
          }
          [Console]::SetCursorPosition([Math]::Max(0, $Left), [Console]::CursorTop)
        }
      }
      "DownArrow" {
        if ($Number) {
          $Value = ($Result -as [Int]) - 1
          if (($MaxLength -eq 0) -or ($MaxLength -gt 0 -and $Value -gt -[Math]::Pow(10, $MaxLength))) {
            $Left = [Console]::CursorLeft
            $Result = "$Value"
            [Console]::SetCursorPosition($StartPosition, [Console]::CursorTop)
            Write-Color $Result -NoNewLine
            [Console]::SetCursorPosition($Left, [Console]::CursorTop)
          }
        }
      }
      "Enter" {
        # Do nothing
      }
      "LeftArrow" {
        if (-not $Secret) {
          $Left = [Console]::CursorLeft
          if ($Left -gt $StartPosition) {
            [Console]::SetCursorPosition($Left - 1, [Console]::CursorTop)
          }
        }
      }
      "RightArrow" {
        if (-not $Secret) {
          $Left = [Console]::CursorLeft
          if ($Left -lt ($StartPosition + $Result.Length)) {
            [Console]::SetCursorPosition($Left + 1, [Console]::CursorTop)
          }
        }
      }
      "Tab" {
        if ($Autocomplete -and $Result.Length -gt 0 -and -not ($Number -or $Secret) -and $null -ne $AutocompleteMatches) {
          $AutocompleteMatches = $Choices | Where-Object { $_ -match $Global:PreviousRegularExpression }
          [Console]::SetCursorPosition($StartPosition, [Console]::CursorTop)
          if ($AutocompleteMatches -is [String]) {
            $Result = $AutocompleteMatches
          } else {
            $CurrentMatch = $AutocompleteMatches[$CurrentIndex]
            if ($Result -eq $PreviousMatch) {
              $Result = $PreviousSearch[$CurrentIndex]
            } else {
              $Result = $CurrentMatch
              $PreviousMatch = $CurrentMatch
              $PreviousSearch = $AutocompleteMatches
            }
            $CurrentIndex = ($CurrentIndex + 1) % $AutocompleteMatches.Length
          }
          Write-Color "$Result $(' ' * 30)" -NoNewLine -Green
          [Console]::SetCursorPosition($StartPosition + $Result.Length, [Console]::CursorTop)
        }
      }
      "UpArrow" {
        if ($Number) {
          $Value = ($Result -as [Int]) + 1
          if (($MaxLength -eq 0) -or ($MaxLength -gt 0 -and $Value -lt [Math]::Pow(10, $MaxLength))) {
            $Left = [Console]::CursorLeft
            $Result = "$Value"
            [Console]::SetCursorPosition($StartPosition, [Console]::CursorTop)
            Write-Color "$Result " -NoNewLine
            [Console]::SetCursorPosition($Left, [Console]::CursorTop)
          }
        }
      }
      Default {
        $Left = [Console]::CursorLeft
        $OnlyNumbers = [Regex]'^-?[0-9]*$'
        if ($Left -eq $StartPosition) {# prepend character
          if ($Number) {
            if ($KeyChar -match $OnlyNumbers) {
              $Result = "${KeyChar}$Result"
              Invoke-OutputDraw -Output (Format-Output $Result) -Left $Left
            }
          } else {
            $Result = "${KeyChar}$Result"
            Invoke-OutputDraw -Output (Format-Output $Result) -Left $Left
          }
        } elseif ($Left -gt $StartPosition -and $Left -lt ($StartPosition + $Result.Length)) {# insert character
          if ($Number) {
            if ($KeyChar -match $OnlyNumbers) {
              $Result = $KeyChar | Invoke-InsertString -To $Result -At ($Left - $StartPosition)
              Invoke-OutputDraw -Output $Result -Left $Left
            }
          } else {
            $Result = $KeyChar | Invoke-InsertString -To $Result -At ($Left - $StartPosition)
            Invoke-OutputDraw -Output $Result -Left $Left
          }
        } else {# append character
          if ($Number) {
            if ($KeyChar -match $OnlyNumbers) {
              $Result += $KeyChar
              $ShouldHighlight = ($MaxLength -gt 0) -and [Console]::CursorLeft -gt ($StartPosition + $MaxLength - 1)
              Write-Color (Format-Output $KeyChar) -NoNewLine -Red:$ShouldHighlight
              if ($Autocomplete) {
                Update-Autocomplete -Output ($Result -as [String])
              }
            }
          } else {
            $Result += $KeyChar
            $ShouldHighlight = ($MaxLength -gt 0) -and [Console]::CursorLeft -gt ($StartPosition + $MaxLength - 1)
            Write-Color (Format-Output $KeyChar) -NoNewLine -Red:$ShouldHighlight
            if ($Autocomplete) {
              Update-Autocomplete -Output ($Result -as [String])
            }
          }
        }
      }
    }
  } Until ($KeyInfo.Key -eq 'Enter' -or $KeyInfo.Key -eq 'Escape')
  Write-Color ""
  if ($KeyInfo.Key -ne 'Escape') {
    if ($Number) {
      $Result -as [Int]
    } else {
      if ($MaxLength -gt 0) {
        $Result.Substring(0, [Math]::Min($Result.Length, $MaxLength))
      } else {
        $Result
      }
    }
  } else {
    $null
  }
}
function Invoke-InsertString
{
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
  if ($At -lt $To.Length -and $At -ge 0) {
    $To.Substring(0, $At) + $Value + $To.Substring($At, $To.length - $At)
  } else {
    $To
  }
}
function Invoke-ListenForWord
{
  <#
  .SYNOPSIS
  Start loop that listens for trigger words and execute passed functions when recognized
  .DESCRIPTION
  This function uses the Windows Speech Recognition. For best results, you should first improve speech recognition via Speech Recognition Voice Training.
  .EXAMPLE
  Invoke-Listen -Triggers "hello" -Actions { Write-Color 'Welcome' -Green }
  .EXAMPLE
  Invoke-Listen -Triggers "hello","quit" -Actions { say 'Welcome' | Out-Null; $true }, { say 'Goodbye' | Out-Null; $false }

  An action will stop listening when it returns a "falsy" value like $true or $null. Conversely, returning "truthy" values will continue the listening loop.
  #>
  [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '', Scope='Function')]
  [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', 'Continue')]
  [CmdletBinding()]
  [Alias('listenFor')]
  Param(
    [Parameter(Mandatory=$true)]
    [String[]] $Triggers,
    [ScriptBlock[]] $Actions,
    [Double] $Threshhold = 0.85
  )
  Use-Speech
  $Engine = Use-Grammar -Words $Triggers
  $Continue = $true;
  Write-Color 'Listening for trigger words...' -Cyan
  while ($Continue) {
    $Recognizer = $Engine.Recognize();
    $Confidence = $Recognizer.Confidence;
    $Text = $Recognizer.text;
    if ($Text.Length -gt 0) {
      Write-Verbose "==> Heard `"$Text`""
    }
    $Index = 0
    $Triggers | ForEach-Object {
      if ($Text -match $_ -and [Double]$Confidence -gt $Threshhold) {
        $Continue = & $Actions[$Index]
      }
      $Index++
    }
  }
}
function Invoke-ListenTo
{
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
  { Write-Color "Event triggered" -Red } | on "SomeEvent"

  Expressive yet terse syntax for easy event-driven design.
  .EXAMPLE
  Invoke-ListenTo -Name "SomeEvent" -Callback { Write-Color "Event: $($Event.SourceIdentifier)" }

  Callbacks hae access to automatic variables such as $Event
  .EXAMPLE
  $Callback | on "SomeEvent" -Once

  Create a listener that automatically destroys itself after one event is triggered
  .EXAMPLE
  $Callback = {
    $Data = $args[1]
    Write-Color "Name ==> $($Data.Name)" -Magenta
    Write-Color "Event ==> $($Data.ChangeType)" -Green
    Write-Color "Fullpath ==> $($Data.FullPath)" -Cyan
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
  $Callback | listenTo "boot" -Variable

  # Change the value of boot and have your computer tell you what changed
  $boot = 43

  .EXAMPLE
  { "EVENT - EXIT" | Out-File ~\dev\MyEvents.txt -Append } | on -Exit

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
    $Watcher.Filter = "*.*"
    $Watcher.EnableRaisingEvents = $true
    $Watcher.IncludeSubdirectories = $IncludeSubDirectories
    Write-Verbose "==> Creating file system watcher events"
    "Created","Changed","Deleted","Renamed" | ForEach-Object {
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
function Invoke-Menu
{
  <#
  .SYNOPSIS
  Create interactive single, multi-select, or single-select list menu.

  Controls:
  - Select item with ENTER key
  - Move up with up arrow key
  - Move down with down arrow key or TAB key
  - Multi-select and single-select with SPACE key
  .PARAMETER FolderContent
  Use this switch to populate the menu with folder contents of current directory (see examples)
  .EXAMPLE
  Invoke-Menu @('one', 'two', 'three')
  .EXAMPLE
  Invoke-Menu @('one', 'two', 'three') -HighlightColor Blue
  .EXAMPLE
  Invoke-Menu @('one', 'two', 'three') -MultiSelect -ReturnIndex | Sort-Object
  .EXAMPLE
  ,(1,2,3,4,5) | menu
  .EXAMPLE
  ,(1,2,3,4,5) | menu -SingleSelect

  The SingleSelect switch allows for only one item to be selected at a time
  .EXAMPLE
  Invoke-Menu -FolderContent | Invoke-Item

  Open a folder via an interactive list menu populated with folder content
  #>
  [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'HighlightColor')]
  [CmdletBinding()]
  [Alias('menu')]
  [OutputType([Object[]])]
  Param (
    [Parameter(Position=0, ValueFromPipeline=$true)]
    [Array] $Items,
    [Switch] $MultiSelect,
    [Switch] $SingleSelect,
    [String] $HighlightColor = 'cyan',
    [Switch] $ReturnIndex = $false,
    [Switch] $FolderContent,
    [Int] $Indent = 0
  )
  function Invoke-MenuDraw
  {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '', Scope='Function')]
    [CmdletBinding()]
    Param (
      [Array] $Items,
      [Int] $Position,
      [Array] $Selection,
      [Switch] $MultiSelect,
      [Switch] $SingleSelect,
      [Int] $Indent = 0
    )
    $Index = 0
    $Items | ForEach-Object {
      $Item = $_
      if ($null -ne $Item) {
        if ($MultiSelect) {
          if ($Selection -contains $Index) {
            $Item = "[x] $Item"
          } else {
            $Item = "[ ] $Item"
          }
        } else {
          if ($SingleSelect) {
            if ($Selection -contains $Index) {
              $Item = "(o) $Item"
            } else {
              $Item = "( ) $Item"
            }
          }
        }
        if ($Index -eq $Position) {
          Write-Color "$(' ' * $Indent)> $Item" -Color $HighlightColor
        } else {
          Write-Color "$(' ' * $Indent)  $Item"
        }
      }
      $Index++
    }
  }
  function Update-MenuSelection
  {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'SingleSelect')]
    [CmdletBinding()]
    Param (
      [Int] $Position,
      [Array] $Selection,
      [Switch] $MultiSelect,
      [Switch] $SingleSelect
    )
    if ($Selection -contains $Position) {
      $Result = $Selection | Where-Object { $_ -ne $Position }
    } else {
      if ($MultiSelect) {
        $Selection += $Position
      } else {
        $Selection = ,$Position
      }
      $Result = $Selection
    }
    $Result
  }
  [Console]::CursorVisible = $false
  $Keycodes = @{
    enter = 13
    escape = 27
    space = 32
    tab = 9
    up = 38
    down = 40
  }
  $Keycode = 0
  $Position = 0
  $Selection = @()
  if ($FolderContent) {
    $Items = Get-ChildItem -Directory | Select-Object -ExpandProperty Name | ForEach-Object { "$_/" }
    $Items += (Get-ChildItem -File | Select-Object -ExpandProperty Name)
  }
  if ($Items.Length -gt 0) {
    Invoke-MenuDraw -Items $Items -Position $Position -Selection $Selection -MultiSelect:$MultiSelect -SingleSelect:$SingleSelect -Indent $Indent
		While ($Keycode -ne $Keycodes.enter -and $Keycode -ne $Keycodes.escape) {
			$Keycode = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown").virtualkeycode
      switch ($Keycode) {
        $Keycodes.escape {
          $Position = $null
        }
        $Keycodes.space {
          $Selection = Update-MenuSelection -Position $Position -Selection $Selection -MultiSelect:$MultiSelect -SingleSelect:$SingleSelect
        }
        $Keycodes.tab {
          $Position = ($Position + 1) % $Items.Length
        }
        $Keycodes.up {
          $Position = (($Position - 1) + $Items.Length) % $Items.Length
        }
        $Keycodes.down {
          $Position = ($Position + 1) % $Items.Length
        }
      }
      If ($null -ne $Position) {
        $StartPosition = [Console]::CursorTop - $Items.Length
        [Console]::SetCursorPosition(0, $StartPosition)
        Invoke-MenuDraw -Items $Items -Position $Position -Selection $Selection -MultiSelect:$MultiSelect -SingleSelect:$SingleSelect -Indent $Indent
      }
		}
	} else {
		$Position = $null
	}
  [Console]::CursorVisible = $true
  if ($ReturnIndex -eq $false -and $null -ne $Position) {
		if ($MultiSelect) {
			return $Items[$Selection]
		} else {
			return $Items[$Position]
		}
	} else {
		if ($MultiSelect) {
			return $Selection
		} else {
			return $Position
		}
	}
}
function Invoke-Once
{
  <#
  .SYNOPSIS
  Higher-order function that takes a function and returns a function that can only be executed a certain number of times
  .PARAMETER Times
  Number of times passed function can be called (default is 1, hence the name - Once)
  .EXAMPLE
  $Function:test = Invoke-Once { Write-Color "Should only see this once" -Red }
  1..10 | ForEach-Object {
    test
  }
  .EXAMPLE
  $Function:greet = Invoke-Once {
    Write-Color "Hello $($args[0])" -Red
  }
  greet "World"
  # no subsequent greet functions are executed
  greet "Jim"
  greet "Bob"

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
function Invoke-Reduce
{
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
  "a","b","c" | Invoke-Reduce -Callback { $args[0] + $args[1] } -InitialValue ""

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
function Invoke-RemoteCommand
{
  <#
  .SYNOPSIS
  Execute script block on remote computer (like Invoke-Command, but remote)
  .EXAMPLE
  Invoke-RemoteCommand -ComputerNames PCNAME -Password 123456 { whoami }
  .EXAMPLE
  { whoami } | Invoke-RemoteCommand -ComputerNames PCNAME -Password 123456
  .EXAMPLE
  { whoami } | Invoke-RemoteCommand -ComputerNames PCNAME

  This will open a prompt for you to input your password
  .EXAMPLE
  { whoami } | irc -ComputerNames Larry, Moe, Curly

  Use the "irc" alias and execute commands on multiple computers!
  .EXAMPLE
  Get-Credential | Export-CliXml -Path .\crendential.xml
  { whoami } | Invoke-RemoteCommand -Credential (Import-Clixml -Path .\credential.xml) -ComputerNames PCNAME -Verbose
  #>
  [CmdletBinding()]
  [Alias('irc')]
  [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingPlainTextForPassword', 'Password')]
  [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUsePSCredentialType', '', Scope='Function')]
  [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingConvertToSecureStringWithPlainText', '', Scope='Function')]
  Param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [ScriptBlock] $ScriptBlock,
    [Parameter(Mandatory=$true)]
    [String[]] $ComputerNames,
    [String] $Password,
    [PSObject] $Credential
  )
  $User = whoami
  if ($Credential) {
    Write-Verbose "==> Using -Credential for authentication"
    $Cred = $Credential
  } elseif ($Password) {
    Write-Verbose "==> Creating credential for $User using -Password"
    $Pass = ConvertTo-SecureString -String $Password -AsPlainText -Force
    $Cred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $User, $Pass
  } else {
    $Cred = Get-Credential -Message "Please provide password to access $(Join-StringsWithGrammar $ComputerNames)" -User $User
  }
  Write-Verbose "==> Running command on $(Join-StringsWithGrammar $ComputerNames)"
  Invoke-Command -ComputerName $ComputerNames -Credential $Cred -ScriptBlock $ScriptBlock
}
function Invoke-Speak
{
  <#
  .SYNOPSIS
  Use Windows Speech Synthesizer to speak input text
  .EXAMPLE
  Invoke-Speak "hello world"
  .EXAMPLE
  "hello world" | Invoke-Speak -Verbose
  .EXAMPLE
  1,2,3 | %{ Invoke-Speak $_ }
  .EXAMPLE
  Get-Content .\phrases.csv | Invoke-Speak
  #>
  [CmdletBinding()]
  [Alias('say')]
  Param(
    [Parameter(Position=0, ValueFromPipeline=$true)]
    [String] $Text = '',
    [String] $InputType = 'text',
    [Int] $Rate = 0,
    [Switch] $Silent,
    [String] $Output = 'none'
  )
  Begin {
    Use-Speech
    $TotalText = ""
  }
  Process {
    Write-Verbose "==> Creating speech synthesizer"
    $synthesizer = New-Object System.Speech.Synthesis.SpeechSynthesizer
    if (-not $Silent) {
      switch ($InputType)
      {
        "ssml" {
          Write-Verbose "==> Received SSML input"
          $synthesizer.SpeakSsml($Text)
        }
        Default {
          Write-Verbose "==> Speaking: $Text"
          $synthesizer.Rate = $Rate
          $synthesizer.Speak($Text)
        }
      }
    }
    $TotalText += "$Text "
  }
  End {
    $TotalText = $TotalText.Trim()
    switch ($Output)
    {
      "file" {
        Write-Verbose "==> [UNDER CONSTRUCTION] save as .WAV file"
      }
      "ssml" {
        $Function:render = New-Template `
'<speak version="1.0" xmlns="http://www.w3.org/2001/10/synthesis" xml:lang="en-US">
    <voice xml:lang="en-US">
        <prosody rate="{{ rate }}">
            <p>{{ text }}</p>
        </prosody>
    </voice>
</speak>'
        render @{ rate = $Rate; text = $TotalText } | Write-Output
      }
      "text" {
        Write-Output $TotalText
      }
      Default {
        Write-Verbose "==> $TotalText"
      }
    }
  }
}
function Invoke-StopListen
{
  <#
  .SYNOPSIS
  Remove event subscriber(s)
  .EXAMPLE
  $Callback | on -Name "SomeEvent"
  "SomeEvent" | Invoke-StopListen

  Remove events using the event "source identifier" (Name)
  .EXAMPLE
  $Callback | on -Name "Namespace:foo"
  $Callback | on -Name "Namespace:bar"
  "Namespace:" | Invoke-StopListen

  Remove multiple events using an event namespace
  .EXAMPLE
  $Listener = $Callback | on -Name "SomeEvent"
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
function Join-StringsWithGrammar()
{
  <#
  .SYNOPSIS
  Helper function that creates a string out of a list that properly employs commands and "and"
  .EXAMPLE
  Join-StringsWithGrammar @("a", "b", "c")

  Returns "a, b, and c"
  #>
  [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'Delimiter')]
  [CmdletBinding()]
  [OutputType([String])]
  Param(
    [Parameter(Mandatory=$true)]
    [String[]] $Items,
    [String] $Delimiter = ','
  )
  $NumberOfItems = $Items.Length
  switch ($NumberOfItems) {
    1 {
      $Items -join ""
    }
    2 {
      $Items -join " and "
    }
    Default {
      @(
        ($Items[0..($NumberOfItems - 2)] -join ", ") + ","
        "and"
        $Items[$NumberOfItems - 1]
      ) -join " "
    }
  }
}
function New-DailyShutdownJob
{
  <#
  .SYNOPSIS
  Create job to shutdown computer at a certain time every day
  .EXAMPLE
  New-DailyShutdownJob -At "22:00"
  #>
  [CmdletBinding()]
  Param(
    [Parameter(Mandatory=$true)]
    [String] $At
  )
  if (Test-Admin) {
    $Trigger = New-JobTrigger -Daily -At $At
    Register-ScheduledJob -Name "DailyShutdown" -ScriptBlock { Stop-Computer -Force } -Trigger $Trigger
  } else {
    Write-Error "==> New-DailyShutdownJob requires Administrator privileges"
  }
}
function New-File
{
  <#
  .SYNOPSIS
  Powershell equivalent of linux "touch" command (includes "touch" alias)
  .EXAMPLE
  New-File <file name>
  .EXAMPLE
  touch <file name>
  #>
  [CmdletBinding(SupportsShouldProcess=$true)]
  [Alias('touch')]
  Param(
    [Parameter(Mandatory=$true)]
    [String] $Name
  )
  if (Test-Path $Name) {
    (Get-ChildItem $Name).LastWriteTime = Get-Date
  } else {
    New-Item -Path . -Name $Name -ItemType "file" -Value ""
  }
}
function New-ProxyCommand
{
  <#
  .SYNOPSIS
  Create function template for proxy function
  .DESCRIPTION
  This function can be used to create a framework for a proxy function. If you want to create a proxy function for a command named Some-Command,
  you should pass "Some-Command" as the Name attribute - New-ProxyCommand -Name Some-Command
  .EXAMPLE
  New-ProxyCommand -Name "Out-Default" | Out-File "Out-Default.ps1"
  .EXAMPLE
  "Invoke-Item" | New-ProxyCommand | Out-File "Invoke-Item-proxy.ps1"
  #>
  [CmdletBinding()]
  Param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [String] $Name
  )
  $metadata = New-Object System.Management.Automation.CommandMetadata (Get-Command $Name)
  Write-Output "
  function $Name
  {
    $([System.Management.Automation.ProxyCommand]::Create($metadata))
  }"
}
function New-SshKey
{
  [CmdletBinding()]
  Param(
    [String] $Name = 'id_rsa'
  )
  Write-Verbose "==> Generating SSH key pair"
  $Path = "~/.ssh/$Name"
  ssh-keygen --% -q -b 4096 -t rsa -N "" -f TEMPORARY_FILE_NAME
  Move-Item -Path TEMPORARY_FILE_NAME -Destination $Path
  Move-Item -Path TEMPORARY_FILE_NAME.pub -Destination "$Path.pub"
  if (Test-Path "$Path.pub") {
    Write-Verbose "==> $Name SSH private key saved to $Path"
    Write-Verbose "==> Saving SSH public key to clipboard"
    Get-Content "$Path.pub" | Set-Clipboard
    Write-Output "==> Public key saved to clipboard"
  } else {
    Write-Error "==> Failed to create SSH key"
  }
}
function New-Template
{
  <#
  .SYNOPSIS
  Create render function that interpolates passed object values
  .PARAMETER Data
  Pass template data to New-Template when using New-Template within pipe chain (see examples)
  .EXAMPLE
  $Function:render = New-Template '<div>Hello {{ name }}!</div>'
  render @{ name = "World" }
  # "<div>Hello World!</div>"

  Use mustache template syntax! Just like Handlebars.js!
  .EXAMPLE
  $Function:render = 'hello {{ name }}' | New-Template
  @{ name = "world" } | render
  # "hello world"

  New-Template supports idiomatic powershell pipeline syntax
  .EXAMPLE
  $Function:render = New-Template '<div>Hello $($Data.name)!</div>'
  render @{ name = "World" }
  # "<div>Hello World!</div>"

  Or stick to plain Powershell syntax...this is a little more verbose ($Data is required)
  .EXAMPLE
  $title = New-Template -Template '<h1>{{ text }}</h1>' -DefaultValues @{ text = "Default" }
  & $title
  # "<h1>Default</h1>"
  & $title @{ text = "Hello World" }
  # "<h1>Hello World</h1>"

  Provide default values for your templates!
  .EXAMPLE
  $div = New-Template -Template '<div>{{ text }}</div>'
  $section = New-Template "<section>
      <h1>{{ title }}</h1>
      $(& $div @{ text = "Hello World!" })
  </section>"

  Templates can even be nested!
  .EXAMPLE
  '{{#green Hello}} {{ name }}' | tpl -Data @{ name = "World" } | Write-Color

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
function Open-Session
{
  <#
  .SYNOPSIS
  Create interactive session with remote computer
  .PARAMETER NoEnter
  Create session(s) but do not enter a session
  .EXAMPLE
  Open-Session -ComputerNames PCNAME -Password 123456
  .EXAMPLE
  Open-Session -ComputerNames PCNAME

  This will open a prompt for you to input your password
  .EXAMPLE
  $Sessions = Open-Session -ComputerNames ServerA,ServerB

  This will open a password prompt and then display an interactive console menu to select ServerA or ServerB.
  $Sessions will point to an array of sessions for ServerA and ServerB and can be used to make new sessions:

  Enter-PSSession -Session $Sessions[1]
  #>
  [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingPlainTextForPassword', 'Password')]
  [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUsePSCredentialType', '', Scope='Function')]
  [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingConvertToSecureStringWithPlainText', '', Scope='Function')]
  [CmdletBinding()]
  Param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [String[]] $ComputerNames,
    [String] $Password,
    [PSObject] $Credential,
    [Switch] $NoEnter
  )
  $User = whoami
  if ($Credential) {
    Write-Verbose "==> Using -Credential for authentication"
    $Cred = $Credential
  } elseif ($Password) {
    Write-Verbose "==> Creating credential for $User using -Password"
    $Pass = ConvertTo-SecureString -String $Password -AsPlainText -Force
    $Cred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $User, $Pass
  } else {
    $Cred = Get-Credential -Message "Please provide password to access $(Join-StringsWithGrammar $ComputerNames)" -User $User
  }
  Write-Verbose "==> Creating session on $(Join-StringsWithGrammar $ComputerNames)"
  $Session = New-PSSession -ComputerName $ComputerNames -Credential $Cred
  Write-Verbose "==> Entering session"
  if (-not $NoEnter) {
    if ($Session.Length -eq 1) {
      Enter-PSSession -Session $Session
    } else {
      Write-Label '{{#green Enter session?}}' -NewLine
      $Index = Invoke-Menu -Items $ComputerNames -ReturnIndex
      if ($null -ne $Index) {
        Enter-PSSession -Session $Session[$Index]
      }
    }
  }
  $Session
}
function Out-Default
{
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
function Remove-Character
{
  [CmdletBinding()]
  [OutputType([String])]
  Param(
    [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
    [String] $Value,
    [Int] $At,
    [Switch] $First,
    [Switch] $Last
  )
  if ($First) {
    $At = 0
  } elseif ($Last) {
    $At = $Value.Length - 1
  }
  if ($At -lt $Value.Length -and $At -ge 0) {
    $Value.Substring(0, $At) + $Value.Substring($At + 1, $Value.length - $At - 1)
  } else {
    $Value
  }
}
function Remove-DailyShutdownJob
{
  <#
  .SYNOPSIS
  Remove job created with New-DailyShutdownJob
  .EXAMPLE
  Remove-DailyShutdownJob
  #>
  [CmdletBinding()]
  Param()
  if (Test-Admin) {
    Unregister-ScheduledJob -Name "DailyShutdown"
  } else {
    Write-Error "==> Remove-DailyShutdownJob requires Administrator privileges"
  }
}
function Remove-DirectoryForce
{
  <#
  .SYNOPSIS
  Powershell equivalent of linux "rm -frd"
  .EXAMPLE
  rf <folder name>
  #>
  [CmdletBinding(SupportsShouldProcess=$true)]
  [Alias('rf')]
  Param(
    [Parameter(Mandatory=$true)]
    [String] $Name
  )
  $Path = Join-Path (Get-Location) $Name
  if (Test-Path $Path) {
    $Cleaned = Resolve-Path $Path
    Write-Verbose "==> Deleting $Cleaned"
    Remove-Item -Path $Cleaned -Recurse
    Write-Verbose "==> Deleted $Cleaned"
  } else {
    Write-Error 'Bad input. No folders/files were deleted'
  }
}
function Show-BarChart
{
  <#
  .SYNOPSIS
  Function to create horizontal bar chart of passed data object
  .PARAMETER Width
  Maximum value used for data normization. Also corresponds to actual width of longest bar (in characters)
  .PARAMETER Alternate
  Alternate row color between light and dark.
  .PARAMETER ShowValues
  Whether or not to show data values to right of each bar
  .EXAMPLE
  @{red = 55; white = 30; blue = 200} | Show-BarChart -WithColor -ShowValues
  .EXAMPLE
  Write-Title "Colors"
  @{red = 55; white = 30; blue = 200} | Show-BarChart -Alternate -ShowValues
  Write-Color ""

  Can be used with Write-Title to create goo looking reports in the terminal
  .EXAMPLE
  Get-ChildItem -File | Invoke-Reduce -FileInfo | Show-BarChart -ShowValues -WithColor

  Easily display a bar chart of files using Invoke-Reduce
  #>
  [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '', Scope='Function')]
  [CmdletBinding()]
  Param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [PSObject] $InputObject,
    [Int] $Width = 100,
    [Switch] $ShowValues,
    [Switch] $Alternate,
    [Switch] $WithColor
  )
  $Data = [PSCustomObject]$InputObject
  $Space = " "
  $Tee = ([Char]9508).ToString()
  $Marker = ([Char]9608).ToString()
  $LargestValue = $Data.PSObject.Properties | Select-Object -ExpandProperty Value | Sort-Object -Descending | Select-Object -First 1
  $LongestNameLength = ($Data.PSObject.Properties.Name | Sort-Object { $_.Length } -Descending | Select-Object -First 1).Length
  $Index = 0
  $Data.PSObject.Properties | Sort-Object { $_.Value } | ForEach-Object {
    $Name = $_.Name
    $Value = ($_.Value / $LargestValue) * $Width
    $IsEven = ($Index % 2) -eq 0
    $Padding = $Space | Write-Repeat -Times ($LongestNameLength - $Name.Length)
    $Bar = $Marker | Write-Repeat -Times $Value
    if ($WithColor) {
      Write-Color "$Padding{{#white $Name $Tee}}$Bar" -Cyan:$($IsEven -and $Alternate) -DarkCyan:$((-not $IsEven -and $Alternate) -or (-not $Alternate)) -NoNewLine
    } else {
      Write-Color "$Padding{{#white $Name $Tee}}$Bar" -White:$($IsEven -and $Alternate) -Gray:$(-not $IsEven -and $Alternate) -NoNewLine
    }
    if ($ShowValues) {
      Write-Color " $($Data.$Name)" -DarkGray
    } else {
      Write-Color ""
    }
    $Index++
  }
}
function Take
{
  <#
  .SYNOPSIS
  Powershell equivalent of oh-my-zsh take function
  .DESCRIPTION
  Using take will create a new directory and then enter the driectory
  .EXAMPLE
  take <folder name>
  #>
  [CmdletBinding(SupportsShouldProcess=$true)]
  Param(
    [Parameter(Mandatory=$true)]
    [String] $Name
  )
  $Path = Join-Path (Get-Location) $Name
  if (Test-Path $Path) {
    Write-Verbose "==> $Path exists"
    Write-Verbose "==> Entering $Path"
    Set-Location $Path
  } else {
    Write-Verbose "==> Creating $Path"
    mkdir $Path
    if (Test-Path $Path) {
      Write-Verbose "==> Entering $Path"
      Set-Location $Path
    }
  }
  Write-Verbose "==> pwd is $(Get-Location)"
}
function Test-Admin
{
  <#
  .SYNOPSIS
  Helper function that returns true if user is in the "built-in" "admin" group, false otherwise
  .EXAMPLE
  Test-Admin
  #>
  [CmdletBinding()]
  [OutputType([Bool])]
  Param()
  if ($IsLinux -is [Bool] -and $IsLinux) {
    (whoami) -eq "root"
  } else {
    ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator) | Write-Output
  }
}
function Test-Empty
{
  <#
  .SYNOPSIS
  Helper function that returns true if directory is empty, false otherwise
  .EXAMPLE
  echo <folder name> | Test-Empty
  .EXAMPLE
  dir . | %{Test-Empty $_.FullName}
  #>
  [CmdletBinding()]
  [ValidateNotNullorEmpty()]
  [OutputType([Bool])]
  Param(
    [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
    [String] $Name
  )
  Get-Item $Name | ForEach-Object { $_.psiscontainer -and $_.GetFileSystemInfos().Count -eq 0 } | Write-Output
}
function Test-Equal
{
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
        "String" { $Left -eq $Right }
        "Int*" { $Left -eq $Right }
        "Double" { $Left -eq $Right }
        "Object*" {
          $Every = { $args[0] -and $args[1] }
          $Index = 0
          $Left | ForEach-Object { Test-Equal $_ $Right[$Index]; $Index++ } | Invoke-Reduce -Callback $Every -InitialValue $true
        }
        "PSCustomObject" {
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
        "Hashtable" {
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
      Write-Verbose "==> Failed to match type of -Left item"
      $false
    }
  } else {
    Write-Verbose "==> One or both items are `$null"
    $Left -eq $Right
  }
}
function Test-Installed
{
  [CmdletBinding()]
  [OutputType([Bool])]
  Param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [String] $Name
  )
  if (Get-Module -ListAvailable -Name $Name) {
    $true
  } else {
    $false
  }
}
function Use-Grammar
{
  [CmdletBinding()]
  Param(
    [Parameter(Mandatory=$true)]
    [String[]] $Words
  )
  Write-Verbose "==> Creating Speech Recognition Engine"
  $Engine = [System.Speech.Recognition.SpeechRecognitionEngine]::New();
  $Engine.InitialSilenceTimeout = 15
  $Engine.SetInputToDefaultAudioDevice();
  $Words | ForEach-Object {
    Write-Verbose "==> Loading grammar for $_"
    $Grammar = [System.Speech.Recognition.GrammarBuilder]::New();
    $Grammar.Append($_)
    $Engine.LoadGrammar($Grammar)
  }
  $Engine
}
function Use-Speech
{
  [CmdletBinding()]
  Param()
  $SpeechSynthesizerTypeName = 'System.Speech.Synthesis.SpeechSynthesizer'
  if (-not ($SpeechSynthesizerTypeName -as [Type])) {
    Write-Verbose "==> Adding System.Speech type"
    Add-Type -AssemblyName System.Speech
  } else {
    Write-Verbose "==> System.Speech is already loaded"
  }
}
function Write-Color
{
  <#
  .SYNOPSIS
  Basically Write-Host with the ability to color parts of the output by using template strings
  .PARAMETER Color
  Performs the function Write-Host's -ForegroundColor. Useful for programmatically setting text color.
  .EXAMPLE
  '{{#red this will be red}} and {{#blue this will be blue}}' | Write-Color
  .EXAMPLE
  Write-Color 'You can color entire string using switch parameters' -Green
  .EXAMPLE
  Write-Color 'You can color entire string using Color parameter' -Color Green
  .EXAMPLE
  '{{#green Hello}} {{#blue {{ name }}}}' | New-Template -Data @{ name = "World" } | Write-Color
  #>
  [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '', Scope='Function')]
  [CmdletBinding()]
  Param(
    [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
    [AllowEmptyString()]
    [String] $Text,
    [String] $Color,
    [Switch] $NoNewLine,
    [Switch] $Black,
    [Switch] $Blue,
    [Switch] $DarkBlue,
    [Switch] $DarkGreen,
    [Switch] $DarkCyan,
    [Switch] $DarkGray,
    [Switch] $DarkRed,
    [Switch] $DarkMagenta,
    [Switch] $DarkYellow,
    [Switch] $Cyan,
    [Switch] $Gray,
    [Switch] $Green,
    [Switch] $Red,
    [Switch] $Magenta,
    [Switch] $Yellow,
    [Switch] $White
  )
  if ($Text.Length -eq 0) {
    Write-Host "" -NoNewline:$NoNewLine
  } else {
    if (-not $Color) {
      $ColorNames = "Black", "DarkBlue", "DarkGreen", "DarkCyan", "DarkRed", "DarkMagenta", "DarkYellow", "Gray", "DarkGray", "Blue", "Green", "Cyan", "Red", "Magenta", "Yellow", "White"
      $Index = ,($ColorNames | Get-Variable | Select-Object -ExpandProperty Value) | Find-FirstIndex
      if ($Index) {
        $Color = $ColorNames[$Index]
      } else {
        $Color = "White"
      }
    }
    $Position = 0
    $Text | Select-String -Pattern '(?<HELPER>){{#((?!}}).)*}}' -AllMatches | ForEach-Object Matches | ForEach-Object {
      Write-Host $Text.Substring($Position, $_.Index - $Position) -ForegroundColor $Color -NoNewline
      $HelperTemplate = $Text.Substring($_.Index, $_.Length)
      $Arr = $HelperTemplate | ForEach-Object { $_ -replace '{{#', '' } | ForEach-Object { $_ -replace '}}', '' } | ForEach-Object { $_ -split ' ' }
      Write-Host ($Arr[1..$Arr.Length] -join ' ') -ForegroundColor $Arr[0] -NoNewline
      $Position = $_.Index + $_.Length
    }
    if ($Position -lt $Text.Length) {
      Write-Host $Text.Substring($Position, $Text.Length - $Position) -ForegroundColor $Color -NoNewline:$NoNewLine
    }
  }
}
function Write-Label
{
  <#
  .SYNOPSIS
  Meant to be used with Invoke-Input or Invoke-Menu
  .EXAMPLE
  Write-Label 'Favorite number?' -NewLine
  $choice = menu @('one'; 'two'; 'three')
  .EXAMPLE
  Write-Label '{{#red Message? }}' -NewLine

  Labels can be customized using mustache color helper templates
  #>
  [CmdletBinding()]
  Param(
    [Parameter(Position=0, ValueFromPipeline=$true)]
    [String] $Text = 'label',
    [String] $Color = 'Cyan',
    [Int] $Indent = 0,
    [Switch] $NewLine
  )
  Write-Color (" " * $Indent) -NoNewLine
  Write-Color "$Text " -Color $Color -NoNewLine:$(-not $NewLine)
}
function Write-Repeat
{
  [CmdletBinding()]
  [Alias('repeat')]
  Param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [AllowEmptyString()]
    [String] $Value,
    [Int] $Times = 1
  )
  Write-Output ($Value * $Times)
}
function Write-Title
{
  <#
  .SYNOPSIS
  Function to print text with a border. Useful for displaying section titles for CLI apps.
  .PARAMETER Template
  Tells Write-Title to expect mustache color templates (see Get-Help Write-Color -Examples)
  .PARAMETER Fallback
  Use "+" and "-" to draw title border
  .PARAMETER Indent
  Add spaces to left of title box to align with input elements
  .EXAMPLE
  "Hello World" | Write-Title
  .EXAMPLE
  "Hello World" | Write-Title -Green

  Easily change border and title text color
  .EXAMPLE
  "Hello World" | Write-Title -Width 20 -TextColor Red

  Change only the color of title text with -TextColor
  .EXAMPLE
  "Hello World" | Write-Title -Width 20

  Titles can have set widths
  .EXAMPLE
  "Hello World" | Write-Title -Fallback

  If your terminal does not have the fancy characters needed for a proper border, fallback to "+" and "-"
  .EXAMPLE
  "{{#magenta Hello}} World" | Write-Title -Template

  Write-Title accepts same input as Write-Color and can be used to customize title text.
  #>
  [CmdletBinding()]
  [Alias('title')]
  Param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [String] $Text,
    [String] $TextColor,
    [String] $SubText = "",
    [Switch] $Template,
    [Switch] $Fallback,
    [Switch] $Blue,
    [Switch] $Cyan,
    [Switch] $DarkBlue,
    [Switch] $DarkCyan,
    [Switch] $DarkGreen,
    [Switch] $DarkRed,
    [Switch] $DarkMagenta,
    [Switch] $DarkYellow,
    [Switch] $Green,
    [Switch] $Magenta,
    [Switch] $Red,
    [Switch] $White,
    [Switch] $Yellow,
    [Int] $Width,
    [Int] $Indent = 0
  )
  if ($Template) {
    $TextLength = ($Text -replace "{{#\w*\s", "" | ForEach-Object { $_ -replace "}}", "" }).Length
  } else {
    $TextLength = $Text.Length
  }
  if ($Width -lt  $TextLength) {
    $Width = $TextLength + 4
  }
  $Space = " "
  if ($Fallback) {
    $TopLeft = '+'
    $TopEdge = '-'
    $TopRight = '+'
    $LeftEdge = $RightEdge = '|'
    $BottomLeft = '+'
    $BottomEdge = $TopEdge
    $BottomRight = '+'
  } else {
    $TopLeft = [Char]9484
    $TopEdge = [Char]9472
    $TopRight = [Char]9488
    $LeftEdge = $RightEdge = [Char]9474
    $BottomLeft = [Char]9492
    $BottomEdge = $TopEdge
    $BottomRight = [Char]9496
  }
  $PaddingLength = [Math]::Floor(($Width - $TextLength - 2) / 2)
  $Padding = $Space | Write-Repeat -Times $PaddingLength
  $WidthInside = (2 * $PaddingLength) + $TextLength
  $BorderColor = @{
    Cyan = $Cyan
    Red = $Red
    Blue = $Blue
    Green = $Green
    Yellow = $Yellow
    Magenta = $Magenta
    White = $White
    DarkBlue = $DarkBlue
    DarkGreen = $DarkGreen
    DarkCyan = $DarkCyan
    DarkRed = $DarkRed
    DarkMagenta = $DarkMagenta
    DarkYellow = $DarkYellow
  }
  Write-Color "$(Write-Repeat $Space -Times $Indent)$TopLeft$(Write-Repeat "$TopEdge" -Times $WidthInside)$TopRight" @BorderColor
  if ($TextColor) {
    Write-Color "$(Write-Repeat $Space -Times $Indent)$LeftEdge$Padding{{#$TextColor $Text}}$Padding$RightEdge" @BorderColor
  } else {
    Write-Color "$(Write-Repeat $Space -Times $Indent)$LeftEdge$Padding$Text$Padding$RightEdge" @BorderColor
  }
  Write-Color "$(Write-Repeat $Space -Times $Indent)$BottomLeft$(Write-Repeat "$BottomEdge" -Times ($WidthInside - $SubText.Length))$SubText$BottomRight" @BorderColor
}
#
# Aliases
#
if (Test-Installed Get-ChildItemColor) {
  Set-Alias -Scope Global -Option AllScope -Name la -Value Get-ChildItemColor
  Set-Alias -Scope Global -Option AllScope -Name ls -Value Get-ChildItemColorFormatWide
}
Set-Alias -Scope Global -Option AllScope -Name g -Value Invoke-GitCommand
Set-Alias -Scope Global -Option AllScope -Name gcam -Value Invoke-GitCommit
Set-Alias -Scope Global -Option AllScope -Name gd -Value Invoke-GitDiff
Set-Alias -Scope Global -Option AllScope -Name glo -Value Invoke-GitLog
Set-Alias -Scope Global -Option AllScope -Name gpom -Value Invoke-GitPushMaster
Set-Alias -Scope Global -Option AllScope -Name grbi -Value Invoke-GitRebase
Set-Alias -Scope Global -Option AllScope -Name gsb -Value Invoke-GitStatus