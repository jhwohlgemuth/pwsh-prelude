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
function Get-EarthRadius {
  <#
  .SYNOPSIS
  Get earth's radius at a given geographic latitude
  .PARAMETER Latitude
  Latitude value in decimal format
  #>
  [CmdletBinding()]
  [OutputType([Double])]
  Param(
    [Parameter(Position=0, ValueFromPipeline=$true)]
    [Double] $Latitude
  )
  Process {
    $GeocentricLatitude = [Math]::Pow((1 - [Constant]::EarthFlattening), 2) * [Math]::Tan((ConvertTo-Radian $Latitude))
    [Constant]::EarthSemiMajorAxis * (1 - ([Constant]::EarthFlattening * [Math]::Pow([Math]::Sin($GeocentricLatitude), 2)))
  }
}
function Get-LogisticSigmoid {
  <#
  .SYNOPSIS
  For a given value, x, returns value of logistic sigmoid function at x

  Note: Available as static method of Prelude class - [Prelude]::Sigmoid
  .DESCRIPTION
  The logistic sigmoid function is commonly used as an activation function within neural networks and to model population growth.
  .PARAMETER Midpoint
  Abscissa axis coordinate of logistic sigmoid function reflection point
  .PARAMETER MaximumValue
  Logistic sigmoid function maximum value
  .PARAMETER Derivative
  Switch parameter to determine which function to use, f(x) or f'(x) = f(x) * f(-x)
  #>
  [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '', Scope='Function')]
  [CmdletBinding()]
  [Alias('sigmoid')]
  [OutputType([Double])]
  Param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [Alias('x')]
    [Double] $Value,
    [Alias('k')]
    [Double] $GrowthRate = 1,
    [Alias('x0')]
    [Double] $Midpoint = 0,
    [Alias('L')]
    [Double] $MaximumValue = 1,
    [Switch] $Derivative
  )
  Process {
    $Sigmoid = { Param($x) $MaximumValue / (1 + [Math]::Pow([Constant]::Euler, -$GrowthRate * ($x - $Midpoint))) }
    if ($Derivative) {
      (& $Sigmoid $Value) * (& $Sigmoid -$Value)
    } else {
      & $Sigmoid $Value
    }
  }
}