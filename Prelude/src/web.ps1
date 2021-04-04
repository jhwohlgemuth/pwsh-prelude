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
function Get-GithubOAuthToken {
    <#
    .SYNOPSIS
    Obtain OAuth token from https://api.github.com
    .DESCRIPTION
    This function enables obtaining an OAuth token from https://api.github.com
    Github provides multiple ways to obtain authentication tokens. This function implements the "device flow" method of authorizing an OAuth app.
    Before using this function, you must:
        1. Create an OAuth app on Github.com
        2. Record app "Client ID" (passed as -ClientID)
        3. Opt-in to "Device Authorization Flow" beta feature
    This function will attempt to open a browser and will require the user to login to his/her Github account to authorize access.
    The one-time device code will be copied to the clipboard for ease of use.
    > Note: For basic authentication scenarios, please use Invoke-WebRequestBasicAuth
    .EXAMPLE
    $Token = Get-GithubOAuthToken -ClientId $ClientId -Scope 'notifications'
    $Request = BasicAuth $Token -Uri 'https://api.github.com/notifications'
    #>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $True, Position = 0)]
        [String] $ClientId,
        [Parameter(Position = 1)]
        [String[]] $Scope
    )
    $ValidScopes = 'repo', 'repo:status', 'repo_deployment', 'public_repo', 'repo:invite', 'security_events', 'admin:repo_hook', 'write:repo_hook', 'read:repo_hook', 'admin:org', 'write:org', 'read:org', 'admin:public_key', 'write:public_key', 'read:public_key', 'admin:org_hook', 'gist', 'notifications', 'user', 'read:user', 'user:email', 'user:follow', 'delete_repo', 'write:discussion', 'read:discussion', 'write:packages', 'read:packages', 'delete:packages', 'admin:gpg_key', 'write:gpg_key', 'read:gpg_key', 'workflow'
    $IsValidScope = $Scope | Invoke-Reduce {
        Param($Acc, $Item)
        $Acc -and ($Item -in $ValidScopes)
    }
    if ($IsValidScope) {
        $DeviceRequestParameters = @{
            Post = $True
            Uri = 'https://github.com/login/device/code'
            Query = @{
                client_id = $ClientId
                scope = $Scope -join '%20'
            }
        }
        $DeviceData = Invoke-WebRequestBasicAuth @DeviceRequestParameters |
            ForEach-Object -MemberName 'Content' |
            ConvertFrom-ByteArray |
            ConvertFrom-QueryString
        $DeviceData | ConvertTo-Json | Write-Verbose
        $TokenRequestParameters = @{
            Post = $True
            Uri = 'https://github.com/login/oauth/access_token'
            Query = @{
                client_id = $ClientId
                device_code = $DeviceData['device_code']
                grant_type = 'urn:ietf:params:oauth:grant-type:device_code'
            }
        }
        $DeviceData['user_code'] | Write-Title -Green -PassThru | Set-Clipboard
        Start-Process $DeviceData['verification_uri']
        $Success = $False
        while (-not $Success) {
            Start-Sleep $DeviceData.interval
            $TokenData = Invoke-WebRequestBasicAuth @TokenRequestParameters |
                ForEach-Object -MemberName 'Content' |
                ConvertFrom-ByteArray |
                ConvertFrom-QueryString
            $Success = $TokenData['token_type'] -eq 'bearer'
        }
        $TokenData | ConvertTo-Json | Write-Verbose
        $TokenData['access_token']
    } else {
        "One or more scope values are invalid (Scopes: $(Join-StringsWithGrammar $Scope))" | Write-Error
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
    .PARAMETER WebRequestParameters
    Object for passing parameters to underlying invocation of Invoke-WebRequest
    .EXAMPLE
    # Authenticate a GET request with a token
    $Uri = 'https://api.github.com/notifications'
    $Query = @{ per_page = 100; page = 1 }
    $Request = Invoke-WebRequestBasicAuth $Token -Uri $Uri -Query $Query
    $Request.Content | ConvertFrom-Json | Format-Table -AutoSize
    .EXAMPLE
    # Use basic authentication with a username and password
    $Uri = 'https://api.github.com/notifications'
    $Query = @{ per_page = 100; page = 1 }
    $Request = Invoke-WebRequestBasicAuth $Username -Password $Token -Uri $Uri -Query $Query
    $Request.Content | ConvertFrom-Json | Format-Table -AutoSize
    .EXAMPLE
    # Execute a PUT request with a data payload
    $Uri = 'https://api.github.com/notifications'
    @{ last_read_at = '' } | BasicAuth $Token -Uri $Uri -Put
    .EXAMPLE
    $Uri = 'https://api.github.com/notifications'
    $Parameters = @{
        SkipCertificateChecks = $True
    }
    @{ last_read_at = '' } | BasicAuth $Token -Uri $Uri -Put -RequestParameters $Parameters
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '', Scope = 'Function')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingUsernameAndPasswordParams', '')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingPlainTextForPassword', 'Password')]
    [CmdletBinding(DefaultParameterSetName = 'token')]
    [Alias('basicauth')]
    Param(
        [Parameter(ParameterSetName = 'basic', Position = 0)]
        [String] $Username,
        [Parameter(ParameterSetName = 'basic')]
        [String] $Password,
        [Parameter(ParameterSetName = 'token', Position = 0)]
        [String] $Token,
        [Parameter(Mandatory = $True)]
        [UriBuilder] $Uri,
        [PSObject] $Query = @{},
        [Switch] $UrlEncode,
        [Switch] $ParseContent,
        [Alias('OTP')]
        [String] $TwoFactorAuthentication = 'none',
        [Switch] $Get,
        [Switch] $Post,
        [Switch] $Put,
        [Switch] $Delete,
        [Parameter(ValueFromPipeline = $True)]
        [PSObject] $Data = @{},
        [PSObject] $WebRequestParameters = @{}
    )
    Process {
        $Authorization = if ($Token.Length -gt 0) {
            "Bearer $Token"
        } else {
            $Credential = [Convert]::ToBase64String([System.Text.Encoding]::Ascii.GetBytes("${Username}:${Password}"))
            "Basic $Credential"
        }
        $Headers = @{
            Authorization = $Authorization
        }
        switch ($TwoFactorAuthentication) {
            'github' {
                'GitHub 2FA' | Write-Title -Green
                $Code = 'Code:' | Invoke-Input -Number -Indent 4
                $Headers.Accept = 'application/vnd.github.v3+json'
                $Headers['x-github-otp'] = $Code
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
        "==> Headers: $($Parameters.Headers | ConvertTo-Json)" | Write-Verbose
        "==> Method: $($Parameters.Method)" | Write-Verbose
        "==> URI: $($Parameters.Uri)" | Write-Verbose
        if ($Method -in 'Post', 'Put') {
            $Parameters.Body = $Data | ConvertTo-Json
            "==> Data: $($Data | ConvertTo-Json)" | Write-Verbose
        }
        $Request = Invoke-WebRequest @Parameters @WebRequestParameters
        if ($ParseContent) {
            $Request.Content | ConvertFrom-Json
        } else {
            $Request
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
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '', Scope = 'Function')]
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
                $Browser.Navigate("file:///$((Get-Item $Content).Fullname)")
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