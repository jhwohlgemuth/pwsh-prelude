@{
    ModuleVersion = '1.0.4.2'
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
        'insert',
        'irc',
        'listenFor',
        'listenTo',
        'menu',
        'on',
        'reduce',
        'repeat',
        'rf',
        'say',
        'title',
        'touch',
        'tpl'
    )
    FunctionsToExport = @(
        'ConvertTo-PowershellSyntax'
        'Enable-Remoting',
        'Find-Duplicate',
        'Find-FirstIndex',
        'Get-File',
        'Home',
        'Install-SshServer',
        'Invoke-DockerInspectAddress',
        'Invoke-DockerRemoveAll',
        'Invoke-DockerRemoveAllImage',
        'Invoke-GitCommand',
        'Invoke-GitCommit',
        'Invoke-GitDiff',
        'Invoke-GitPushMaster',
        'Invoke-GitStatus',
        'Invoke-GitRebase',
        'Invoke-GitLog',
        'Invoke-Input',
        'Invoke-InsertString',
        'Invoke-ListenTo',
        'Invoke-ListenForWord',
        'Invoke-Menu',
        'Invoke-Once',
        'Invoke-Reduce',
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
        'Show-BarChart',
        'Take',
        'Test-Admin',
        'Test-Empty',
        'Test-Equal',
        'Test-Installed',
        'Use-Grammar',
        'Use-Speech',
        'Write-Color',
        'Write-Label',
        'Write-Repeat',
        'Write-Title'
    )
    PrivateData = @{
        PSData = @{
            Tags = @('dev', 'helpers', 'git', 'docker')
            LicenseUri = 'https://github.com/jhwohlgemuth/pwsh-handy-helpers/blob/master/LICENSE'
            ProjectUri = 'https://github.com/jhwohlgemuth/pwsh-handy-helpers'
        }
    }
}
