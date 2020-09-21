@{
    ModuleVersion = '1.0.2.1'
    RootModule = 'pwsh-handy-helpers.psm1'
    GUID = '5af3199a-e01b-4ed6-87ad-fdea39aa7e77'
    CompanyName = 'Unknown'
    Author = 'Jason Wohlgemuth'
    Copyright = '(c) 2020 Jason Wohlgemuth. All rights reserved.'
    Description = 'Helper functions, aliases and more'
    PowerShellVersion = '5.0'
    FileList = @()
    CmdletsToExport = @()
    VariablesToExport = @()
    AliasesToExport = @(
        '~',
        'dip',
        'dra',
        'drai',
        'irc',
        'rf',
        'say',
        'touch',
        'tpl'
    )
    FunctionsToExport = @(
        'ConvertTo-PowershellSyntax'
        'Enable-Remoting',
        'Find-Duplicates',
        'Get-File',
        'Home',
        'Install-SshServer',
        'Invoke-DockerInspectAddress',
        'Invoke-DockerRemoveAll',
        'Invoke-DockerRemoveAllImages',
        'Invoke-GitCommand',
        'Invoke-GitCommit',
        'Invoke-GitDiff',
        'Invoke-GitPushMaster',
        'Invoke-GitStatus',
        'Invoke-GitRebase',
        'Invoke-GitLog',
        'Invoke-RemoteCommand',
        'Invoke-Speak',
        'Join-StringsWithGrammar',
        'New-DailyShutdownJob',
        'New-File',
        'New-ProxyCommand',
        'New-SshKey',
        'New-Template',
        'Open-Session',
        'Out-Default',
        'Remove-DailyShutdownJob',
        'Remove-DirectoryForce',
        'Take',
        'Test-Admin',
        'Test-Empty',
        'Test-Installed'
    )
    PrivateData = @{
        PSData = @{
            Tags = @('dev', 'helpers', 'git', 'docker')
            LicenseUri = 'https://github.com/jhwohlgemuth/pwsh-handy-helpers/blob/master/LICENSE'
            ProjectUri = 'https://github.com/jhwohlgemuth/pwsh-handy-helpers'
        }
    }
}
    