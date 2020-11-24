& (Join-Path $PSScriptRoot '_setup.ps1') 'applied'

Describe 'Constant Class' {
  It 'provides immutable values' {
    [Math]::Round([ConstantTest]::Euler, 3) | Should -Be 2.718
    { [ConstantTest]::Euler = 5 } | Should -Throw -Because 'constants are immutable'
    [Math]::Round([ConstantTest]::Phi, 3) | Should -Be 1.618
    { [ConstantTest]::Phi = 5 } | Should -Throw -Because 'constants are immutable'
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
    Get-EarthRadius | Should -Be ([ConstantTest]::EarthRadiusEquator)
    0 | Get-EarthRadius | Should -Be ([ConstantTest]::EarthRadiusEquator)
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