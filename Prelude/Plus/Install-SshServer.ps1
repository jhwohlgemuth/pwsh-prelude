function Install-SshServer {
    <#
    .SYNOPSIS
    Install OpenSSH server
    .LINK
    https://docs.microsoft.com/en-us/windows-server/administration/openssh/openssh_install_firstuse
    #>
    [CmdletBinding(SupportsShouldProcess = $True)]
    Param()
    if ($PSCmdlet.ShouldProcess('OpenSSH Server Configuration')) {
        Write-Verbose '==> Enabling OpenSSH server'
        Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0
        Write-Verbose '==> Starting sshd service'
        Start-Service sshd
        Write-Verbose '==> Setting sshd service to start automatically'
        Set-Service -Name sshd -StartupType 'Automatic'
        Write-Verbose '==> Adding firewall rule for sshd'
        New-NetFirewallRule -Name sshd -DisplayName 'OpenSSH Server (sshd)' -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22
    } else {
        '==> Would have added windows OpenSSH.Server capability, started "sshd" service, and added a firewall rule for "sshd"' | Write-Color -DarkGray
    }
}