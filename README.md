Powershell Prelude <sup>[†](#footnotes)</sup>
==================
[![CodeFactor](https://www.codefactor.io/repository/github/jhwohlgemuth/pwsh-prelude/badge)](https://www.codefactor.io/repository/github/jhwohlgemuth/pwsh-prelude)
[![Build Status](https://travis-ci.com/jhwohlgemuth/pwsh-prelude.svg?branch=master)](https://travis-ci.com/jhwohlgemuth/pwsh-prelude)
[![codecov](https://codecov.io/gh/jhwohlgemuth/pwsh-prelude/branch/master/graph/badge.svg?token=3NMKOGN0Q8)](https://codecov.io/gh/jhwohlgemuth/pwsh-prelude/)
[![PowerShell Gallery Version](https://img.shields.io/powershellgallery/v/pwsh-prelude)](https://www.powershellgallery.com/packages/pwsh-prelude)
> A "standard" library for PowerShell inspired by the preludes of [Haskell](https://hackage.haskell.org/package/base-4.7.0.2/docs/Prelude.html), [ReasonML](https://reazen.github.io/relude/#/), [Rust](https://doc.rust-lang.org/std/prelude/index.html), [Purescript](https://pursuit.purescript.org/packages/purescript-prelude), [Elm](https://github.com/elm/core), [Scala cats/scalaz](https://github.com/fosskers/scalaz-and-cats), and [others](https://lodash.com/docs). It provides useful "*functional-programming-pattern-preferring*" helpers, functions, utilities, wrappers, and aliases for things you might find yourself wanting to do on a somewhat regular basis.

This module is meant to be a generic toolset that you import every time you open a terminal via your Windows Terminal `$PROFILE`. [I certainly do](https://github.com/jhwohlgemuth/env/tree/master/dev-with-windows-terminal). Naturally, it has ***ZERO external dependencies***<sup>[‡](#footnotes)</sup> and (mostly) works on Linux ;)

If you love functional programming patterns, scripting languages, and [ubiquitous terminals](https://docs.microsoft.com/en-us/powershell/scripting/install/installing-powershell-core-on-linux?view=powershell-7)...this module might have something for you!

> "It is almost like he just browsed the [awesome-powershell](https://github.com/janikvonrotz/awesome-powershell) repository, read some Powershell scripting blogs, and then added all his favorite functions and aliases into a grab-bag module..."  
*- Probably some people after reading this README*

Quick Start
-----------

1. Install module
```powershell
Install-Module -Name pwsh-prelude
```

2. Import module
```powershell
Import-Module pwsh-prelude
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
- `ConvertFrom-Pair`
- `ConvertFrom-QueryString`
- `ConvertTo-PowershellSyntax`
- `ConvertTo-Iso8601`
- `ConvertTo-Pair`
- `ConvertTo-QueryString`
- `Enable-Remoting`
- `Find-Duplicate`
- `Find-FirstIndex`
- `Format-MoneyValue`
- `Get-Extremum`
- `Get-Factorial`
- `Get-File`
- `Get-GithubOAuthToken`
- `Get-HostsContent`
- `Get-Maximum`
- `Get-Minimum`
- `Get-Permutation`
- `Get-Screenshot`
- `Get-State`
- `Import-Html`
- `Install-SshServer`
- `Invoke-Chunk`
- `Invoke-DropWhile`
- `Invoke-Flatten`
- `Invoke-FireEvent`
- `Invoke-GetProperty`
- `Invoke-Input`
- `Invoke-InsertString`
- `Invoke-ListenTo`
- `Invoke-ListenForWord`
- `Invoke-Menu`
- `Invoke-Method`
- `Invoke-ObjectInvert`
- `Invoke-ObjectMerge`
- `Invoke-Once`
- `Invoke-Operator`
- `Invoke-PropertyTransform`
- `Invoke-Partition`
- `Invoke-Reduce`
- `Invoke-RemoteCommand`
- `Invoke-RunApplication`
- `Invoke-Speak`
- `Invoke-TakeWhile`
- `Invoke-Tap`
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
- `Update-HostsFile`
- `Use-Grammar`
- `Use-Speech`
- `Use-Web`
- `Write-Color`
- `Write-Label`
- `Write-Title`

Aliases
-------
> Use `Get-Alias <Name>` to see alias details. **Example**: `Get-Alias dra`

```Powershell
# View all pwsh-prelude aliases
Get-Alias | Where-Object { $_.Source -eq 'pwsh-prelude' }
```

Credits
-------
- [Microsoft]() - *[Powershell](https://github.com/powershell/powershell) (d'uh), [Windows Terminal](https://github.com/jhwohlgemuth/env/tree/master/dev-with-windows-terminal), and VS Code (the editor I use)*
- [Pester](https://pester.dev/) - *testing*
- [PSScriptAnalyzer](https://github.com/PowerShell/PSScriptAnalyzer) - *static analysis (linting)*
- [janikvonrotz/awesome-powershell](https://github.com/janikvonrotz/awesome-powershell) - *inspiration*
- [chrisseroka/ps-menu](https://github.com/chrisseroka/ps-menu) - *inspiration*
- [PrateekKumarSingh/Graphical](https://github.com/PrateekKumarSingh/graphical) - *inspiration*
- [mattifestation/PowerShellArsenal](https://github.com/mattifestation/PowerShellArsenal) - *inspiration*
- [PowerShellMafia/PowerSploit](https://github.com/PowerShellMafia/PowerSploit) - *inspiration*
- [Lodash](https://lodash.com/docs/) and [ramdajs](https://ramdajs.com/docs/) - *inspiration*

Footnotes
---------
> ***†*** This module is ***NOT*** an "official" Microsoft Powershell prelude module

> ***‡*** This code was inspired and enabled by [several people and projects](#Credits)