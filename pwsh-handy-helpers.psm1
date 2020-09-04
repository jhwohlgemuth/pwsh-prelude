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
  param(
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
  param (
    [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
    [string] $Name
  )
  Get-Item $Name | Get-ChildItem -Recurse | Get-FileHash | Group-Object -Property Hash | Where-Object Count -GT 1 | ForEach-Object {$_.Group | Select-Object Path, Hash} | Write-Output
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
  param(
    [Parameter(Mandatory=$true,Position=0,ValueFromPipeline=$true)]
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
  param()
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
  param()
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
  param(
    [Parameter(Mandatory=$true,Position=0,ValueFromPipeline=$true)]
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
  param()
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
  param()
  docker rmi $(docker images -a -q)
}
function Invoke-GitCommand { git $args }
function Invoke-GitCommit { git commit -vam $args }
function Invoke-GitDiff { git diff $args }
function Invoke-GitPushMaster { git push origin master }
function Invoke-GitStatus { git status -sb }
function Invoke-GitRebase { git rebase -i $args }
function Invoke-GitLog { git log --oneline --decorate }
function Invoke-RemoteCommand
{
  <#
  .SYNOPSIS
  Execute script block on remote computer (like Invoke-Command, but remote)
  .EXAMPLE
  Invoke-RemoteCommand -ComputerName PCNAME -Password 123456 { whoami }
  .EXAMPLE
  { whoami } | Invoke-RemoteCommand -ComputerName PCNAME -Password 123456
  .EXAMPLE
  { whoami } | Invoke-RemoteCommand -ComputerName PCNAME

  This will open a prompt for you to input your password
  #>
  [CmdletBinding()]
  [Alias('irc')]
  [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingPlainTextForPassword", "Password")]
  param(
    [Parameter(Mandatory=$true,Position=0,ValueFromPipelineByPropertyName=$true,ValueFromPipeline=$true)]
    [System.Management.Automation.ScriptBlock] $ScriptBlock,
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
  Write-Verbose "==> Running command on $ComputerName"
  Invoke-Command -ComputerName $ComputerName -Credential $Credential -ScriptBlock $ScriptBlock
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
  param(
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
function New-DailyShutdownJob
{
  <#
  .SYNOPSIS
  Create job to shutdown computer at a certain time every day
  .EXAMPLE
  New-DailyShutdownJob -At "22:00"
  #>
  [CmdletBinding()]
  param(
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
  param (
    [Parameter(Mandatory=$true)]
    [string] $Name
  )
  if (Test-Path $Name) {
    (Get-ChildItem $Name).LastWriteTime = Get-Date
  } else {
    New-Item -Path . -Name $Name -ItemType "file" -Value ""
  }
}
function New-SshKey
{
  [CmdletBinding()]
  param(
    [Parameter()]
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
function Remove-DailyShutdownJob
{
  <#
  .SYNOPSIS
  Remove job created with New-DailyShutdownJob
  .EXAMPLE
  Remove-DailyShutdownJob
  #>
  [CmdletBinding()]
  param()
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
  param (
    [Parameter(Mandatory=$true)]
    [string] $Name
  )
  $Path = Join-Path (Get-Location) $Name
  if (Test-Path $Path) {
    $Cleaned = Resolve-Path $Path
    Write-Verbose "=> Deleting $Cleaned"
    Remove-Item -Path $Cleaned -Recurse
    Write-Verbose "=> Deleted $Cleaned"
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
  param (
    [Parameter(Mandatory=$true)]
    [string] $Name
  )
  $Path = Join-Path (Get-Location) $Name
  if (Test-Path $Path) {
    Write-Verbose "=> $Path exists"
    Write-Verbose "=> Entering $Path"
    Set-Location $Path
  } else {
    Write-Verbose "=> Creating $Path"
    mkdir $Path
    if (Test-Path $Path) {
      Write-Verbose "=> Entering $Path"
      Set-Location $Path
    }
  }
  Write-Verbose "=> pwd is $(Get-Location)"
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
  param ()
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
  param (
    [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
    [string] $Name
  )
  Get-Item $Name | ForEach-Object {$_.psiscontainer -AND $_.GetFileSystemInfos().Count -EQ 0} | Write-Output
}
function Test-Installed
{
  [CmdletBinding()]
  [OutputType([bool])]
  param(
    [string] $Name
  )
  Get-Module -ListAvailable -Name $Name
}
#
# Aliases
#
Set-Alias -Scope Global -Option AllScope -Name la -Value Get-ChildItem
Set-Alias -Scope Global -Option AllScope -Name ls -Value Get-ChildItemColorFormatWide
Set-Alias -Scope Global -Option AllScope -Name g -Value Invoke-GitCommand
Set-Alias -Scope Global -Option AllScope -Name gcam -Value Invoke-GitCommit
Set-Alias -Scope Global -Option AllScope -Name gd -Value Invoke-GitDiff
Set-Alias -Scope Global -Option AllScope -Name glo -Value Invoke-GitLog
Set-Alias -Scope Global -Option AllScope -Name gpom -Value Invoke-GitPushMaster
Set-Alias -Scope Global -Option AllScope -Name grbi -Value Invoke-GitRebase
Set-Alias -Scope Global -Option AllScope -Name gsb -Value Invoke-GitStatus