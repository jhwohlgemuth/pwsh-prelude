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
  [Bool] $ControlBox = $true
  [Bool] $MaximizeBox = $false
  [Bool] $MinimizeBox = $false
}
class BrowserOptions: Options {
  [String] $Anchor = 'Left,Top,Right,Bottom'
  [PSObject] $Size = @{ Height = 700; Width = 960 }
  [Bool] $IsWebBrowserContextMenuEnabled = $false
}
function ConvertFrom-ByteArray {
  <#
  .SYNOPSIS
  Converts bytes to human-readable text
  #>
  [CmdletBinding()]
  Param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [Array] $Data
  )
  Begin {
    function Invoke-Convert {
      Param(
        [Parameter(Position=0)]
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
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [String] $Value
  )
  $Html = New-Object -ComObject 'HTMLFile'
  if ($null -ne $Html) {
    $Html.IHTMLDocument2_write($Value)
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
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
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
        $Key,$Value = $Item -split '='
        $Acc.$Key = $Value
      } -InitialValue @{}
    } else {
      $Decoded
    }
  }
}
function ConvertTo-Iso8601 {
  [CmdletBinding()]
  Param(
    [Parameter(Position=0, ValueFromPipeline=$true)]
    [String] $Value
  )
  Process {
    $Value | Get-Date -UFormat '+%Y-%m-%dT%H:%M:%S.000Z'
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
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
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
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
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

  #>
  [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '', Scope='Function')]
  [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingUsernameAndPasswordParams', '')]
  [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingPlainTextForPassword', 'Password')]
  [CmdletBinding(DefaultParameterSetName='token')]
  [Alias('basicauth')]
  Param(
    [Parameter(ParameterSetName='basic', Position=0)]
    [String] $Username,
    [Parameter(ParameterSetName='basic')]
    [String] $Password,
    [Parameter(ParameterSetName='token', Position=0)]
    [String] $Token,
    [Parameter(Mandatory=$true)]
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
    [Parameter(ValueFromPipeline=$true)]
    [PSObject] $Data = @{}
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
    $Method = Find-FirstTrueVariable 'Get','Post','Put','Delete'
    $Uri.Query = $Query | ConvertTo-QueryString -UrlEncode:$UrlEncode
    $Parameters = @{
      Headers = $Headers
      Method = $Method
      Uri = $Uri.Uri
    }
    "==> Headers: $($Parameters.Headers | ConvertTo-Json)" | Write-Verbose
    "==> Method: $($Parameters.Method)" | Write-Verbose
    "==> URI: $($Parameters.Uri)" | Write-Verbose
    if ($Method -in 'Post','Put') {
      $Parameters.Body = $Data | ConvertTo-Json
      "==> Data: $($Data | ConvertTo-Json)" | Write-Verbose
    }
    $Request = Invoke-WebRequest @Parameters
    if ($ParseContent) {
      $Request | Invoke-GetProperty Content | ConvertFrom-Json
    } else {
      $Request
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

  Note: For basic authentication scenarios, please use Invoke-WebRequestBasicAuth

  .EXAMPLE
  $Token = Get-GithubOAuthToken -ClientId $ClientId -Scope 'notifications'
  $Request = BasicAuth $Token -Uri 'https://api.github.com/notifications'

  #>
  [CmdletBinding()]
  Param(
    [Parameter(Mandatory=$true, Position=0)]
    [String] $ClientId,
    [Parameter(Position=1)]
    [String[]] $Scope
  )
  $DeviceRequestParameters = @{
    Post = $true
    Uri = 'https://github.com/login/device/code'
    Query = @{
      client_id = $ClientId
      scope = $Scope -join '%20'
    }
  }
  $DeviceData = Invoke-WebRequestBasicAuth @DeviceRequestParameters |
    Invoke-GetProperty Content |
    ConvertFrom-ByteArray |
    ConvertFrom-QueryString
  $DeviceData | ConvertTo-Json | Write-Verbose
  $TokenRequestParameters = @{
    Post = $true
    Uri = 'https://github.com/login/oauth/access_token'
    Query = @{
      client_id = $ClientId
      device_code = $DeviceData['device_code']
      grant_type = 'urn:ietf:params:oauth:grant-type:device_code'
    }
  }
  $DeviceData['user_code'] | Write-Title -Green -PassThru | Set-Clipboard
  Start-Process $DeviceData['verification_uri']
  $Success = $false
  while (-not $Success) {
    Start-Sleep $DeviceData.interval
    $TokenData = Invoke-WebRequestBasicAuth @TokenRequestParameters |
      Invoke-GetProperty Content |
      ConvertFrom-ByteArray |
      ConvertFrom-QueryString
    $Success = $TokenData['token_type'] -eq 'bearer'
  }
  $TokenData | ConvertTo-Json | Write-Verbose
  $TokenData['access_token']
}
function Show-HtmlContent {
  <#
  .SYNOPSIS
  Display HTML content (string, file, or URI) in a web browser Windows form
  Returns [System.Windows.Forms.HtmlDocument] object
  .PARAMETER OnShown
  Function to be executed once form is shown. $Form and $Browser variables are available within function scope.
  .PARAMETER OnComplete
  Function to be executed whenever the Document within the browser is loaded. $Form and $Browser variables are available within function scope.
  .PARAMETER OnClose
  Function to be executed immediately before form is disposed. $Form and $Browser variables are available within function scope.
  .EXAMPLE
  '<h1>Hello World</h1>' | Show-HtmlContent
  .EXAMPLE
  Show-Content -Uri 'https://google.com'
  .EXAMPLE
  Show-Content -File '.\file.html'
  .EXAMPLE
  $OnClose = {
    Param($Browser)
    $Browser.Document.GetElementsByTagName('h1').innerText | Write-Color -Green
  }
  '<h1 contenteditable="true">Type Here</h1>' | Show-HtmlContent -OnClose $OnClose | Out-Null
  #>
  [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '', Scope='Function')]
  [CmdletBinding(DefaultParameterSetName='string')]
  Param(
    [Parameter(ParameterSetName='string', Position=0, ValueFromPipeline=$true)]
    [String] $Content,
    [Parameter(ParameterSetName='file')]
    [String] $File,
    [Parameter(ParameterSetName='uri')]
    [Uri] $Uri,
    [FormOptions] $FormOptions = @{},
    [BrowserOptions] $BrowserOptions = @{},
    [ScriptBlock] $OnShown = {},
    [ScriptBlock] $OnComplete = {},
    [ScriptBlock] $OnClose = {}
  )
  Begin {
    Use-Web -Browser
    $Form = $FormOptions.SetProperties(([Windows.Forms.Form]::New()))
    $Browser = $BrowserOptions.SetProperties(([Windows.Forms.WebBrowser]::New()))
    $Form.Controls.Add($Browser)
    $Form.Add_Shown({
      '==> Form shown' | Write-Verbose
      $Form.BringToFront()
      & $OnShown -Form $Form -Browser $Browser
    });
    $Browser.Add_DocumentCompleted({
      "==> Document load complete ($($_.Url))" | Write-Verbose
      & $OnComplete -Form $Form -Browser $Browser
    })
  }
  Process {
    if ($File -or (-not $Content -and $Uri)) {
      if (-not $Uri) {
        $Uri = "file:///$((Get-Item $File).Fullname)"
      }
      "==> Navigating to $Uri" | Write-Verbose
      $Browser.Navigate($Uri)
    } else {
      $Browser.DocumentText = $Content
    }
    if ($Form.ShowDialog() -ne 'OK') {
      $Document = $Browser.Document
      '==> Browser Closing...' | Write-Verbose
      & $OnClose -Form $Form -Browser $Browser
      # $Form.Dispose()
      '==> Form disposed' | Write-Verbose
      return $Document
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
    [Switch] $Browser
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
}