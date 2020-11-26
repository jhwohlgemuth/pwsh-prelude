& (Join-Path $PSScriptRoot '_setup.ps1') 'applied'

Describe 'Constant Class' {
  It 'provides immutable values' {
    [Math]::Round([ConstantTest]::Euler, 3) | Should -Be 2.718
    { [ConstantTest]::Euler = 5 } | Should -Throw -Because 'constants are immutable'
    [Math]::Round([ConstantTest]::Phi, 3) | Should -Be 1.618
    { [ConstantTest]::Phi = 5 } | Should -Throw -Because 'constants are immutable'
  }
}
Describe 'Coordinate Class' {
  It 'can convert geodetic values to cartesian' {
    [CoordinateTest]::ToCartesian(41.25, 96.0) | ForEach-Object { [Math]::Round($_, 5) } | Should -Be -501980.22547,4776022.81393,4183337.2134
    [CoordinateTest]::ToCartesian(41.25, 96.0, 1000) | ForEach-Object { [Math]::Round($_, 5) } | Should -Be -502058.81413,4776770.53508,4183996.55921
    [CoordinateTest]::ToCartesian(41.25, 96.0, 10000) | ForEach-Object { [Math]::Round($_, 5) } | Should -Be -502766.11207,4783500.02543,4189930.67155
    [CoordinateTest]::ToCartesian(41.25, 96.0, 100000) | ForEach-Object { [Math]::Round($_, 5) } | Should -Be -509839.09144,4850794.92896,4249271.79491
  }
  It 'can convert cartesian to geodetic' {
    $X = -501980.22547
    $Y = 4776022.81393
    $Z = 4183337.2134
    [CoordinateTest]::ToGeodetic($X, $Y, $Z) | ForEach-Object { [Math]::Round($_, 2) } | Should -Be 41.25,96,0
    $X = -502058.81413
    $Y = 4776770.53508
    $Z = 4183996.55921
    [CoordinateTest]::ToGeodetic($X, $Y, $Z) | ForEach-Object { [Math]::Round($_, 2) } | Should -Be 41.25,96,1000
    $X = -502766.11207
    $Y = 4783500.02543
    $Z = 4189930.67155
    [CoordinateTest]::ToGeodetic($X, $Y, $Z) | ForEach-Object { [Math]::Round($_, 2) } | Should -Be 41.25,96,10000
    $X = -509839.09144
    $Y = 4850794.92896
    $Z = 4249271.79491
    [CoordinateTest]::ToGeodetic($X, $Y, $Z) | ForEach-Object { [Math]::Round($_, 2) } | Should -Be 41.25,96,100000
    $X = -501980.22547
    $Y = 4776022.81393
    $Z = 4183337.2134
    $Geodetic = [CoordinateTest]::FromCartesian($X, $Y, $Z)
    [Math]::Round($Geodetic.Latitude, 2) | Should -Be 41.25
    [Math]::Round($Geodetic.Longitude, 2) | Should -Be 96
    [Math]::Round($Geodetic.Height, 2) | Should -Be 0
  }
  It 'can convert decimal to sexagesimal' {
    [CoordinateTest]::ToSexagesimal(32.7157) | Should -Be 32,42,56.52
    [CoordinateTest]::ToSexagesimal(96) | Should -Be 96,0,0
    [CoordinateTest]::ToSexagesimal(116.7762) | Should -Be 116,46,34.32
    [CoordinateTest]::ToSexagesimal(-116.7762) | Should -Be -116,46,34.32
  }
}
Describe 'ConvertTo-Degree' {
  It 'can convert radian values to degrees' {
    $PI = [Math]::Pi
    0 | ConvertTo-Degree | Should -Be 0
    ($PI / 2) | ConvertTo-Degree | Should -Be 90
    $PI | ConvertTo-Degree | Should -Be 180
    0,(2 * $PI),(4 * $PI) | ConvertTo-Degree | Should -Be 0,0,0
  }
}
Describe 'ConvertTo-Radian' {
  It 'can convert degree values to radians' {
    $PI = [Math]::Pi
    0 | ConvertTo-Radian | Should -Be 0
    90 | ConvertTo-Radian | Should -Be ($PI / 2)
    180 | ConvertTo-Radian | Should -Be $PI
    360 | ConvertTo-Radian | Should -Be 0
    0,360,720 | ConvertTo-Radian | Should -Be 0,0,0
  }
}
Describe 'Get-EarthRadius' {
  It 'can return earth radius for a given latitude' {
    $a = [CoordinateTest]::SemiMajorAxis
    $b = [CoordinateTest]::SemiMinorAxis
    -90 | Get-EarthRadius | Should -Be $b -Because 'the radius is equal to semi-minor axis at the poles'
    Get-EarthRadius | Should -Be $a
    0 | Get-EarthRadius | Should -Be $a -Because 'the radius is equal to semi-major axis at the equator'
    [Math]::Round((23.437055555555556 | Get-EarthRadius), 4) | Should -Be 6374777.8209 -Because 'it is the Northern Tropic latitude'
    [Math]::Round((45 | Get-EarthRadius), 4) | Should -Be 6367489.5439
    90 | Get-EarthRadius | Should -Be $b -Because 'the radius is equal to semi-minor axis at the poles'
  }
}
Describe 'Get-Extremum' {
  It 'can return maximum value from array of numbers' {
    $Max = 5
    $Values = 1,2,2,1,$Max,2,3
    $Values | Get-Extremum -Max | Should -Be $Max
    Get-Extremum -Max $Values | Should -Be $Max
    0,-1,4,2,7,2,0 | Get-Extremum -Max | Should -Be 7
  }
  It 'can return minimum value from array of numbers' {
    $Min = 0
    $Values = 1,2,2,1,$Min,2,3
    $Values | Get-Extremum -Min | Should -Be $Min
    Get-Extremum -Min $Values | Should -Be $Min
    0,-1,4,2,7,2,0 | Get-Extremum -Min | Should -Be -1
  }
  It 'Get-Maximum' {
    $Max = 5
    $Values = 1,2,2,1,$Max,2,3
    $Values | Get-Maximum | Should -Be $Max
    Get-Maximum $Values | Should -Be $Max
    0,-1,4,2,7,2,0 | Get-Maximum | Should -Be 7
  }
  It 'Get-Minimum' {
    $Min = 0
    $Values = 1,2,2,1,$Min,2,3
    $Values | Get-Minimum | Should -Be $Min
    Get-Minimum $Values | Should -Be $Min
    0,-1,4,2,7,2,0 | Get-Minimum | Should -Be -1
  }
}
Describe 'Get-Factorial' {
  It 'can calculate n!' {
    0 | Get-Factorial | Should -Be 1
    1 | Get-Factorial | Should -Be 1
    2 | Get-Factorial | Should -Be 2
    10 | Get-Factorial | Should -Be 3628800
    20 | Get-Factorial | Should -Be 2432902008176640000
    1..5 | Get-Factorial | Should -Be 1,2,6,24,120
    Get-Factorial 2 | Should -Be 2
    Get-Factorial 10 | Should -Be 3628800
  }
}
Describe 'Get-Haversine/ArcHaversine' {
  It 'should return a value in the range [0..1]' {
    42,50,77 | Get-Haversine | ForEach-Object { [Math]::Round($_, 5) } | Should -Be 0.12843,0.17861,0.38752
    0.12843,0.17861,0.38752 | Get-ArcHaversine | ForEach-Object { [Math]::Round($_) } | Should -Be 42,50,77
    42,50,77 | Get-Haversine | Get-ArcHaversine | Should -Be 42,50,77
  }
  It -Skip 'should be provided via static method of Prelude class' {
    [PreludeTest]::Hav(42),
    [PreludeTest]::Hav(50),
    [PreludeTest]::Hav(77) | ForEach-Object { [Math]::Round($_, 5) } | Should -Be 0.12843,0.17861,0.38752
  }
}
Describe 'Get-HaversineDistance' {
  It 'can calculate the distance between two points on the earth' {
    Get-HaversineDistance -From @{} -To @{} | Should -Be 0
    $Omaha = @{ Latitude = 41.25; Longitude = -96 }
    $SanDiego = @{ Latitude = 32.7157; Longitude = -117.1611 }
    [Math]::Round((Get-HaversineDistance -From $Omaha -To $SanDiego), 4) | Should -Be 2097705.7401
    [Math]::Round(($Omaha | Get-HaversineDistance -To $SanDiego), 4) | Should -Be 2097705.7401
  }
}
Describe 'Get-LogisticSigmoid' {
  It 'can return values along the logistic sigmoid curve' {
    0 | Get-LogisticSigmoid | Should -Be 0.5
    [Double]::NegativeInfinity | Get-LogisticSigmoid | Should -Be 0
    [Double]::PositiveInfinity | Get-LogisticSigmoid | Should -Be 1
    [Double]::PositiveInfinity | Get-LogisticSigmoid -MaximumValue 3 | Should -Be 3
    0 | Get-LogisticSigmoid -Derivative | Should -Be 0.25
    $Left = [Math]::Round((Get-LogisticSigmoid -5), 10)
    $Right = [Math]::Round(1 - (Get-LogisticSigmoid 5), 10)
    $Left | Should -Be $Right -Because 'it is a symmetry property of the logistic function'
  }
}
Describe 'Get-Mean/Median' {
  It 'can calculate mean (average) for discrete uniform random variable' {
    1..10 | Get-Mean | Should -Be 5.5
    Get-Mean -Data (1..10) | Should -Be 5.5
    1,3,4,5,6,9,14,30 | Get-Mean | Should -Be 9
    30,4,3,1,6,9,14,5 | Get-Mean | Should -Be 9
  }
  It 'can calculate "trimmed" mean' {
    1..10 | Get-Mean -Trim 0.1 | Should -Be 5.5 -Because '1..10 and 2..9 have the same mean'
    Get-Mean -Data (1..10) -Trim 0.1 | Should -Be 5.5
    (1..10 | Get-Mean -Trim 1),(1..10 | Get-Mean -Trim 1) | Test-Equal | Should -BeTrue -Because '10% of 10 is 1'
    1,3,4,5,6,9,14,30 | Get-Mean -Trim 2 | Should -Be 6
    30,4,3,1,6,9,14,5 | Get-Mean -Trim 2 | Should -Be 6
    (30,4,3,1,6,9,14,5 | Get-Mean -Trim 2),(30,4,3,1,6,9,14,5 | Get-Mean -Trim 0.25) | Test-Equal | Should -BeTrue '25% of 8 is 2'
  }
  It 'can calculate median for discrete uniform random variable' {
    1..5 | Get-Median | Should -Be 3
    2,1,4,5,3 | Get-Median | Should -Be 3
    1..10 | Get-Median | Should -Be 5.5
    19,3,6,7,1,9,2,5,4,8 | Get-Median | Should -Be 5.5
    Get-Median -Data (1..5) | Should -Be 3
    Get-Median -Data (1..10) | Should -Be 5.5
  }
}