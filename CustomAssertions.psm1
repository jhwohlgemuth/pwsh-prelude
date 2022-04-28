[Diagnostics.CodeAnalysis.SuppressMessageAttribute('RequireDirective', '')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '')]
Param()

function Test-ObjectKeyArray {
    <#
    .SYNOPSIS
    Compares the keys of the input object with an expected array of values.
    .EXAMPLE
    @{ 'a' = 1; 'b' = 2; 'c' = 3 } | Should -HaveKeys @('a', 'b', 'c')
    .EXAMPLE
    @{ 'x' = 1; 'y' = 2; 'z' = 3 } | Should -not -HaveKeys @('a', 'b', 'c')
    #>
    [CmdletBinding()]
    Param(
        [PSObject] $ActualValue,
        [Array] $ExpectedValue,
        [Switch] $Negate,
        [String] $Because,
        [Management.Automation.SessionState] $CallerSessionState
    )
    $SortedExpected = $ExpectedValue | Sort-Object
    $SortedActual = $ActualValue.Keys | Sort-Object
    $Succeeded = 0..($ExpectedValue.Count - 1) |
        ForEach-Object { ($SortedExpected[$_] -eq $SortedActual[$_]) } |
        Invoke-Reduce -Every
    if ($Negate) { $Succeeded = -not $Succeeded }
    if (-not $Succeeded) {
        $NegateMessage = if ($Negate) { 'NOT ' }
        $ExpectedMessage = "@($($ExpectedValue -join ', '))"
        $BecauseMessage = if ($Because) { " because ${Because}" }
        $FailureMessage = "Expected input object to ${NegateMessage}have keys, ${ExpectedMessage}${BecauseMessage}."
    }
    return [PSCustomObject]@{
        Succeeded = $Succeeded
        FailureMessage = $FailureMessage
    }
}
Add-ShouldOperator -Name 'HaveKeys' -InternalName 'Test-ObjectKeyArray' -Test ${Function:Test-ObjectKeyArray}