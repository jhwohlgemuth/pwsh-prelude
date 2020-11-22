function ConvertTo-Degree {
  <#
  .SYNOPSIS
  Convert radians to degrees
  #>
  [CmdletBinding()]
  [Alias('toDegree')]
  [OutputType([Double])]
  Param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [Double] $Radians
  )
  Process {
    ($Radians * (180 / [Math]::Pi)) % 360
  }
}
function ConvertTo-Radian {
  <#
  .SYNOPSIS
  Convert degrees to radians
  #>
  [CmdletBinding()]
  [Alias('toRadian')]
  [OutputType([Double])]
  Param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [Double] $Degrees
  )
  Process {
    ($Degrees % 360) * ([Math]::Pi / 180)
  }
}
function Get-Haversine {
  <#
  .SYNOPSIS
  Return haversine of an angle
  .DESCRIPTION
  The Haversine is most frequently used within the Haversine formula when calculating great-circle distance between two points on a sphere.

  Note: Available as static method of Prelude class - [Prelude]::Hav
  #>
  [CmdletBinding()]
  [OutputType([Double])]
  Param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [Double] $Degrees
  )
  Process {
    0.5 * (1 - [Math]::Cos((ConvertTo-Radian $Degrees)))
  }
}
function Get-ArcHaversine {
  <#
  .SYNOPSIS
  Return archaversine (ahav) of a value, in degrees. This is the inverse function of Get-Haversine.

  Note: Available as static method of Prelude class - [Prelude]::Ahav
  #>
  [CmdletBinding()]
  [OutputType([Double])]
  Param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [Double] $Value
  )
  Process {
    ConvertTo-Degree ([Math]::Acos(1 - (2 * $Value)))
  }
}