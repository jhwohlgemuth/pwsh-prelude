
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
            $Path = (Resolve-Path $File).Path
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
function Enable-Remoting {
    <#
    .SYNOPSIS
    Function to enable Powershell remoting for workgroup computer
    .PARAMETER TrustedHosts
    Comma-separated list of trusted host names
    example: 'RED,WHITE,BLUE'
    .EXAMPLE
    Enable-Remoting
    .EXAMPLE
    Enable-Remoting -TrustedHosts 'MARIO,LUIGI'
    #>
    [CmdletBinding()]
    Param(
        [String] $TrustedHosts = '*',
        [Switch] $PassThru
    )
    if (Test-Admin) {
        Write-Verbose '==> Making network private'
        Get-NetConnectionProfile | Set-NetConnectionProfile -NetworkCategory Private
        $Path = 'WSMan:\localhost\Client\TrustedHosts'
        Write-Verbose '==> Enabling Powershell remoting'
        Enable-PSRemoting -Force -SkipNetworkProfileCheck
        Write-Verbose '==> Updated trusted hosts'
        Set-Item $Path -Value $TrustedHosts -Force
        if ($PassThru) {
            return Get-Item $Path
        }
    } else {
        Write-Error '==> Enable-Remoting requires Administrator privileges'
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
        $Job = Start-Job -Name 'Find-Duplicate' -ScriptBlock {
            . $Using:ModulePath
            Find-Duplicate -Path $Using:Path
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
    # returns 'Bar'
    #>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $True, Position = 0)]
        [Array] $VariableNames,
        [Int] $DefaultIndex = 0,
        $DefaultValue = $Null
    )
    $Index = $VariableNames | Get-Variable -ValueOnly | Find-FirstIndex
    if ($Index -is [Int]) {
        $VariableNames[$Index]
    } else {
        if ($Null -ne $DefaultValue) {
            $DefaultValue
        } else {
            $VariableNames[$DefaultIndex]
        }
    }
}
function Get-DefaultBrowser {
    <#
    .SYNOPSIS
    Get string name of user-selected default browser
    #>
    [CmdletBinding()]
    [OutputType([String])]
    Param()
    $Path = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.html\UserChoice\'
    $Abbreviation = if (Test-Path -Path $Path) {
        (Get-ItemProperty -Path $Path).ProgId.Substring(0, 2).ToUpper()
    } else {
        ''
    }
    switch ($Abbreviation) {
        'FI' { 'Firefox' }
        'IE' { 'IE' }
        'CH' { 'Chrome' }
        'OP' { 'Opera' }
        Default { 'Unknown' }
    }
}
function Get-File {
    <#
    .SYNOPSIS
    Download a file from an internet endpoint (ex: http://example.com/file.txt)
    .EXAMPLE
    Get-File http://example.com/file.txt
    .EXAMPLE
    Get-File http://example.com/file.txt -File myfile.txt
    .EXAMPLE
    'http://example.com/file.txt' | Get-File
    #>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $True, Position = 0, ValueFromPipeline = $True)]
        [String] $Url,
        [String] $File = 'download.txt'
    )
    $Client = New-Object System.Net.WebClient
    $Client.DownloadFile($Url, $File)
}
function Get-HostsContent {
    <#
    .SYNOPSIS
    Get and parse contents of hosts file
    .PARAMETER Path
    Specifies an alternate hosts path. Defaults to %SystemRoot%\System32\drivers\etc\hosts.
    .EXAMPLE
    Get-HostsContent
    .EXAMPLE
    Get-HostsContent '.\hosts'
    #>
    [CmdletBinding()]
    [OutputType([String])]
    Param(
        [Parameter(Position = 0, ValueFromPipeline = $True)]
        [ValidateScript( { Test-Path $_ })]
        [String] $Path
    )
    if (-not $Path) {
        $Path = if (-not $IsLinux) {
            Join-Path $Env:SystemRoot 'System32\drivers\etc\hosts'
        } else {
            '/etc/hosts'
        }
    }
    $CommentLine = '^\s*#'
    $HostLine = '^\s*(?<IPAddress>\S+)\s+(?<Hostname>\S+)(\s*|\s+#(?<Comment>.*))$'
    $HomeAddress = [Net.IPAddress]'127.0.0.1'
    $LineNumber = 0
    (Get-Content $Path -ErrorAction Stop) | ForEach-Object {
        if (($_ -match $HostLine) -and ($_ -notmatch $CommentLine)) {
            $IpAddress = $Matches['IPAddress']
            $Comment = if ($Matches['Comment']) { $Matches['Comment'] } else { '' }
            $Result = [PSCustomObject]@{
                LineNumber = $LineNumber
                IPAddress = $IpAddress
                IsValidIP = [Net.IPAddress]::TryParse($IPAddress, [Ref] $HomeAddress)
                Hostname = $Matches['Hostname']
                Comment = $Comment.Trim()
            }
            $Result.PSObject.TypeNames.Insert(0, 'Hosts.Entry')
            $Result
        }
        $LineNumber++
    }
}
function Get-Screenshot {
    <#
    .SYNOPSIS
    Create screenshot
    .DESCRIPTION
    Create screenshot of one or all monitors. The screenshot is saved as a BITMAP (bmp) file.

    When selecting a monitor, the assumed setup is:

    +-----+  +-----+  +-----+  +-----+
    |  1  |  |  2  |  |  3  |  | ... |  etc...
    +-----+  +-----+  +-----+  +-----+

    .PARAMETER Monitor
    Number that identifies desired monitor
    .EXAMPLE
    Get-Screenshot

    .EXAMPLE
    Get-Screenshot 'MyPictures'
    # save screenshot of all monitors (one BMP file) to '.\MyPictures\screenshot.bmp'
    .EXAMPLE
    1..3 | screenshot
    # save screenshot of each monitor, in separate BMP files
    #>
    [CmdletBinding()]
    [Alias('screenshot')]
    [OutputType([String])]
    Param(
        [Parameter(Position = 0)]
        [ValidateScript( { Test-Path $_ })]
        [String] $Path = (Get-Location),
        [Parameter(Position = 1)]
        [String] $Name = ("screenshot-$(Get-Date -UFormat '+%y%m%d%H%M%S')"),
        [Parameter(ValueFromPipeline = $True)]
        [Int] $Monitor = 0
    )
    Process {
        if ($IsLinux -is [Bool] -and $IsLinux) {
            '==> Get-Screenshot is only supported on Windows platform' | Write-Color -Red
        } else {
            [Void][System.Reflection.Assembly]::LoadWithPartialName('System.Drawing')
            [Void][System.Reflection.Assembly]::LoadWithPartialName('System.Windows.Forms')
            $ScreenBounds = [Windows.Forms.SystemInformation]::VirtualScreen
            $VideoController = Get-CimInstance -Query 'SELECT VideoModeDescription FROM Win32_VideoController'
            if ($VideoController.VideoModeDescription -and $VideoController.VideoModeDescription -match '(?<ScreenWidth>^\d+) x (?<ScreenHeight>\d+) x .*$') {
                $ScreenWidth = [Int]$Matches['ScreenWidth']
            }
            $UseDifferentMonitor = $ScreenWidth -and ($Monitor -gt 0)
            $Width = if ($UseDifferentMonitor) { $ScreenWidth } else { $ScreenBounds.Width }
            $Height = $ScreenBounds.Height
            $Left = if ($UseDifferentMonitor) { $ScreenBounds.X + ($ScreenWidth * ($Monitor - 1)) } else { $ScreenBounds.X }
            $Bottom = $ScreenBounds.Y
            $Size = New-Object 'System.Drawing.Size' @($Width, $Height)
            $Point = New-Object 'System.Drawing.Point' @($Left, $Bottom)
            $Screenshot = New-Object 'System.Drawing.Bitmap' @($Width, $Height)
            $DrawingGraphics = [System.Drawing.Graphics]::FromImage($Screenshot)
            $DrawingGraphics.CopyFromScreen($Point, [System.Drawing.Point]::Empty, $Size)
            $DrawingGraphics.Dispose()
            if ($UseDifferentMonitor) {
                $Fullname = Join-Path (Resolve-Path $Path) "$Name-$Monitor.bmp"
                "==> Saving screenshot of monitor #${Monitor} to $Fullname" | Write-Verbose
            } else {
                $Fullname = Join-Path (Resolve-Path $Path) "$Name.bmp"
                "==> Saving screenshot of all monitors to $Fullname" | Write-Verbose
            }
            $Screenshot.Save($Fullname)
            $Screenshot.Dispose()
            $Fullname
        }
    }
}
function Invoke-ListenForWord {
    <#
    .SYNOPSIS
    Start loop that listens for trigger words and execute passed functions when recognized
    .DESCRIPTION
    This function uses the Windows Speech Recognition. For best results, you should first improve speech recognition via Speech Recognition Voice Training.
    .EXAMPLE
    Invoke-Listen -Triggers 'hello' -Actions { Write-Color 'Welcome' -Green }
    .EXAMPLE
    Invoke-Listen -Triggers 'hello','quit' -Actions { say 'Welcome' | Out-Null; $True }, { say 'Goodbye' | Out-Null; $False }
    An action will stop listening when it returns a "falsy" value like $True or $Null. Conversely, returning "truthy" values will continue the listening loop.
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '', Scope = 'Function')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', 'Continue')]
    [CmdletBinding()]
    [Alias('listenFor')]
    Param(
        [Parameter(Mandatory = $True)]
        [String[]] $Triggers,
        [ScriptBlock[]] $Actions,
        [Double] $Threshhold = 0.85
    )
    Use-Speech
    $Engine = Use-Grammar -Words $Triggers
    $Continue = $True;
    Write-Color 'Listening for trigger words...' -Cyan
    while ($Continue) {
        $Recognizer = $Engine.Recognize();
        $Confidence = $Recognizer.Confidence;
        $Text = $Recognizer.text;
        if ($Text.Length -gt 0) {
            Write-Verbose "==> Heard `"$Text`""
        }
        $Index = 0
        $Triggers | ForEach-Object {
            if ($Text -match $_ -and [Double]$Confidence -gt $Threshhold) {
                $Continue = & $Actions[$Index]
            }
            $Index++
        }
    }
}
function Invoke-RemoteCommand {
    <#
    .SYNOPSIS
    Lightweight wrapper function for Invoke-Command that simplifies the interface and allows for using a string password directly
    .PARAMETER Parameters
    Object to pass parameters to underlying Invoke-Command call (ex: -Parameters @{ HideComputerName = $True })
    .EXAMPLE
    Invoke-RemoteCommand -ComputerNames PCNAME -Password 123456 { whoami }
    .EXAMPLE
    { whoami } | Invoke-RemoteCommand -ComputerNames PCNAME -Password 123456
    .EXAMPLE
    # This will open a prompt for you to input your password
    { whoami } | Invoke-RemoteCommand -ComputerNames PCNAME
    .EXAMPLE
    # Use the "irc" alias and execute commands on multiple computers!
    { whoami } | irc -ComputerNames Larry,Moe,Curly
    .EXAMPLE
    Get-Credential | Export-CliXml -Path .\crendential.xml
    { whoami } | Invoke-RemoteCommand -Credential (Import-Clixml -Path .\credential.xml) -ComputerNames PCNAME -Verbose
    .EXAMPLE
    irc '.\path\to\script.ps1'
    .EXAMPLE
    { Get-Process } | irc -Name Mario -Parameters @{ HideComputerName = $True }
    #>
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingPlainTextForPassword', 'Password')]
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUsePSCredentialType', '', Scope = 'Function')]
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingConvertToSecureStringWithPlainText', '', Scope = 'Function')]
    [CmdletBinding(DefaultParameterSetName = 'scriptblock')]
    [Alias('irc')]
    Param(
        [Parameter(ParameterSetName = 'scriptblock', Mandatory = $True, Position = 0, ValueFromPipeline = $True)]
        [ScriptBlock] $ScriptBlock,
        [Parameter(ParameterSetName = 'file', Mandatory = $True, Position = 0)]
        [ValidateScript( { Test-Path $_ })]
        [String] $FilePath,
        [Parameter(ParameterSetName = 'scriptblock', Mandatory = $True)]
        [Parameter(ParameterSetName = 'file', Mandatory = $True)]
        [Alias('Name')]
        [String[]] $ComputerName,
        [Parameter(ParameterSetName = 'scriptblock')]
        [Parameter(ParameterSetName = 'file')]
        [String] $Password,
        [Parameter(ParameterSetName = 'scriptblock')]
        [Parameter(ParameterSetName = 'file')]
        [PSObject] $Credential,
        [Parameter(ParameterSetName = 'scriptblock')]
        [Parameter(ParameterSetName = 'file')]
        [Switch] $AsJob,
        [Parameter(ParameterSetName = 'scriptblock')]
        [Parameter(ParameterSetName = 'file')]
        [PSObject] $Parameters = @{}
    )
    $User = whoami
    if ($Credential) {
        '==> Using -Credential for authentication' | Write-Verbose
        $Cred = $Credential
    } elseif ($Password) {
        "==> Creating credential for $User using -Password" | Write-Verbose
        $Pass = ConvertTo-SecureString -String $Password -AsPlainText -Force
        $Cred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $User, $Pass
    } else {
        $Cred = Get-Credential -Message "Please provide password to access $(Join-StringsWithGrammar $ComputerName)" -User $User
    }
    "==> Running command on $(Join-StringsWithGrammar $ComputerName)" | Write-Verbose
    $Execute = if ($FilePath) {
        @{ FilePath = $FilePath }
    } else {
        @{ ScriptBlock = $ScriptBlock }
    }
    Invoke-Command -ComputerName $ComputerName -Credential $Cred -AsJob:$AsJob @Execute @Parameters
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
    1,2,3 | %{ say $_ }
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
    Powershell equivalent of linux "touch" command (includes "touch" alias)
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
            New-Item -Path . -Name $Name -ItemType 'file' -Value ''
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
function New-ProxyCommand {
    <#
    .SYNOPSIS
    Create function template for proxy function
    .DESCRIPTION
    This function can be used to create a framework for a proxy function. If you want to create a proxy function for a command named Some-Command,
    you should pass "Some-Command" as the Name attribute - New-ProxyCommand -Name Some-Command
    .EXAMPLE
    New-ProxyCommand -Name 'Out-Default' | Out-File 'Out-Default.ps1'
    .EXAMPLE
    'Invoke-Item' | New-ProxyCommand | Out-File 'Invoke-Item-proxy.ps1'
    #>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $True, Position = 0, ValueFromPipeline = $True)]
        [String] $Name
    )
    $Metadata = New-Object System.Management.Automation.CommandMetadata (Get-Command $Name)
    Write-Output "
  function $Name
  {
    $([System.Management.Automation.ProxyCommand]::Create($Metadata))
  }"
}
function Open-Session {
    <#
    .SYNOPSIS
    Create interactive session with remote computer
    .PARAMETER NoEnter
    Create session(s) but do not enter a session
    .EXAMPLE
    Open-Session -ComputerNames PCNAME -Password 123456
    .EXAMPLE
    # This will open a prompt for you to input your password
    Open-Session -ComputerNames PCNAME
    .EXAMPLE
    $Sessions = Open-Session -ComputerNames ServerA,ServerB
    # This will open a password prompt and then display an interactive console menu to select ServerA or ServerB.
    # $Sessions will point to an array of sessions for ServerA and ServerB and can be used to make new sessions:
    Enter-PSSession -Session $Sessions[1]
    #>
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingPlainTextForPassword', 'Password')]
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUsePSCredentialType', '', Scope = 'Function')]
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingConvertToSecureStringWithPlainText', '', Scope = 'Function')]
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $True, Position = 0, ValueFromPipeline = $True)]
        [String[]] $ComputerNames,
        [String] $Password,
        [PSObject] $Credential,
        [Switch] $NoEnter
    )
    $User = whoami
    if ($Credential) {
        Write-Verbose '==> Using -Credential for authentication'
        $Cred = $Credential
    } elseif ($Password) {
        Write-Verbose "==> Creating credential for $User using -Password"
        $Pass = ConvertTo-SecureString -String $Password -AsPlainText -Force
        $Cred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $User, $Pass
    } else {
        $Cred = Get-Credential -Message "Please provide password to access $(Join-StringsWithGrammar $ComputerNames)" -User $User
    }
    Write-Verbose "==> Creating session on $(Join-StringsWithGrammar $ComputerNames)"
    $Session = New-PSSession -ComputerName $ComputerNames -Credential $Cred
    Write-Verbose '==> Entering session'
    if (-not $NoEnter) {
        if ($Session.Length -eq 1) {
            Enter-PSSession -Session $Session
        } else {
            Write-Label '{{#green Enter session?}}' -NewLine
            $Index = Invoke-Menu -Items $ComputerNames -ReturnIndex
            if ($Null -ne $Index) {
                Enter-PSSession -Session $Session[$Index]
            }
        }
    }
    $Session
}
function Remove-DirectoryForce {
    <#
    .SYNOPSIS
    Powershell equivalent of linux "rm -frd"
    .EXAMPLE
    rf <folder name>
    #>
    [CmdletBinding(SupportsShouldProcess = $True)]
    [Alias('rf')]
    Param(
        [Parameter(Mandatory = $True, Position = $True, ValueFromPipeline = $True)]
        [ValidateScript( { Test-Path $_ })]
        [String] $Path
    )
    Process {
        $AbsolutePath = Resolve-Path $Path
        if ($PSCmdlet.ShouldProcess($AbsolutePath)) {
            "==> Deleting $AbsolutePath" | Write-Verbose
            Remove-Item -Path $AbsolutePath -Recurse
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
    # new name of file will be 'foo.baz'
    #>
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '', Scope = 'Function')]
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
function Take {
    <#
    .SYNOPSIS
    Powershell equivalent of oh-my-zsh take function
    .DESCRIPTION
    Using take will create a new directory and then enter the driectory
    .EXAMPLE
    take <folder name>
    #>
    [CmdletBinding(SupportsShouldProcess = $True)]
    Param(
        [Parameter(Mandatory = $True)]
        [String] $Name
    )
    $Path = Join-Path (Get-Location) $Name
    if (Test-Path $Path) {
        "==> $Path exists" | Write-Verbose
        if ($PSCmdlet.ShouldProcess($Path)) {
            "==> Entering $Path" | Write-Verbose
            Set-Location $Path
        } else {
            "==> Would have entered $Path" | Write-Color -DarkGray
        }
    } else {
        if ($PSCmdlet.ShouldProcess($Path)) {
            "==> Creating $Path" | Write-Verbose
            mkdir $Path
            if (Test-Path $Path) {
                Write-Verbose "==> Entering $Path"
                Set-Location $Path
            }
        } else {
            "==> Would have created and entered $Path" | Write-Color -DarkGray
        }
    }
    Write-Verbose "==> pwd is $(Get-Location)"
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
        if (Get-Command $Name) {
            "==> '$Name' is an available command" | Write-Verbose
            $Result = $True
        }
    } Catch {
        "==> '$Name' is not available command" | Write-Verbose
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
    echo <folder name> | Test-Empty
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
function Update-HostsFile {
    <#
    .SYNOPSIS
    Update and/or add entries of a hosts file.
    .PARAMETER Path
    Specifies an alternate hosts path. Defaults to %SystemRoot%\System32\drivers\etc\hosts.
    .PARAMETER PassThru
    Outputs parsed HOSTS file upon completion.
    .EXAMPLE
    Update-HostsFile -IPAddress '127.0.0.1' -Hostname 'c2.evil.com'
    .EXAMPLE
    Update-HostsFile -IPAddress '127.0.0.1' -Hostname 'c2.evil.com' -Comment 'Malware C2'
    #>
    [CmdletBinding(SupportsShouldProcess = $True)]
    Param(
        [Parameter(Mandatory = $True, Position = 0)]
        [Alias('IP')]
        [Net.IpAddress] $IPAddress,
        [Parameter(Mandatory = $True, Position = 1)]
        [ValidateNotNullOrEmpty()]
        [Alias('Name')]
        [String] $Hostname,
        [Parameter(Position = 2)]
        [String] $Comment,
        [ValidateScript( { Test-Path $_ })]
        [String] $Path = (Join-Path $Env:SystemRoot 'System32\drivers\etc\hosts'),
        [Switch] $PassThru
    )
    $Raw = Get-Content $Path
    $Hosts = Get-HostsContent $Path
    $Comment = if ($Comment) { "# $Comment" } else { '' }
    $Entry = "$IpAddress $Hostname $Comment"
    $HostExists = $Hostname -in $Hosts.Hostname
    $Hosts | Where-Object { $_.Hostname -eq $Hostname } | ForEach-Object {
        if ($_.IpAddress -eq $IPAddress) {
            "The hostname, '$Hostname', and IP address, '$IPAddress', already exist in $Path." | Write-Verbose
        } else {
            if ($PSCmdlet.ShouldProcess($Path)) {
                "Replacing hostname, '$Hostname', in $Path." | Write-Verbose
                $Raw[$_.LineNumber] = $Entry
            } else {
                "==> Would be replacing hostname, '$Hostname', in $Path." | Write-Color -DarkGray
            }
        }
    }
    if (-not $HostExists) {
        if ($PSCmdlet.ShouldProcess($Path)) {
            "Appending '$Hostname' at '$IPAddress' to $Path." | Write-Verbose
            $Raw += "`n$Entry"
        } else {
            "==> Would be appending '$Hostname' at '$IPAddress' to $Path." | Write-Color -DarkGray
        }
    }
    $Raw | Out-File -Encoding ascii -FilePath $Path -ErrorAction Stop
    if ($PassThru) {
        Get-HostsContent $Path
    }
}
function Use-Grammar {
    <#
    .SYNOPSIS
    Create speech recognition engine, load grammars for words, and return the engine
    #>
    [CmdletBinding()]
    [OutputType([System.Speech.Recognition.SpeechRecognitionEngine])]
    Param(
        [Parameter(Mandatory = $True)]
        [String[]] $Words
    )
    Write-Verbose '==> Creating Speech Recognition Engine'
    $Engine = New-Object 'System.Speech.Recognition.SpeechRecognitionEngine';
    $Engine.InitialSilenceTimeout = 15
    $Engine.SetInputToDefaultAudioDevice();
    foreach ($Word in $Words) {
        "==> Loading grammar for $Word" | Write-Verbose
        $Grammar = New-Object 'System.Speech.Recognition.GrammarBuilder';
        $Grammar.Append($Word)
        $Engine.LoadGrammar($Grammar)
    }
    $Engine
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