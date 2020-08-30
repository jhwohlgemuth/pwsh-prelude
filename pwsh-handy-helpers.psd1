@{
    ModuleVersion = '1.0.0.0'
    RootModule = 'pwsh-handy-helpers.psm1'
    GUID = 'bb889cc0-6f40-45e9-b9e8-52faf745e6d82'
    CompanyName = 'Unknown'
    Author = 'Jason Wohlgemuth'
    Copyright = '(c) 2020 Jason Wohlgemuth. All rights reserved.'
    Description = 'Helper functions, aliases and more'
    PowerShellVersion = '5.0'
    FileList = @()
    CmdletsToExport = @()
    VariablesToExport = @()
    AliasesToExport = @()
    FunctionsToExport = @(
        'Find-Duplicates',
        'Get-File',
        'Install-SshServer',
        'New-File',
        'New-SshKey',
        'Remove-DirectoryForce',
        'Take',
        'Test-Admin',
        'Test-Empty',
        'Test-Installed',
    )
    PrivateData = @{
        PSData = @{
            Tags = @('helpers')
            LicenseUri = 'https://github.com/jhwohlgemuth/pwsh-handy-helpers/blob/master/LICENSE'
            ProjectUri = 'https://github.com/jhwohlgemuth/pwsh-handy-helpers'
        }
    }
}
    