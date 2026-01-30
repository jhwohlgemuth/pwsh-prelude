# AGENT.md - Project Configuration for AI Agents

## Project Overview
**Prelude** is a PowerShell "standard" library providing utilities, helpers, functions, type accelerators, and aliases inspired by functional programming language preludes. It supports linear algebra, graph theory, data analysis, and system automation.

## Project Structure

### Main Directories
- **`Prelude/`** - PowerShell module source
  - `Prelude.psd1` - Module manifest
  - `Prelude.psm1` - Module entry point
  - `src/` - Source files organized by functionality
    - `core.ps1` - Core functions
    - `application.ps1` - Application utilities
    - `data.ps1` - Data manipulation
    - `graph.ps1` - Graph theory implementations
    - `matrix.ps1` - Linear algebra/matrix operations
    - `productivity.ps1` - Productivity helpers
    - `web.ps1` - Web utilities
  - `Plus/` - Extended functionality
  - `types/` - Custom type definitions
  - `formats/` - PowerShell formatting files
- **`csharp/`** - C# implementations for performance
  - `Tests/` - .NET unit tests
  - `Graph/`, `Matrix/`, etc. - Domain-specific implementations
- **`tests/`** - PowerShell Pester tests
  - `*.Tests.ps1` - Test files corresponding to `src/` modules
- **`docs/`**, **`examples/`** - Documentation and examples
- **`styles/`** - Code quality/linting rules (alex, proselint, etc.)

### Configuration Files
- `Prelude.psd1` - PowerShell module manifest (defines exports)
- `PSScriptAnalyzerSettings.psd1` - PSScriptAnalyzer configuration
- `stryker-config.json` - Mutation testing configuration
- `appveyor.yml` - CI/CD configuration
- `codecov.yml` - Code coverage configuration

## Development Conventions

### PowerShell Functions
- Located in `Prelude/src/` organized by feature area
- Functions follow verb-noun naming: `Get-Something`, `Set-Something`, `New-Something`
- Must be exported in `Prelude.psd1` under `FunctionsToExport`
- Should have Comment-Based Help (CBH) with `.SYNOPSIS`, `.DESCRIPTION`, `.PARAMETER`, `.EXAMPLE`

### C# Code
- Located in `csharp/` with corresponding project files (`.csproj`)
- Performance-critical code is implemented in C#
- Tests in `csharp/Tests/Tests.csproj` using standard .NET testing
- Classes follow PascalCase naming

### Testing
- PowerShell tests: `tests/*.Tests.ps1` using Pester framework
- .NET tests: `csharp/Tests/*.Tests.cs`
- Test files should mirror source file names
- Run tests with build tasks (see below)

### Code Quality
- PowerShell scripts analyzed with PSScriptAnalyzer
- Configuration: `PSScriptAnalyzerSettings.psd1`
- Custom rules: `PSScriptAnalyzerCustomRules.psm1`
- StyleCop used for C# (config: `stylecop.json`)

## Build & Test Tasks

Available VS Code tasks (run with `Ctrl+Shift+B` or via task runner):
- **build** - Compile .NET projects: `dotnet build csharp/Tests/Tests.csproj`
- **watch** - Watch mode: `dotnet watch run csharp/Tests/Tests.csproj`
- **publish** - Publish: `dotnet publish csharp/Tests/Tests.csproj`

### Using Invoke-Task for Testing and Linting

The main task execution script is `./Invoke-Task.ps1`. Run any task using switch parameters:

**Setup Scripts:**
- `./Invoke-Setup.ps1` - Install/configure development dependencies
- `./Invoke-FixPesterSetup.ps1` - Fix Pester installation issues

#### Available Tasks

**Lint - Analyze and format code**
```powershell
./Invoke-Task.ps1 -Lint                    # Lint PowerShell and C# code with auto-fix
./Invoke-Task.ps1 -Lint -Skip dotnet       # Lint only PowerShell code
./Invoke-Task.ps1 -Lint -Skip powershell   # Lint only C# code
./Invoke-Task.ps1 -Lint -DryRun            # Analyze without making changes
./Invoke-Task.ps1 -Lint -CI                # Run in CI mode
```
Runs PSScriptAnalyzer on PowerShell (`Prelude/src/` and `Prelude/Plus/`) and dotnet-format on C# code. Configuration: `PSScriptAnalyzerSettings.psd1`, `PSScriptAnalyzerCustomRules.psm1`.

