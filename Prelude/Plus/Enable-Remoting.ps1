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
        [String] $TrustedHosts = '*',
        [Switch] $PassThru
    )
    if (Test-Admin) {
        '==> [INFO] Making network private' | Write-Verbose
        Get-NetConnectionProfile | Set-NetConnectionProfile -NetworkCategory Private
        $Path = 'WSMan:\localhost\Client\TrustedHosts'
        '==> [INFO] Enabling Powershell remoting' | Write-Verbose
        Enable-PSRemoting -Force -SkipNetworkProfileCheck
        '==> [INFO] Updated trusted hosts' | Write-Verbose
        Set-Item $Path -Value $TrustedHosts -Force
        if ($PassThru) {
            return Get-Item $Path
        }
    } else {
        '==> [ERROR] Enable-Remoting requires Administrator privileges' | Write-Error
    }
}