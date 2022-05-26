[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '', Scope = 'Function', Target = 'ConvertFrom-FolderStructure')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '', Scope = 'Function', Target = 'Invoke-Pack')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '', Scope = 'Function', Target = 'Out-Tree')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '', Scope = 'Function', Target = 'Rename-FileExtension')]
Param()

function ConvertFrom-FolderStructure {
    <#
    .SYNOPSIS
    Convert Get-ChildItem output to nested hashtable
    .PARAMETER IncludeHidden
    Include hidden files (adds -Force to Get-ChildItem calls)
    .PARAMETER RemoveExtensions
    Do not include file extensions in output key names (use BaseName instead of Name)
    .EXAMPLE
    $Data = ConvertFrom-FolderStructure
    .EXAMPLE
    $Data = 'some/directory' | ConvertFrom-FolderStructure -RemoveExtensions
    .EXAMPLE
    ConvertFrom-FolderStructure -IncludeHidden | Out-Tree
    #>
    [CmdletBinding()]
    [OutputType([Object])]
    Param(
        [Parameter(Position = 0, ValueFromPipeline = $True)]
        [ValidateScript({ (Test-Path $_) })]
        [String] $Path = (Get-Location).Path,
        [Switch] $IncludeHidden,
        [Switch] $RemoveExtensions
    )
    Begin {
        function Test-Branch {
            Param(
                [Parameter(Mandatory = $True, Position = 0)]
                $Value
            )
            $Value.GetType().Name -eq 'DirectoryInfo'
        }
        function Invoke-Iterate {
            Param(
                [Parameter(Mandatory = $True, Position = 0)]
                [String] $Path
            )
            $Output = @{}
            $Parameters = @{
                IncludeHidden = $IncludeHidden
                RemoveExtensions = $RemoveExtensions
            }
            $Items = Get-ChildItem $Path -Force:$IncludeHidden
            foreach ($Item in $Items) {
                $Attribute = if ($RemoveExtensions) { 'BaseName' } else { 'Name' }
                $Output[$Item.$Attribute] = if (Test-Branch $Item) {
                    $Item | Get-StringPath | ConvertFrom-FolderStructure @Parameters
                } else {
                    $Item.Name
                }
            }
            $Output
        }
    }
    Process {
        Invoke-Iterate $Path
    }
}
function ConvertTo-AbstractSyntaxTree {
    <#
    .SYNOPSIS
    Convert string or file to abstract syntax tree object
    .EXAMPLE
    '$Answer = 42' | ConvertTo-AbstractSyntaxTree
    .EXAMPLE
    ConvertTo-AbstractSyntaxTree '.\path\to\script.ps1'
    #>
    [CmdletBinding()]
    [OutputType([System.Management.Automation.Language.ScriptBlockAst])]
    Param(
        [Parameter(Position = 0)]
        [String] $File,
        [Parameter(ValueFromPipeline = $True)]
        [String] $String
    )
    Process {
        if ($File) {
            $Path = Get-StringPath $File
        }
        if ($Path -and (Test-Path $Path)) {
            [System.Management.Automation.Language.Parser]::ParseFile($Path, [Ref]$Null, [Ref]$Null)
        } elseif ($String.Length -gt 0) {
            [System.Management.Automation.Language.Parser]::ParseInput($String, [Ref]$Null, [Ref]$Null)
        }
    }
}
function ConvertTo-PlainText {
    <#
    .SYNOPSIS
    Convert SecureString value to human-readable plain text
    #>
    [CmdletBinding()]
    [Alias('plain')]
    [OutputType([String])]
    Param(
        [Parameter(Mandatory = $True, Position = 0, ValueFromPipeline = $True)]
        [SecureString] $Value
    )
    Process {
        try {
            $BinaryString = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($Value);
            $PlainText = [System.Runtime.InteropServices.Marshal]::PtrToStringBSTR($BinaryString);
        } finally {
            if ($BinaryString -ne [IntPtr]::Zero) {
                [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($BinaryString);
            }
        }
        $PlainText
    }
}
function Find-Duplicate {
    <#
    .SYNOPSIS
    Helper function that calculates file hash values to find duplicate files recursively
    .EXAMPLE
    Find-Duplicate 'path/to/folder'
    .EXAMPLE
    Get-Location | Find-Duplicate
    #>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $True, ValueFromPipeline = $True)]
        [String] $Path,
        [Switch] $AsJob
    )
    $Path = Get-Item $Path
    "==> Finding duplicate files in `"$Path`"" | Write-Verbose
    if ($AsJob) {
        $ModulePath = Join-Path $PSScriptRoot 'productivity.ps1'
        $Job = if (Test-Command -Name 'Start-ThreadJob') {
            Start-ThreadJob -Name 'Find-Duplicate' -ScriptBlock {
                . $Using:ModulePath
                Find-Duplicate -Path $Using:Path
            }
        } else {
            Start-Job -Name 'Find-Duplicate' -ScriptBlock {
                . $Using:ModulePath
                Find-Duplicate -Path $Using:Path
            }
        }
        "==> Started job (Id=$($Job.Id)) to find duplicate files" | Write-Verbose
        "==> To get results, use `"`$Files = Receive-Job $($Job.Name)`"" | Write-Verbose
    } else {
        $Path |
            Get-ChildItem -Recurse |
            Get-FileHash |
            Group-Object -Property Hash |
            Where-Object Count -GT 1 |
            ForEach-Object { $_.Group | Select-Object Path, Hash } |
            Sort-Object -Property Hash
    }
}
function Find-FirstTrueVariable {
    <#
    .SYNOPSIS
    Given list of variable names, returns string name of first variable that returns $True
    .EXAMPLE
    $Foo = $False
    $Bar = $True
    $Baz = $False

    Find-FirstTrueVariable 'Foo','Bar','Baz'
    # 'Bar'
    #>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $True, Position = 0)]
        [Array] $VariableNames,
        [Int] $DefaultIndex = 0,
        $DefaultValue = $Null
    )
    $Index = $VariableNames | Get-Variable -ValueOnly | Find-FirstIndex
    if ($Index -ge 0) {
        $VariableNames[$Index]
    } else {
        if ($Null -ne $DefaultValue) {
            $DefaultValue
        } else {
            $VariableNames[$DefaultIndex]
        }
    }
}
function Get-ParameterList {
    <#
    .SYNOPSIS
    Get parameter names and types for a given piece of PowerShell code
    .EXAMPLE
    '{ Param($A, $B, $C) $A + $B + $C }' | Get-ParameterList
    .EXAMPLE
    'Get-Maximum' | Get-ParameterList
    .EXAMPLE
    Get-ParameterList -Path 'path/to/Some-Function.ps1'
    #>
    [CmdletBinding()]
    [OutputType([System.Object])]
    Param(
        [Parameter(Position = 0)]
        [String] $Path,
        [Parameter(ValueFromPipeline = $True)]
        [String] $String
    )
    $AlwaysTrue = { $True }
    $Lookup = @{
        Name = 'Name'
        Type = 'StaticType'
        Required = 'Extent'
    }
    $Reducer = {
        Param($Name, $Value)
        switch ($Name) {
            'Name' {
                $Value -replace '^\$', ''
            }
            'StaticType' {
                $Value.ToString()
            }
            'Extent' {
                $Value.Text -match '[Mm]andatory\s*=\s*\$[Tt]rue'
            }
            Default {
                $Value
            }
        }
    }
    $Code = if ($Path) {
        Get-Content $Path
    } else {
        if (Test-Command $String) {
            (Get-Item -Path function:$String).Definition
        } else {
            $String
        }
    }
    $Ast = $Code | ConvertTo-AbstractSyntaxTree
    $Ast.Findall($AlwaysTrue, $True) |
        ForEach-Object ParamBlock |
        Select-Object -First 1 |
        Deny-Null |
        ForEach-Object Parameters |
        Select-Object Name, StaticType, Extent |
        Invoke-PropertyTransform -Lookup $Lookup -Transform $Reducer |
        Sort-Object -Property Name -Unique
}
function Get-StringPath {
    <#
    .SYNOPSIS
    Converts directories and file information to strings.
    Converts string paths to absolute string paths.
    .EXAMPLE
    (Get-Location) | ConvertTo-String"
    # 'C:\full\path\to\current\directory'
    #>
    [CmdletBinding()]
    [OutputType([String])]
    Param(
        [Parameter(Mandatory = $True, Position = 0, ValueFromPipeline = $True)]
        $Value
    )
    Process {
        $Type = $Value.GetType().Name
        switch ($Type) {
            'DirectoryInfo' {
                $Value.FullName
            }
            'FileInfo' {
                $Value.FullName
            }
            'PathInfo' {
                $Value.Path
            }
            Default {
                if (Test-Path -Path $Value) {
                    (Resolve-Path -Path $Value).Path
                } else {
                    $Value
                }
            }
        }
    }
}
function Invoke-GoogleSearch {
    <#
    .SYNOPSIS
    Perform Google search within default web browser using Google search operators, available as cmdlet paramters
    .EXAMPLE
    'PowerShell Prelude' | google -Url 'pwsh'
    .EXAMPLE
    'Small-World Properties of Facebook Group Networks' | google -Type 'pdf' -Exact
    .EXAMPLE
    google -Site 'example.com' -Subdomain

    # Search subdomains for a given site
    #>
    [CmdletBinding()]
    [Alias('google')]
    [OutputType([String])]
    Param(
        [Parameter(Position = 0, ValueFromPipeline = $True)]
        [String[]] $Keyword = @(),
        [ValidateSet('OR', 'AND')]
        [Alias('OP')]
        [String] $BinaryOperation = 'OR',
        [Switch] $Exact,
        [String[]] $Exclude,
        [String[]] $Include,
        [Switch] $Private,
        [ValidateSet(
            'swf', 'pdf', 'ps', 'dwf', 'kml', 'kmz',
            'gpx', 'hwp', 'htm', 'html', 'xls', 'xlsx',
            'ppt', 'pptx', 'doc', 'docx', 'odp', 'ods',
            'odt', 'rtf', 'svg', 'tex', 'txt', 'text',
            'bas', 'c', 'cc', 'cpp', 'h', 'hpp', 'cs',
            'java', 'pl', 'py', 'wml', 'wap', 'xml'
        )]
        [String] $Type,
        [String] $Related,
        [String[]] $Site,
        [Switch] $Subdomain,
        [String] $Source,
        [String] $Text,
        [String] $Url,
        [String] $Custom,
        [Switch] $Encode,
        [Switch] $PassThru
    )
    Begin {
        Add-Type -AssemblyName System.Web
        $Root = if ($Private) { 'https://duckduckgo.com/?q=' } else { 'https://google.com/search?q=' }
        $Terms = @()
    }
    End {
        if ($Input.Count -gt 1) {
            $Keyword = $Input
        }
        if ($Exact) {
            $Keyword = $Keyword | ForEach-Object { "`"$_`"" }
        }
        if ($Include.Count -gt 0) {
            $Data = $Include | ForEach-Object { "+$_" }
            $Terms += ($Data -join ' ')
        }
        if ($Exclude.Count -gt 0) {
            $Data = $Exclude | ForEach-Object { "-$_" }
            $Terms += ($Data -join ' ')
        }
        if ($Related.Length -gt 0) {
            $Terms += "related:$Related"
        }
        if ($Site.Count -gt 0) {
            $Data = $Site | ForEach-Object { "site:$_" }
            $Terms += ($Data -join " $BinaryOperation ")
            if ($Subdomain) {
                $Terms += '-inurl:www'
            }
        }
        if ($Source.Length -gt 0) {
            $Terms += "source:$Source"
        }
        if ($Text.Length -gt 0) {
            $Terms += "intext:$Text"
        }
        if ($Url.Length -gt 0) {
            $Terms += "inurl:$Url"
        }
        if ($Type.Length -gt 0) {
            $Terms += "filetype:$Type"
        }
        if ($Custom.Length -gt 0) {
            $Terms += $Custom
        }
        $SearchString += ($Keyword -join " $BinaryOperation ")
        if ($Terms.Count -gt 0) {
            if ($SearchString.Length -gt 0) {
                $SearchString += ' '
            }
            $SearchString += "$($Terms -join ' ')"
        }
        if ($Encode) {
            $SearchString = [System.Web.HttpUtility]::UrlEncode($SearchString)
        }
        if ($PassThru) {
            return $SearchString
        } else {
            "${Root}${SearchString}" | Out-Browser -Default
        }
    }
}
function Invoke-Pack {
    <#
    .SYNOPSIS
    Function that will serialize one or more files into a single XML file. Use Invoke-Unpack to restore files.
    .PARAMETER Root
    Save paths relative to this path. Needed when packing folders/files not descendent from current location.
    .EXAMPLE
    ls some/folder | pack
    #>
    [CmdletBinding()]
    [Alias('pack')]
    [OutputType([String])]
    Param(
        [Parameter(ValueFromPipeline = $True)]
        [Array] $Items,
        [Parameter(Position = 0)]
        [ValidateScript({ (Test-Path $_) })]
        [String] $Root = (Get-Location).Path,
        [String] $Output = 'packed',
        [Switch] $Compress
    )
    Begin {
        function Get-PathFragment {
            Param(
                [Parameter(Position = 0)]
                [System.IO.FileInfo] $Item
            )
            ($Item | Get-StringPath).Replace($Root, '')
        }
        function ConvertTo-ItemList {
            Param(
                [Parameter(Position = 0)]
                [Array] $Values
            )
            foreach ($Value in $Values) {
                $Item = Get-Item -Path ($Value | Get-StringPath)
                switch ($Item.GetType().Name) {
                    'DirectoryInfo' {
                        Get-ChildItem -Path $Item -File -Recurse -Force
                    }
                    'FileInfo' {
                        Get-Item -Path $Item
                    }
                }
            }
        }
        function ConvertTo-ObjectList {
            Param(
                [Parameter(Position = 0)]
                [Array] $Items
            )
            foreach ($Item in $Items) {
                $Name = $Item.Name
                $Parameters = if ($Name.EndsWith('.dll')) {
                    @{
                        Raw = $True
                        Encoding = 'Byte'
                    }
                } else {
                    @{}
                }
                @{
                    Name = $Name
                    Path = Get-PathFragment $Item
                    Content = Get-Content $Item.FullName @Parameters
                }
            }
        }
    }
    End {
        $Values = if ($Input.Count -gt 0) { $Input } else { $Items }
        $OutputPath = Join-Path (Get-Location).Path "$Output.xml"
        ConvertTo-ObjectList (ConvertTo-ItemList $Values) | Export-Clixml $OutputPath -Force
        if ($Compress) {
            $CompressedOutputPath = Join-Path (Get-Location).Path "$Output.zip"
            Compress-Archive -Path $OutputPath -DestinationPath $CompressedOutputPath
            Remove-Item -Path $OutputPath
            return Get-StringPath $CompressedOutputPath
        }
        Get-StringPath $OutputPath
    }
}
function Invoke-Speak {
    <#
    .SYNOPSIS
    Use Windows Speech Synthesizer to speak input text
    .EXAMPLE
    Invoke-Speak 'hello world'
    .EXAMPLE
    'hello world' | Invoke-Speak -Verbose
    .EXAMPLE
    1, 2, 3 | %{ say $_ }
    .EXAMPLE
    Get-Content .\phrases.csv | Invoke-Speak
    #>
    [CmdletBinding()]
    [Alias('say')]
    Param(
        [Parameter(Position = 0, ValueFromPipeline = $True)]
        [String] $Text = '',
        [String] $InputType = 'text',
        [Int] $Rate = 0,
        [Switch] $Silent,
        [String] $Output = 'none'
    )
    Begin {
        Use-Speech
        $TotalText = ''
    }
    Process {
        if ($IsLinux -is [Bool] -and $IsLinux) {
            Write-Verbose '==> Invoke-Speak is only supported on Windows platform'
        } else {
            Write-Verbose '==> Creating speech synthesizer'
            $Synthesizer = New-Object System.Speech.Synthesis.SpeechSynthesizer
            if (-not $Silent) {
                switch ($InputType) {
                    'ssml' {
                        Write-Verbose '==> Received SSML input'
                        $Synthesizer.SpeakSsml($Text)
                    }
                    Default {
                        Write-Verbose "==> Speaking: $Text"
                        $Synthesizer.Rate = $Rate
                        $Synthesizer.Speak($Text)
                    }
                }
            }
            $TotalText += "$Text "
        }
    }
    End {
        if ($IsLinux -is [Bool] -and $IsLinux) {
            Write-Verbose '==> Invoke-Speak was not executed, no output was created'
        } else {
            $TotalText = $TotalText.Trim()
            switch ($Output) {
                'file' {
                    Write-Verbose '==> [UNDER CONSTRUCTION] save as .WAV file'
                }
                'ssml' {
                    $Output = "
<speak version=`"1.0`" xmlns=`"http://www.w3.org/2001/10/synthesis`" xml:lang=`"en-US`">
    <voice xml:lang=`"en-US`">
        <prosody rate=`"$Rate`">
            <p>$TotalText</p>
        </prosody>
    </voice>
</speak>
"
                    $Output | Write-Output
                }
                'text' {
                    Write-Output $TotalText
                }
                Default {
                    Write-Verbose "==> $TotalText"
                }
            }
        }
    }
}
function Invoke-Unpack {
    <#
    .SYNOPSIS
    Function to restore folders/files serialized via Invoke-Pack.
    .EXAMPLE
    'path/to/packed.xml' | Invoke-Unpack
    .EXAMPLE
    ls 'some/folder' | %{ unpack -File $_ }
    #>
    [CmdletBinding()]
    [Alias('unpack')]
    Param(
        [Parameter(Position = 0, ValueFromPipeline = $True)]
        [ValidateScript({ (Test-Path $_) })]
        [String] $Path,
        [Parameter(ValueFromPipeline = $True)]
        [System.IO.FileInfo] $File
    )
    Process {
        $Value = if ($Path) { $Path } else { Get-Item $File }
        $Pack = Import-Clixml $Value
        $Base = Join-Path (Get-Location).Path (Get-Item $Value).BaseName
        foreach ($Item in $Pack) {
            $OutputPath = Join-Path $Base $Item.Path
            if ($Item.Path.EndsWith('.dll')) {
                New-Item -Path $OutputPath -Force | Out-Null
                $Item.Content | Set-Content -Path $OutputPath -Encoding 'Byte' -Force
            } else {
                New-Item -Path $OutputPath -Value ($Item.Content -join "`n") -Force | Out-Null
            }
        }
    }
}
function Measure-Performance {
    <#
    .SYNOPSIS
    Measure the execution of a scriptblock a certain number of times. Return analysis of results.
    .DESCRIPTION
    This function returns the results as an object with the following keys:
      - Min
      - Max
      - Range
      - Mean
      - TrimmedMean (mean trimmed 10% on both sides)
      - Median
      - StandardDeviation
      - Runs (the original results of each run - can be used for custom analysis beyond these results)
    .PARAMETER Milliseconds
    Output results in milliseconds instead of "ticks"
    .PARAMETER Sample
    Use ($Runs - 1) instead of $Runs when calculating the standard deviation
    .EXAMPLE
    { Get-Process } | Measure-Performance -Runs 500
    #>
    [CmdletBinding()]
    [OutputType([PSObject])]
    [OutputType([Hashtable])]
    Param(
        [Parameter(Mandatory = $True, Position = 0, ValueFromPipeline = $True)]
        [ScriptBlock] $ScriptBlock,
        [Parameter(Position = 1)]
        [Int] $Runs = 100,
        [Switch] $Milliseconds,
        [Switch] $Sample
    )
    $Results = @()
    $Units = if ($Milliseconds) { 'TotalMilliseconds' } else { 'Ticks' }
    for ($Index = 0; $Index -lt $Runs; $Index++) {
        Write-Progress -Activity 'Measuring Performance' -CurrentOperation "Run #$($Index + 1) of ${Runs}" -PercentComplete ([Math]::Ceiling(($Index / $Runs) * 100))
        $Results += (Measure-Command -Expression $ScriptBlock).$Units
    }
    Write-Progress -Activity 'Analyzing performance data...'
    $Minimum = Get-Minimum $Results
    $Maximum = Get-Maximum $Results
    $Mean = Get-Mean $Results
    $TrimmedMean = Get-Mean $Results -Trim 0.1
    $Median = Get-Median $Results
    $StandardDeviation = [Math]::Sqrt((Get-Variance $Results -Sample:$Sample))
    "Results for $Runs run(s) (values in $Units):" | Write-Verbose
    "==> Mean = $Mean" | Write-Verbose
    "==> Mean (10% trimmed) = $TrimmedMean" | Write-Verbose
    "==> Median = $Median" | Write-Verbose
    "==> Standard Deviation = $StandardDeviation" | Write-Verbose
    Write-Progress -Activity 'Measuring Performance' -Completed
    @{
        Min = $Minimum
        Max = $Maximum
        Range = ($Maximum - $Minimum)
        Mean = $Mean
        TrimmedMean = $TrimmedMean
        Median = $Median
        StandardDeviation = $StandardDeviation
        Runs = $Results
    }
}
function New-File {
    <#
    .SYNOPSIS
    PowerShell equivalent of linux "touch" command (includes "touch" alias)
    .EXAMPLE
    New-File <file name>
    .EXAMPLE
    touch <file name>
    #>
    [CmdletBinding(SupportsShouldProcess = $True)]
    [Alias('touch')]
    [OutputType([Bool])]
    Param(
        [Parameter(Mandatory = $True)]
        [String] $Name,
        [Switch] $PassThru
    )
    $Result = $False
    if (Test-Path $Name) {
        if ($PSCmdlet.ShouldProcess($Name)) {
            (Get-ChildItem $Name).LastWriteTime = Get-Date
            "==> Updated `"last write time`" of $Name" | Write-Verbose
            $Result = $True
        } else {
            "==> Would have updated `"last write time`" of $Name" | Write-Color -DarkGray
        }
    } else {
        if ($PSCmdlet.ShouldProcess($Name)) {
            New-Item -Path . -Name $Name -ItemType 'file' -Value '' -Force
            "==> Created new file, $Name" | Write-Verbose
            $Result = $True
        } else {
            "==> Would have created new file, $Name" | Write-Color -DarkGray
        }
    }
    if ($PassThru) {
        $Result
    }
}
function Out-Tree {
    <#
    .SYNOPSIS
    Output a tree of the input array
    .PARAMETER Limit
    Limit the depth of the tree
    Caution: Performance will be affected by excessive file depth
    .EXAMPLE
    @{ Foo = 1; Bar = 2; Baz = 3 } | Out-Tree
    # ├─ Foo
    # ├─ Bar
    # └─ Baz
    .EXAMPLE
    @{ Foo = 1; Bar = 2; Baz = 3 } | Out-Tree -Property Key
    # ├─ Bar
    # ├─ Baz
    # └─ Foo
    #>
    [CmdletBinding()]
    [OutputType([String])]
    Param(
        [Parameter(Mandatory = $True, Position = 0, ValueFromPipeline = $True)]
        $Items,
        [String] $Prefix = '',
        [String] $Property = 'Value',
        [Int] $Level = 1,
        [Int] $Limit = 3
    )
    Begin {
        $Pipe = '│'
        $Initial = ''
        function Get-LineContent {
            Param(
                [Parameter(Position = 0)]
                [String] $Value,
                [Switch] $IsTerminal,
                [Switch] $IsDirectory
            )
            $Branch = '├'
            $EmHyphen = '─'
            $TerminalBranch = '└'
            $FolderMarker = if ($IsDirectory) { '/' } else { '' }
            if ($IsTerminal) {
                "${TerminalBranch}${EmHyphen} ${Value}${FolderMarker}`r`n"
            } else {
                "${Branch}${EmHyphen} ${Value}${FolderMarker}`r`n"
            }
        }
        function Out-TreeStructure {
            Param(
                [Parameter(Position = 0)]
                $Items
            )
            if ($Items.Count -gt 0) {
                $Ordered = $Items | ConvertTo-OrderedDictionary -Property $Property
                $LastIndex = $Ordered.Count - 1
                $Index = 0
                foreach ($Value in $Ordered.Keys) {
                    $IsTerminal = $Index -eq $LastIndex
                    $IsEnumerableValue = Test-Enumerable $Ordered.$Value
                    $Content = Get-LineContent $Value -IsTerminal:$IsTerminal -IsDirectory:$IsEnumerableValue
                    $Initial += "${Prefix}${Content}"
                    if ($IsEnumerableValue -and ($Level -lt $Limit)) {
                        $Augment = if (-not $IsTerminal) { "${Pipe}  " } else { '   ' }
                        $Initial += Out-Tree $Ordered.$Value -Prefix "${Prefix}${Augment}" -Level ($Level + 1) -Limit $Limit
                    }
                    $Index += 1
                }
                $Initial
            }
        }
        Out-TreeStructure $Items
    }
    End {
        Out-TreeStructure $Input
    }
}
function Remove-DirectoryForce {
    <#
    .SYNOPSIS
    PowerShell equivalent of linux "rm -frd"
    .EXAMPLE
    rf ./path/to/folder
    #>
    [CmdletBinding(SupportsShouldProcess = $True)]
    [Alias('rf')]
    Param(
        [Parameter(Mandatory = $True, Position = 0, ValueFromPipeline = $True)]
        [ValidateScript( { Test-Path $_ })]
        [String] $Path
    )
    Process {
        $AbsolutePath = Get-StringPath $Path
        if ($PSCmdlet.ShouldProcess($AbsolutePath)) {
            "==> Deleting $AbsolutePath" | Write-Verbose
            Remove-Item -Path $AbsolutePath -Recurse -Force
            "==> Deleted $AbsolutePath" | Write-Verbose
        } else {
            "==> Would have deleted $AbsolutePath" | Write-Color -DarkGray
        }
    }
}
function Rename-FileExtension {
    <#
    .SYNOPSIS
    Change the extension of one or more files
    .EXAMPLE
    'foo.bar' | Rename-FileExtension -To 'baz'

    # New name of file will be 'foo.baz'
    #>
    [CmdletBinding(SupportsShouldProcess = $True)]
    [OutputType([String])]
    Param(
        [Parameter(Mandatory = $True, Position = 0, ValueFromPipeline = $True)]
        [String] $Path,
        [String] $To,
        [Switch] $TXT,
        [Switch] $JPG,
        [Switch] $PNG,
        [Switch] $GIF,
        [Switch] $MD,
        [Switch] $PassThru
    )
    Process {
        $NewExtension = if ($To.Length -gt 0) {
            $To
        } else {
            Find-FirstTrueVariable 'TXT', 'JPG', 'PNG', 'GIF', 'MD'
        }
        $NewName = [System.IO.Path]::ChangeExtension($Path, $NewExtension.ToLower())
        if ($PSCmdlet.ShouldProcess($Path)) {
            Rename-Item -Path $Path -NewName $NewName
            "==> Renamed $Path to $NewName" | Write-Verbose
        } else {
            "==> Rename $Path to $NewName" | Write-Color -DarkGray
        }
        if ($PassThru) {
            $NewName
        }
    }
}
function Test-Admin {
    <#
    .SYNOPSIS
    Helper function that returns true if user is in the "built-in" "admin" group, false otherwise
    .EXAMPLE
    Test-Admin
    #>
    [CmdletBinding()]
    [OutputType([Bool])]
    Param()
    if ($IsLinux -is [Bool] -and $IsLinux) {
        (whoami) -eq 'root'
    } else {
        ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator) | Write-Output
    }
}
function Test-Command {
    <#
    .SYNOPSIS
    Helper function that returns true if the command is available in the current shell, false otherwise
    .DESCRIPTION
    This function does the work of Get-Command, but without the necessary error when the passed command is not found.
    .EXAMPLE
    Test-Command 'dir'
    #>
    [CmdletBinding()]
    [OutputType([Bool])]
    Param(
        [Parameter(Mandatory = $True, Position = 0)]
        [String] $Name
    )
    $Result = $False
    $OriginalPreference = $ErrorActionPreference
    $ErrorActionPreference = 'stop'
    try {
        if (Get-Command -Name $Name) {
            "==> [INFO] '$Name' is an available command" | Write-Verbose
            $Result = $True
        }
    } Catch {
        "==> [INFO] '$Name' is not available command" | Write-Verbose
    } Finally {
        $ErrorActionPreference = $OriginalPreference
    }
    $Result
}
function Test-Empty {
    <#
    .SYNOPSIS
    Helper function that returns true if directory is empty, false otherwise
    .EXAMPLE
    echo someFolderName | Test-Empty
    .EXAMPLE
    dir . | %{Test-Empty $_.FullName}
    #>
    [CmdletBinding()]
    [ValidateNotNullorEmpty()]
    [OutputType([Bool])]
    Param(
        [Parameter(Mandatory = $True, ValueFromPipeline = $True)]
        [String] $Name
    )
    Get-Item $Name | ForEach-Object { $_.psiscontainer -and $_.GetFileSystemInfos().Count -eq 0 } | Write-Output
}
function Test-Installed {
    <#
    .SYNOPSIS
    Return $True if module is installed, $False otherwise
    .EXAMPLE
    Test-Installed 'Prelude'
    #>
    [CmdletBinding()]
    [OutputType([Bool])]
    Param(
        [Parameter(Mandatory = $True, Position = 0, ValueFromPipeline = $True)]
        [String] $Name
    )
    if (Get-Module -ListAvailable -Name $Name) {
        $True
    } else {
        $False
    }
}
function Use-Speech {
    <#
    .SYNOPSIS
    Load System.Speech type if it is not already loaded.
    #>
    [CmdletBinding()]
    [OutputType([Bool])]
    Param(
        [Switch] $PassThru
    )
    $Result = $False
    if ($IsLinux -is [Bool] -and $IsLinux) {
        Write-Verbose '==> Speech synthesizer can only be used on Windows platform'
    } else {
        $SpeechSynthesizerTypeName = 'System.Speech.Synthesis.SpeechSynthesizer'
        if (-not ($SpeechSynthesizerTypeName -as [Type])) {
            '==> Adding System.Speech type' | Write-Verbose
            Add-Type -AssemblyName System.Speech
        } else {
            '==> System.Speech is already loaded' | Write-Verbose
        }
        $Result = $True
    }
    if ($PassThru) {
        $Result
    }
}