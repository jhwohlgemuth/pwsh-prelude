function ConvertTo-Iso8601 {
  [CmdletBinding()]
  Param(
    [Parameter(Position=0, ValueFromPipeline=$true)]
    [String] $Value
  )
  $Value | Get-Date -UFormat '+%Y-%m-%dT%H:%M:%S.000Z'
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
  $Callback = {
    Param($Acc, $Item)
    $Key = $Item.Name
    $Value = $Item.Value
    "${Acc}$(if ($Acc -ne '') { '&' } else { '' })${Key}=${Value}"
  }
  $QueryString = $InputObject.GetEnumerator() | Sort-Object Name | Invoke-Reduce $Callback ''
  if ($UrlEncode) {
    Add-Type -AssemblyName System.Web
    [System.Web.HttpUtility]::UrlEncode($QueryString)
  } else {
    $QueryString
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
  $Html = New-Object -ComObject "HTMLFile"
  $Html.IHTMLDocument2_write($Content)
  $Html
}
function Invoke-WebRequestWithBasicAuth {
  <#
  .SYNOPSIS
  Invoke-WebRequest wrapper that makes it easier to use basic authentication
  .PARAMETER TwoFactorAuthentication
  Name of API that requires 2FA. Use 'none' when 2FA is not required.
  Possible values:
  - 'Github'
  - 'none' [Default]
  .EXAMPLE
  $Uri = 'https://api.github.com/notifications'
  $Query = @{ per_page = 100; page = 1 }
  $Request = Invoke-WebRequestWithBasicAuth $Username $Token -Uri $Uri -Query $Query
  $Request.Content | ConvertFrom-Json | Format-Table -AutoSize
  #>
  [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '', Scope='Function')]
  [CmdletBinding()]
  Param(
    [Parameter(Position=0)]
    [String] $Username,
    [Parameter(Position=1)]
    [String] $Token,
    [UriBuilder] $Uri,
    [PSObject] $Query = @{},
    [Switch] $UrlEncode,
    [PSObject] $Data,
    [String] $TwoFactorAuthentication = 'none',
    [Switch] $Get,
    [Switch] $Post,
    [Switch] $Put,
    [Switch] $Delete
  )
  $Credential = [Convert]::ToBase64String([System.Text.Encoding]::Ascii.GetBytes("${Username}:${Token}"))
  $Headers = @{
    Authorization = "Basic $Credential"
  }
  switch ($TwoFactorAuthentication) {
    'github' {
      $Code = '2FA Code:' | Invoke-Input -Number
      $Headers.Accept = 'application/vnd.github.v3+json'
      $Headers['x-github-otp'] = $Code
    }
    Default {
      # Do nothing
    }
  }
  $Uri.Query = $Query | ConvertTo-QueryString -UrlEncode:$UrlEncode
  $Parameters = @{
    Headers = $Headers
    Method = (Find-FirstTrueVariable 'Get','Post','Put','Delete')
    Uri = $Uri.Uri
  }
  Invoke-WebRequest @Parameters
}
function Invoke-WebRequestWithOAuth {
  [CmdletBinding()]
  Param()

}