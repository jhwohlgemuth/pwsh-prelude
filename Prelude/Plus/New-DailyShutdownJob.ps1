function New-DailyShutdownJob {
    <#
    .SYNOPSIS
    Create job to shutdown computer at a certain time every day
    .EXAMPLE
    New-DailyShutdownJob -At '22:00'
    #>
    [CmdletBinding()]
    [OutputType([Bool])]
    Param(
        [Parameter(Mandatory = $True)]
        [String] $At,
        [Switch] $PassThru
    )
    $Result = $False
    if (Test-Admin) {
        $Trigger = New-JobTrigger -Daily -At $At
        Register-ScheduledJob -Name 'DailyShutdown' -ScriptBlock { Stop-Computer -Force } -Trigger $Trigger
        $Result = $True
    } else {
        Write-Error '==> New-DailyShutdownJob requires Administrator privileges'
    }
    if ($PassThru) {
        $Result
    }
}