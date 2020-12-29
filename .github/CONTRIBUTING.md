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
> First off, thank you for considering contributing to `pwsh-prelude`!

If you would like to make a feature request or enhancement suggestion, please open an issue.

If you would like to generously provide a pull request to correct a verified issue, please adhere to this project's [standards](#project-standards). Before making a pull request for a desired feature, please socialize the concept by opening an issue first.

Project Architecture
--------------------

The main module file, [pwsh-prelude.psm1](../pwsh-prelude.psm1), simply imports the functions of every `.ps1` file in the [src](../src) folder and sets some additional aliases. The files in the [src](../src) directory are named according to the general category of the functions it contains:
- `application.ps1`: Collection of functions that can be used to create a PowerShell command line application
- `applied.ps1`: Library of functions for performing applied mathematics such as probability, combinatorics, and statistics 
- `core.ps1`: Functional helper functions like `Invoke-Reduce` and `Test-Equal`. These functions typically do not have dependencies on other files in the [src](../src) folder
- `data.ps1`: Functions for ingesting and converting data
- `events.ps1`: Functions needed for event-driven operations (inspired by `Backbone.Events`)
- `matrix.ps1`: Helper functions for using `[Matrix]` objects
- `productivity.ps1`: A grab bag of sorts that contains functions like `Home`, `Take`, and `Test-Empty`.
- `user-interface.ps1`: Functions and utilties that could be used to make a PowerShell CLI application (see [the kitchen sink](../kitchensink.ps1) for an example)
- `web.ps1`: Functions for working with web technology
- `cs/Matrix`: C# files for `[Matrix]` type accelator
- `cs/Geodetic`: C# files for `[Coordinate]` and `[Datum]` type accelators
- `cs/Graph`: C# files for `[Graph]`, `[Edge]`, and `[Node]` type accelators


Project Setup <sup>[[1]](#footnotes)</sup>
=============
> Friends don't let friends use Powershell without [Windows Terminal](https://www.microsoft.com/en-us/p/windows-terminal/9n0dx20hk701?activetab=pivot:overviewtab). Please follow [these instructions](https://github.com/jhwohlgemuth/env/tree/master/dev-with-windows-terminal) to customize your terminal and achieve new levels of epic productivity — *"I can't believe it's not Linux!"* ™

Prelude uses a build script for PowerShell development tasks and `dotnet` for C# tasks.

PowerShell Workflow Tasks
-------------------------
**Requirements**
- Run `./Invoke-Setup.ps1` to install PowerShell development depencencies
> ***NOTE*** You may need to run `Set-ExecutionPolicy Unrestricted` before executing `Invoke-Setup.ps1`

All PowerShell tasks are contained within [build.ps1](../build.ps1) and can be executed via the following commands:
- Lint code: `./build.ps1 -Lint`
- Run tests: `./build.ps1 -Test`
> ***NOTE***: PowerShell tests are located in the `/tests` directory
- Lint code and run tests: `./build.ps1 -Lint -Test`
- Run tests (with coverage): `./build.ps1 -Test -WithCoverage`
- Run tests (with coverage) and show report: `./build.ps1 -Test -WithCoverage -ShowCoverageReport`

> ***NOTE***: Using `-ShowCoverageReport` requires that [ReportGenerator](https://danielpalme.github.io/ReportGenerator/) is installed and `reportgenerator.exe` is available from the command line.

C# Workflow Tasks
-----------------
**Requirements**
- [.NET SDK v5.0](https://dotnet.microsoft.com/download/visual-studio-sdks)
> ***NOTE***: The easiest way to install .NET is to use [Visual Studio Community](https://visualstudio.microsoft.com/vs/community/)

**Run Tests**
> ***NOTE***: C# tests are located in the `src/cs/Tests` directory
- Within the `src/cs` directory, run `dotnet test`

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
- Running `./build.ps1 -Lint` should not return any issues (this includes naming functions using Powershell "approved" verbs)
- Running `./build.ps1 -Test -Tag 'Local' -Exclude 'LinuxOnly'` should have no failures (local and [remote](https://travis-ci.com/github/jhwohlgemuth/pwsh-prelude))
- Exceptions to any of these standards should be supported by strong reasoning and sufficient effort
- Beyond the rules identified by `./build.ps1 -Lint` <sup>[[2]](#footnotes)</sup>, all code additions should adhere to the following:
  - Use two-spaces for indentation
  - Variables should be [***PascalCase***](https://techterms.com/definition/pascalcase) (**ex**: `$Foo`, `$MyEvent`, etc...)
  - Function names should be of the form, `Verb-SomeThing`, where `Verb` is an "approved" verb (see Powershell's `Get-Verb` cmdlet)
  - Types should be [***PascalCase***](https://techterms.com/definition/pascalcase) (**ex**: `[String]`, `[Int]`, etc...)
  - Operators should be ***lowercase*** (**ex**: `-eq`, `-not`, `-match`, etc...)
  - [Variable scopes](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_scopes?view=powershell-7) should be [***PascalCase***](https://techterms.com/definition/pascalcase) (**ex**: `$Script:`, `$Env:`, `$Global:`, etc...)
  - Do not use aliases (they will be replaced by `./build.ps1 -Lint` anyways)
  - Use single quotes unless double quotes are required (**ex**: variable interpolation, [special characters](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_special_characters?view=powershell-7), etc...)
  - Single space after higher-order functions like `ForEach-Object` and `Where-Object`
  - Single-line scriptblocks should have a single space after the opening bracket and before the closing bracket
    ```Powershell
    # Example
    Get-ChildItem -File | ForEach-Object { $_.FullName }
    ```
  - Hashtables (and custom objects) should have a single space after the opening bracket and before the closing bracket
    ```Powershell
    # Example
    @{ foo = "bar" }
    ```
  - Semi-colons should be followed by a single space
    ```Powershell
    # Examples
    @{ a = "a"; b = "b"; c = "c" }
    [PSCustomObject]@{ a = "a"; b = "b"; c = "c" }
    ```
  - Comparison operators (like `=`) should have a single space before and after, except for values in `[Parameter(...)]` decorator (**ex**: `$Foo = "bar"`, `[Parameter(Mandatory=$true, Position=0)]`)
  - Use the ["One True Brace Style" (1TBS)](https://en.wikipedia.org/wiki/Indentation_style#Variant:_1TBS_(OTBS))
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
  - When in doubt, write code that is consistent with preponderance of existing codebase. Let's call this the "priority of pre-existing preponderance rule".

Footnotes
---------
> **[1]** In an effor to maximize cross-platform support, tests are run on Windows and Linux. However, Windows 10 is the only *officially* supported OS for development on this project. There should be a good reason for tests not passing on all platforms (**ex:** Using windows speech recognition libraries)

> **[2]** `.\build.ps1 -Lint` uses the [built-in PSScriptAnalyzer rules](https://github.com/PowerShell/PSScriptAnalyzer/tree/development/Rules) ***and*** custom rules contained within [`.\rule.psm1`](..\rule.psm1)