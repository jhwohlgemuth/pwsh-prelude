Powershell Handy Helpers Module
===============================
[![CodeFactor](https://www.codefactor.io/repository/github/jhwohlgemuth/pwsh-handy-helpers/badge)](https://www.codefactor.io/repository/github/jhwohlgemuth/pwsh-handy-helpers)
[![Build Status](https://travis-ci.com/jhwohlgemuth/pwsh-handy-helpers.svg?branch=master)](https://travis-ci.com/jhwohlgemuth/pwsh-handy-helpers)
[![PowerShell Gallery Version](https://img.shields.io/powershellgallery/v/pwsh-handy-helpers)](https://www.powershellgallery.com/packages/pwsh-handy-helpers)
> Useful functions and aliases for everyday development tasks

Quick Start
-----------

1. Install module
```powershell
Install-Module -Name pwsh-handy-helpers
```

2. Import module
```powershell
Import-Module pwsh-handy-helpers
```

Examples
--------
- Create a new file
```powershell
touch somefile.txt
```
- Create a new directory and then enter it
```powershell
take ~/path/to/some/folder
```
- Navigate folders without having to use `cd`
```powershell
# old busted
cd path/to/some/folder

# new hotness
path/to/some/folder
```

### And much more! Check out the [functions](#Functions) and [aliases](#Aliases) sections below for details

Functions
---------
> Use `Get-Help <Function-Name>` to see usage details. **Example**: `Get-Help Find-Duplicates -examples`

- `ConvertTo-PowershellSyntax`
- `Enable-Remoting`
- `Find-Duplicates`
- `Find-FirstIndex`
- `Get-File`
- `Install-SshServer`
- `Invoke-Listen`
- `Invoke-RemoteCommand`
- `Invoke-Speak`
- `Join-StringsWithGrammar`
- `New-DailyShutdownJob`
- `New-File`
- `New-ProxyCommand`
- `New-SshKey`
- `New-Template`
- `Open-Session`
- `Out-Default`
- `Remove-DailyShutdownJob`
- `Remove-DirectoryForce`
- `Take`
- `Test-Admin`
- `Test-Empty`
- `Test-Installed`
- `Use-Grammar`
- `Use-Speech`
- `Write-Color`

Aliases
-------
> Use `Get-Alias <Name>` to see alias details. **Example**: `Get-Alias dra`

- `~`
- `dip`
- `dra`
- `drai`
- `g`
- `gcam`
- `gd`
- `gpom`
- `grbi`
- `gsb`
- `irc`
- `la`
- `listen`
- `ls`
- `rf`
- `say`
- `touch`
- `tpl`
