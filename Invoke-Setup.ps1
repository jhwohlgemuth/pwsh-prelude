[Diagnostics.CodeAnalysis.SuppressMessageAttribute('AdvancedFunctionHelpContent', '')]
[CmdletBinding()]
Param()
function Test-Command {
    Param(
        [Parameter(Mandatory = $True, Position = 0)]
        [String] $Command
    )
    $Result = $False
    $OriginalPreference = $ErrorActionPreference
    $ErrorActionPreference = 'stop'
    try {
        if (Get-Command $Command) {
            $Result = $True
        }
    } Finally {
        $ErrorActionPreference = $OriginalPreference
    }
    $Result
}
if (Test-Command 'dotnet') {
    dotnet tool install -g dotnet-format
}
Install-Module -Force -Scope CurrentUser -Name PSScriptAnalyzer
Install-Module -Force -Scope CurrentUser -Name BuildHelpers
Install-Module -Force -Scope CurrentUser -Name Pester -SkipPublisherCheck -RequiredVersion 5.0.4