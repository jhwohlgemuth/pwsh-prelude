.PHONY: validate update publish

validate:
	@powershell Test-ModuleManifest -Path (Join-Path (Get-Location) pwsh-handy-helpers.psd1)

update:
	powershell Install-Module -Name PowerShellGet -RequiredVersion 2.2.1 -Force

allow-tls:
	powershell [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls -bor [Net.SecurityProtocolType]::Tls11 -bor [Net.SecurityProtocolType]::Tls12

publish: validate
	@powershell Publish-Module -Path (Get-Location) -NuGetApiKey $$ENV:NUGET_API_KEY -Verbose