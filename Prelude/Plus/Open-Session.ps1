[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingConvertToSecureStringWithPlainText', '', Scope = 'Function', Target = 'Open-Session')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingPlainTextForPassword', '', Scope = 'Function', Target = 'Open-Session')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUsePSCredentialType', '', Scope = 'Function', Target = 'Open-Session')]
Param()

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

    # Open a prompt for you to input your password
    .EXAMPLE
    $Sessions = Open-Session -ComputerNames ServerA,ServerB
    # This will open a password prompt and then display an interactive console menu to select ServerA or ServerB.

    # $Sessions will point to an array of sessions for ServerA and ServerB and can be used to make new sessions:
    Enter-PSSession -Session $Sessions[1]
    #>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $True, Position = 0, ValueFromPipeline = $True)]
        [String[]] $ComputerNames,
        [SecureString] $Password,
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
            if ($Null -ne $Index) {
                Enter-PSSession -Session $Session[$Index]
            }
        }
    }
    $Session
}