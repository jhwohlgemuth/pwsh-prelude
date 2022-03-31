[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingConvertToSecureStringWithPlainText', '', Scope = 'Function', Target = 'Invoke-RemoteCommand')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingPlainTextForPassword', '', Scope = 'Function', Target = 'Invoke-RemoteCommand')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUsePSCredentialType', '', Scope = 'Function', Target = 'Invoke-RemoteCommand')]
Param()

function Invoke-RemoteCommand {
    <#
    .SYNOPSIS
    Lightweight wrapper function for Invoke-Command that simplifies the interface and allows for using a string password directly
    .PARAMETER Parameters
    Object to pass parameters to underlying Invoke-Command call (ex: -Parameters @{ HideComputerName = $True })
    .EXAMPLE
    Invoke-RemoteCommand -ComputerNames PCNAME -Password 123456 { whoami }
    .EXAMPLE
    { whoami } | Invoke-RemoteCommand -ComputerNames PCNAME -Password 123456
    .EXAMPLE
    # This will open a prompt for you to input your password
    { whoami } | Invoke-RemoteCommand -ComputerNames PCNAME
    .EXAMPLE
    # Use the "irc" alias and execute commands on multiple computers!
    { whoami } | irc -ComputerNames Larry,Moe,Curly
    .EXAMPLE
    Get-Credential | Export-CliXml -Path .\crendential.xml
    { whoami } | Invoke-RemoteCommand -Credential (Import-Clixml -Path .\credential.xml) -ComputerNames PCNAME -Verbose
    .EXAMPLE
    irc '.\path\to\script.ps1'
    .EXAMPLE
    { Get-Process } | irc -Name Mario -Parameters @{ HideComputerName = $True }
    #>
    [CmdletBinding(DefaultParameterSetName = 'scriptblock')]
    [Alias('irc')]
    Param(
        [Parameter(ParameterSetName = 'scriptblock', Mandatory = $True, Position = 0, ValueFromPipeline = $True)]
        [ScriptBlock] $ScriptBlock,
        [Parameter(ParameterSetName = 'file', Mandatory = $True, Position = 0)]
        [ValidateScript( { Test-Path $_ })]
        [String] $FilePath,
        [Parameter(ParameterSetName = 'scriptblock', Mandatory = $True)]
        [Parameter(ParameterSetName = 'file', Mandatory = $True)]
        [Alias('Name')]
        [String[]] $ComputerName,
        [Parameter(ParameterSetName = 'scriptblock')]
        [Parameter(ParameterSetName = 'file')]
        [SecureString] $Password,
        [Parameter(ParameterSetName = 'scriptblock')]
        [Parameter(ParameterSetName = 'file')]
        [PSObject] $Credential,
        [Parameter(ParameterSetName = 'scriptblock')]
        [Parameter(ParameterSetName = 'file')]
        [Switch] $AsJob,
        [Parameter(ParameterSetName = 'scriptblock')]
        [Parameter(ParameterSetName = 'file')]
        [PSObject] $Parameters = @{}
    )
    $User = whoami
    if ($Credential) {
        '==> Using -Credential for authentication' | Write-Verbose
        $Cred = $Credential
    } elseif ($Password) {
        "==> Creating credential for $User using -Password" | Write-Verbose
        $Pass = ConvertTo-SecureString -String $Password -AsPlainText -Force
        $Cred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $User, $Pass
    } else {
        $Cred = Get-Credential -Message "Please provide password to access $(Join-StringsWithGrammar $ComputerName)" -User $User
    }
    "==> Running command on $(Join-StringsWithGrammar $ComputerName)" | Write-Verbose
    $Execute = if ($FilePath) {
        @{ FilePath = $FilePath }
    } else {
        @{ ScriptBlock = $ScriptBlock }
    }
    Invoke-Command -ComputerName $ComputerName -Credential $Cred -AsJob:$AsJob @Execute @Parameters
}