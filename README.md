Powershell Handy Helpers Module
===============================
[![CodeFactor](https://www.codefactor.io/repository/github/jhwohlgemuth/pwsh-handy-helpers/badge)](https://www.codefactor.io/repository/github/jhwohlgemuth/pwsh-handy-helpers)
[![Build Status](https://travis-ci.com/jhwohlgemuth/pwsh-handy-helpers.svg?branch=master)](https://travis-ci.com/jhwohlgemuth/pwsh-handy-helpers)
[![PowerShell Gallery Version](https://img.shields.io/powershellgallery/v/pwsh-handy-helpers)](https://www.powershellgallery.com/packages/pwsh-handy-helpers)
> Useful helpers, functions, utilities, wrappers, and aliases for things you might find yourself wanting to do on a somewhat regular basis.

Imagine you are trying to perform some technical task on Windows, like executing commands on remote computers. And then you think:
- It should be easier to enable remoting...
- ...and to execute commands on other computers
- ...by passing idiomatic scriptblocks,
- ...to functions that do stuff like shutdown the remote computer
- ...and speak to me
- ...and other totally reasonable stuff ([see function section](#Functions))

If you have ever had a similar thought train, this module might be for you!

> "It is almost like he just browsed the [awesome-powershell](https://github.com/janikvonrotz/awesome-powershell) repository, read some Powershell scripting blogs, and then added all his favorite functions and aliases into a grab-bag module..."  
*- Probably some people that are reading this README*


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
- Exexute code on a remote computer
```powershell
{ whoami } | irc -ComputerNames PCNAME
```
- Make your computer talk
```powershell
say "Hello World"
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
- `Invoke-Input`
- `Invoke-InsertString`
- `Invoke-Listen`
- `Invoke-Menu`
- `Invoke-MenuDraw`
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
- `Remove-Character`
- `Remove-DailyShutdownJob`
- `Remove-DirectoryForce`
- `Take`
- `Test-Admin`
- `Test-Empty`
- `Test-Installed`
- `Update-MenuSelection`
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
- `input`
- `irc`
- `la`
- `listen`
- `ls`
- `menu`
- `rf`
- `say`
- `touch`
- `tpl`
