function ConvertTo-Iso8601 {
  [CmdletBinding()]
  Param(
    [Parameter(Position=0, ValueFromPipeline=$true)]
    [String] $Value
  )
  $Value | Get-Date -UFormat '+%Y-%m-%dT%H:%M:%S.000Z'
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
  $Query = @{ 'per_page' = 100; page = 1}
  $Request = Invoke-WebRequestWithBasicAuth $Username $Token -Uri $Uri -Query $Query
  $Request.Content | ConvertFrom-Json | Format-Table -AutoSize
  #>
  [CmdletBinding()]
  Param(
    [Parameter(Position=0)]
    [String] $Username,
    [Parameter(Position=1)]
    [String] $Token,
    [Uri] $Uri,
    [PSObject] $Query,
    [PSObject] $Data,
    [String] $TwoFactorAuthentication = 'none'
  )
  $Credential = [Convert]::ToBase64String([System.Text.Encoding]::Ascii.GetBytes("${Username}:${Token}"))
  $Headers = @{
    Authorization = "Basic $Credential"
  }
  switch ($TwoFactorAuthentication.ToLower()) {
    'github' {
      $Code = '2FA Code:' | Invoke-Input -Number
      $Headers.Accept = 'application/vnd.github.v3+json'
      $Headers['x-github-otp'] = $Code
    }
    Default {
      # Do nothing
    }
  }
  $Parameters = @{
    Uri = $Uri
    Headers = $Headers
  }
  Invoke-WebRequest @Parameters
}
function Invoke-WebRequestWithOAuth {
  [CmdletBinding()]
  Param()
  
}