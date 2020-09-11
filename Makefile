.PHONY: install publish test validate

publish: validate
	@powershell Publish-Module -Path (Get-Location) -NuGetApiKey $$ENV:NUGET_API_KEY -Verbose

install:
	powershell Update-Module -Name PowerShellGet -Force
	powershell Install-Module -Name Pester -Force

validate:
	@powershell Test-ModuleManifest -Path (Join-Path (Get-Location) pwsh-handy-helpers.psd1)
	@powershell if ((Write-Output $$ENV:NUGET_API_KEY).Length -eq 46) { Write-Output "Valid: NUGET_API_KEY" }

test:
	@powershell Invoke-Pester