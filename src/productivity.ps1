function Enable-Remoting {
  <#
  .SYNOPSIS
  Function to enable Powershell remoting for workgroup computer
  .PARAMETER TrustedHosts
  Comma-separated list of trusted host names
  example: 'RED,WHITE,BLUE'
  .EXAMPLE
  Enable-Remoting
  .EXAMPLE
  Enable-Remoting -TrustedHosts 'MARIO,LUIGI'
  #>
  [CmdletBinding()]
  Param(
    [String] $TrustedHosts = '*'
  )
  if (Test-Admin) {
    Write-Verbose '==> Making network private'
    Get-NetConnectionProfile | Set-NetConnectionProfile -NetworkCategory Private
    $Path = 'WSMan:\localhost\Client\TrustedHosts'
    Write-Verbose '==> Enabling Powershell remoting'
    Enable-PSRemoting -Force -SkipNetworkProfileCheck
    Write-Verbose '==> Updated trusted hosts'
    Set-Item $Path -Value $TrustedHosts -Force
    Get-Item $Path
  } else {
    Write-Error '==> Enable-Remoting requires Administrator privileges'
  }
}
function Find-Duplicate {
  <#
  .SYNOPSIS
  Helper function that calculates file hash values to find duplicate files recursively
  .EXAMPLE
  Find-Duplicate 'path/to/folder'
  .EXAMPLE
  Get-Location | Find-Duplicate
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
    Sort-Object -Property Hash |
    Write-Output
}
function Find-FirstTrueVariable {
  [CmdletBinding()]
  Param(
    [Parameter(Mandatory=$true, Position=0)]
    [Array] $VariableNames,
    [Int] $DefaultIndex = 0,
    $DefaultValue = $null
  )
  $Index = $VariableNames | Get-Variable -ValueOnly | Find-FirstIndex
  if ($Index -is [Int]) {
    $VariableNames[$Index]
  } else {
    if ($null -ne $DefaultValue) {
      $DefaultValue
    } else {
      $VariableNames[$DefaultIndex]
    }
  }
}
function Get-File {
  <#
  .SYNOPSIS
  Download a file from an internet endpoint (ex: http://example.com/file.txt)
  .EXAMPLE
  Get-File http://example.com/file.txt
  .EXAMPLE
  Get-File http://example.com/file.txt -File myfile.txt
  .EXAMPLE
  'http://example.com/file.txt' | Get-File
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
function Home {
  [CmdletBinding()]
  [Alias('~')]
  Param()
  Set-Location ~
}
function Install-SshServer {
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
function Invoke-DockerInspectAddress {
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
function Invoke-DockerRemoveAll {
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
function Invoke-DockerRemoveAllImage {
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
function Invoke-GitCommand { git $args }
function Invoke-GitCommit { git commit -vam $args }
function Invoke-GitDiff { git diff $args }
function Invoke-GitPushMaster { git push origin master }
function Invoke-GitStatus { git status -sb }
function Invoke-GitRebase { git rebase -i $args }
function Invoke-GitLog { git log --oneline --decorate }
function Invoke-ListenForWord {
  <#
  .SYNOPSIS
  Start loop that listens for trigger words and execute passed functions when recognized
  .DESCRIPTION
  This function uses the Windows Speech Recognition. For best results, you should first improve speech recognition via Speech Recognition Voice Training.
  .EXAMPLE
  Invoke-Listen -Triggers 'hello' -Actions { Write-Color 'Welcome' -Green }
  .EXAMPLE
  Invoke-Listen -Triggers 'hello','quit' -Actions { say 'Welcome' | Out-Null; $true }, { say 'Goodbye' | Out-Null; $false }

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
function Invoke-RemoteCommand {
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
    Write-Verbose '==> Using -Credential for authentication'
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
function Invoke-Speak {
  <#
  .SYNOPSIS
  Use Windows Speech Synthesizer to speak input text
  .EXAMPLE
  Invoke-Speak 'hello world'
  .EXAMPLE
  'hello world' | Invoke-Speak -Verbose
  .EXAMPLE
  1,2,3 | %{ say $_ }
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
    $TotalText = ''
  }
  Process {
    if ($IsLinux -is [Bool] -and $IsLinux) {
      Write-Verbose '==> Invoke-Speak is only supported on Windows platform'
    } else {
      Write-Verbose '==> Creating speech synthesizer'
      $synthesizer = New-Object System.Speech.Synthesis.SpeechSynthesizer
      if (-not $Silent) {
        switch ($InputType)
        {
          'ssml' {
            Write-Verbose '==> Received SSML input'
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
  }
  End {
    if ($IsLinux -is [Bool] -and $IsLinux) {
      Write-Verbose '==> Invoke-Speak was not executed, no output was created'
    } else {
      $TotalText = $TotalText.Trim()
      switch ($Output)
      {
        'file' {
          Write-Verbose '==> [UNDER CONSTRUCTION] save as .WAV file'
        }
        'ssml' {
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
        'text' {
          Write-Output $TotalText
        }
        Default {
          Write-Verbose "==> $TotalText"
        }
      }
    }
  }
}
function New-DailyShutdownJob {
  <#
  .SYNOPSIS
  Create job to shutdown computer at a certain time every day
  .EXAMPLE
  New-DailyShutdownJob -At '22:00'
  #>
  [CmdletBinding()]
  Param(
    [Parameter(Mandatory=$true)]
    [String] $At
  )
  if (Test-Admin) {
    $Trigger = New-JobTrigger -Daily -At $At
    Register-ScheduledJob -Name 'DailyShutdown' -ScriptBlock { Stop-Computer -Force } -Trigger $Trigger
  } else {
    Write-Error '==> New-DailyShutdownJob requires Administrator privileges'
  }
}
function New-File {
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
    New-Item -Path . -Name $Name -ItemType 'file' -Value ''
  }
}
function New-ProxyCommand {
  <#
  .SYNOPSIS
  Create function template for proxy function
  .DESCRIPTION
  This function can be used to create a framework for a proxy function. If you want to create a proxy function for a command named Some-Command,
  you should pass "Some-Command" as the Name attribute - New-ProxyCommand -Name Some-Command
  .EXAMPLE
  New-ProxyCommand -Name 'Out-Default' | Out-File 'Out-Default.ps1'
  .EXAMPLE
  'Invoke-Item' | New-ProxyCommand | Out-File 'Invoke-Item-proxy.ps1'
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
function New-SshKey {
  [CmdletBinding()]
  Param(
    [String] $Name = 'id_rsa'
  )
  Write-Verbose '==> Generating SSH key pair'
  $Path = "~/.ssh/$Name"
  ssh-keygen --% -q -b 4096 -t rsa -N '' -f TEMPORARY_FILE_NAME
  Move-Item -Path TEMPORARY_FILE_NAME -Destination $Path
  Move-Item -Path TEMPORARY_FILE_NAME.pub -Destination "$Path.pub"
  if (Test-Path "$Path.pub") {
    Write-Verbose "==> $Name SSH private key saved to $Path"
    Write-Verbose '==> Saving SSH public key to clipboard'
    Get-Content "$Path.pub" | Set-Clipboard
    Write-Output '==> Public key saved to clipboard'
  } else {
    Write-Error '==> Failed to create SSH key'
  }
}
function Open-Session {
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
    Write-Verbose '==> Using -Credential for authentication'
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
  Write-Verbose '==> Entering session'
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
function Remove-DailyShutdownJob {
  <#
  .SYNOPSIS
  Remove job created with New-DailyShutdownJob
  .EXAMPLE
  Remove-DailyShutdownJob
  #>
  [CmdletBinding()]
  Param()
  if (Test-Admin) {
    Unregister-ScheduledJob -Name 'DailyShutdown'
  } else {
    Write-Error '==> Remove-DailyShutdownJob requires Administrator privileges'
  }
}
function Remove-DirectoryForce {
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
function Rename-FileExtension {
  [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '', Scope='Function')]
  [CmdletBinding(SupportsShouldProcess=$true)]
  Param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [String] $Path,
    [String] $To,
    [Switch] $TXT,
    [Switch] $JPG,
    [Switch] $PNG,
    [Switch] $GIF,
    [Switch] $MD
  )
  Process {
    $NewExtension = if ($To.Length -gt 0) {
      $To
    } else {
      Find-FirstTrueVariable 'TXT','JPG','PNG','GIF','MD'
    }
    $NewName = [System.IO.Path]::ChangeExtension($Path, $NewExtension.ToLower())
    if ($PSCmdlet.ShouldProcess($Path)) {
      Rename-Item -Path $Path -NewName $NewName
      "==> Renamed $Path to $NewName" | Write-Verbose
    } else {
      "==> Rename $Path to $NewName" | Write-Color -Yellow
    }
  }
}
function Take {
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
function Test-Admin {
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
    (whoami) -eq 'root'
  } else {
    ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator) | Write-Output
  }
}
function Test-Empty {
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
function Test-Installed {
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
function Use-Grammar {
  [CmdletBinding()]
  [OutputType([System.Speech.Recognition.SpeechRecognitionEngine])]
  Param(
    [Parameter(Mandatory=$true)]
    [String[]] $Words
  )
  Write-Verbose '==> Creating Speech Recognition Engine'
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
function Use-Speech {
  <#
  .SYNOPSIS
  Load System.Speech type if it is not already loaded.
  #>
  [CmdletBinding()]
  Param()
  if ($IsLinux -is [Bool] -and $IsLinux) {
    Write-Verbose '==> Speech synthesizer can only be used on Windows platform'
  } else {
    $SpeechSynthesizerTypeName = 'System.Speech.Synthesis.SpeechSynthesizer'
    if (-not ($SpeechSynthesizerTypeName -as [Type])) {
      Write-Verbose '==> Adding System.Speech type'
      Add-Type -AssemblyName System.Speech
    } else {
      Write-Verbose '==> System.Speech is already loaded'
    }
  }
}