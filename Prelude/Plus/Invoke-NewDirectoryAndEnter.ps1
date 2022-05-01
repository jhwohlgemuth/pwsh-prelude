function Invoke-NewDirectoryAndEnter {
    <#
    .SYNOPSIS
    PowerShell equivalent of oh-my-zsh take function
    .DESCRIPTION
    Using take will create a new directory and then enter the driectory
    .EXAMPLE
    take ./new/folder/name
    #>
    [CmdletBinding(SupportsShouldProcess = $True)]
    [Alias('take')]
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