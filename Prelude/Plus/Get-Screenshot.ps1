function Get-Screenshot {
    <#
    .SYNOPSIS
    Create screenshot
    .DESCRIPTION
    Create screenshot of one or all monitors. The screenshot is saved as a BITMAP (bmp) file.

    When selecting a monitor, the assumed setup is:

    +-----+  +-----+  +-----+  +-----+
    |  1  |  |  2  |  |  3  |  | ... |  etc...
    +-----+  +-----+  +-----+  +-----+

    .PARAMETER Monitor
    Number that identifies desired monitor
    .PARAMETER Clipboard
    Copy screenshot to clipboard
    .EXAMPLE
    Get-Screenshot
    .EXAMPLE
    Get-Screenshot 'MyPictures'
    # save screenshot of all monitors (one BMP file) to '.\MyPictures\screenshot.bmp'
    .EXAMPLE
    1..3 | screenshot
    # save screenshot of each monitor, in separate BMP files
    #>
    [CmdletBinding()]
    [Alias('screenshot')]
    [OutputType([String])]
    Param(
        [Parameter(Position = 0)]
        [ValidateScript( { Test-Path $_ })]
        [String] $Path = (Get-Location),
        [Parameter(Position = 1)]
        [String] $Name = ("screenshot-$(Get-Date -UFormat '+%y%m%d%H%M%S')"),
        [Parameter(ValueFromPipeline = $True)]
        [Int] $Monitor = 0,
        [Switch] $Clipboard
    )
    Process {
        if ($IsLinux -is [Bool] -and $IsLinux) {
            '==> Get-Screenshot is only supported on Windows platform' | Write-Color -Red
        } else {
            [Void][System.Reflection.Assembly]::LoadWithPartialName('System.Drawing')
            [Void][System.Reflection.Assembly]::LoadWithPartialName('System.Windows.Forms')
            $ScreenBounds = [Windows.Forms.SystemInformation]::VirtualScreen
            $VideoController = Get-CimInstance -Query 'SELECT VideoModeDescription FROM Win32_VideoController'
            if ($VideoController.VideoModeDescription -and $VideoController.VideoModeDescription -match '(?<ScreenWidth>^\d+) x (?<ScreenHeight>\d+) x .*$') {
                $ScreenWidth = [Int]$Matches['ScreenWidth']
            }
            $UseDifferentMonitor = $ScreenWidth -and ($Monitor -gt 0)
            $Width = if ($UseDifferentMonitor) { $ScreenWidth } else { $ScreenBounds.Width }
            $Height = $ScreenBounds.Height
            $Left = if ($UseDifferentMonitor) { $ScreenBounds.X + ($ScreenWidth * ($Monitor - 1)) } else { $ScreenBounds.X }
            $Bottom = $ScreenBounds.Y
            $Size = New-Object 'System.Drawing.Size' @($Width, $Height)
            $Point = New-Object 'System.Drawing.Point' @($Left, $Bottom)
            $Screenshot = New-Object 'System.Drawing.Bitmap' @($Width, $Height)
            $DrawingGraphics = [System.Drawing.Graphics]::FromImage($Screenshot)
            $DrawingGraphics.CopyFromScreen($Point, [System.Drawing.Point]::Empty, $Size)
            $DrawingGraphics.Dispose()
            if ($Clipboard) {
                [System.Windows.Forms.Clipboard]::SetImage($Screenshot)
                '==> [INFO] Screenshot copied to clipboard' | Write-Verbose
            } else {
                if ($UseDifferentMonitor) {
                    $Fullname = Join-Path (Get-StringPath $Path) "$Name-$Monitor.bmp"
                    "==> [INFO] Saving screenshot of monitor #${Monitor} to $Fullname" | Write-Verbose
                } else {
                    $Fullname = Join-Path (Get-StringPath $Path) "$Name.bmp"
                    "==> [INFO] Saving screenshot of all monitors to $Fullname" | Write-Verbose
                }
                $Screenshot.Save($Fullname)
                "==> [INFO] Screenshot saved to $Fullname" | Write-Verbose
            }
            $Screenshot.Dispose()
            $Fullname
        }
    }
}