**Test - Run unit tests**
```powershell
./Invoke-Task.ps1 -Test                              # Run all tests
./Invoke-Task.ps1 -Test -Skip powershell             # Run only C# tests
./Invoke-Task.ps1 -Test -Skip dotnet                 # Run only PowerShell Pester tests
./Invoke-Task.ps1 -Test -WithCoverage                # Run tests with code coverage
./Invoke-Task.ps1 -Test -WithCoverage -GenerateCoverageReport  # Generate coverage report
./Invoke-Task.ps1 -Test -Tags Remote                 # Run only tests tagged 'Remote'
./Invoke-Task.ps1 -Test -Exclude WindowsOnly         # Exclude tests tagged 'WindowsOnly'
./Invoke-Task.ps1 -Test -Filter '*Readability*'      # Run tests matching filter pattern
./Invoke-Task.ps1 -Test -Platform linux              # Run tests for Linux
```
Runs Pester tests (`tests/*.Tests.ps1`) and .NET tests (`csharp/Tests/Tests.csproj`). Coverage reports can be viewed at `.\coverage\index.htm`.

**Build - Compile C# and create link libraries**
```powershell
./Invoke-Task.ps1 -Build                   # Format, test, and build link libraries
./Invoke-Task.ps1 -Build -BuildOnly        # Skip formatting and testing
./Invoke-Task.ps1 -Build -Version 2019     # Use Visual Studio 2019
./Invoke-Task.ps1 -Build -Architecture x86 # Build for 32-bit architecture
```
Formats C# code, runs tests, builds link libraries saved to `Prelude/bin/`. Requires Visual Studio and compiler (csc.exe). Supports 2019 and 2022 editions.

**Publish - Publish module to PowerShell Gallery**
```powershell
./Invoke-Task.ps1 -Publish                 # Bump build version and publish
./Invoke-Task.ps1 -Publish -Minor          # Bump minor version (e.g., 1.1.1 -> 1.2.0)
./Invoke-Task.ps1 -Publish -Major          # Bump major version (e.g., 1.1.1 -> 2.0.0)
./Invoke-Task.ps1 -Publish -DryRun         # Simulate publishing without making changes
```
Updates module version in `Prelude.psd1` and publishes to PowerShell Gallery. Requires valid `$Env:NUGET_API_KEY`. Version bump defaults to build increment if no flag specified.

**Check - Verify development environment**
```powershell
./Invoke-Task.ps1 -Check                   # Check environment against VS 2022 Community
./Invoke-Task.ps1 -Check -Version 2019     # Check against VS 2019
```
Validates that the environment has necessary tools and dependencies for Prelude development.

**Mutate - Run Stryker mutation tests**
```powershell
./Invoke-Task.ps1 -Mutate -Project Matrix     # Run mutation tests on Matrix project
./Invoke-Task.ps1 -Mutate -Project Graph      # Run mutation tests on Graph project
./Invoke-Task.ps1 -Mutate -Project Geodetic   # Run mutation tests on Geodetic project
```
Executes mutation testing using Stryker (configured in `stryker-config.json`). Supported projects: Matrix, Graph, Geodetic. Opens report in browser after completion.

**Benchmark - Run C# performance benchmarks**
```powershell
./Invoke-Task.ps1 -Benchmark                # Run all benchmarks
```
Executes BenchmarkDotNet benchmarks from `csharp/Performance/Performance.csproj` in Release mode.

## Module Export Configuration

The `Prelude.psd1` file defines module exports:
```powershell
CmdletsToExport       = @(...)  # Exported cmdlets
FunctionsToExport     = @(...)  # Exported functions
AliasesToExport       = @(...)  # Exported aliases
VariablesToExport     = @(...)  # Exported variables
```

**Important**: When adding new functions, add them to the appropriate export list in `Prelude.psd1`.

## Common Editing Tasks

### Adding a New Function
1. Create or add function to appropriate file in `Prelude/src/`
2. Add to `FunctionsToExport` in `Prelude.psd1`
3. Create corresponding test in `tests/`
4. Add Comment-Based Help to function

### Removing a Function
1. Remove function definition from `Prelude/src/`
2. Remove from export lists in `Prelude.psd1`
3. Remove or update corresponding tests

### Modifying C# Code
1. Edit in `csharp/<component>/` folder
2. Compile with build task
3. Update tests if behavior changes

## Key Files to Understand

| File | Purpose |
|------|---------|
| [Prelude/Prelude.psd1](Prelude/Prelude.psd1) | Module manifest - defines all exports |
| [Prelude/Prelude.psm1](Prelude/Prelude.psm1) | Module initialization and setup |
| [Prelude/src/core.ps1](Prelude/src/core.ps1) | Core utilities and foundational functions |
| [tests/_setup.ps1](tests/_setup.ps1) | Pester test setup and imports |
| [PSScriptAnalyzerSettings.psd1](PSScriptAnalyzerSettings.psd1) | Code style rules |

## Important Notes

- **Module exports**: Always synchronize function definitions with `Prelude.psd1` exports
- **Test coverage**: Maintain tests alongside function implementations
- **Documentation**: Use Comment-Based Help for all public functions
- **Naming conventions**: Follow PowerShell verb-noun standards
- **Performance**: Consider C# implementations for computationally intensive operations

## Related Documentation

- See [README.md](README.md) for project overview and quick start
- See [examples/](examples/) for usage examples
- See [docs/](docs/) for detailed documentation
- PowerShell module manifest reference: about_Module_Manifests
