& (Join-Path $PSScriptRoot '_setup.ps1') 'applied'

Describe 'ConvertTo-Degree' -Tag 'Local', 'Remote' {
    It 'can convert radian values to degrees' {
        $PI = [Math]::Pi
        0 | ConvertTo-Degree | Should -Be 0
        ($PI / 2) | ConvertTo-Degree | Should -Be 90
        $PI | ConvertTo-Degree | Should -Be 180
        0, (2 * $PI), (4 * $PI) | ConvertTo-Degree | Should -Be 0, 0, 0
    }
}
Describe 'ConvertTo-Radian' -Tag 'Local', 'Remote' {
    It 'can convert degree values to radians' {
        $PI = [Math]::Pi
        0 | ConvertTo-Radian | Should -Be 0
        90 | ConvertTo-Radian | Should -Be ($PI / 2)
        180 | ConvertTo-Radian | Should -Be $PI
        360 | ConvertTo-Radian | Should -Be 0
        0, 360, 720 | ConvertTo-Radian | Should -Be 0, 0, 0
    }
}
Describe 'Get-Extremum' -Tag 'Local', 'Remote' {
    It 'can return maximum value from array of numbers' {
        $Max = 5
        $Values = 1, 2, 2, 1, $Max, 2, 3
        $Values | Get-Extremum -Max | Should -Be $Max
        Get-Extremum -Max $Values | Should -Be $Max
        0, -1, 4, 2, 7, 2, 0 | Get-Extremum -Max | Should -Be 7
    }
    It 'can return minimum value from array of numbers' {
        $Min = 0
        $Values = 1, 2, 2, 1, $Min, 2, 3
        $Values | Get-Extremum -Min | Should -Be $Min
        Get-Extremum -Min $Values | Should -Be $Min
        0, -1, 4, 2, 7, 2, 0 | Get-Extremum -Min | Should -Be -1
    }
    It 'can return minimum or maximum value from array of date values' {
        $Min = '10/11/1492'
        $Max = '10/10/2021'
        $DateStrings = '9/24/2010', $Max, '02/03/2018', $Min
        $DateStrings | Get-Minimum | Should -Be $Min
        $DateStrings | Get-Maximum | Should -Be $Max
        $Min = [DateTime]'1492-10-11'
        $Max = [DateTime]'2021-10-10'
        $DateValues = $DateStrings | ForEach-Object { [DateTime]::Parse($_) }
        $DateValues | Get-Minimum | Should -Be $Min
        $DateValues | Get-Maximum | Should -Be $Max
    }
    It 'Get-Maximum' {
        $Max = 5
        $Values = 1, 2, 2, 1, $Max, 2, 3
        $Values | Get-Maximum | Should -Be $Max
        Get-Maximum $Values | Should -Be $Max
        0, -1, 4, 2, 7, 2, 0 | Get-Maximum | Should -Be 7
    }
    It 'Get-Minimum' {
        $Min = 0
        $Values = 1, 2, 2, 1, $Min, 2, 3
        $Values | Get-Minimum | Should -Be $Min
        Get-Minimum $Values | Should -Be $Min
        0, -1, 4, 2, 7, 2, 0 | Get-Minimum | Should -Be -1
    }
}
Describe 'Get-Factorial' -Tag 'Local', 'Remote' {
    It 'can calculate n!' {
        0 | Get-Factorial | Should -Be 1
        1 | Get-Factorial | Should -Be 1
        2 | Get-Factorial | Should -Be 2
        10 | Get-Factorial | Should -Be 3628800
        20 | Get-Factorial | Should -Be 2432902008176640000
        1..5 | Get-Factorial | Should -Be 1, 2, 6, 24, 120
        Get-Factorial 2 | Should -Be 2
        Get-Factorial 10 | Should -Be 3628800
    }
    It 'can calculate n! for large n values (n = 200)' {
        $Value = [BigInt]::Parse('788657867364790503552363213932185062295135977687173263294742533244359449963403342920304284011984623904177212138919638830257642790242637105061926624952829931113462857270763317237396988943922445621451664240254033291864131227428294853277524242407573903240321257405579568660226031904170324062351700858796178922222789623703897374720000000000000000000000000000000000000000000000000')
        $Result = 200 | Get-Factorial
        $Result | Should -Be $Value
        $Result.GetType().Name | Should -Be 'BigInteger'
    }
}
Describe 'Get-LogisticSigmoid' -Tag 'Local', 'Remote' {
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
Describe 'Get-Mean/Median' -Tag 'Local', 'Remote' {
    It 'can calculate mean (average) for discrete uniform random variable' {
        1..10 | Get-Mean | Should -Be 5.5
        Get-Mean -Data (1..10) | Should -Be 5.5
        1, 3, 4, 5, 6, 9, 14, 30 | Get-Mean | Should -Be 9
        30, 4, 3, 1, 6, 9, 14, 5 | Get-Mean | Should -Be 9
        $Population = 4779736, 710231, 6392017, 2915918, 37253956, 5029196, 3574097, 897934
        $Population | Get-Mean | Should -Be 7694135.625
    }
    It 'can calculate geometric mean' {
        $Mean = 3, 5, 6, 6, 7, 10, 12 | Get-Mean -Geometric
        [Math]::Round($Mean, 2).ToString() | Should -Be '6.43'
        $Mean = 2, 4, 8 | Get-Mean -Geometric
        [Math]::Round($Mean, 2).ToString() | Should -Be '4'
    }
    It 'can calculate harmonic mean' {
        1, 4, 4 | Get-Mean -Harmonic | Should -Be 2
        $Mean = 3, 5, 6, 6, 7, 10, 12 | Get-Mean -Harmonic
        [Math]::Round($Mean, 2).ToString() | Should -Be '5.87'
    }
    It 'can calculate quadratic mean (root mean square)' {
        1, 3, 4, 5, 7 | Get-Mean -Quadratic | Should -Be 4.47213595499958
        3, 5, 6, 6, 7, 10, 12 | Get-Mean -Quadratic | Should -Be 7.54983443527075
    }
    It 'can calculate "trimmed" mean' {
        1..10 | Get-Mean -Trim 0.1 | Should -Be 5.5 -Because '1..10 and 2..9 have the same mean'
        Get-Mean -Data (1..10) -Trim 0.1 | Should -Be 5.5
        (1..10 | Get-Mean -Trim 1), (1..10 | Get-Mean -Trim 1) | Test-Equal | Should -BeTrue -Because '10% of 10 is 1'
        1, 3, 4, 5, 6, 9, 14, 30 | Get-Mean -Trim 2 | Should -Be 6
        30, 4, 3, 1, 6, 9, 14, 5 | Get-Mean -Trim 2 | Should -Be 6
        (30, 4, 3, 1, 6, 9, 14, 5 | Get-Mean -Trim 2), (30, 4, 3, 1, 6, 9, 14, 5 | Get-Mean -Trim 0.25) | Test-Equal | Should -BeTrue '25% of 8 is 2'
    }
    It 'can calculate median for discrete uniform random variable' {
        1..5 | Get-Median | Should -Be 3
        2, 1, 4, 5, 3 | Get-Median | Should -Be 3
        1..10 | Get-Median | Should -Be 5.5
        19, 3, 6, 7, 1, 9, 2, 5, 4, 8 | Get-Median | Should -Be 5.5
        Get-Median -Data (1..5) | Should -Be 3
        Get-Median -Data (1..10) | Should -Be 5.5
    }
}
Describe 'Get-Permutation' -Tag 'Local', 'Remote' {
    It 'can return permutations for a given group of items' {
        Get-Permutation 'ab' | Should -Be @('a', 'b'), @('b', 'a')
        Get-Permutation 'abc' | Should -Be @('a', 'b', 'c'), @('a', 'c', 'b'), @('c', 'a', 'b'), @('c', 'b', 'a'), @('b', 'c', 'a'), @('b', 'a', 'c')
        Get-Permutation 2 | Should -Be @(0, 1), @(1, 0)
        Get-Permutation 2 1 | Should -Be @(1, 2), @(2, 1)
        Get-Permutation 3 | Should -Be @(0, 1, 2), @(0, 2, 1), @(1, 0, 2), @(1, 2, 0), @(2, 0, 1), @(2, 1, 0)
        Get-Permutation 3 1 | Should -Be @(1, 2, 3), @(1, 3, 2), @(2, 1, 3), @(2, 3, 1), @(3, 1, 2), @(3, 2, 1)
        Get-Permutation 1, 2, 3 | Should -Be @(1, 2, 3), @(1, 3, 2), @(3, 1, 2), @(3, 2, 1), @(2, 3, 1), @(2, 1, 3)
        Get-Permutation 4 | Select-Object -First 10 | Should -Be @(0, 1, 2, 3), @(0, 1, 3, 2), @(0, 2, 1, 3), @(0, 2, 3, 1), @(0, 3, 1, 2), @(0, 3, 2, 1), @(1, 0, 2, 3), @(1, 0, 3, 2), @(1, 2, 0, 3), @(1, 2, 3, 0)
    }
    It 'can return permutations for a given group of items via pipeline' {
        'ab' | Get-Permutation | Should -Be @('a', 'b'), @('b', 'a')
        'abc' | Get-Permutation | Should -Be @('a', 'b', 'c'), @('a', 'c', 'b'), @('c', 'a', 'b'), @('c', 'b', 'a'), @('b', 'c', 'a'), @('b', 'a', 'c')
        'foo', 'bar' | Get-Permutation | Should -Be @('foo', 'bar'), @('bar', 'foo')
        2 | Get-Permutation | Should -Be @(0, 1), @(1, 0)
        2 | Get-Permutation -Offset 1 | Should -Be @(1, 2), @(2, 1)
        3 | Get-Permutation | Should -Be @(0, 1, 2), @(0, 2, 1), @(1, 0, 2), @(1, 2, 0), @(2, 0, 1), @(2, 1, 0)
        1, 2, 3 | Get-Permutation | Should -Be @(1, 2, 3), @(1, 3, 2), @(3, 1, 2), @(3, 2, 1), @(2, 3, 1), @(2, 1, 3)
    }
    It 'can can string concatenate output' {
        'cat' | Get-Permutation -Words | Should -Be 'cat', 'cta', 'tca', 'tac', 'atc', 'act'
        'foo', 'bar' | Get-Permutation -Words | Should -Be @('foobar'), @('barfoo')
        1..3 | Get-Permutation -Words | Should -Be '123', '132', '312', '321', '231', '213'
    }
    It 'can handle null values' {
        $Permutations = $Null, 1, 3 | Get-Permutation
        $Permutations | ForEach-Object Count | Get-Maximum | Should -Be 3
        $Permutations | Should -HaveCount 6
        $Permutations = 1, $Null, 3 | Get-Permutation
        $Permutations | ForEach-Object Count | Get-Maximum | Should -Be 3
        $Permutations | Should -HaveCount 6
    }
    It 'can return k-permutations' {
        1..3 | Get-Permutation -Choose 1 | Should -Be @(1), @(3), @(2)
        1..3 | Get-Permutation -Choose 2 | Should -Be @(1, 2), @(1, 3), @(3, 1), @(3, 2), @(2, 3), @(2, 1)
        1..3 | Get-Permutation | Should -Be @(1, 2, 3), @(1, 3, 2), @(3, 1, 2), @(3, 2, 1), @(2, 3, 1), @(2, 1, 3)
        3 | Get-Permutation -Choose 1 | Should -Be @(0), @(1), @(2)
        3 | Get-Permutation | Should -Be @(0, 1, 2), @(0, 2, 1), @(1, 0, 2), @(1, 2, 0), @(2, 0, 1), @(2, 1, 0)
        'cat' | Get-Permutation -Choose 2 -Words | Should -Be 'ca', 'ct', 'tc', 'ta', 'at', 'ac'
    }
    It 'can return k-permutations with unique elements (combinations)' {
        $Results = 1..3 | Get-Permutation -Unique
        $Results -join '' | Should -Be '123' -Because 'combinations count by membership, not order'
        1..3 | Get-Permutation -Choose 2 -Unique | Should -Be @(1, 2), @(1, 3), @(2, 3) -Because 'combinations count by membership, not order'
        3 | Get-Permutation -Choose 2 -Unique | Should -Be @(0, 1), @(0, 2), @(1, 2) -Because 'combinations count by membership, not order'
        # 6 | Get-Permutation -Choose 4 -Unique | Should -HaveCount 15 -Because 'the number of items returned obeys a simple formula'
        'cat' | Get-Permutation -Choose 2 -Unique -Words | Should -Be 'ca', 'ct', 'at'
        'hello' | Get-Permutation -Choose 2 -Unique -Words | Should -Be 'he', 'hl', 'hl', 'ho', 'el', 'el', 'eo', 'll', 'lo', 'lo'
        'hello' | Get-Permutation -Choose 3 -Unique -Words | Should -Be 'hel', 'hel', 'heo', 'hll', 'hlo', 'hlo', 'ell', 'elo', 'elo', 'llo'
    }
}
Describe 'Get-Softmax' -Tag 'Local', 'Remote', 'WindowsOnly' {
    It 'can handle input from pipe' {
        $Expected = '0.00216569646006109', '0.00588697333334214', '0.118243020252665', '0.873704309953932'
        -1, 0, 3, 5 | Get-Softmax | ForEach-Object { $_.ToString() } | Should -Be $Expected
    }
    It 'can handle array input' {
        $Expected = '0.00216569646006109', '0.00588697333334214', '0.118243020252665', '0.873704309953932'
        Get-Softmax -Values -1, 0, 3, 5 | ForEach-Object { $_.ToString() } | Should -Be $Expected
    }
    It 'can handle matrix input' {
        $Round = { Param($X) [Math]::Round($X.Real, 3) }
        $Expected = 0.032, 0.087, 0.237, 0.644
        $A = 1..4 | New-Matrix
        $Result = $A | Get-Softmax | Invoke-MatrixMap $Round
        $Result.Values.Real | Should -Be $Expected
        $Result = Get-Softmax -Values $A | Invoke-MatrixMap $Round
        $Result.Values.Real | Should -Be $Expected
    }
}
Describe 'Get-Sum' -Tag 'Local', 'Remote' {
    It 'can return the sum of a list of numbers' {
        1..5 | Get-Sum | Should -Be 15
        1, 1, 1, 1, 1 | Get-Sum | Should -Be 5
        1..100 | Get-Sum | Should -Be 5050
        Get-Sum -Values (1..100) | Should -Be 5050
        $C1 = New-ComplexValue 1 1
        $C2 = New-ComplexValue 2 2
        $C3 = New-ComplexValue 3 3
        $Expected = New-ComplexValue 6 6
        $C1, $C2, $C3 | Get-Sum | Should -Be $Expected
    }
    It 'can return the weighted sum of a list of numbers' {
        1, 1, 1, 1, 1 | Get-Sum -Weight 1, 2, 3, 4, 5 | Should -Be 15
        Get-Sum -Values 1, 1, 1, 1, 1 -Weight 1, 2, 3, 4, 5 | Should -Be 15
    }
    It 'can calculate the count of true values' {
        $True, $True, $True, $True | Get-Sum | Should -Be 4
        $True, $False, $False, $False, $True | Get-Sum | Should -Be 2
        $False, $False, $False | Get-Sum | Should -Be 0
    }
}
Describe 'Get-Variance / Get-Covariance' -Tag 'Local', 'Remote' {
    It 'can return variance for discrete uniform random variable' {
        $X = 1..10
        $Biased = $X | Get-Variance
        $Unbiased = [Math]::Round(($X | Get-Variance -Sample), 2)
        $Biased | Should -Be 8.25
        $Unbiased | Should -Be 9.17
        [Math]::Round((($Unbiased * ($X.Count - 1)) / $X.Count), 2) | Should -Be $Biased
        Get-Variance $X | Should -Be 8.25
        [Math]::Round((Get-Variance $X -Sample), 2) | Should -Be 9.17
    }
    It 'can return coovariance of two discrete uniform random variables' {
        $X = 1..5
        $X, $X | Get-Covariance | Should -Be (Get-Variance $X) -Because 'Cov(x,x) = Var(x)'
        Get-Covariance $X, $X | Should -Be (Get-Variance $X) -Because 'Cov(x,x) = Var(x)'
        $X = 1692, 1978, 1884, 2151, 2519
        $Y = 68, 102, 110, 112, 154
        $X, $Y | Get-Covariance -Sample | Should -Be 9107.30
        $X, $Y | Get-Covariance | Should -Be (Get-Covariance $Y, $X)
    }
}
Describe 'Invoke-Imputation' -Tag 'Local', 'Remote' {
    It 'can impute missing values' {
        1, $Null, 3, $Null, 5 | Invoke-Imputation | Should -Be @(1, 0, 3, 0, 5)
        1, $Null, 3, $Null, 5 | Invoke-Imputation -With 42 | Should -Be @(1, 42, 3, 42, 5)
        1, $Null, 3, $Null, $Null | Invoke-Imputation | Should -Be @(1, 0, 3, 0, 0)
        1, $Null, 3, $Null, $Null | Invoke-Imputation -Limit 1 | Should -Be @(1, 0, 3, $Null, $Null)
        $Null, $Null, $Null | Invoke-Imputation -Limit 1 | Should -Be @(0, $Null, $Null)
        $Null, $Null, $Null | Invoke-Imputation -With 42 | Should -Be @(42, 42, 42)
        Invoke-Imputation @(1, $Null, 3, $Null, 5) | Should -Be @(1, 0, 3, 0, 5)
        Invoke-Imputation @(1, $Null, 3, $Null, 5) -With 42 | Should -Be @(1, 42, 3, 42, 5)
        Invoke-Imputation @(1, $Null, 3, $Null, $Null) | Should -Be @(1, 0, 3, 0, 0)
        Invoke-Imputation @(1, $Null, 3, $Null, $Null) -Limit 1 | Should -Be @(1, 0, 3, $Null, $Null)
        Invoke-Imputation @($Null, $Null, $Null) -Limit 1 | Should -Be @(0, $Null, $Null)
        Invoke-Imputation @($Null, $Null, $Null) -With 42 | Should -Be @(42, 42, 42)
    }
    It 'can impute missing string values' {
        'foo', 'bar', $Null | Invoke-Imputation -With 'baz' | Should -Be @('foo', 'bar', 'baz')
        'foo', 'bar', '' | Invoke-Imputation -With 'baz' | Should -Be @('foo', 'bar', 'baz')
    }
    It 'can pass-thru values that need no imputation' {
        $Expected = @(1, 2, 3, 4, 5)
        1..5 | Invoke-Imputation | Should -Be $Expected
        1..5 | Invoke-Imputation -With 'sub' -Limit 3 | Should -Be $Expected
        Invoke-Imputation (1..5) 'sub' | Should -Be $Expected
        Invoke-Imputation (1..5) -With 'sub' -Limit 2 | Should -Be $Expected
    }
}