Getting Started
===============
- Read this guide (including the [Code of Conduct](CODE_OF_CONDUCT.md))
- Fork this repository and clone your fork locally
- [Setup your environment](#project-setup) to use development tasks (test, lint, etc...)
- Adhere to the [project standards](#project-standards)
- Write some code and stuff...
- Push your changes and create a pull request

Code of Conduct
---------------
> Please read and adhere to the [code of conduct](CODE_OF_CONDUCT.md)

Introduction
------------
> First off, thank you for considering contributing to `Prelude`!

If you would like to make a feature request or enhancement suggestion, please open an issue.

If you would like to generously provide a pull request to correct a verified issue, please adhere to this project's [standards](#project-standards). Before making a pull request for a desired feature, please socialize the concept by opening an issue first.

Project Architecture
--------------------

The Prelude module entry point, [Prelude.psm1](../Prelude/Prelude.psm1), simply imports the functions of every `.ps1` file in the [src](../Prelude/src) folder. The files in the [src](../Prelude/src) directory are named according to the general category of the functions it contains:
- [`Prelude\src\`](./Prelude/src)
  - [`application.ps1`](../src/application.ps1): Collection of functions that can be used to create a PowerShell command line application
  - [`applied.ps1`](../src/applied.ps1): Library of functions for performing applied mathematics such as probability, combinatorics, and statistics 
  - [`core.ps1`](../src/core.ps1): Functional helper functions like `Invoke-Reduce` and `Test-Equal`. These functions typically do not have dependencies on other files in the [src](../Prelude/src) folder
  - [`data.ps1`](../src/data.ps1): Functions for ingesting and shaping data
  - [`events.ps1`](../src/events.ps1): Functions needed for event-driven operations (inspired by [`Backbone.Events` API](https://backbonejs.org/#Events))
  - [`matrix.ps1`](../src/matrix.ps1): Helper functions for using `[Matrix]` objects
  - [`productivity.ps1`](../src/productivity.ps1): A grab bag of sorts that contains functions like `Home`, `Take`, and `Test-Empty`.
  - [`user-interface.ps1`](../src/user-interface.ps1): Functions and utilties that could be used to make a PowerShell CLI application (see [the kitchen sink](../kitchensink.ps1) for an example)
  - [`web.ps1`](../src/web.ps1): Functions for working with web technology
- [`Prelude\formats\`](../Prelude/formats)
  - [`Format.ps1xml` files](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_format.ps1xml?view=powershell-7.1)
- [`Prelude\types\`](../Prelude/types)
  - [`Types.ps1xml` files](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_types.ps1xml?view=powershell-7.1)
- [`Prelude\Prelude.psd1`](../Prelude/Prelude.psd1): Prelude module manifest file
- [`Prelude\Prelude.psd1`](../Prelude/Prelude.psm1): Prelude module entry point

The Prelude project contains C# code that is added to the module as dynamic link libraries (DLLs). The code is organized as a single solution with multiple projects:
- [`csharp\`]()
  - [`Matrix\`](../csharp/Matrix)
    - Project directory for `[Matrix]` type accelator <sup>[[5]](#footnotes)</sup>
  - [`Geodetic\`](../csharp/Geodetic)
    - Project directory for `[Coordinate]` and `[Datum]` type accelators <sup>[[5]](#footnotes)</sup>
  - [`Graph\`](../csharp/Graph)
    - Project directory for `[Graph]`, `[Edge]`, and `[Node]` type accelators <sup>[[5]](#footnotes)</sup>
  - [`Performance\`](../csharp/Performance)
    - Project directory for C# benchmarks
    > ***NOTE***: Benchmarks are executed using [BenchmarkDotNet](https://benchmarkdotnet.org/)
  - [`Tests\`](../csharp/Tests)
    - Project directory for C# tests


Project Setup <sup>[[1]](#footnotes)</sup>
=============
> Friends don't let friends use Powershell without [Windows Terminal](https://www.microsoft.com/en-us/p/windows-terminal/9n0dx20hk701?activetab=pivot:overviewtab). Please follow [these instructions](https://github.com/jhwohlgemuth/env/tree/master/dev-with-windows-terminal) to customize your terminal and achieve new levels of epic productivity — *"I can't believe it's not Linux!"* ™

Prelude uses a build script for PowerShell development tasks and `dotnet` for C# tasks.

PowerShell Workflow Tasks
-------------------------
**Requirements**
- Run `.\Invoke-Setup.ps1` to install PowerShell development depencencies
> ***NOTE*** You may need to run `Set-ExecutionPolicy Unrestricted` before executing `Invoke-Setup.ps1`

All PowerShell tasks are contained within [Invoke-Task.ps1](../Invoke-Task.ps1) and can be executed via the following commands:

| Purpose                                                  | Command                                                         |
| -------------------------------------------------------: | --------------------------------------------------------------- |
| Lint **ALL** code                                        | `.\Invoke-Task.ps1 -Lint`                                       |
| Lint **ONLY POWERSHELL** code                            | `.\Invoke-Task.ps1 -Lint -Skip dotnet`                          |
| Lint **ALL** code and run **ALL** tests                  | `.\Invoke-Task.ps1 -Lint -Test`                                 |
| **ALL** tests                                            | `.\Invoke-Task.ps1 -Test`                                       |
| **ONLY** PowerShell tests                                | `.\Invoke-Task.ps1 -Test -Skip dotnet`                          |
| **ONLY WINDOWS** PowerShell tests                        | `.\Invoke-Task.ps1 -Test -Skip 'dotnet' -Exclude 'LinuxOnly'`   |
| **ONLY LINUX** PowerShell tests                          | `.\Invoke-Task.ps1 -Test -Skip 'dotnet' -Exclude 'WindowsOnly'` |
| **ALL** tests with coverage <sup>[[3]](#footnotes)</sup> | `.\Invoke-Task.ps1 -Test -WithCoverage`                         |
| ...and open coverage report                              | `.\Invoke-Task.ps1 -Test -WithCoverage -ShowCoverageReport`     |

> ***NOTE***: PowerShell tests are located in the `/tests` directory

C# Workflow Tasks
-----------------
**Requirements**
- [.NET SDK v5.0](https://dotnet.microsoft.com/download/visual-studio-sdks)
> ***NOTE***: The easiest way to install .NET is to use [Visual Studio Community](https://visualstudio.microsoft.com/vs/community/)

**Lint C# code**
```PowerShell
.\Invoke-Task.ps1 -Lint -Skip powershell
```

**Run C# Tests**
```powershell
.\Invoke-Task.ps1 -Test -Skip powershell
```
> ***NOTE***: C# tests are located in the `src/cs/Tests` directory

**Run C# Benchmarks**
> ***NOTE***: C# benchmarks depend on [BenchmarkDotNet](https://benchmarkdotnet.org/)
```powershell
.\Invoke-Task.ps1 -Benchmark
```

Visual Studio Code Configuration
--------------------------------
**General Development**
- Install [VSCode](https://code.visualstudio.com/)
- Install [PowerShell VSCode extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode.PowerShell)

**Linux Development within Docker Container**
- [Follow the instructions of this article](https://code.visualstudio.com/docs/remote/containers)

Project Standards
=================
- New functions should be added to the file most closely related to the intended purpose of the new function, in alphabetical order.
- Running `.\Invoke-Task.ps1 -Lint` should not return any issues (this includes naming functions using Powershell "approved" verbs)
- Tests should have no failures when run locally
  > **Windows:** `.\Invoke-Task.ps1 -Test -Tags Local -Platform Windows`
  
  > **Linux:** `./Invoke-Task.ps1 -Test -Tags Local -Platform Linux`
- Tests should have no failures when run remotely

  | Platform | Status |
  | :------: | ------ |
  | Windows  | [![AppVeyor build status](https://ci.appveyor.com/api/projects/status/i0rl050w9b972uh4/branch/master?svg=true "Windows")](https://ci.appveyor.com/project/jhwohlgemuth/pwsh-prelude/branch/master)    |
  | Linux    | [![Buddy pipeline status](https://app.buddy.works/wohlgemuth-technology-foundation/pwsh-prelude/pipelines/pipeline/299257/badge.svg?token=fda3da4664f6ba92e480e43a4a15c2427c040ee0c0691bd43e891c32e51aff31 "Linux")](https://app.buddy.works/wohlgemuth-technology-foundation/pwsh-prelude/pipelines/pipeline/299257)    |

- Exceptions to any of these standards should be supported by strong reasoning and sufficient effort
- Although this project has many rules <sup>[[3]](#footnotes)</sup>, running `./Invoke-Task.ps1 -Lint` should automatically enforce most of them. In any case, here are some standards to keep in mind:
  - Use two-spaces for indentation <sup>[[4]](#footnotes)</sup>
  - Variables should be [***PascalCase***](https://techterms.com/definition/pascalcase) (**ex**: `$Foo`, `$MyEvent`, etc...)
  - Function names should be of the form, `Verb-SomeThing`, where `Verb` is an "approved" verb (see Powershell's `Get-Verb` cmdlet)
  - Types and type accelators should be [***PascalCase***](https://techterms.com/definition/pascalcase) (**ex**: `[String]`, `[Int]`, etc...).
  - Operators should be ***lowercase*** (**ex**: `-eq`, `-not`, `-match`, etc...) <sup>[[4]](#footnotes)</sup>
  - [Variable scopes](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_scopes?view=powershell-7) should be [***PascalCase***](https://techterms.com/definition/pascalcase) (**ex**: `$Script:`, `$Env:`, `$Global:`, etc...)
  - Do not use aliases <sup>[[4]](#footnotes)</sup>
  - Use single quotes unless double quotes are required (**ex**: variable interpolation, [special characters](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_special_characters?view=powershell-7), etc...) <sup>[[4]](#footnotes)</sup>
  - Single space after higher-order functions like `ForEach-Object` and `Where-Object` <sup>[[4]](#footnotes)</sup>
  - Single-line scriptblocks should have a single space after the opening bracket and before the closing bracket <sup>[[4]](#footnotes)</sup>
    ```Powershell
    # Example
    Get-ChildItem -File | ForEach-Object { $_.FullName }
    ```
  - Hashtables (and custom objects) should have a single space after the opening bracket and before the closing bracket <sup>[[4]](#footnotes)</sup>
    ```Powershell
    # Example
    @{ foo = "bar" }
    ```
  - Semi-colons should be followed by a single space <sup>[[4]](#footnotes)</sup>
    ```Powershell
    # Examples
    @{ a = "a"; b = "b"; c = "c" }
    [PSCustomObject]@{ a = "a"; b = "b"; c = "c" }
    ```
  - Comparison operators (like `=`) should have a single space before and after, except for values in `[Parameter(...)]` decorator (**ex**: `$Foo = "bar"`, `[Parameter(Mandatory=$true, Position=0)]`) <sup>[[4]](#footnotes)</sup>
  - Use the ["One True Brace Style" (1TBS)](https://en.wikipedia.org/wiki/Indentation_style#Variant:_1TBS_(OTBS)) <sup>[[4]](#footnotes)</sup>
    ```Powershell
    if ($Condition) {
      # code code code
    } else {
      # code code code
    }
    function Invoke-Awesome {
      # code code code
    }
    ```
  - Prefer pipelines and avoid un-necessary variable declarations.
  - Use `DarkGray` when using `Write-Color` within "WhatIf" blocks.
    ```Powershell
    if ($PSCmdlet.ShouldProcess($Path)) {
      # code code code
    } else {
      '==> Would have executed code code code' | Write-Color -DarkGray
    }
    ```
  - When in doubt, write code that is consistent with preponderance of existing codebase. Let's call this the "***priority of pre-existing preponderance rule***".

Footnotes
---------
> **[1]** In an effort to maximize cross-platform support, tests are run on Windows and Linux. However, Windows 10 is the only *officially* supported OS for development on this project. There should be a good reason for tests not passing on all platforms (**ex:** Using windows speech recognition libraries)

> **[2]** `-WithCoverage` and `-ShowCoverageReport` require that [ReportGenerator](https://danielpalme.github.io/ReportGenerator/) is installed and `reportgenerator.exe` is available from the command line.

> **[3]** The rules for this project are configured in three places:
  1. [Default PSScriptAnalyzer rules](https://github.com/PowerShell/PSScriptAnalyzer/tree/development/Rules)
  2. Rules enabled by [`PSScriptAnalyzerSettings.psd1`](../PSScriptAnalyzerSettings.psd1)
  3. Custom rules defined within [`PSScriptAnalyzerCustomRules.psm1`](../PSScriptAnalyzerCustomRules.psm1)

> **[4]** Should be "auto-fixed" by `.\Invoke-Task.ps1 -Lint`

> **[5]** PowerShell type accelerators are added  [dynamic link libraries](../Prelude/bin) built from associated C# code