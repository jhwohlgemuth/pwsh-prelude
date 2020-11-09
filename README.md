Powershell Prelude <sup>[[1]](#footnotes)</sup>
==================
[![CodeFactor](https://www.codefactor.io/repository/github/jhwohlgemuth/pwsh-prelude/badge)](https://www.codefactor.io/repository/github/jhwohlgemuth/pwsh-prelude)
[![Build Status](https://travis-ci.com/jhwohlgemuth/pwsh-prelude.svg?branch=master)](https://travis-ci.com/jhwohlgemuth/pwsh-prelude)
[![codecov](https://codecov.io/gh/jhwohlgemuth/pwsh-prelude/branch/master/graph/badge.svg?token=3NMKOGN0Q8)](https://codecov.io/gh/jhwohlgemuth/pwsh-prelude/)
[![PowerShell Gallery Version](https://img.shields.io/powershellgallery/v/pwsh-prelude)](https://www.powershellgallery.com/packages/pwsh-prelude)
> A "standard" library for PowerShell inspired by the preludes of [Haskell](https://hackage.haskell.org/package/base-4.7.0.2/docs/Prelude.html), [ReasonML](https://reazen.github.io/relude/#/), [Rust](https://doc.rust-lang.org/std/prelude/index.html), [Purescript](https://pursuit.purescript.org/packages/purescript-prelude), [Elm](https://github.com/elm/core), [Scala cats/scalaz](https://github.com/fosskers/scalaz-and-cats), and [others](https://lodash.com/docs). It provides useful "*functional-programming-pattern-preferring*" helpers, functions, utilities, wrappers, and aliases for things you might find yourself wanting to do on a somewhat regular basis.

PowerShell is not limited to purely functional programming like Haskell or confined to a browser like Elm. Interacting with the host computer (and other computers) is a large part of PowerShell’s power and purpose. A prelude for PowerShell should be more than “just” a library of utility functions – it should also help “fill the gaps” in the language that one finds after constant use, within and beyond the typical use cases.

This module is meant to be a generic toolset that you import every time you open a terminal via your Windows Terminal `$PROFILE`. [**I certainly do**](https://github.com/jhwohlgemuth/env/tree/master/dev-with-windows-terminal).

Naturally, it has ***ZERO external dependencies***<sup>[[2]](#footnotes)</sup> and (mostly) works on Linux<sup>[[3]](#footnotes)</sup> ;)

If you love functional programming patterns, scripting languages, and [ubiquitous terminals](https://docs.microsoft.com/en-us/powershell/scripting/install/installing-powershell-core-on-linux?view=powershell-7)...this module might have something for you!

> "It is almost like he just browsed the [awesome-powershell](https://github.com/janikvonrotz/awesome-powershell) repository, read some Powershell scripting blogs, and then added all his favorite functions and aliases into a grab-bag module..."  
*- Probably some people after reading this README*

Quick Start
-----------

1. Install module
```Powershell
Install-Module -Name pwsh-prelude
```

2. Import module
```Powershell
Import-Module pwsh-prelude
```

Things You Could Do With Prelude
--------------------------------
> Although `pwsh-prelude` has more than the standard "standard" libary, it still comes packed with functions engineered to enhance script sustainability
- List all permutations of a word
```Powershell
'cat' | Get-Permutation

# or use the "method" format, and make a list
'cat'.Permutation | Join-StringsWithGrammar # "cat, cta, tca, tac, atc, and act"
```
- Perform various operations on strings
```Powershell
$abc = 'b' | insert -To 'ac' -At 2
$abc = 'abcd' | remove -Last
```
- Leverage higher-order functions like reduce to add the first 100 integers (Just like Gauss!)
```Powershell
$Sum = 1..100 | reduce { Param($a, $b) $a + $b }

# or with the -Add switch
$Sum = 1..100 | reduce -Add
```
- Execute code on a remote computer
```Powershell
{ whoami } | irc -ComputerNames PCNAME
```
- Make your computer talk
```Powershell
say 'Hello World'
```
- Make a remote computer talk
```Powershell
{ say 'Hello World' } | irc -ComputerNames PCNAME
```
- Use events to communicate within your script/app
```Powershell
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
```Powershell
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
```Powershell
Get-ChildItem -File | Invoke-Reduce -FileInfo | Show-BarChart
```

Be More Productive
------------------
> `pwsh-prelude` includes a handful of functions and aliases that will make you more productive

- Create a new file
```powershell
touch somefile.txt
```
- Create a new directory and then enter it
```Powershell
take ~/path/to/some/folder
```
- Navigate folders without having to use `cd`
```Powershell
# old busted
cd path/to/some/folder

# new hotness
path/to/some/folder
```
- Find duplicate files (based on hash of content)
```Powershell
Get-Location | Find-Duplicate
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
- `ConvertTo-PlainText`
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
- `Import-Html` <sup>[[3]](#footnotes)</sup>
- `Install-SshServer` <sup>[[3]](#footnotes)</sup>
- `Invoke-Chunk`
- `Invoke-DropWhile`
- `Invoke-Flatten`
- `Invoke-FireEvent`
- `Invoke-GetProperty`
- `Invoke-Input`
- `Invoke-InsertString`
- `Invoke-ListenTo`
- `Invoke-ListenForWord` <sup>[[3]](#footnotes)</sup>
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
- `Invoke-Speak` <sup>[[3]](#footnotes)</sup>
- `Invoke-TakeWhile`
- `Invoke-Tap`
- `Invoke-Unzip`
- `Invoke-WebRequestBasicAuth`
- `Invoke-Zip`
- `Invoke-ZipWith`
- `Join-StringsWithGrammar`
- `New-ApplicationTemplate`
- `New-DailyShutdownJob` <sup>[[3]](#footnotes)</sup>
- `New-File`
- `New-ProxyCommand`
- `New-SshKey`
- `New-Template`
- `Open-Session`
- `Remove-Character`
- `Remove-DailyShutdownJob` <sup>[[3]](#footnotes)</sup>
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
- `Use-Grammar` <sup>[[3]](#footnotes)</sup>
- `Use-Speech` <sup>[[3]](#footnotes)</sup>
- `Use-Web` <sup>[[3]](#footnotes)</sup>
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

Type Extensions
---------------
> For details on how to extend types with `Types.ps1xml` files, see [About Types.ps1xml](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_types.ps1xml?view=powershell-7)

Prelude uses type extensions to provide method versions of most core functions. This may be useful in some situations (or if you just don't feel like using pipelines...)

**Examples**
```Powershell
# Factorials
(4).Factorial # 24

# Permutations as a property (similar property for numbers and arrays)
'cat'.Permutations # 'cat','cta','tca','tac','atc','act'

# Flatten an array
@(1,@(2,3,@(4,5))).Flatten # 1,2,3,4,5

# Reduce an array just like you would in other languages like JavaScript
$Add = { Param($a,$b) $a + $b }
@(1,2,3).Reduce($Add, 0) # 6

```
> For the full list of functions, read through the `ps1xml` files in [`./types`](./types)

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
- [MartinSGill/Profile](https://github.com/MartinSGill/Profile) - *inspiration*
- [Lodash](https://lodash.com/docs/) and [ramdajs](https://ramdajs.com/docs/) - *inspiration*

Footnotes
---------
> ***[1]*** This module is ***NOT*** an "official" Microsoft Powershell prelude module

> ***[2]*** This code was inspired and enabled by [several people and projects](#Credits)

> ***[3]*** The following functions are not supported on Linux:
- `Invoke-ListenForWord`
- `Invoke-Speak`
- `Install-SshServer`
- `Import-Html`
- `New-DailyShutdownJob`
- `Remove-DailyShutdownJob`
- `Use-Grammar`
- `Use-Speech`
- `Use-Web`