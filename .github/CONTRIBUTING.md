
Getting Started
---------------
- Read this guide
- Fork this repository and clone your fork locally
- Adhere to the [project standards](#project-standards)
- Write some code and stuff...
- Push your changes and create a pull request

Code of Conduct
---------------
> Please read and adhere to the [code of conduct](CODE_OF_CONDUCT.md)

Introduction
------------
> First off, thank you for considering contributing to `pwsh-handy-helpers`!

If you would like to make a feature request or enhancement suggestion, please open an issue.

If you would like to generously provide a pull request to correct a verified issue, please adhere to this project's [standards](#project-standards). Before making a pull request for a desired feature, please socialize the concept by opening an issue first.

Project Architecture
--------------------

The main module file, [pwsh-handy-helpers.psm1](../pwsh-handy-helpers.psm1), simply imports the functions of every `.ps1` file in the [src](../src) folder and sets some additional aliases. The files in the [src](../src) directory are named according to the general category of the functions it contains:
- `core.ps1`: Functional helper functions like `Invoke-Reduce` and `Test-Equal`. These functions typically do not have dependencies on other files in the [src](../src) folder
- `user-interface.ps1`: Functions and utilties that could be used to make a PowerShell CLI application (see [the kitchen sink](../kitchensink.ps1) for an example)
- `productivity.ps1`: A grab bag of sorts that contains functions like `Home`, `Take`, and `Test-Empty`.
- `override.ps1`: Functions that "clobber" existing functions like `Out-Default` (which enables one to omit `cd` when changing directories)

Project Setup
-------------
> Friends don't let friends use Powershell without [Windows Terminal](https://www.microsoft.com/en-us/p/windows-terminal/9n0dx20hk701?activetab=pivot:overviewtab). Please follow [these instructions](https://github.com/jhwohlgemuth/env/tree/master/dev-with-windows-terminal) to customize your terminal and achieve new levels of epic productivity — *"I can't believe it's not Linux!"* ™

As a Powershell module, all that is really required for developing `pwsh-handy-helpers` is that Powershell be installed (on Windows or [Linux](https://github.com/PowerShell/PowerShell))

> ***NOTE***: Although almost all functions work on Windows and Linux, certain functions (like `Invoke-Speak` are intrinsically dependent on Windows DLLs and therefor do not work on Linux Powershell installations)

Workflow tasks are contained within [build.ps1]() and can be executed via the following commands:
- Lint code: `./build.ps1 -Lint`
- Run tests: `./build.ps1 -Test`
- Lint code and run tests: `./build.ps1 -Lint -Test`
- Run tests (with coverage): `./build.ps1 -Test -WithCoverage`
- Run tests (with coverage) and show report: `./build.ps1 -Test -WithCoverage -ShowCoverageReport`

> ***NOTE***: Using `-ShowCoverageReport` requires that [ReportGenerator]() is installed and `reportgenerator.exe` is available from the command line.

Project Standards
-----------------
- New functions should be added to the file most closely related to the intended purpose of the new function, in alphabetical order.
- Running `./build.ps1 -Lint` should not return any issues (this includes naming functions using Powershell "approved" verbs)
- Running `./build.ps1 -Test` should have no failures (local and [CI](https://travis-ci.com/github/jhwohlgemuth/pwsh-handy-helpers))
- Exceptions to any of these standards should be supported by strong reasoning and sufficient effort
- Beyond the rules identified by `./build.ps1 -Lint`, all code additions should adhere to the following:
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
    ```
  - Prefer pipelines and avoid un-necessary variable declarations.
  - When in doubt, write code that is consistent with preponderance of existing codebase. Let's call this the "priority of pre-existing preponderance rule".
