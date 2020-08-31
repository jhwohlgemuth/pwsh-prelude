.PHONY: publish update validate

publish: validate
	@powershell Publish-Module -Path (Get-Location) -NuGetApiKey $$ENV:NUGET_API_KEY -Verbose -Exclude "Makefile","README.md",".vscode/settings.json"

update:
	powershell Update-Module -Name PowerShellGet

validate:
	@powershell Test-ModuleManifest -Path (Join-Path (Get-Location) pwsh-handy-helpers.psd1)
	@powershell if ((Write-Output $$ENV:NUGET_API_KEY).Length -eq 46) { Write-Output "Valid: NUGET_API_KEY" }