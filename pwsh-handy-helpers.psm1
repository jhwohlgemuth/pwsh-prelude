function ConvertFrom-VirtualKeycodes
{
  [CmdletBinding()]
  Param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [array] $Text
  )
  $Lookup = [PSCustomObject]@{
    9 = "<TAB>"
    13 = "<ENTER>"
    16 = "<SHIFT>"
    17 = "<CONTROL>"
    20 = "<CAPSLOCK>"
    27 = "<ESCAPE>"
    32 = " "
    37 = "<LEFT>"
    38 = "<UP>"
    39 = "<RIGHT>"
    40 = "<DOWN>"
    46 = "<DELETE>"
    48 = "0"
    49 = "1"
    50 = "2"
    51 = "3"
    52 = "4"
    53 = "5"
    54 = "6"
    55 = "7"
    56 = "8"
    57 = "9"
    65 = "a"
    66 = "b"
    67 = "c"
    68 = "d"
    69 = "e"
    70 = "f"
    71 = "g"
    72 = "h"
    73 = "i"
    74 = "j"
    75 = "k"
    76 = "l"
    77 = "m"
    78 = "n"
    79 = "o"
    80 = "p"
    81 = "q"
    82 = "r"
    83 = "s"
    84 = "t"
    85 = "u"
    86 = "v"
    87 = "w"
    88 = "x"
    89 = "y"
    90 = "z"
    96 = "0"
    97 = "1"
    98 = "2"
    99 = "3"
    100 = "4"
    101 = "5"
    102 = "6"
    103 = "7"
    104 = "8"
    105 = "9"
  }
  $Keys = $Text | ForEach-Object {
    $Key = $Lookup.$_
    if ($null -ne $Key) {
      $Key
    }
  }
  $Keys -Join ""
}
function ConvertTo-PowershellSyntax
{
  Param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipelineByPropertyName=$true, ValueFromPipeline=$true)]
    [string] $Value,
    [string] $DataVariableName = "Data"
  )
  Write-Output $Value |
    ForEach-Object { $_ -Replace '(?<!{{#[\w\s]*)\s*}}', ')' } |
    ForEach-Object { $_ -Replace '{{(?!#)\s*', "`$(`$$DataVariableName." }
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
    [string] $TrustedHosts = "*"
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
function Find-Duplicates
{
  <#
  .SYNOPSIS
  Helper function that calculates file hash values to find duplicate files recursively
  .EXAMPLE
  Find-Duplicates <path to folder>
  .EXAMPLE
  pwd | Find-Duplicates
  #>
  [CmdletBinding()]
  Param(
    [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
    [string] $Name
  )
  Get-Item $Name |
    Get-ChildItem -Recurse |
    Get-FileHash |
    Group-Object -Property Hash |
    Where-Object Count -GT 1 |
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
  [CmdletBinding()]
  Param(
    [Parameter(Position=0, ValueFromPipeline=$true)]
    [array] $Values,
    [scriptblock] $Predicate = { $args[0] -eq $true }
  )
  @($Values | ForEach-Object{ $i = 0 }{ if(& $Predicate $_){ [array]::IndexOf($Values, $_) }; $i++ }).Where({ $_ }, 'First')
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
    [string] $Url,
    [string] $File="download.txt"
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
  dip <container name/id>
  .EXAMPLE
  echo <container name/id> | dip
  #>
  [CmdletBinding()]
  [Alias('dip')]
  Param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [string] $Name
  )
  docker inspect --format '{{ .NetworkSettings.IPAddress }}' $Name
}
function Invoke-DockerRemoveAll
{
  <#
  .SYNOPSIS
  Remove ALL Docker containers
  .EXAMPLE
  dra <container name/id>
  #>
  [CmdletBinding()]
  [Alias('dra')]
  Param()
  docker stop $(docker ps -a -q); docker rm $(docker ps -a -q)
}
function Invoke-DockerRemoveAllImages
{
  <#
  .SYNOPSIS
  Remove ALL Docker images
  .EXAMPLE
  drai <container name/id>
  #>
  [CmdletBinding()]
  [Alias('drai')]
  Param()
  docker rmi $(docker images -a -q)
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
  #>
  [CmdletBinding()]
  [Alias('input')]
  Param(
    [Parameter(Position=0, ValueFromPipeline=$true)]
    [string] $Label = 'input:',
    [switch] $Secret,
    [switch] $Number,
    [int] $MaxLength = 0
  )
  Write-Color "$Label " -Cyan -NoNewLine
  $Result = ""
  $StartPosition = [Console]::CursorLeft
  Do  {
    $KeyInfo = [Console]::ReadKey($true)
    $KeyChar = $KeyInfo.KeyChar
    switch ($KeyInfo.Key) {
      "Backspace" {
        if (-Not $Secret) {
          $Left = [Console]::CursorLeft
          if ($Left -gt $StartPosition) {
            [Console]::SetCursorPosition($StartPosition, [Console]::CursorTop)
            $Updated = $Result | Remove-Character -At ($Left - $StartPosition - 1)
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
            [Console]::SetCursorPosition([Math]::Max(0, $Left - 1), [Console]::CursorTop)
          }
        }
      }
      "Delete" {
        if (-Not $Secret) {
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
          [Console]::SetCursorPosition([Math]::Max(0, $Left), [Console]::CursorTop)
        }
      }
      "DownArrow" {
        if ($Number) {
          $Value = ($Result -As [int]) - 1
          if (($MaxLength -eq 0) -Or ($MaxLength -gt 0 -And $Value -gt -[Math]::Pow(10, $MaxLength))) {
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
        if (-Not $Secret) {
          $Left = [Console]::CursorLeft
          if ($Left -gt $StartPosition) {
            [Console]::SetCursorPosition($Left - 1, [Console]::CursorTop)
          }
        }
      }
      "RightArrow" {
        if (-Not $Secret) {
          $Left = [Console]::CursorLeft
          if ($Left -lt ($StartPosition + $Result.Length)) {
            [Console]::SetCursorPosition($Left + 1, [Console]::CursorTop)
          }
        }
      }
      "UpArrow" {
        if ($Number) {
          $Value = ($Result -As [int]) + 1
          if (($MaxLength -eq 0) -Or ($MaxLength -gt 0 -And $Value -lt [Math]::Pow(10, $MaxLength))) {
            $Left = [Console]::CursorLeft
            $Result = "$Value"
            [Console]::SetCursorPosition($StartPosition, [Console]::CursorTop)
            Write-Color "$Result " -NoNewLine
            [Console]::SetCursorPosition($Left, [Console]::CursorTop)
          }
        }
      }
      Default {
        function Format-Output
        {
          Param(
            [Parameter(Mandatory=$true, Position=0)]
            [string] $Value
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
            [string] $Output,
            [int] $Left = 0
          )
          [Console]::SetCursorPosition($StartPosition, [Console]::CursorTop)
          if ($MaxLength -gt 0 -And $Output.Length -gt $MaxLength) {
            Write-Color $Output.Substring(0, $MaxLength) -NoNewLine
            Write-Color $Output.Substring($MaxLength, $Output.Length - $MaxLength) -NoNewLine -Red
          } else {
            Write-Color $Output -NoNewLine
          }
          [Console]::SetCursorPosition($Left + 1, [Console]::CursorTop)
        }
        $Left = [Console]::CursorLeft
        if ($Left -eq $StartPosition) {# prepend character
          $Result = "${KeyChar}$Result"
          Invoke-OutputDraw -Output (Format-Output $Result) -Left $Left
        } elseif ($Left -gt $StartPosition -And $Left -lt ($StartPosition + $Result.Length)) {# insert character
          $Result = $KeyChar | Invoke-InsertString -To $Result -At ($Left - $StartPosition)
          Invoke-OutputDraw -Output $Result -Left $Left
        } else {# append character
          $Result += $KeyChar
          $ShouldHighlight = ($MaxLength -gt 0) -And [Console]::CursorLeft -gt ($StartPosition + $MaxLength - 1)
          Write-Color (Format-Output $KeyChar) -NoNewLine -Red:$ShouldHighlight
        }
      }
    }
  } Until ($KeyInfo.Key -eq 'Enter' -Or $KeyInfo.Key -eq 'Escape')
  if ($KeyInfo.Key -ne 'Escape') {
    if ($Number) {
      $Result -As [int]
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
  Param(
    [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
    [string] $Value,
    [Parameter(Mandatory=$true)]
    [string] $To,
    [Parameter(Mandatory=$true)]
    [int] $At
  )
  if ($At -lt $To.Length -And $At -ge 0) {
    $To.Substring(0, $At) + $Value + $To.Substring($At, $To.length - $At)
  } else {
    $To
  }
}
function Invoke-Listen
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
  [CmdletBinding()]
  [Alias('listen')]
  Param(
    [Parameter(Mandatory=$true)]
    [string[]] $Triggers,
    [scriptblock[]] $Actions,
    [double] $Threshhold = 0.85
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
    $Triggers | ForEach-Object { $i = 0 } {
      if ($Text -match $_ -and [double]$Confidence -gt $Threshhold) {
        $Continue = & $Actions[$i]
      }
      $i++
    }
  }
}
function Invoke-Menu
{
  <#
  .SYNOPSIS
  Create interactive single, multi-select, or single-select list menu
  .EXAMPLE
  menu @('one', 'two', 'three')
  .EXAMPLE
  menu @('one', 'two', 'three') -MultiSelect -ReturnIndex | Sort-Object
  .EXAMPLE
  ,(1,2,3,4,5) | menu
  .EXAMPLE
  ,(1,2,3,4,5) | menu -SingleSelect

  The SingleSelect switch allows for only one item to be selected at a time
  #>
  [CmdletBinding()]
  [Alias('menu')]
  Param (
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [array] $Items,
    [switch] $MultiSelect,
    [switch] $SingleSelect,
    [switch] $ReturnIndex = $false
  )
  [Console]::CursorVisible = $false
  $Keycodes = @{
    enter = 13;
    escape = 27;
    space = 32;
    up = 38;
    down = 40;
  }
  $Keycode = 0
  $Position = 0
  $Selection = @()
  if ($Items.Length -gt 0) {
    Invoke-MenuDraw -Items $Items -Position $Position -Selection $Selection -MultiSelect:$MultiSelect -SingleSelect:$SingleSelect
		While ($Keycode -ne $Keycodes.enter -and $Keycode -ne $Keycodes.escape) {
			$Keycode = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown").virtualkeycode
      switch ($Keycode) {
        $Keycodes.escape {
          $Position = $null
        }
        $Keycodes.space {
          $Selection = Update-MenuSelection -Position $Position -Selection $Selection -MultiSelect:$MultiSelect -SingleSelect:$SingleSelect
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
        Invoke-MenuDraw -Items $Items -Position $Position -Selection $Selection -MultiSelect:$MultiSelect -SingleSelect:$SingleSelect
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
function Invoke-MenuDraw
{
  [CmdletBinding()]
  Param (
    [array] $Items, 
    [int] $Position, 
    [array] $Selection,
    [switch] $MultiSelect,
    [switch] $SingleSelect
  )
  $Items | ForEach-Object { $i = 0 } {
    $Item = $_
    if ($null -ne $Item) {
      if ($MultiSelect) {
        if ($Selection -contains $i) {
          $Item = "[x] $Item"
        } else {
          $Item = "[ ] $Item"
        }
      } else {
        if ($SingleSelect) {
          if ($Selection -contains $i) {
            $Item = "(o) $Item"
          } else {
            $Item = "( ) $Item"
          }
        }
      }
      if ($i -eq $Position) {
        Write-Color "> $Item" -Cyan
      } else {
        Write-Color "  $Item"
      }
    }
    $i++
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
  [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingPlainTextForPassword", "Password")]
  [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingPlainTextForPassword", "Credential")]
  Param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipelineByPropertyName=$true, ValueFromPipeline=$true)]
    [System.Management.Automation.ScriptBlock] $ScriptBlock,
    [Parameter(Mandatory=$true)]
    [string[]] $ComputerNames,
    [Parameter()]
    [string] $Password,
    [Parameter()]
    [psobject] $Credential
  )
  $User = whoami
  if ($Credential) {
    Write-Verbose "==> Using -Credential for authentication"
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
    [Parameter(Position=0, ValueFromPipelineByPropertyName=$true, ValueFromPipeline=$true)]
    [string] $Text = "",
    [string] $InputType = "text",
    [int] $Rate = 0,
    [switch] $Silent,
    [string] $Output = "none"
  )
  Begin {
    Use-Speech
    $TotalText = ""
  }
  Process {
    Write-Verbose "==> Creating speech synthesizer"
    $synthesizer = New-Object System.Speech.Synthesis.SpeechSynthesizer
    if (-Not $Silent) {
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
        $function:render = New-Template `
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
function Join-StringsWithGrammar()
{
  <#
  .SYNOPSIS
  Helper function that creates a string out of a list that properly employs commands and "and"
  .EXAMPLE
  Join-StringsWithGrammar @("a", "b", "c")

  Returns "a, b, and c"
  #>
  [CmdletBinding()]
  Param(
    [Parameter(Mandatory=$true)]
    [string[]] $Items,
    [string] $Delimiter = ","
  )
  $NumberOfItems = $Items.Length
  switch ($NumberOfItems)
  {
    1 {
      $Items
    }
    2 {
      $Items -Join " and "
    }
    Default {
      @(
        ($Items[0..($NumberOfItems - 2)] -Join ", ") + ","
        "and"
        $Items[$NumberOfItems - 1]
      ) -Join " "
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
    [string] $At
  )
  if (Test-Admin) {
    $trigger = New-JobTrigger -Daily -At $At
    Register-ScheduledJob -Name "DailyShutdown" -ScriptBlock { Stop-Computer -Force } -Trigger $trigger
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
    [string] $Name
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
    [string] $Name
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
    [string] $Name="id_rsa"
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
  .EXAMPLE
  $function:render = New-Template '<div>Hello {{ name }}!</div>'
  render @{ name = "World" }
  # "<div>Hello World!</div>"

  Use mustache template syntax! Just like Handlebars.js!
  .EXAMPLE
  $function:render = 'hello {{ name }}' | New-Template
  @{ name = "world" } | render
  # "hello world"

  New-Template supports idiomatic powershell pipeline syntax
  .EXAMPLE
  $function:render = New-Template '<div>Hello $($Data.name)!</div>'
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
  #>
  [CmdletBinding()]
  [Alias('tpl')]
  Param(
    [Parameter(Position=0, ValueFromPipelineByPropertyName=$true, ValueFromPipeline=$true)]
    [string] $Template,
    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [psobject] $DefaultValues
  )
  $script:__template = $Template # This line is super important
  $script:__defaults = $DefaultValues # This line is also super important
  {
    Param(
      [Parameter(Position=0, ValueFromPipelineByPropertyName=$true, ValueFromPipeline=$true)]
      [psobject] $Data,
      [switch] $PassThru
    )
    if ($PassThru) {
      $render = $__template
    } else {
      $DataVariableName = Get-Variable -Name Data | ForEach-Object{ $_.Name }
      $render = $__template | ConvertTo-PowershellSyntax -DataVariableName $DataVariableName
    }
    if (-Not $Data) {
      $Data = $__defaults
    }
    $render = $render -Replace '"', '`"'
    $importDataVariable = "`$Data = '$(ConvertTo-Json ([System.Management.Automation.PSObject]$Data))' | ConvertFrom-Json"
    $powershell = [powershell]::Create()
    [void]$powershell.AddScript($importDataVariable).AddScript("Write-Output `"$render`"")
    $powershell.Invoke()
    [void]$powershell.Dispose()
  }
}
function Open-Session
{
  <#
  .SYNOPSIS
  Create interactive session with remote computer
  .EXAMPLE
  Open-Session -ComputerName PCNAME -Password 123456
  .EXAMPLE
  Open-Session -ComputerName PCNAME

  This will open a prompt for you to input your password
  #>
  [CmdletBinding()]
  [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingPlainTextForPassword", "Password")]
  Param(
    [Parameter(Mandatory=$true)]
    [string] $ComputerName,
    [Parameter()]
    [string] $Password
  )
  $User = whoami
  Write-Verbose "==> Creating credential for $User"
  if ($Password) {
    $Pass = ConvertTo-SecureString -String $Password -AsPlainText -Force
    $Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $User, $Pass
  } else {
    $Credential = Get-Credential -Message "Please provide password to access $ComputerName" -User $User
  }
  Write-Verbose "==> Creating session"
  $Session = New-PSSession -ComputerName $ComputerName -Credential $Credential
  Write-Verbose "==> Entering session"
  Enter-PSSession -Session $Session
}
function Out-Default
{
  <#
  .ForwardHelpTargetName Out-Default
  .ForwardHelpCategory Function
  #>
  [CmdletBinding(HelpUri='http://go.microsoft.com/fwlink/?LinkID=113362', RemotingCapability='None')]
  Param(
    [switch] ${Transcript},
    [Parameter(Position=0, ValueFromPipeline=$true)]
    [psobject] ${InputObject}
  )
  Begin {
    try {
      $outBuffer = $null
      if ($PSBoundParameters.TryGetValue('OutBuffer', [ref]$outBuffer)) {
        $PSBoundParameters['OutBuffer'] = 1
      }
      $wrappedCmd = $ExecutionContext.InvokeCommand.GetCommand('Microsoft.PowerShell.Core\Out-Default', [System.Management.Automation.CommandTypes]::Cmdlet)
      $scriptCmd = {& $wrappedCmd @PSBoundParameters }
      $steppablePipeline = $scriptCmd.GetSteppablePipeline()
      $steppablePipeline.Begin($PSCmdlet)
    } catch {
      throw
    }
  }
  Process {
    try {
      $do_process = $true
      if ($_ -is [System.Management.Automation.ErrorRecord]) {
        if ($_.Exception -is [System.Management.Automation.CommandNotFoundException]) {
          $__command = $_.Exception.CommandName
          if (Test-Path -Path $__command -PathType Container) {
            Set-Location $__command
            $do_process = $false
          } elseif ($__command -match '^https?://|\.(com|org|net|edu|dev|gov|io)$') {
            [System.Diagnostics.Process]::Start($__command)
            $do_process = $false
          }
        }
      }
      if ($do_process) {
        $global:LAST = $_;
        $steppablePipeline.Process($_)
      }
    } catch {
      throw
    }
  }
  End {
    try {
      $steppablePipeline.End()
    } catch {
      throw
    }
  }
}
function Remove-Character
{
  [CmdletBinding()]
  Param(
    [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
    [string] $Value,
    [int] $At,
    [switch] $First,
    [switch] $Last
  )
  if ($First) {
    $At = 0
  } elseif ($Last) {
    $At = $Value.Length - 1
  }
  if ($At -lt $Value.Length -And $At -ge 0) {
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
    [string] $Name
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
    [string] $Name
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
  [OutputType([bool])]
  Param()
  ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator) | Write-Output
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
  [OutputType([bool])]
  Param(
    [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
    [string] $Name
  )
  Get-Item $Name | ForEach-Object {$_.psiscontainer -AND $_.GetFileSystemInfos().Count -EQ 0} | Write-Output
}
function Test-Installed
{
  [CmdletBinding()]
  [OutputType([bool])]
  Param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [string] $Name
  )
  if (Get-Module -ListAvailable -Name $Name) {
    $true
  } else {
    $false
  }
}
function Update-MenuSelection
{
  [CmdletBinding()]
	Param (
    [int] $Position,
    [array] $Selection,
    [switch] $MultiSelect,
    [switch] $SingleSelect
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
function Use-Grammar
{
  [CmdletBinding()]
  Param(
    [Parameter(Mandatory=$true)]
    [string[]] $Words
  )
  Write-Verbose "==> Creating Speech Recognition Engine"
  $Engine = [System.Speech.Recognition.SpeechRecognitionEngine]::new();
  $Engine.InitialSilenceTimeout = 15
  $Engine.SetInputToDefaultAudioDevice();
  $Words | ForEach-Object {
    Write-Verbose "==> Loading grammar for $_"
    $Grammar = [System.Speech.Recognition.GrammarBuilder]::new();
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
  if (-Not ($SpeechSynthesizerTypeName -as [type])) {
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
  .EXAMPLE
  $function:render = '{{#red "this will be red" }} and {{#blue this will be blue" }} | Write-Color
  .EXAMPLE
  Write-Color 'You can still color entire strings using switch parameters' -Green
  #>
  [CmdletBinding()]
  Param(
    [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
    [AllowEmptyString()]
    [string] $Text,
    [switch] $NoNewLine,
    [switch] $Black,
    [switch] $DarkBlue,
    [switch] $DarkGreen,
    [switch] $DarkCyan,
    [switch] $DarkRed,
    [switch] $DarkMagenta,
    [switch] $DarkYellow,
    [switch] $Gray,
    [switch] $DarkGray,
    [switch] $Blue,
    [switch] $Green,
    [switch] $Cyan,
    [switch] $Red,
    [switch] $Magenta,
    [switch] $Yellow,
    [switch] $White
  )
  if ($Text.Length -eq 0) {
    Write-Host "" -NoNewline:$NoNewLine
  } else {
    $ColorNames = "Black", "DarkBlue", "DarkGreen", "DarkCyan", "DarkRed", "DarkMagenta", "DarkYellow", "Gray", "DarkGray", "Blue", "Green", "Cyan", "Red", "Magenta", "Yellow", "White"
    $Index = ,($ColorNames | Get-Variable | Select-Object -ExpandProperty Value) | Find-FirstIndex
    if ($Index) {
      $Color = $ColorNames[$Index]
    } else {
      $Color = "White"
    }
    $position = 0
    $Text | Select-String -Pattern '(?<HELPER>){{#[\w\s]*}}' -AllMatches | ForEach-Object matches | ForEach-Object {
      Write-Host $Text.Substring($position, $_.Index - $position) -ForegroundColor $Color -NoNewline
      $HelperTemplate = $Text.Substring($_.Index, $_.Length)
      $Arr = $HelperTemplate | ForEach-Object { $_ -Replace '{{#', '' } | ForEach-Object { $_ -Replace '}}', '' } | ForEach-Object { $_ -Split ' ' }
      Write-Host $Arr[1] -ForegroundColor $Arr[0] -NoNewline
      $position = $_.Index + $_.Length
    }
    if ($position -lt $Text.Length) {
      Write-Host $Text.Substring($position, $Text.Length - $position) -ForegroundColor $Color -NoNewline:$NoNewLine
    }
  }
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