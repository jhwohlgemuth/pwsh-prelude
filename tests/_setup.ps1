[Diagnostics.CodeAnalysis.SuppressMessageAttribute('RequireDirective', '')]
Param(
    [String] $GroupName
)
$Name = 'Prelude'
if (Get-Module -Name $Name) {
    Remove-Module -Name $Name
}
Import-Module "${PSScriptRoot}\..\${Name}"
"==> [INFO] Running tests for ${GroupName}..." | Write-Verbose