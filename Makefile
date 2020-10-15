.PHONY: install lint publish test test-ci validate

publish: validate lint test
	@powershell Publish-Module -Path (Get-Location) -NuGetApiKey $$ENV:NUGET_API_KEY -Verbose

install:
	powershell Update-Module -Name PowerShellGet -Force
	powershell Install-Module -Name Pester -Force

validate:
	@powershell Test-ModuleManifest -Path (Join-Path (Get-Location) pwsh-handy-helpers.psd1)
	@powershell if ((Write-Output $$ENV:NUGET_API_KEY).Length -eq 46) { Write-Output "Valid: NUGET_API_KEY" }

test-ci:
	@powershell '$$results = Invoke-Pester -PassThru; if ($$results.FailedCount -gt 0) { throw "$$($$results.FailedCount) tests failed." }'