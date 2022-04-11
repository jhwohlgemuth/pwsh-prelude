function Remove-DailyShutdownJob {
    <#
    .SYNOPSIS
    Remove job created with New-DailyShutdownJob
    .EXAMPLE
    Remove-DailyShutdownJob
    #>
    [CmdletBinding()]
    [OutputType([Bool])]
    Param(
        [Switch] $PassThru
    )
    $Result = $False
    if (Test-Admin) {
        Unregister-ScheduledJob -Name 'DailyShutdown'
        $Result = $True
    } else {
        Write-Error '==> Remove-DailyShutdownJob requires Administrator privileges'
    }
    if ($PassThru) {
        $Result
    }
}