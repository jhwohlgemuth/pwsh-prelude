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
function Get-EarthRadius {
  <#
  .SYNOPSIS
  Get earth's radius at a given geodetic latitude
  .PARAMETER Latitude
  Latitude value in decimal degree format
  #>
  [CmdletBinding()]
  [OutputType([Double])]
  Param(
    [Parameter(Position=0, ValueFromPipeline=$true)]
    [ValidateRange(-90, 90)]
    [Double] $Latitude
  )
  Process {
    $a = [Coordinate]::SemiMajorAxis
    $b = [Coordinate]::SemiMinorAxis
    $Beta = ConvertTo-Radian $Latitude
    [Math]::Sqrt(
      ([Math]::Pow(([Math]::Pow($a, 2) * [Math]::Cos($Beta)), 2) + [Math]::Pow(([Math]::Pow($b, 2) * [Math]::Sin($Beta)), 2)) /
      ([Math]::Pow(($a * [Math]::Cos($Beta)), 2) + [Math]::Pow(($b * [Math]::Sin($Beta)), 2))
    )
  }
}
function Get-Extremum {
  <#
  .SYNOPSIS
  Function to return extremum (maximum or minimum) of an array of numbers
  .EXAMPLE
  $Maximum = 1,2,3,4,5 | Get-Extremum -Max
  # 5
  .EXAMPLE
  $Minimum = 1,2,3,4,5 | Get-Extremum -Min
  # 1
  #>
  [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'Maximum')]
  [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'Minimum')]
  [CmdletBinding()]
  Param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [Array] $InputObject,
    [Alias('Max')]
    [Switch] $Maximum,
    [Alias('Min')]
    [Switch] $Minimum
  )
  Begin {
    function Invoke-GetExtremum {
      param (
        [Parameter(Position=0)]
        [Array] $Values
      )
      if ($Values.Count -gt 0) {
        $Type = Find-FirstTrueVariable 'Maximum','Minimum'
        $Values | Measure-Object -Maximum:$Maximum -Minimum:$Minimum | ForEach-Object { $_.$Type }
      }
    }
    Invoke-GetExtremum $InputObject
  }
  End {
    Invoke-GetExtremum $Input
  }
}
function Get-Factorial {
  <#
  .SYNOPSIS
  Return factorial of Value, Value!.
  .EXAMPLE
  Get-Factorial 10
  # 3628800

  #>
  [CmdletBinding()]
  [OutputType([Int32])]
  Param(
    [Parameter(Position=0, ValueFromPipeline=$true)]
    [Int] $Value
  )
  Process {
    if ($Value -eq 0) {
      1
    } else {
      1..$Value | Invoke-Reduce { Param($Acc,$Item) $Acc * $Item } -InitialValue 1
    }
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
function Get-Maximum {
  <#
  .SYNOPSIS
  Wrapper for Get-Extremum with the -Maximum switch
  #>
  [CmdletBinding()]
  [Alias('max')]
  Param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [Array] $Values
  )
  Begin {
    if ($Values.Count -gt 0) {
      Get-Extremum -Maximum $Values
    }
  }
  End {
    if ($Input.Count -gt 0) {
      $Input | Get-Extremum -Maximum
    }
  }
}
function Get-Mean {
  <#
  .SYNOPSIS
  Calculate mean (average) for list of numerical values
  .DESCRIPTION
  Specifically, this function returns the "expected value" (mean) for a discrete uniform random variable.
  .EXAMPLE
  1..10 | mean
  #>
  [CmdletBinding()]
  [Alias('mean')]
  Param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [Array] $Data
  )
  End {
    if ($Input.Count -gt 0) {
      $Data = $Input
    }
    ($Data | Measure-Object -Sum).Sum / $Data.Count
  }
}
function Get-Median {
  <#
  .SYNOPSIS
  Calculate median for list of numerical values
  .DESCRIPTION
  Specifically, this function returns the median for a discrete uniform random variable.
  .EXAMPLE
  1..10 | median
  #>
  [CmdletBinding()]
  [Alias('median')]
  Param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [Array] $Data
  )
  End {
    if ($Input.Count -gt 0) {
      $Data = $Input
    }
    $Sorted = $Data | Sort-Object
    $Index = $Sorted.Count / 2
    if ($Sorted.Count % 2 -eq 0) {
      $Left = $Sorted[$Index - 1]
      $Right = $Sorted[$Index]
    } else {
      $Left = [Math]::Floor($Sorted[$Index])
      $Right = $Left
    }
    ($Left + $Right) / 2
  }
}
function Get-Minimum {
  <#
  .SYNOPSIS
  Wrapper for Get-Extremum with the -Minimum switch
  #>
  [CmdletBinding()]
  [Alias('min')]
  Param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [Array] $Values
  )
  Begin {
    if ($Values.Count -gt 0) {
      Get-Extremum -Minimum $Values
    }
  }
  End {
    if ($Input.Count -gt 0) {
      $Input | Get-Extremum -Minimum
    }
  }
}