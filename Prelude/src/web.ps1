[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingPlainTextForPassword', '', Scope = 'Function', Target = 'Invoke-WebRequestBasicAuth')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingUsernameAndPasswordParams', '', Scope = 'Function', Target = 'Invoke-WebRequestBasicAuth')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '', Scope = 'Function', Target = 'Add-Metadata')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '', Scope = 'Function', Target = 'Invoke-WebRequestBasicAuth')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '', Scope = 'Function', Target = 'Out-Browser')]
Param()

class Options {
    [String[]] GetProperties() {
        return $this | Get-Member -MemberType Properties | Select-Object -ExpandProperty Name
    }
    [PSObject] SetProperties($Object) {
        $this.GetProperties() | ForEach-Object { $Object.$_ = $this.$_ }
        return $Object
    }
}
class FormOptions: Options {
    [Int] $Width = 960
    [Int] $Height = 700
    [Int] $FormBorderStyle = 3
    [Double] $Opacity = 1.0
    [Bool] $ControlBox = $True
    [Bool] $MaximizeBox = $False
    [Bool] $MinimizeBox = $False
}
class BrowserOptions: Options {
    [String] $Anchor = 'Left,Top,Right,Bottom'
    [PSObject] $Size = @{ Height = 700; Width = 960 }
    [Bool] $IsWebBrowserContextMenuEnabled = $False
}
function Add-Metadata {
    <#
    .SYNOPSIS
    Identify certain elements and wrap them in semantic HTML tags.
    .EXAMPLE
    'My email is foo@bar.com' | ConvertTo-Html
    #>
    Param(
        [Parameter(Mandatory = $True, Position = 0, ValueFromPipeline = $True)]
        [String] $Text,
        [String[]] $Keyword,
        [Hashtable] $Abbreviations,
        [Switch] $Microformat,
        [ValidateSet('all', 'date', 'duration', 'email', 'url', 'ip')]
        [String[]] $Disable
    )
    Begin {
        $Custom = [Regex](($Keyword | ForEach-Object { "(\b${_}\b)" }) -join '|' )
        $Date = [Regex](New-RegexString -Date)
        $Duration = [RegEx](New-RegexString -Duration)
        $Email = [Regex](New-RegexString -Email)
        $Url = [Regex](New-RegexString -Url)
        $IpAdress = [Regex](New-RegexString -IPv4 -IPv6)
        $Attributes = @{
            Custom = 'itemprop="thing"'
            Date = 'itemscope itemtype="https://schema.org/DateTime" class="dt-event"'
            Duration = 'itemscope itemprop="event" itemtype="https://schema.org/Event" class="duration dt-event"'
            Email = 'itemscope itemprop="email" itemtype="https://schema.org/email" class="u-email"'
            End = 'itemscope itemprop="endTime" itemtype="https://schema.org/Time" class="dt-end"'
            Start = 'itemscope itemprop="startTime" itemtype="https://schema.org/Time" class="dt-start"'
            Url = 'itemscope itemprop="url" itemtype="https://schema.org/URL" class="u-url"'
        }
        $Options = [Text.RegularExpressions.RegexOptions]'IgnoreCase, CultureInvariant'
    }
    Process {
        If ($Keyword.Count -gt 0) {
            $Text = [Regex]::Replace(
                $Text,
                $Custom,
                {
                    Param($Match)
                    $Value = $Match.Value
                    $ClassName = $Value -replace '\s', '-'
                    if ($Microformat) {
                        "<span $($Attributes.Custom) class=`"keyword p-item`" data-keyword=`"${ClassName}`">${Value}</span>"
                    } else {
                        "<span class=`"keyword`" data-keyword=`"${ClassName}`">${Value}</span>"
                    }
                }
            )
        }
        if ($Abbreviations.Count -gt 0) {
            $Items = $Abbreviations.GetEnumerator()
            foreach ($Item in $Items) {
                $Name = $Item.Name
                $Value = $Item.Value
                $Text = [Regex]::Replace(
                    $Text,
                    "\b${Value}\b",
                    {
                        Param($Match)
                        $Value = $Match.Value
                        "<abbr title=`"${Name}`">${Value}</abbr>"
                    }
                )
            }
        }
        if ('all' -notin $Disable) {
            switch ($True) {
                { 'url' -notin $Disable } {
                    $Text = [Regex]::Replace(
                        $Text,
                        $Url,
                        {
                            Param($Match)
                            $Value = $Match.Groups[1].Value
                            if ($Microformat) {
                                "<a $($Attributes.Url) href=`"${Value}`">${Value}</a>"
                            } else {
                                "<a href=`"${Value}`">${Value}</a>"
                            }
                        },
                        $Options
                    )
                }
                { 'date' -notin $Disable } {
                    $Text = [Regex]::Replace(
                        $Text,
                        $Date,
                        {
                            Param($Match)
                            $Value = $Match.Groups[1].value
                            $Data = $Value | Test-Match -Date
                            $IsoValue = [DateTime]"$($Data.Month)/$($Data.Day)/$($Data.Year)" | ConvertTo-Iso8601
                            if ($Microformat) {
                                "<time $($Attributes.Date) datetime=`"${IsoValue}`">${Value}</time>"
                            } else {
                                "<time datetime=`"${IsoValue}`">${Value}</time>"
                            }
                        },
                        $Options
                    )
                }
                { 'duration' -notin $Disable } {
                    $Text = [Regex]::Replace(
                        $Text,
                        $Duration,
                        {
                            Param($Match)
                            $Value = $Match.Groups[1].value
                            $Data = $Value | Test-Match -Duration
                            $Start = $Data.Start
                            $End = $Data.End
                            $Timezone = if ($Data.IsZulu) { ' data-timezone="Zulu"' } else { '' }
                            if ($Microformat) {
                                "<span $($Attributes.Duration)${Timezone}><time $($Attributes.Start) datetime=`"${Start}`">${Start}</time> - <time $($Attributes.End) datetime=`"${End}`">${End}</time></span>"
                            } else {
                                "<span class=`"duration`"${Timezone}><time datetime=`"${Start}`">${Start}</time> - <time datetime=`"${End}`">${End}</time></span>"
                            }
                        },
                        $Options
                    )
                }
                { 'email' -notin $Disable } {
                    $Text = [Regex]::Replace(
                        $Text,
                        $Email,
                        {
                            Param($Match)
                            $Value = $Match.Groups[1].Value
                            if ($Microformat) {
                                "<a $($Attributes.Email) href=`"mailto:${Value}`">${Value}</a>"
                            } else {
                                "<a href=`"mailto:${Value}`">${Value}</a>"
                            }
                        },
                        $Options
                    )
                }
                { 'ip' -notin $Disable } {
                    $Text = [Regex]::Replace(
                        $Text,
                        $IpAdress,
                        {
                            Param($Match)
                            $Value = $Match.Groups[1].Value
                            "<a class=`"ip`" href=`"${Value}`">${Value}</a>"
                        },
                        $Options
                    )
                }
            }
        }
        $Text
    }
}
function ConvertFrom-ByteArray {
    <#
    .SYNOPSIS
    Converts bytes to human-readable text
    #>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $True, Position = 0, ValueFromPipeline = $True)]
        [Array] $Data
    )
    Begin {
        function Invoke-Convert {
            Param(
                [Parameter(Position = 0)]
                $Data
            )
            if ($Data.Length -gt 0) {
                if ($Data -is [Byte] -or $Data[0] -is [Byte]) {
                    [System.Text.Encoding]::ASCII.GetString($Data)
                } else {
                    $Data
                }
            }
        }
        Invoke-Convert $Data
    }
    End {
        Invoke-Convert $Input
    }
}
function ConvertFrom-EpochDate () {
    <#
    .SYNOPSIS
    Converts epoch dates into datetime values
    .PARAMETER Epoch
    The epoch to use in conversion
    (Default value is '01.01.1970')
    .EXAMPLE
    '1577836800' | ConvertFrom-EpochDate -AsString
    # '1/1/20'
    .EXAMPLE
    '1577836800000000' | ConvertFrom-EpochDate -Microseconds -AsString
    # '1/1/20'
    #>
    [CmdletBinding()]
    [OutputType([System.String])]
    [OutputType([DateTime])]
    Param(
        [Parameter(Position = 0, ValueFromPipeline = $True)]
        [BigInt] $Value,
        [Switch] $Milliseconds,
        [Switch] $Microseconds,
        [Switch] $AsString,
        [String] $Epoch = '01.01.1970',
        [String] $Format = 'M/d/y'
    )
    $Units = if ($Milliseconds) {
        1000
    } elseif ($Microseconds) {
        1000000
    } else {
        1
    }
    $Result = (Get-Date $Epoch) + ([System.TimeSpan]::fromseconds($Value / $Units))
    if ($AsString) {
        $Result.ToString($Format)
    } else {
        $Result
    }
}
function ConvertFrom-Html {
    <#
    .SYNOPSIS
    Convert HTML string into object.
    .EXAMPLE
    '<html><body><h1>hello</h1></body></html>' | ConvertFrom-Html
    #>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $True, Position = 0, ValueFromPipeline = $True)]
        [String] $Value
    )
    $Html = New-Object -ComObject 'HTMLFile'
    try {
        # This works in PowerShell with Office installed
        $Html.IHTMLDocument2_write($Value)
    } catch {
        # This works when Office is not installed
        $Content = [System.Text.Encoding]::Unicode.GetBytes($Value)
        $Html.Write($Content)
    }
    $Html
}
function ConvertFrom-QueryString {
    <#
    .SYNOPSIS
    Returns parsed query parameters
    #>
    [CmdletBinding()]
    [OutputType([Object[]])]
    [OutputType([String])]
    Param(
        [Parameter(Mandatory = $True, Position = 0, ValueFromPipeline = $True)]
        [String] $Query
    )
    Begin {
        Use-Web
    }
    Process {
        $Decoded = [System.Web.HttpUtility]::UrlDecode($Query)
        if ($Decoded -match '=') {
            $Decoded -split '&' | Invoke-Reduce {
                Param($Acc, $Item)
                $Key, $Value = $Item -split '='
                $Acc.$Key = $Value.Trim()
            } -InitialValue @{}
        } else {
            $Decoded
        }
    }
}
function ConvertTo-Iso8601 {
    <#
    .SYNOPSIS
    Convert value to date in ISO 8601 format
    .NOTES
    See https://www.iso.org/iso-8601-date-and-time-format.html
    #>
    [CmdletBinding()]
    Param(
        [Parameter(Position = 0, ValueFromPipeline = $True)]
        [String] $Value
    )
    Process {
        $Value | Get-Date -UFormat '+%Y-%m-%dT%H:%M:%S.000Z'
    }
}
function ConvertTo-JavaScript {
    <#
    .SYNOPSIS
    Convert PowerShell values to JavaScript strings. It is similar to ConvertTo-Json, but with broader support for Prelude types.
    .EXAMPLE
    $A = [Node]'A'
    $B = [Node]'B'
    $A, $B | ConvertTo-JavaScript
    .EXAMPLE
    @{ foo = 'bar' } | ConvertTo-JavaScript
    # returns {"foo":"bar"}
    .NOTES
    The ConvertTo-JavaScript cmdlet is not intended to be used as a data serializer as data is removed during conversion.
    #>
    [CmdletBinding()]
    [OutputType([System.String])]
    Param(
        [Parameter(Mandatory = $True, Position = 0, ValueFromPipeline = $True)]
        $Value
    )
    Begin {
        $CoordinateTemplate = {
            Param($Value)
            "{latitude: $($Value.Latitude), longitude: $($Value.Longitude), height: $($Value.Height), hemisphere: '$($Value.Hemisphere -join '')'}"
        }
        $MatrixTemplate = {
            Param($Value)
            $Rows = $Value.Values.Real |
                Invoke-Chunk -Size $Value.Size[1] |
                ForEach-Object { $_ -join ', ' } |
                ForEach-Object { "[$_]" }
            "[$($Rows -join ', ')]"
        }
        $NodeTemplate = {
            Param($Value)
            "{id: '$($Value.Id)', label: '$($Value.Label)'}"
        }
        $EdgeTemplate = {
            Param($Value)
            $Source = (& $NodeTemplate -Value $Value.Source)
            $Target = (& $NodeTemplate -Value $Value.Target)
            "{source: $Source, target: $Target}"
        }
        $GraphTemplate = {
            Param($Value)
            "{nodes: $($Value.Nodes | ConvertTo-JavaScript), edges: $($Value.Edges | ConvertTo-JavaScript)}"
        }
        $DefaultTemplate = {
            Param($Value)
            $Value | ConvertTo-Json -Compress
        }
        function Invoke-Convert {
            Param($Value)
            $Type = $Value.GetType().Name
            $Template = switch ($Type) {
                'Coordinate' { $CoordinateTemplate }
                'Matrix' { $MatrixTemplate }
                'Node' { $NodeTemplate }
                'DirectedEdge' { $EdgeTemplate }
                'Edge' { $EdgeTemplate }
                'Graph' { $GraphTemplate }
                Default { $DefaultTemplate }
            }
            & $Template -Value $Value
        }
        switch ($Value.Count) {
            1 {
                Invoke-Convert -Value $Value
            }
            { $_ -gt 1 } {
                "[$(($Value | ForEach-Object { Invoke-Convert -Value $_ }) -join ', ')]"
            }
        }
    }
    End {
        switch ($Input.Count) {
            1 {
                Invoke-Convert -Value $Input[0]
            }
            { $_ -gt 1 } {
                "[$(($Input | ForEach-Object { Invoke-Convert -Value $_ }) -join ', ')]"
            }
        }
    }
}
function ConvertTo-QueryString {
    <#
    .SYNOPSIS
    Returns URL-encoded query string
    #>
    [CmdletBinding()]
    [OutputType([String])]
    Param(
        [Parameter(Mandatory = $True, Position = 0, ValueFromPipeline = $True)]
        [PSObject] $InputObject,
        [Switch] $UrlEncode
    )
    Begin {
        Use-Web
    }
    Process {
        $Callback = {
            Param($Acc, $Item)
            $Key = $Item.Name
            $Value = $Item.Value
            "${Acc}$(if ($Acc -ne '') { '&' } else { '' })${Key}=${Value}"
        }
        $QueryString = $InputObject.GetEnumerator() | Sort-Object Name | Invoke-Reduce $Callback ''
        if (-not $QueryString) {
            $QueryString = ''
        }
        if ($UrlEncode) {
            Add-Type -AssemblyName System.Web
            [System.Web.HttpUtility]::UrlEncode($QueryString)
        } else {
            $QueryString
        }
    }
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
    $HostLine = '^\s*(?<IPAddress>[01-9\.\:]+)\s+(?<Hostname>[^#]+)(\s*|\s+#(?<Comment>.*))$'
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
                Hostname = $Matches['Hostname'].Trim()
                Comment = $Comment.Trim()
            }
            $Result.PSObject.TypeNames.Insert(0, 'Hosts.Entry')
            $Result
        }
        $LineNumber++
    }
}
function Get-HtmlElement {
    <#
    .SYNOPSIS
    Helper utility for getting elements as an array from HTML formatted input using tagname, id, or class name
    .EXAMPLE
    $Html | Get-HtmlElement 'div'
    .EXAMPLE
    $Html | Get-HtmlElement '.some-class'
    .EXAMPLE
    $Html | Get-HtmlElement '#some-identifier'
    #>
    [CmdletBinding()]
    [OutputType([System.Object[]])]
    Param(
        [Parameter(ValueFromPipeline = $True)]
        $InputObject,
        [Parameter(Mandatory = $True, Position = 0)]
        [String] $Selector
    )
    Process {
        $InputType = $InputObject.GetType().Name
        $Html = if ($InputType -eq 'String') {
            $InputObject | ConvertFrom-Html
        } else {
            $InputObject
        }
        $Elements = @()
        switch -Regex ($Selector) {
            '^[.].*' {
                $ClassName = $_ | Remove-Character -At 0
                foreach ($Element in $Html.all) {
                    if ($Element.className -eq $ClassName) {
                        $Elements += $Element
                    }
                }
            }
            '^#.*' {
                $Id = $_ | Remove-Character -At 0
                foreach ($Element in $Html.getElementById($Id)) {
                    $Elements += $Element
                }
            }
            Default {
                foreach ($Element in $Html.all.tags($Selector)) {
                    $Elements += $Element
                }
            }
        }
        $Elements
    }
}
function Import-Html {
    <#
    .SYNOPSIS
    Import and parse an a local HTML file or web page.
    .EXAMPLE
    Import-Html example.com | ForEach-Object { $_.body.innerHTML }
    .EXAMPLE
    Import-Html .\bookmarks.html | ForEach-Object { $_.all.tags('a') } | Selelct-Object -ExpandProperty textContent
    #>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $True, Position = 0, ValueFromPipeline = $True)]
        [Alias('Uri')]
        [String] $Path
    )
    if (Test-Path $Path) {
        $Content = Get-Content -Path $Path -Raw
    } else {
        $Content = (Invoke-WebRequest -Uri $Path).Content
    }
    ConvertFrom-Html $Content
}
function Invoke-WebRequestBasicAuth {
    <#
    .SYNOPSIS
    Invoke-WebRequest wrapper that makes it easier to use basic authentication
    .PARAMETER TwoFactorAuthentication
    Name of API that requires 2FA. Use 'none' when 2FA is not required.
    Possible values:
        - 'Github'
        - 'none' [Default]
    .PARAMETER Data
    Data (Body) payload for HTTP request. Will only function with PUT and POST requests.
    ==> Analogous to the '-d' cURL flag
    ==> Data object will be converted to JSON string
    .PARAMETER Session
    Name for custom web session variable.
    This cmdlet will try to remember the session variable, by default.  Use -DisableSession to disable this behavior.
    See https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.utility/invoke-webrequest?view=powershell-7.2#example-2-use-a-stateful-web-service
    .PARAMETER Download
    Download content at URI.
    .PARAMETER WebRequestParameters
    Object for passing parameters to underlying invocation of Invoke-WebRequest
    Note: "Custom" is an alias for this parameter
    .EXAMPLE
    # Authenticate a GET request with a token
    $Uri = 'https://api.github.com/notifications'
    $Query = @{ per_page = 100; page = 1 }
    $Response = Invoke-WebRequestBasicAuth $Uri -Token $Token -Query $Query -ParseContent
    $Response | Format-Table -AutoSize
    .EXAMPLE
    # Use basic authentication with a username and password
    $Uri = 'https://api.github.com/notifications'
    $Query = @{ per_page = 100; page = 1 }
    $Response = Invoke-WebRequestBasicAuth $Uri -Username $Username -Password $Token -Query $Query -ParseContent
    $Response | Format-Table -AutoSize
    .EXAMPLE
    # Execute a PUT request with a data payload
    $Uri = 'https://api.github.com/notifications'
    @{ last_read_at = '' } | BasicAuth $Uri -Put -Token $Token
    .EXAMPLE
    $Uri = 'https://api.github.com/notifications'
    $Parameters = @{
        SkipCertificateChecks = $True
    }
    @{ last_read_at = '' } | basicauth $Uri -Put -Token $Token -Custom $Parameters
    .EXAMPLE
    # Download and parse an API JSON response (can also parse HTML and CSV content)
    $Uri = 'https://db.ygoprodeck.com/api/v7/cardinfo.php
    basicauth $Uri -Query @{ name = 'Galaxy-Eyes Photon Dragon' } -ParseContent
    #>
    [CmdletBinding(DefaultParameterSetName = 'none', SupportsShouldProcess = $True)]
    [Alias('basicauth')]
    Param(
        [Parameter(ParameterSetName = 'basic')]
        [String] $Username,
        [Parameter(ParameterSetName = 'basic')]
        [String] $Password,
        [Parameter(ParameterSetName = 'token')]
        [String] $Token,
        [PSObject] $Headers = @{},
        [String] $Session = 'PreludeBasicAuthSession',
        [Switch] $DisableSession,
        [Parameter(Mandatory = $True, Position = 0)]
        [UriBuilder] $Uri,
        [PSObject] $Query = @{},
        [Switch] $UrlEncode,
        [Switch] $Download,
        [ValidateScript( { Test-Path $_ })]
        [String] $Folder = (Get-Location).Path,
        [Switch] $ParseContent,
        [Alias('OTP')]
        [String] $TwoFactorAuthentication = 'none',
        [Switch] $Get,
        [Switch] $Post,
        [Switch] $Put,
        [Switch] $Delete,
        [Parameter(ValueFromPipeline = $True)]
        [PSObject] $Data = @{},
        [Alias('Custom')]
        [PSObject] $WebRequestParameters = @{}
    )
    Begin {
        function Get-ParsedContent {
            Param(
                [Parameter(Mandatory = $True, Position = 0)]
                $Request
            )
            $Content = $Request.Content
            $Type = $Request.Headers.'Content-Type'
            switch -Regex ($Type) {
                '^text\/csv' {
                    $Content | ConvertFrom-Csv
                }
                '^text\/html' {
                    $Content | ConvertFrom-Html
                }
                '^application\/xhtml[+]xml' {
                    $Content | ConvertFrom-Html
                }
                '^application\/json' {
                    $Content | ConvertFrom-Json
                }
                '^text\/(plain|css|javascript)' {
                    "==> [INFO] Cannot parse content of type, ${Type}" | Write-Verbose
                    $Content
                }
                '^(image|video|font|audio|model)\/' {
                    "==> [INFO] Cannot parse content of type, ${Type}" | Write-Verbose
                    $Content
                }
                Default {
                    "==> [WARN] Unable to resolve type, ${Type}" | Write-Warning
                    $Content
                }
            }
        }
        function Write-ObjectData {
            Param(
                [Parameter(Mandatory = $True, Position = 0, ValueFromPipeline = $True)]
                $Object
            )
            foreach ($Pair in $Object.GetEnumerator()) {
                $Key = $Pair.Key
                $Value = $Pair.Value
                $Value = if ($Value -is [Hashtable]) {
                    $Value | ConvertTo-Json -Compress
                } else {
                    $Value
                }
                "     ${Key}: ${Value}," | Write-Color -DarkGray
            }
        }
    }
    Process {
        if ($PSBoundParameters.ContainsKey('Password') -or $PSBoundParameters.ContainsKey('Token')) {
            $Headers.Authorization = if ($Token.Length -gt 0) {
                "Bearer $Token"
            } else {
                $Credential = [Convert]::ToBase64String([System.Text.Encoding]::Ascii.GetBytes("${Username}:${Password}"))
                "Basic $Credential"
            }
        }
        switch ($TwoFactorAuthentication) {
            'github' {
                if ($PSCmdlet.ShouldProcess('GitHub 2FA')) {
                    'GitHub 2FA' | Write-Title -Green
                    $Code = 'Code:' | Invoke-Input -Number -Indent 4
                    $Headers.Accept = 'application/vnd.github.v3+json'
                    $Headers['x-github-otp'] = $Code
                } else {
                    '==> [DRYRUN] Would have set Accept and x-github-otp headers' | Write-Color -DarkGray
                }
            }
            Default {
                # Do nothing
            }
        }
        $Method = Find-FirstTrueVariable 'Get', 'Post', 'Put', 'Delete'
        $Uri.Query = $Query | ConvertTo-QueryString -UrlEncode:$UrlEncode
        $Parameters = @{
            Headers = $Headers
            Method = $Method
            Uri = $Uri.Uri
        }
        if ($Method -in 'Post', 'Put') {
            $Parameters.Body = $Data | ConvertTo-Json
        }
        if (-not $DisableSession) {
            $WebSession = Get-Variable -Name $Session -ValueOnly -ErrorAction Ignore
            if ($WebSession -is [Microsoft.PowerShell.Commands.WebRequestSession]) {
                $Parameters.WebSession = $WebSession
            } else {
                $Parameters.SessionVariable = $Session
            }
        }
        $OutFile = Join-Path $Folder (Split-Path $Uri.Path -Leaf)
        if ($Download) {
            $Parameters.OutFile = $OutFile
        }
        if ($PSCmdlet.ShouldProcess('Invoke-WebRequest')) {
            $Request = Invoke-WebRequest @Parameters @WebRequestParameters -UseBasicParsing
        } else {
            '==> [DRYRUN] Would have called Invoke-WebRequest with the parameters:' | Write-Color -DarkGray
            $Parameters, $WebRequestParameters | Invoke-ObjectMerge | Write-ObjectData
        }
        if ($ParseContent) {
            if ($PSCmdlet.ShouldProcess('Parse content')) {
                $Content = Get-ParsedContent $Request
                if ($Download) {
                    $Parameters = @{
                        Encoding = 'default'
                        FilePath = $OutFile
                    }
                    $Content | Out-File @Parameters | Out-Null
                } else {
                    $Content
                }
            } else {
                '==> [DRYRUN] Would have returned parsed response content' | Write-Color -DarkGray
            }
        } else {
            if ($PSCmdlet.ShouldProcess('Return request response')) {
                $Request
            } else {
                '==> [DRYRUN] Would have returned response' | Write-Color -DarkGray
            }
        }
    }
}
function Out-Browser {
    <#
    .SYNOPSIS
    Display HTML content (string, file, or URI) in a web browser Windows form. Out-Browser will auto-detect content type.
    Returns [System.Windows.Forms.HtmlDocument] object
    .PARAMETER OnShown
    Function to be executed once form is shown. $Form and $Browser variables are available within function scope.
    .PARAMETER OnComplete
    Function to be executed whenever the Document within the browser is loaded. $Form and $Browser variables are available within function scope.
    .PARAMETER OnClose
    Function to be executed immediately before form is disposed. $Form and $Browser variables are available within function scope.
    .PARAMETER Default
    Use operating system default browser (i.e. Firefox, Chrome, etc...) instead of WebBrowser control.
    Note: OnShown, OnComplete, and OnClose will not be run when the Default parameter is used.
    .PARAMETER PassThru
    - Return WebBrowser document object when not using -Default parameter
    - Return process when using -Default parameter
    .EXAMPLE
    '<h1>Hello World</h1>' | Out-Browser
    .EXAMPLE
    'https://google.com' | Out-Browser
    .EXAMPLE
    '.\file.html' | Out-Browser
    .EXAMPLE
    $OnClose = {
        Param($Browser)
        $Browser.Document.GetElementsByTagName('h1').innerText | Write-Color -Green
    }
    '<h1 contenteditable="true">Type Here</h1>' | Out-Browser -OnClose $OnClose | Out-Null
    #>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $True, Position = 0, ValueFromPipeline = $True)]
        [String] $Content,
        [FormOptions] $FormOptions = @{},
        [BrowserOptions] $BrowserOptions = @{},
        [ScriptBlock] $OnShown = {},
        [ScriptBlock] $OnComplete = {},
        [ScriptBlock] $OnClose = {},
        [Switch] $Default,
        [Switch] $PassThru
    )
    Begin {
        Use-Web -Browser
        $Form = $FormOptions.SetProperties((New-Object 'Windows.Forms.Form'))
        $Browser = $BrowserOptions.SetProperties((New-Object 'Windows.Forms.WebBrowser'))
        $Browser.Size = @{ Width = $Form.Width; Height = $Form.Height }
        $Form.Controls.Add($Browser)
        $ShownCallback = {
            '==> Form shown' | Write-Verbose
            $Form.BringToFront()
            & $OnShown -Form $Form -Browser $Browser
        }
        $CompletedCallback = {
            "==> Document load complete ($($_.Url))" | Write-Verbose
            & $OnComplete -Form $Form -Browser $Browser
        }
        $Form.Add_Shown($ShownCallback);
        $Browser.Add_DocumentCompleted($CompletedCallback)
    }
    Process {
        "==> Browser is $(if($Browser.IsOffline) { 'OFFLINE' } else { 'ONLINE' })" | Write-Verbose
        $IsFile = if (Test-Path $Content -IsValid) { Test-Path $Content } else { $False }
        $IsUri = ([Uri]$Content).IsAbsoluteUri
        if ($Default) {
            $FilePath = if ($IsFile -or $IsUri) {
                $Content
            } else {
                $TempRoot = if ($IsLinux) { '/tmp' } else { $Env:temp }
                $Path = Join-Path $TempRoot 'content.html'
                $Content | Set-Content -Path $Path
                $Path
            }
            $Process = Start-Process -FilePath $FilePath -PassThru
            if ($PassThru) {
                return $Process
            }
        } else {
            if ($IsFile) {
                "==> Opening ${Content}..." | Write-Verbose
                $Browser.Navigate("file:///$(Get-Item $Content | Get-StringPath)")
            } elseif ($IsUri) {
                "==> Navigating to ${Content}..." | Write-Verbose
                $Browser.Navigate([Uri]$Content)
            } else {
                '==> Opening HTML in WebBrowser control...' | Write-Verbose
                $Browser.DocumentText = "$Content"
            }
            if ($Form.ShowDialog() -ne 'OK') {
                $Document = $Browser.Document
                '==> Browser closing...' | Write-Verbose
                & $OnClose -Form $Form -Browser $Browser
                $Form.Dispose()
                '==> Form disposed' | Write-Verbose
                if ($PassThru) {
                    return $Document
                }
            }
        }
    }
}
function Save-File {
    <#
    .SYNOPSIS
    Download and save a file from a local or remote location.
    .PARAMETER SleepInterval
    Initial number of seconds to wait before checking if BitsTransfer job is complete.
    .PARAMETER WebClient
    Use .NET Web Client class instead of BitsTransfer.
    See https://docs.microsoft.com/en-us/dotnet/api/system.net.webclient
    .PARAMETER CustomParameters
    Parameters to pass to Start-BitsTransfer.
    .EXAMPLE
    'https://storage.googleapis.com/ygoprodeck.com/pics/93717133.jpg' | Save-File 'dragon.jpg'
    .EXAMPLE
    'https://storage.googleapis.com/ygoprodeck.com/pics/93717133.jpg' | Save-File 'dragon.jpg' -Asynchronous -Priority 'High'
    #>
    [CmdletBinding(DefaultParameterSetName = 'normal', SupportsShouldProcess = $True)]
    Param(
        [Parameter(Mandatory = $True, ValueFromPipeline = $True)]
        [UriBuilder] $Uri,
        [ValidateScript( { Test-Path $_ })]
        [String] $Destination = (Get-Location).Path,
        [Parameter(Position = 0)]
        [String[]] $Filename,
        [Parameter(ParameterSetName = 'asynchronous')]
        [Switch] $Asynchronous,
        [Parameter(ParameterSetName = 'asynchronous')]
        [Switch] $PassThru,
        [ValidateSet('Foreground', 'High', 'Normal', 'Low')]
        [String] $Priority = 'Foreground',
        [Parameter(ParameterSetName = 'asynchronous')]
        [Int] $SleepInterval = 1,
        [Switch] $WebClient,
        [PSObject] $CustomParameters = @{}
    )
    Begin {
        function Format-FileVersion {
            Param(
                [Parameter(Mandatory = $True, Position = 0, ValueFromPipeline = $True)]
                [String] $Name
            )
            $Elapsed = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()
            $Extension = [System.IO.Path]::GetExtension($Name)
            $Filename = $Name.Substring(0, $Name.Length - $Extension.Length)
            "${Filename}-${Elapsed}${Extension}"
        }
        function Test-JobComplete {
            Param(
                [Parameter(Mandatory = $True, Position = 0, ValueFromPipeline = $True)]
                $BitsJob
            )
            $State = $BitsJob.JobState
            ($State -ne 'Transferring') -and ($State -ne 'Connecting')
        }
        $Count = 0
        $CanUseBitsTransfer = Test-Command 'Start-BitsTransfer'
        $Client = if ($CanUseBitsTransfer -and (-not $WebClient)) {
            '==> [INFO] Using Start-BitsTransfer' | Write-Verbose
            $Null
        } else {
            '==> [INFO] Using .NET Web Client class' | Write-Verbose
            New-Object 'System.Net.WebClient'
        }
    }
    Process {
        $Name = if ($Filename.Count -gt 0) { $Filename[$Count] } else { Split-Path $Uri.Path -Leaf }
        $Path = Join-Path $Destination $Name
        if (Test-Path -Path $Path) {
            $Name = $Name | Format-FileVersion
            $Path = Join-Path $Destination $Name
        }
        if ($Client) {
            if ($PSCmdlet.ShouldProcess($Path)) {
                "==> [INFO] Saving file to ${Path} using WebClient..." | Write-Verbose
                if ($Asynchronous) {
                    $Client.DownloadFileAsync($Uri, $Path)
                } else {
                    $Client.DownloadFile($Uri, $Path)
                }
            }
        } elseif ($CanUseBitsTransfer) {
            $Parameters = @{
                Asynchronous = $Asynchronous
                Destination = $Path
                DisplayName = 'PreludeBitsJob'
                Priority = $Priority
                Source = $Uri.Uri
                TransferType = 'Download'
            }
            $Job = Start-BitsTransfer @Parameters @CustomParameters
            if ($Asynchronous) {
                $Id = $Job.JobId
                "==> [INFO] Finishing BitsTransfer job [${Id}]..." | Write-Verbose
                if ($PassThru) {
                    return $Job
                } else {
                    $Seconds = $SleepInterval
                    while (-not (Test-JobComplete $Job)) {
                        "==> [INFO] BitsTransfer status [${Id}]: $($Job.JobState)" | Write-Verbose
                        Start-Sleep -Seconds $Seconds
                        $Seconds += 1
                    }
                    switch ($Job.JobState) {
                        'Transferred' {
                            Complete-BitsTransfer -BitsJob $Job
                            "==> [INFO] BitsTransfer Job [${Id}], complete." | Write-Verbose
                        }
                        'Error' {
                            "==> [ERROR] BitsTransfer Job [${Id}], failed." | Write-Error
                            $Job | Format-List
                        }
                        Default {
                            # Do nothing
                        }
                    }
                }
            }
            "==> [INFO] Saved file to ${Path} using BitsTransfer." | Write-Verbose
        }
        $Count += 1
    }
}
function Test-Url {
    <#
    .SYNOPSIS
    Test if a URL is accessible
    .PARAMETER Code
    Return status code as a string instead of boolean value
    .PARAMETER WebRequestParameters
    Object for passing parameters to underlying invocation of Invoke-WebRequest
    .EXAMPLE
    'https://google.com' | Test-Url
    #>
    [CmdletBinding()]
    [OutputType([Bool])]
    [OutputType([String])]
    Param(
        [Parameter(Mandatory = $True, Position = 0, ValueFromPipeline = $True)]
        [UriBuilder] $Value,
        [Switch] $Code,
        [PSObject] $WebRequestParameters = @{}
    )
    Process {
        $Response = try {
            Invoke-WebRequestBasicAuth -Uri $Value.Uri -WebRequestParameters $WebRequestParameters
        } catch {
            @{ StatusCode = '404' }
        }
        $StatusCode = $Response | Get-Property StatusCode
        switch ($StatusCode) {
            200 {
                if ($Code) { '200' } else { $True }
            }
            Default {
                if ($Code) { $StatusCode.ToString() } else { $False }
            }
        }
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
function Use-Web {
    <#
    .SYNOPSIS
    Load related types for using web (with or without a web browser), if types are not already loaded.
    .PARAMETER Browser
    Whether or not to load WebBrowser type
    #>
    [CmdletBinding()]
    Param(
        [Switch] $Browser,
        [Switch] $PassThru
    )
    if (-not ('System.Web.HttpUtility' -as [Type])) {
        '==> Adding System.Web types' | Write-Verbose
        Add-Type -AssemblyName System.Web
    } else {
        '==> System.Web is already loaded' | Write-Verbose
    }
    if ($Browser) {
        if (-not ('System.Windows.Forms.WebBrowser' -as [Type])) {
            '==> Adding System.Windows.Forms types' | Write-Verbose
            Add-Type -AssemblyName System.Windows.Forms
        } else {
            '==> System.Windows.Forms is already loaded' | Write-Verbose
        }
    }
    if ($PassThru) {
        $True
    }
}