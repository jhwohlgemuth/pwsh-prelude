function ConvertTo-Degree {
    <#
    .SYNOPSIS
    Convert radians to degrees
    #>
    [CmdletBinding()]
    [Alias('toDegree')]
    [OutputType([Double])]
    Param(
        [Parameter(Mandatory = $True, Position = 0, ValueFromPipeline = $True)]
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
        [Parameter(Mandatory = $True, Position = 0, ValueFromPipeline = $True)]
        [Double] $Degrees
    )
    Process {
        ($Degrees % 360) * ([Math]::Pi / 180)
    }
}
function Get-Covariance {
    <#
    .SYNOPSIS
    Return covariance of two discrete uniform random variables
    .DESCRIPTION
    Covariance measures the total variation of two random variables from their expected values.
    Using covariance, we can only gauge the direction of the relationship (whether the variables tend to move in tandem or show an inverse relationship).
    However, it does not indicate the strength of the relationship, nor the dependency between the variables.
    To measure the strength and relationship between variables, calculate correlation.
    .PARAMETER Sample
    Divide by ($Data.Count - 1) instead of $Data.Count. Reasearch "degrees of freedom" for more information. May also be referred to as "unbiased".
    .EXAMPLE
    $X = 1692,1978,1884,2151,2519
    $Y = 68,102,110,112,154
    $X,$Y | Get-Covariance -Sample
    #>
    [CmdletBinding()]
    [Alias('covariance')]
    Param(
        [Parameter(Position = 0, ValueFromPipeline = $True)]
        [Array] $Data,
        [Switch] $Sample
    )
    End {
        $Values = if ($Input.Count -eq 2) { $Input } else { $Data }
        $X, $Y = $Values
        $MeanX = Get-Mean $X
        $MeanY = Get-Mean $Y
        $ResidualX = $X | ForEach-Object { $_ - $MeanX }
        $ResidualY = $Y | ForEach-Object { $_ - $MeanY }
        $Values = $ResidualX, $ResidualY | Invoke-Zip | ForEach-Object { $_[0] * $_[1] }
        if ($Sample) {
            ($Values | Get-Sum) / ($Values.Count - 1)
        } else {
            Get-Mean $Values
        }
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
        [Parameter(Mandatory = $True, Position = 0, ValueFromPipeline = $True)]
        [Array] $InputObject,
        [Alias('Max')]
        [Switch] $Maximum,
        [Alias('Min')]
        [Switch] $Minimum
    )
    Begin {
        function Invoke-GetExtremum {
            Param(
                [Parameter(Position = 0)]
                [Array] $Values
            )
            if ($Values.Count -gt 0) {
                $Type = Find-FirstTrueVariable 'Maximum', 'Minimum'
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
    Return factorial of Value, Value!
    .EXAMPLE
    Get-Factorial 10
    # 3628800
    .EXAMPLE
    200 | factorial
    # 788657867364790503552363213932185062295135977687173263294742533244359449963403342920304284011984623904177212138919638830257642790242637105061926624952829931113462857270763317237396988943922445621451664240254033291864131227428294853277524242407573903240321257405579568660226031904170324062351700858796178922222789623703897374720000000000000000000000000000000000000000000000000
    #>
    [CmdletBinding()]
    [OutputType([Int])]
    Param(
        [Parameter(Position = 0, ValueFromPipeline = $True)]
        [Int] $Value
    )
    Process {
        if ($Value -eq 0) {
            1
        } else {
            1..$Value | Invoke-Reduce {
                Param(
                    [BigInt] $Acc,
                    [BigInt] $Item
                )
                [BigInt]::Multiply($Acc, $Item)
            }
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
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '', Scope = 'Function')]
    [CmdletBinding()]
    [Alias('sigmoid')]
    [OutputType([Double])]
    Param(
        [Parameter(Mandatory = $True, Position = 0, ValueFromPipeline = $True)]
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
        $Sigmoid = { Param($X) $MaximumValue / (1 + [Math]::Pow([Math]::E, (-1 * $GrowthRate) * ($X - $Midpoint))) }
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
        [Parameter(Mandatory = $True, Position = 0, ValueFromPipeline = $True)]
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
    .PARAMETER Trim
    Return "trimmed" mean where a certain number of items from the beginning and end of the sorted data are excluded from the mean.
    Note: If this parameter value is in the range (0,1), it will be treated as a percentage.
    .EXAMPLE
    1..10 | mean
    .EXAMPLE
    1..10 | mean -Trim 1
    #>
    [CmdletBinding()]
    [Alias('mean')]
    Param(
        [Parameter(Mandatory = $True, Position = 0, ValueFromPipeline = $True)]
        [Array] $Data,
        [ValidateRange(0, [Double]::PositiveInfinity)]
        [Double] $Trim = 0,
        [Array] $Weight
    )
    End {
        if ($Input.Count -gt 0) {
            $Data = $Input
        }
        if ($Trim -gt 0 -and $Trim -lt 1) {
            $Trim = [Math]::Floor($Trim * $Data.Count)
        }
        $Data = $Data | Sort-Object
        $Data = $Data[$Trim..($Data.Count - 1 - $Trim)]
        ($Data | Get-Sum -Weight $Weight) / $Data.Count
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
        [Parameter(Mandatory = $True, Position = 0, ValueFromPipeline = $True)]
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
        [Parameter(Mandatory = $True, Position = 0, ValueFromPipeline = $True)]
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
function Get-Permutation {
    <#
    .SYNOPSIS
    Return permutaions of input object
    .DESCRIPTION
    Implements the "Steinhaus–Johnson–Trotter" algorithm that leverages adjacent transpositions ("swapping")
    combined with lexicographic ordering in order to create a list of permutations.
    In mathematical terms, the number of items return by Get-Permutation can be quantified as follows:
        Get-Permutation $n ==> (Get-Factorial $n) items = P(n,n) = n!
        Get-Permutation $n -Choose $k ==> ((Get-Factorial $n) / (Get-Factorial ($n - $k))) items = P(n,k) = n! / (n - k)!
        Get-Permutation $n -Choose $k -Unique ==> ((Get-Factorial $n) / ((Get-Factorial $k) * (Get-Factorial ($n - $k)))) items = C(n,k) = n! / k!(n - k)!
    Note: Get-Permutation will start to exhibit noticeable pause before completion for n = 7
    .PARAMETER Words
    Combine individual permutations as strings (see examples)
    .PARAMETER Choose
    Return permutations selected from -Choose items. For a value of "k" for Choose parameter,
    the equivalent mathematical formula for the number items returned by "Get-Permutation n -Choose k" is: n! / (n - k)!
    .PARAMETER Unique
    Return only permutations that are unique up to set membership (order does not matter)
    .EXAMPLE
    2 | Get-Permutation
    # @(0,1),@(1,0)
    1,2 | Get-Permutation
    # @(1,2),@(2,1)
    2 | Get-Permutation -Offset 1
    # @(1,2).@(2,1)
    .EXAMPLE
    'cat' | permute -Words
    # 'cat','cta','tca','tac','atc','act'
    .EXAMPLE
    'hello' | permute -Choose 2 -Unique -Words
    # 'he','hl','hl','ho','el','el','eo','ll','lo','lo'
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '', Scope = 'Function')]
    [CmdletBinding()]
    [Alias('permute')]
    Param(
        [Parameter(Position = 0, ValueFromPipeline = $True)]
        [Array] $InputObject,
        [Parameter(Position = 1)]
        [Int] $Offset = 0,
        [Int] $Choose,
        [Switch] $Unique,
        [Switch] $Words
    )
    Begin {
        function Invoke-Swap {
            <#
            .SYNOPSIS
            Swap two elements of an array
            ==> b = (a += b -= a) - b
            #>
            Param(
                [Array] $Items,
                [Int] $Next,
                [Int] $Current
            )
            $Items[$Next] = ($Items[$Current] += $Items[$Next] -= $Items[$Current]) - $Items[$Next]
        }
        function Test-Moveable {
            Param(
                [Parameter(Position = 0)]
                [Array] $Work,
                [Parameter(Position = 1)]
                [Array] $Direction,
                [Parameter(Position = 2)]
                [Int] $Index
            )
            if (($Index -eq 0 -and $Direction[$Index] -eq 0) -or ($Index -eq ($Work.Count - 1) -and $Direction[$Index] -eq 1)) {
                return $False
            }
            if (($Index -gt 0) -and ($Direction[$Index] -eq 0) -and ($Work[$Index] -gt $Work[$Index - 1])) {
                return $True
            }
            if ($Index -lt ($Work.Count - 1) -and ($Direction[$Index] -eq 1) -and ($Work[$Index] -gt $Work[$Index + 1])) {
                return $True
            }
            if (($Index -gt 0) -and ($Index -lt $Work.Count)) {
                if (($Direction[$Index] -eq 0 -and $Work[$Index] -gt $Work[$Index - 1]) -or ($Direction[$Index] -eq 1 -and $Work[$Index] -gt $Work[$Index + 1])) {
                    return $True
                }
            }
            return $False
        }
        function Test-MoveableExist {
            [OutputType([Bool])]
            Param(
                [Parameter(Position = 0)]
                [Array] $Work,
                [Parameter(Position = 1)]
                [Array] $Direction
            )
            $IsMoveable = $False
            for ($Index = 0; $Index -lt $Work.Count; $Index++) {
                if (Test-Moveable -Work $Work -Direction $Direction -Index $Index) {
                    $IsMoveable = $True
                    Break
                }
            }
            $IsMoveable
        }
        function Find-LargestMoveable {
            [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', 'Position')]
            Param(
                [Parameter(Position = 0)]
                [Array] $Work,
                [Parameter(Position = 1)]
                [Array] $Direction
            )
            $Index = 0
            foreach ($Item in $Work) {
                if ((Test-Moveable -Work $Work -Direction $Direction -Index $Index) -and ($Largest -lt $Item)) {
                    $Largest = $Item
                    $Position = $Index
                }
                $Index++
            }
            $Position
        }
        function Invoke-Permutation {
            Param(
                [Parameter(Position = 0)]
                [Int] $Value,
                [Parameter(Position = 1)]
                [Int] $Offset,
                [Int] $Choose,
                [Switch] $Unique
            )
            $Results = New-Object 'Object[]' @((Get-Factorial $Value))
            $Work = 0..($Value - 1) | ForEach-Object { $_ + $Offset }
            $Direction = $Work | ForEach-Object { 0 }
            $Step = 1
            $Results[0] = $Work.Clone()
            while ((Test-MoveableExist $Work $Direction)) {
                $Current = Find-LargestMoveable $Work $Direction
                $NextPosition = if ($Direction[$Current] -eq 0) { $Current - 1 } else { $Current + 1 }
                Invoke-Swap -Items $Work -Next $NextPosition -Current $Current
                Invoke-Swap -Items $Direction -Next $NextPosition -Current $Current
                0..($Value - 1) |
                    Where-Object { $Work[$_] -gt $Work[$NextPosition] } |
                    ForEach-Object { $Direction[$_] = if ($Direction[$_] -eq 0) { 1 } else { 0 } }
                $Results[$Step] = $Work.Clone()
                $Step++
            }
            if ($Choose -gt 0) {
                $Items = New-Object 'System.Collections.ArrayList'
                foreach ($Result in $Results) {
                    [Void]$Items.Add($Result[0..($Choose - 1)])
                }
                $Results = $Items | Select-Object -Unique
            }
            if ($Unique) {
                $Choices = New-Object 'System.Collections.ArrayList'
                foreach ($Result in $Results) {
                    $Choice = $Result | Sort-Object
                    [Void]$Choices.Add($Choice)
                }
                $Choices | Sort-Object -Unique
            } else {
                $Results
            }
        }
        $GetResults = {
            Param(
                [Parameter(Position = 0)]
                [Array] $InputObject
            )
            $Count = $InputObject.Count
            $Items = $InputObject
            $Value = $Count
            if ($Count -gt 0) {
                if ($Count -eq 1) {
                    $First = $InputObject[0]
                    $Type = $First.GetType().Name
                    if ($Null -ne $First -and $Type -eq 'String') {
                        $Items = $First.ToCharArray()
                        $Value = $Items.Count
                    } elseif ($Type -match 'Int') {
                        $Items = @()
                        $Value = $First
                    }
                }
                if ($Items.Count -gt 0) {
                    $Result = [System.Collections.ArrayList]@{}
                    $Parameters = @{
                        Value = $Value
                        Offset = 0
                        Choose = $Choose
                        Unique = $Unique
                    }
                    foreach ($Item in (Invoke-Permutation @Parameters)) {
                        $Permutation = $Items[$Item]
                        if ($Words) {
                            $Permutation = $Permutation -join ''
                        }
                        [Void]$Result.Add($Permutation)
                    }
                    $Result
                } else {
                    $Parameters = @{
                        Value = $Value
                        Offset = $Offset
                        Choose = $Choose
                        Unique = $Unique
                    }
                    Invoke-Permutation @Parameters | Sort-Object -Property { $_ -join '' }
                }
            }
        }
        & $GetResults $InputObject
    }
    End {
        & $GetResults $Input
    }
}
function Get-Sum {
    <#
    .SYNOPSIS
    Calculate sum of list of numbers
    .EXAMPLE
    1..100 | sum
    #>
    [CmdletBinding()]
    [Alias('sum')]
    [OutputType([System.Numerics.Complex])]
    [OutputType([Int])]
    Param(
        [Parameter(Position = 0, ValueFromPipeline = $True)]
        [Array] $Values,
        [Parameter(Position = 1)]
        [Array] $Weight
    )
    Begin {
        if ($Values.Count -gt 0) {
            if ($Weight.Count -eq $Values.Count) {
                $Size = $Values.Count
                $X = $Values | New-Matrix -Size 1, $Size
                $W = $Weight | New-Matrix -Size $Size, $Size -Diagonal
                $Values = ($X * $W).Values
            }
            $Sum = 0
            foreach ($Value in $Values) {
                $Sum += $Value
            }
            if ($Sum.Imaginary -eq 0) {
                $Sum.Real
            } else {
                $Sum
            }
        }
    }
    End {
        if ($Input.Count -gt 0) {
            if ($Weight.Count -eq $Input.Count) {
                $Size = $Input.Count
                $X = $Input | New-Matrix -Size 1, $Size
                $W = $Weight | New-Matrix -Size $Size, $Size -Diagonal
                $Values = ($X * $W).Values
            } else {
                $Values = $Input
            }
            $Sum = 0
            foreach ($Value in $Values) {
                $Sum += $Value
            }
            if ($Sum.Imaginary -eq 0) {
                $Sum.Real
            } else {
                $Sum
            }
        }
    }
}
function Get-Variance {
    <#
    .SYNOPSIS
    Return variance for discrete uniform random variable
    .DESCRIPTION
    The variance is basically the spread (dispersion) of the data.
    .PARAMETER Sample
    Divide by ($Data.Count - 1) instead of $Data.Count. Reasearch "degrees of freedom" for more information. May also be referred to as "unbiased".
    .EXAMPLE
    1..10 | Get-Variance
    .EXAMPLE
    1..10 | variance -Sample
    #>
    [CmdletBinding()]
    [Alias('variance')]
    Param(
        [Parameter(Position = 0, ValueFromPipeline = $True)]
        [Array] $Data,
        [Switch] $Sample
    )
    End {
        $Values = if ($Input.Count -gt 0) { $Input } else { $Data }
        if ($Sample -and $Values.Count -gt 1) {
            $Mean = Get-Mean $Values
            $SquaredResidual = $Values | ForEach-Object { [Math]::Pow(($_ - $Mean), 2) }
            ($SquaredResidual | Get-Sum) / ($Values.Count - 1)
        } else {
            $Squared = $Values | ForEach-Object { [Math]::Pow($_, 2) }
            (Get-Mean $Squared) - [Math]::Pow((Get-Mean $Values), 2)
        }
    }
}