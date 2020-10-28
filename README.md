Powershell Prelude <sup>[†](#footnotes)</sup>
==================
[![CodeFactor](https://www.codefactor.io/repository/github/jhwohlgemuth/pwsh-handy-helpers/badge)](https://www.codefactor.io/repository/github/jhwohlgemuth/pwsh-handy-helpers)
[![Build Status](https://travis-ci.com/jhwohlgemuth/pwsh-handy-helpers.svg?branch=master)](https://travis-ci.com/jhwohlgemuth/pwsh-handy-helpers)
[![codecov](https://codecov.io/gh/jhwohlgemuth/pwsh-handy-helpers/branch/master/graph/badge.svg?token=3NMKOGN0Q8)](https://codecov.io/gh/jhwohlgemuth/pwsh-handy-helpers/)
[![PowerShell Gallery Version](https://img.shields.io/powershellgallery/v/pwsh-handy-helpers)](https://www.powershellgallery.com/packages/pwsh-handy-helpers)
> A "standard" library for PowerShell inspired by the preludes of [Haskell](https://hackage.haskell.org/package/base-4.7.0.2/docs/Prelude.html), [ReasonML](https://reazen.github.io/relude/#/), [Rust](https://doc.rust-lang.org/std/prelude/index.html), [Purescript](https://pursuit.purescript.org/packages/purescript-prelude), [Elm](https://github.com/elm/core), [Scala cats/scalaz](https://github.com/fosskers/scalaz-and-cats), and [others](https://lodash.com/docs). It provides useful "*functional-programming-pattern-preferring*" helpers, functions, utilities, wrappers, and aliases for things you might find yourself wanting to do on a somewhat regular basis.

This module is meant to be a generic tool that you add to your Windows Terminal `$PROFILE`. [I certainly do](https://github.com/jhwohlgemuth/env/tree/master/dev-with-windows-terminal). Obviously, it has ***ZERO external dependencies*** ;)

If you love functional programming patterns, scripting languages, and [ubiquitous terminals](https://docs.microsoft.com/en-us/powershell/scripting/install/installing-powershell-core-on-linux?view=powershell-7)...this module might have something for you!

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
- Find duplicate files (based on hash of content)
```powershell
Get-Location | Find-Duplicate
```
- Perform various operations on strings
```powershell
$abc = 'b' | insert -To 'ac' -At 2
$abc = 'abcd' | remove -Last
```
- Leverage higher-order functions like reduce to add the first 100 integers (Just like Gauss!)
```powershell
$Sum = 1..100 | reduce -Callback { Param($a, $b) $a + $b } -InitialValue 0

# or with the -Add switch
$Sum = 1..100 | reduce -Add -InitialValue 0
```
- Exexute code on a remote computer
```powershell
{ whoami } | irc -ComputerNames PCNAME
```
- Make your computer talk
```powershell
say 'Hello World'
```
- Make a remote computer talk
```powershell
{ say 'Hello World' } | irc -ComputerNames PCNAME
```
- Use events to communicate within your script/app
```powershell
{ 'Event triggered' | Write-Color -Red } | on 'SomeEvent'

# You can even listen to variables!!!
# Declare a value for boot
$boot = 42
# Create a callback
$Callback = {
  $Data = $Event.MessageData
  say "$($Data.Name) was changed from $($Data.OldValue), to $($Data.Value)"
}
# Start the variable listener
$Callback | listenTo 'boot' -Variable
# Change the value of boot and have your computer tell you what changed
$boot = 43
```
- Create a form in the terminal (see the [./kitchensink.ps1](./kitchensink.ps1) for another example)
```powershell
'Example' | Write-Title
$Fullname = input 'Full Name?' -Indent 4
$Username = input 'Username?' -MaxLength 10 -Indent 4
$Age = input 'Age?' -Number -Indent 4
$Pass = input 'Password?' -Secret -Indent 4
$Word = input 'Favorite Saiya-jin?' -Autocomplete -Indent 4 -Choices @('Goku','Gohan','Goten','Vegeta','Trunks')
'Favorite number?' | Write-Label -Indent 4 -NewLine
$Choice = menu @('one'; 'two'; 'three') -Indent 4
```
- Visualize file sizes in a directory with one line of code!
```powershell
Get-ChildItem -File | Invoke-Reduce -FileInfo | Show-BarChart
```

### And much more! Check out the [functions](#Functions) and [aliases](#Aliases) sections below for details

Functions
---------
> Use `Get-Help <Function-Name>` to see usage details. **Example**: `Get-Help Find-Duplicates -examples`

- `ConvertFrom-ByteArray`
- `ConvertFrom-Html`
- `ConvertFrom-QueryString`
- `ConvertTo-PowershellSyntax`
- `ConvertTo-Iso8601`
- `ConvertTo-QueryString`
- `Enable-Remoting`
- `Find-Duplicate`
- `Find-FirstIndex`
- `Format-MoneyValue`
- `Get-File`
- `Get-GithubOAuthToken`
- `Get-State`
- `Import-Html`
- `Install-SshServer`
- `Invoke-DropWhile`
- `Invoke-FireEvent`
- `Invoke-GetProperty`
- `Invoke-Input`
- `Invoke-InsertString`
- `Invoke-ListenTo`
- `Invoke-ListenForWord`
- `Invoke-Menu`
- `Invoke-Method`
- `Invoke-Once`
- `Invoke-Operator`
- `Invoke-PropertyTransform`
- `Invoke-Reduce`
- `Invoke-RemoteCommand`
- `Invoke-RunApplication`
- `Invoke-Speak`
- `Invoke-TakeWhile`
- `Invoke-WebRequestBasicAuth`
- `Invoke-Zip`
- `Invoke-ZipWith`
- `Join-StringsWithGrammar`
- `New-ApplicationTemplate`
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
- `Remove-Indent`
- `Rename-FileExtension`
- `Save-State`
- `Show-BarChart`
- `Take`
- `Test-Admin`
- `Test-Empty`
- `Test-Equal`
- `Test-Installed`
- `Use-Grammar`
- `Use-Speech`
- `Use-Web`
- `Write-Color`
- `Write-Label`
- `Write-Title`

Aliases
-------
> Use `Get-Alias <Name>` to see alias details. **Example**: `Get-Alias dra`

- `~`
- `basicauth`
- `dip`
- `dra`
- `drai`
- `dropWhile`
- `equal`
- `g`
- `gcam`
- `gd`
- `gpom`
- `grbi`
- `gsb`
- `input`
- `insert`
- `irc`
- `la`
- `listenFor`
- `listenTo`
- `ls`
- `menu`
- `method`
- `on`
- `op`
- `prop`
- `reduce`
- `remove`
- `repeat`
- `rf`
- `say`
- `takeWhile`
- `touch`
- `tpl`
- `transform`
- `trigger`


Footnotes
---------
> ***†*** This module is ***NOT*** an "official" Microsoft Powershell prelude module