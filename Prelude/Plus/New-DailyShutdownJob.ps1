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
        [DateTime] $At,
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
                "==> Creating daily shutdown task at ${At}" | Write-Verbose
                $ScriptBlock = 'Invoke-Command -Scriptblock { Stop-Computer -Force }'
                $Parameters = @{
                    TaskName = $Name
                    Action = New-ScheduledTaskAction -Execute 'Powershell.exe' -Argument $ScriptBlock
                    Trigger = New-ScheduledTaskTrigger -Daily -At $At
                    Description = "Daily shutdown at ${At}"
                    Force = $True
                }
                Register-ScheduledTask @Parameters | Out-Null
                $Result = (Get-ScheduledTask -TaskName $Name).State -eq 'Ready'
            } else {
                "==> Creating daily shutdown job at ${At}" | Write-Verbose
                $Trigger = New-JobTrigger -Daily -At $At
                Register-ScheduledJob -Name $Name -ScriptBlock { Stop-Computer -Force } -Trigger $Trigger
                $Result = $True
            }
        } else {
            Write-Error "==> $($MyInvocation.MyCommand.Name) requires Administrator privileges"
        }
        if ($PassThru) {
            $Result
        }
    }
}