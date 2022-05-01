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
      3. Opt-in to "Device Authorization Flow" beta feature via the "Enable Device Flow" checkbox on the OAuth app settings page
    This function will attempt to open a browser and will require the user to login to his/her Github account to authorize access.
    The one-time device code will be copied to the clipboard for ease of use.
    .EXAMPLE
    $Token = Get-GithubOAuthToken -ClientId $ClientId -Scope 'notifications'
    $Uri = 'https://api.github.com/notifications'
    $Request = BasicAuth $Uri -Token $Token
    .NOTES
    For basic authentication scenarios, please use Invoke-WebRequestBasicAuth
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