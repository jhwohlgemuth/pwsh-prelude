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