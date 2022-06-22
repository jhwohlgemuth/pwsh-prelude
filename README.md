PowerShell Prelude <sup>[1](#1)</sup>
==================
[![CodeFactor](https://www.codefactor.io/repository/github/jhwohlgemuth/pwsh-prelude/badge?style=for-the-badge "Code Quality")](https://www.codefactor.io/repository/github/jhwohlgemuth/pwsh-prelude)
[![AppVeyor branch](https://img.shields.io/appveyor/build/jhwohlgemuth/Prelude/master?logo=appveyor&style=for-the-badge "Appveyor Build Status")](https://ci.appveyor.com/project/jhwohlgemuth/Prelude)
[![Code Coverage](https://img.shields.io/codecov/c/github/jhwohlgemuth/pwsh-prelude/master?style=for-the-badge&token=3NMKOGN0Q8&logo=codecov "Codecov Code Coverage")](https://codecov.io/gh/jhwohlgemuth/pwsh-prelude/)
[![PowerShell Gallery Version](https://img.shields.io/powershellgallery/v/Prelude?label=version&style=for-the-badge&logo=powershell "PowerShell Gallery Version")](https://www.powershellgallery.com/packages/Prelude)
[![Code Size](https://img.shields.io/github/languages/code-size/jhwohlgemuth/pwsh-prelude.svg?style=for-the-badge)](#quick-start)
> A "standard" library for PowerShell inspired by the preludes of [Haskell](https://hackage.haskell.org/package/base-4.7.0.2/docs/Prelude.html), [ReasonML](https://reazen.github.io/relude/#/), [Rust](https://doc.rust-lang.org/std/prelude/index.html), [Purescript](https://pursuit.purescript.org/packages/purescript-prelude), [Elm](https://github.com/elm/core), [Scala cats/scalaz](https://github.com/fosskers/scalaz-and-cats), and [others](https://lodash.com/docs). It provides useful helpers, functions, utilities, wrappers, [type accelerators](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_type_accelerators?view=powershell-7.1), and aliases for things you might find yourself wanting to do on a somewhat regular basis - from meta-programming to linear algebra.

Getting Started
---------------

1. Open PowerShell prompt (or [Windows Terminal app](https://www.microsoft.com/en-us/p/windows-terminal/9n0dx20hk701?activetab=pivot:overviewtab))

2. Install Prelude module via [PowerShell Gallery](https://www.powershellgallery.com/)
```PowerShell
Install-Module -Name Prelude -Scope CurrentUser
```

2. **[ALTERNATIVE]** Download this repo and save the [./Prelude](./Prelude) folder to your modules directory. You can list your module directories by executing `$Env:PSModulePath -split ';'` in your PowerShell terminal. Choose one that suits your needs and permissions.

3. Import Prelude into current context
```PowerShell
Import-Module -Name Prelude
```

> **Note**
> For scripts, add `#Requires -Modules Prelude` to the top of your file - the "Requires" directive will prevent your script from running without the required module dependencies ([reference](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_requires?view=powershell-7.1))

What is Prelude?
----------------
> Are you new to PowerShell? If so, please look through [this presentation](https://powershell.surge.sh) for a quick introduction to the merits and magic of PowerShell and how Prelude makes it even better.  If you are already familiar with another language (like Python or JavaScript), you can look at these [comparisons of Prelude to other popular languages, libraries, and tools](./examples/Compare.md).

PowerShell is not limited to purely functional programming like Haskell or confined to a browser like Elm. Interacting with the host computer (and other computers) is a large part of PowerShell’s power and purpose. A prelude for PowerShell should be more than “just” a library of utility functions – it should also help “fill the gaps” in the language that one finds after constant use, within and beyond<sup>[5](#5)</sup> the typical use cases. Use cases are varied and include:
- Linear algebra, graph theory, and statistics
- Data shaping, analysis, and visualization
- Local and remote automation
- Creating command line [user interfaces](./kitchensink.ps1)
- PowerShell meta-programming
- **See the [examples folder](./examples) for detailed examples**

> "It is almost like someone just browsed the [awesome-powershell](https://github.com/janikvonrotz/awesome-powershell) repository, read some PowerShell scripting blogs, wrote some C# versions of algorithms, and then added all their favorite functions and aliases into a grab-bag module..."  
*- Anonymous*

So what, big deal, who cares?
-----------------------------

This module provides [data types](#type-accelerators) and patterns for scripting within a [ubiquitous terminal environment](https://docs.microsoft.com/en-us/powershell/scripting/install/installing-powershell-core-on-linux?view=powershell-7). Prelude enables complex analysis, strives to make your scripts more sustainable, encourages you to put away the black boxes<sup>[6](#6)</sup>, and empowers you to take control of your productivity. It works almost everywhere and can be "installed"<sup>[7](#7)</sup> without system/administrator/root privileges.

> **Note**
> For maximum effectiveness, it is recommended that you add `Import-Module -Name Prelude` to your Windows Terminal `$PROFILE`. [**I certainly do**](https://github.com/jhwohlgemuth/env/tree/master/dev-with-windows-terminal).

Naturally, it has ***ZERO external dependencies***<sup>[2](#2)</sup> and (mostly) works on Linux<sup>[3](#3)</sup> ;)

Things You Can Do With Prelude
------------------------------
> Although `Prelude` has more than the standard "standard" libary, it still comes packed with functions engineered to enhance script sustainability

- List all permutations of a word
```PowerShell
'cat' | Get-Permutation

# or use the "method" format, and make a list
'cat'.Permutations() | Join-StringsWithGrammar # "cat, cta, tca, tac, atc, and act"
```
- Perform various operations on strings
```PowerShell
$Abc = 'b' | insert -To 'ac' -At 2
$Abc = 'abcd' | remove -Last
```
- Create templates for easy repetitive string interpolation using handlebars syntax
    <div align="center">
      <a href="#"><img alt="Templates are easy and can be nested!" src="http://www.jasonwohlgemuth.com/pwsh-prelude/images/template.gif" alt="String interpolation templates" width="1280"/></a>
    </div>
- Leverage higher-order functions like reduce to add the first 100 integers (Just like Gauss!)
```PowerShell
$Sum = 1..100 | reduce { Param($A, $B) $A + $B }

# or with the -Add switch
$Sum = 1..100 | reduce -Add
```
- Execute code on a remote computer
```PowerShell
{ whoami } | irc -ComputerNames PCNAME
```
- Make your computer talk <sup>[3](#3)</sup>
```PowerShell
say 'Hello World'
```
- Make a remote computer talk
```PowerShell
{ say 'Hello World' } | irc -ComputerNames PCNAME
```
- Use events to communicate within your script/app
```PowerShell
{ 'Event triggered' | Write-Color -Red } | on 'SomeEvent'

# You can even listen to variables!!!
# Declare a value for boot
$Boot = 42
# Create a callback
$Callback = {
  $Data = $Event.MessageData
  say "$($Data.Name) was changed from $($Data.OldValue), to $($Data.Value)"
}
# Start the variable listener
$Callback | listenTo 'Boot' -Variable
# Change the value of boot and have your computer tell you what changed
$Boot = 43
```
-  Quickly create complext UI elements like paginated multi-select menus
    <div align="center">
      <a href="#"><img alt="Batteries include user input" src="http://www.jasonwohlgemuth.com/pwsh-prelude/images/multiselect.gif" alt="Multi-select Menu" width="1280"/></a>
    </div>

- Create a full form in the terminal (see the [./kitchensink.ps1](./kitchensink.ps1) for a more complete example)
```PowerShell
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
```PowerShell
Get-ChildItem -File | Invoke-Reduce -FileInfo | Write-BarChart
```

Be More Productive
------------------
> `Prelude` includes a handful of functions and aliases that will make you more productive

- Create a new file
```powershell
touch somefile.txt
```
- Create a new directory and then enter it
```PowerShell
take ~/path/to/some/folder
```
- Save screenshots
```PowerShell
# ...all monitors
screenshot
#...or just one
2 | screenshot
```
- Find duplicate files (based on hash of content)
```PowerShell
Get-Location | Find-Duplicate
```
- Print out file/folder structure of a directory (like `tree`)
```PowerShell
ConvertFrom-FolderStructure | Out-Tree
```

- Identify bad links using your browser bookmarks export
```PowerShell
'bookmarks.html' | Import-Html | Get-HtmlElement 'a' | prop 'href' | ? { -not (Test-Url $_) }
```

### **And then...**
- Use complex values
- Calculate matrix inverses
- Solve linear systems
- Calculate multiple matrix norms
- Compute eignenvalues and eigenvectors
- ...and more!

Functions
---------
> List all functions with `Get-Command -Module Prelude -CommandType Function`. Use `Get-Help <Function-Name>` to see usage details.

<details>
  <summary>list of functions</summary>
  
  - `Add-Metadata`
  - `ConvertFrom-Base64`
  - `ConvertFrom-ByteArray`
  - `ConvertFrom-EpochDate`
  - `ConvertFrom-Html`
  - `ConvertFrom-FolderStructure`
  - `ConvertFrom-Pair`
  - `ConvertFrom-QueryString`
  - `ConvertTo-AbstractSyntaxTree`
  - `ConvertTo-Base64`
  - `ConvertTo-Degree`
  - `ConvertTo-Html`
  - `ConvertTo-PowerShellSyntax`
  - `ConvertTo-Iso8601`
  - `ConvertTo-JavaScript`
  - `ConvertTo-OrderedDictionary`
  - `ConvertTo-Pair`
  - `ConvertTo-PlainText`
  - `ConvertTo-QueryString`
  - `ConvertTo-Radian`
  - `Deny-Empty`
  - `Deny-Null`
  - `Deny-Value`
  - `Enable-Remoting`
  - `Find-Duplicate`
  - `Find-FirstIndex`
  - `Format-ComplexValue`
  - `Format-Json`
  - `Format-MoneyValue`
  - `Get-Covariance`
  - `Get-DefaultBrowser`
  - `Get-Extremum`
  - `Get-Factorial`
  - `Get-GithubOAuthToken`
  - `Get-HostsContent`
  - `Get-HtmlElement`
  - `Get-LogisticSigmoid`
  - `Get-Maximum`
  - `Get-Minimum`
  - `Get-ParameterList`
  - `Get-Permutation`
  - `Get-Plural`
  - `Get-Property`
  - `Get-Screenshot`
  - `Get-Singular`
  - `Get-Softmax`
  - `Get-State`
  - `Get-StateName`
  - `Get-StringPath`
  - `Get-SyllableCount`
  - `Get-Variance`
  - `Import-Excel`
  - `Import-Html` <sup>[3](#3)</sup>
  - `Import-Raw`
  - `Install-SshServer`
  - `Invoke-Chunk`
  - `Invoke-DropWhile`
  - `Invoke-Flatten`
  - `Invoke-FireEvent`
  - `Invoke-GoogleSearch`
  - `Invoke-Imputation`
  - `Invoke-Input`
  - `Invoke-InsertString`
  - `Invoke-ListenTo`
  - `Invoke-ListenForWord` <sup>[3](#3)</sup>
  - `Invoke-MatrixMap`
  - `Invoke-Menu`
  - `Invoke-Method`
  - `Invoke-NewDirectoryAndEnter`
  - `Invoke-Normalize`
  - `Invoke-NpmInstall`
  - `Invoke-ObjectInvert`
  - `Invoke-ObjectMerge`
  - `Invoke-Once`
  - `Invoke-Operator`
  - `Invoke-Pack`
  - `Invoke-Partition`
  - `Invoke-Pick`
  - `Invoke-PropertyTransform`
  - `Invoke-Reduce`
  - `Invoke-Repeat`
  - `Invoke-RemoteCommand`
  - `Invoke-RunApplication`
  - `Invoke-Speak` <sup>[3](#3)</sup>
  - `Invoke-TakeWhile`
  - `Invoke-Tap`
  - `Invoke-Unpack`
  - `Invoke-Unzip`
  - `Invoke-WebRequestBasicAuth`
  - `Invoke-Zip`
  - `Invoke-ZipWith`
  - `Join-StringsWithGrammar`
  - `Measure-Performance`
  - `Measure-Readability`
  - `New-ComplexValue`
  - `New-DailyShutdownJob`
  - `New-DesktopApplication`
  - `New-File`
  - `New-Template`
  - `New-TerminalApplicationTemplate`
  - `New-WebApplication`
  - `Open-Session`
  - `Out-Browser`
  - `Out-Tree`
  - `Remove-Character`
  - `Remove-DailyShutdownjob`
  - `Remove-DirectoryForce`
  - `Remove-Indent`
  - `Rename-FileExtension`
  - `Save-File`
  - `Save-JsonData`
  - `Save-State`
  - `Save-TemplateData`
  - `Test-Admin`
  - `Test-ApplicationContext`
  - `Test-Command`
  - `Test-DiagonalMatrix`
  - `Test-Empty`
  - `Test-Enumerable`
  - `Test-Equal`
  - `Test-Installed`
  - `Test-Matrix`
  - `Test-SquareMatrix`
  - `Test-SymmetricMatrix`
  - `Test-Url`
  - `Update-Application`
  - `Update-HostsFile`
  - `Use-Grammar` <sup>[3](#3)</sup>
  - `Use-Speech` <sup>[3](#3)</sup>
  - `Use-Web` <sup>[3](#3)</sup>
  - `Write-BarChart`
  - `Write-Color`
  - `Write-Label`
  - `Write-Status`
  - `Write-Title`
  
</details>

Aliases
-------
> Use `Get-Alias <Name>` to see alias details. **Example**: `Get-Alias dra`

```PowerShell
# View all Prelude aliases
Get-Alias | Where-Object { $_.Source -eq 'Prelude' }
```

Type Accelerators
-----------------
- `[Complex]`
  > Shortcut for `System.Numerics.Complex` provided for convenience
  ```PowerShell
  $C = [Complex]::New(1, 7)

  # ...or use the helper function
  $C = complex 1 7

  # Complex values have a custom format ps1xml file
  # simply return a complex value to see the beauty
  $C

  # ...or format complex values for us in your scripts
  $C | Format-ComplexValue -WithColor | Write-Label
  ```

  > **Note**
  > Full class name is `System.Numerics.Complex`

- `[Coordinate]`
  > Class for working with geodetic and cartesian earth coordinate values.
  ```PowerShell
  $Omaha = [Coordinate]@{ latitude = 41.25; longitude = -96 }
  $Omaha.ToString()
  # 41°15'0"N 96°0'0"W

  $Omaha.ToCartesian()
  # -501980.225469305, -4776022.81392779, 4183337.21339675

  # Calculate distance between two points on the earth
  $SanDiego = [Coordinate]@{ latitude = 32.7157 ; longitude = -117.1611 }
  $Distance = $Omaha - $SanDiego
  # Distance = 2097705.740066118 (meters)
  ```

  > **Note**
  > Full class name is `Prelude.Geodetic.Coordinate`

- `[Datum]`
  > Namespace for geodetic constants
  ```PowerShell
  [Datum]::Radius | Write-Color -Cyan
  # output 6371001
  ```

  > **Note**
  > Full class name is `Prelude.Geodetic.Datum`

- `[Matrix]`
  > Perform all kinds of matrix math. Tested on multiple math books - 100% Guaranteed to make homework easier<sup>[4](#4)</sup>

  <div align="center">
      <a href="#"><img alt="Matrix arithmetic is so easy!" src="http://www.jasonwohlgemuth.com/pwsh-prelude/images/matrix.gif" alt="Matrix math!" width="1280"/></a>
  </div>

  ```PowerShell
  $A = [Matrix]::New(3)
  $A.Rows = 1..9

  # ...or use the helper function
  $A = 1..9 | matrix 3,3

  # ...and then do math!
  $A.Det() -eq 0 # true, looks like this matrix isn't going to have an inverse!

  # ...and more math
  $B = 2 * $A
  $Product = $A * $B
  $Sum = $A + $B
  $IsEqual = $A -eq $B # $IsEqual is False
  $I = matrix 3,3 -Identity
  $IsEqual = (2 * $I) -eq ($I + $I) # now $IsEqual is True!

  # fit a simple linear regression model
  $X0 = 1,1,1,1,1 | matrix 5,1
  $X1 = -2,-1,0,1,2 | matrix 5,1
  $X = $X0.Augment($X1)
  $Y = 0,0,1,1,3 | matrix 5,1
  $B = ($X.Transpose() * $X).Inverse() * ($X.Transpose() * $Y)
  # ==> The result is a 2x1 matrix with the desired values (1 and 0.7, in this case)

  ```

  > **Note**
  > Full class name is `Prelude.Matrix`

- `[Node]`
  > Simple node data structure for use with Graph data structure
  ```PowerShell
  $A = [Node]'a'
  $B = [Node]'b'
  $C = [Node]'c'
  ```

  > **Note**
  > Full class name is `Prelude.Node`

- `[Edge]`
  > Simple edge data structure for use with Graph data structure. Edges are composed of two nodes and an optional weight (default weight is `1`).
  
  > Un-weighted graphs can be constructed by using default weight of 1 for all associated edges).
  ```PowerShell
  $AB = [Edge]::New($A, $B)
  $BC = [Edge]::New($B, $C)
  
  # OR you can use PowerShell helper functions

  $AB = New-Edge $A $B
  $BC = New-Edge $B $C
  ```

  > **Note**
  > Full class name is `Prelude.Edge`

- `[DirectedEdge]`
  > Exactly like `[Edge]`, but directed.
  ```PowerShell
  $AB = [DirectedEdge]::New($A, $B)
  $BC = [DirectedEdge]::New($B, $C)
  
  # OR you can use PowerShell helper functions

  $AB = New-Edge -From $A -To $B -Directed
  $BC = New-Edge -From $B -To $C -Directed
  ```

  > **Note**
  > Full class name is `Prelude.DirectedEdge`

- `[Graph]`
  > Data structure to model objects (nodes) and relations (edges). Named `[Graph]` instead of `[Network]` to avoid confusion with computer networks, a common use case for PowerShell. 
  ```PowerShell
  $Nodes = $A, $B, $C
  $Edges = $AB, $BC
  $G = New-Graph $Nodes $Edges

  # OR create graph using just edges
  # (necessary nodes are "auto" added)

  $G = [Graph]::New($Edges)

  # Add nodes
  $D = [Node]'d'
  $G.Add($D)

  # View adjacency matrix
  $G.AdjacencyMatrix

  # algorithms and other cool stuff are UNDER CONSTRUCTION

  ```

  > **Note**
  > Full class name is `Prelude.Graph`

Type Extensions
---------------
> For details on how to extend types with `Types.ps1xml` files, see [About Types.ps1xml](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_types.ps1xml?view=powershell-7)

Prelude uses type extensions to provide method versions of most core functions. This may be useful in some situations (or if you just don't feel like using pipelines...)

**Examples**
```PowerShell
# Factorials
(4).Factorial() # 24

# Permutations as a property (similar property for numbers and arrays)
'cat'.Permutations() # 'cat','cta','tca','tac','atc','act'

# Flatten an array
@(1,@(2,3,@(4,5))).Flatten() # 1,2,3,4,5

# Reduce an array just like you would in other languages like JavaScript
$Add = { Param($a,$b) $a + $b }
@(1,2,3).Reduce($Add, 0) # 6

```

> **Note**
> For the full list of functions, read through the `ps1xml` files in the [types directory](./Prelude/types).

Contributing
------------
Have an idea? Want to help implement a fix? Check out the [contributing guide](./.github/CONTRIBUTING.md).

Credits
-------
- [Microsoft](https://www.microsoft.com)
  - [PowerShell](https://github.com/powershell/powershell) (d'uh)
  - [Windows Terminal](https://github.com/jhwohlgemuth/env/tree/master/dev-with-windows-terminal)
  - [VS Code](https://code.visualstudio.com/) - *the editor I use for writing PowerShell*
  - [Visual Studio 2019](https://visualstudio.microsoft.com/vs/) - *the editor I use for writing C#*
- [Pester](https://pester.dev/) - *testing*
- [PSScriptAnalyzer](https://github.com/PowerShell/PSScriptAnalyzer) - *static analysis (linting)*
- [BenchmarkDotNet](https://benchmarkdotnet.org/) - *C# benchmarks*
- [CODECOGS](https://www.codecogs.com/latex/eqneditor.php) - *LaTeX in examples/README.md*
- [janikvonrotz/awesome-powershell](https://github.com/janikvonrotz/awesome-powershell) - *inspiration*
- [chrisseroka/ps-menu](https://github.com/chrisseroka/ps-menu) - *inspiration*
- [PrateekKumarSingh/Graphical](https://github.com/PrateekKumarSingh/graphical) - *inspiration*
- [mattifestation/PowerShellArsenal](https://github.com/mattifestation/PowerShellArsenal) - *inspiration*
- [PowerShellMafia/PowerSploit](https://github.com/PowerShellMafia/PowerSploit) - *inspiration*
- [NetworkX](https://networkx.org/) - *inspiration*
- [C# Algorithms](https://github.com/aalhour/C-Sharp-Algorithms) - *inspiration* & *reference implementation*
- [Math.NET Numerics](https://numerics.mathdotnet.com/) - *inspiration*
- [MartinSGill/Profile](https://github.com/MartinSGill/Profile) - *inspiration*
- [Lodash](https://lodash.com/docs/) and [ramdajs](https://ramdajs.com/docs/) - *inspiration*

-------------

**Footnotes**
-------------

[1]
---
> This module is ***NOT*** an "official" Microsoft PowerShell prelude module

[2]
---
> This code was inspired and enabled by [several people and projects](#Credits)

[3]
---
> The following functions are not supported on Linux:
- `Invoke-ListenForWord`
- `Invoke-Speak`
- `Import-Html`
- `Use-Grammar`
- `Use-Speech`
- `Use-Web`

[4]
---
> Results may vary. The 100% guarantee is not 100% certain in 100% of cases.

[5]
---
> Sometimes ***way*** beyond :)

[6]
---
> Compiled code, closed source software, arcane code snippets copy/pasted from the internet nether-realm, etc...

[7]
---
> The installation of Prelude can be as simple as copying the [./Prelude](./Prelude) folder into one of the directories in your `$Env:PSModulePath` variable.
