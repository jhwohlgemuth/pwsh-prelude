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