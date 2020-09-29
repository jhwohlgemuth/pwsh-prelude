@{
    ModuleVersion = '1.0.3.5'
    RootModule = 'pwsh-handy-helpers.psm1'
    GUID = '5af3199a-e01b-4ed6-87ad-fdea39aa7e77'
    CompanyName = 'MyBusiness'
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
        'input',
        'irc',
        'listen',
        'menu',
        'rf',
        'say',
        'touch',
        'tpl'
    )
    FunctionsToExport = @(
        'ConvertTo-PowershellSyntax'
        'Enable-Remoting',
        'Find-Duplicates',
        'Find-FirstIndex',
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
        'Invoke-Input',
        'Invoke-InsertString',
        'Invoke-Listen',
        'Invoke-Menu',
        'Invoke-MenuDraw',
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
        'Remove-Character',
        'Remove-DailyShutdownJob',
        'Remove-DirectoryForce',
        'Take',
        'Test-Admin',
        'Test-Empty',
        'Test-Installed',
        'Update-MenuSelection',
        'Use-Grammar',
        'Use-Speech',
        'Write-Color',
        'Write-Label'
    )
    PrivateData = @{
        PSData = @{
            Tags = @('dev', 'helpers', 'git', 'docker')
            LicenseUri = 'https://github.com/jhwohlgemuth/pwsh-handy-helpers/blob/master/LICENSE'
            ProjectUri = 'https://github.com/jhwohlgemuth/pwsh-handy-helpers'
        }
    }
}
    