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
    Begin {
        $Result = $False
        $Version = $PSVersionTable.PSVersion.Major
        $Name = 'DailyShutdown'
    }
    End {
        if (Test-Admin) {
            if ($Version -ge 7) {
                "==> Removing `"${Name}`" task" | Write-Verbose
                Unregister-ScheduledTask -TaskName $Name -Confirm:$False
            } else {
                "==> Removing `"${Name}`" job" | Write-Verbose
                Unregister-ScheduledJob -Name $Name
            }
            $Result = $True
        } else {
            Write-Error "==> $($MyInvocation.MyCommand.Name) requires Administrator privileges"
        }
        if ($PassThru) {
            $Result
        }
    }
}