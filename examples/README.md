Prelude Usage Examples
======================
> Are you more familiar with Python? You can find some Python vs Prelude comparison examples [here](./Compare.md).

1. [Use GitHub API to retrieve notifications](#example-1)
1. [Estimate when your laptop will die](#example-2)
1. [Identify carrier of a phone number](#example-3)
1. [Get current count of space objects](#example-4)
1. [Estimate the "Golden Ratio"](#example-5)
1. [Solve a system of linear equations](#example-6)
1. [Analyze Pandemic game play using graph theory](#example-7)

Example #1
----------
> This example requires a [GitHub personal access token](https://docs.github.com/en/github/authenticating-to-github/creating-a-personal-access-token) or a [client ID from an OAuth app](https://docs.github.com/en/developers/apps/authorizing-oauth-apps#device-flow).

Using the [GitHub REST API](https://docs.github.com/en/rest), you can easily get all kinds of data from GitHub.

First, create variables for your token:

```PowerShell
# using a personal access token
$Token = 'your personal access token'

# OR using OAuth with a client ID
$Token = Get-GithubOAuthToken -ClientId 'your app client id' -Scope 'notifications'
```

You can retrieve the titles of your [notifications](https://docs.github.com/en/rest/reference/activity#notifications) using `Invoke-WebRequestBasicAuth`:

```PowerShell
# Create an object to configure the request
$Query = @{ per_page = 100 }

# Get the first page of notification (max 100)
$Uri = "https://api.github.com/notifications"
$Data = basicauth $Uri -Token $Token -Query $Query | prop Content | ConvertFrom-Json

# Print the notification titles
$Data | prop 'subject.title'
```

> **Note**
> The results are paginated. Use the `page` key in your query to retrieve more results.

You can also make changes like marking notifications as read using `Invoke-WebRequestBasicAuth` with the `-Put` and `-Data` parameters:

```PowerShell
# Send request to mark ALL notifications as "read"
$Uri = "https://api.github.com/notifications"
@{ last_read_at = '' } | basicauth $Uri -Token $Token -Put
```

------

Example #2
----------
> Estimate when your laptop battery will die

First, generate a battery report:

```PowerShell
Invoke-Expression 'powercfg /batteryreport'
```

The previous command should have created the file, `battery-report.html` in your current directory.

Next, import the HTML file and extract the necessary data:

```PowerShell
$Html = [String](Get-Content .\battery-report.html) | ConvertFrom-Html
$Raw = $Html.all.tags('table')[5].all.tags('td') |
    prop innerText |
    chunk -s 3 |
    op join ';' |
    ConvertFrom-Csv -Delimiter ';' |
    Select-Object 'PERIOD', 'FULL CHARGE CAPACITY '
```

The data needs to be shaped before it can be used. We can simply create `$Lookup` to map the field names and `$Reducer` to format the values in each column, based on type. Then we transform (see `help transform -examples`) the data and filter out empty rows:

```PowerShell
$NotSpace = { $Args[0] -ne ' ' }
$Lookup = @{
    Date = 'PERIOD'
    Capacity = 'FULL CHARGE CAPACITY '
}
$Reducer = {
    Param($Name, $Value)
    switch ($Name) {
        $Lookup.Date {
            ([DateTime]($Value | takeWhile $NotSpace)).ToFileTime()
        }
        $Lookup.Capacity {
            [Int]($Value | takeWhile $NotSpace)
        }
    }
}
$Data = $Raw | transform $Lookup $Reducer | ? { $_.Capacity -gt 0 }
```

We can now fit the data with a simple linear model using matrices. This is done via the equation,

$$
\widehat{\beta } = {\left ( \textbf{X}^{\text{T}} \textbf{X} \right )}^{-1} \textbf{X}^{\text{T}}\textbf{Y}
$$

To ensure this equation will render an answer, we must first verify that **X<sup>T</sup> X** is non-singular, that is, we must verify

$$
\text{det}\begin{vmatrix} \textbf{X}^{\text{T}}\textbf{X} \end{vmatrix} \neq 0
$$

We can quickly calculate the necessary determinant:

```PowerShell
# this should return $True
($X.Transpose() * $X).Det() -ne 0
```

With the knowledge that we possess a non-singular matrix, we proceed with the simple linear model calculations:

```PowerShell
# create the X and Y matrices
$Shape = $Data.Count, 1
$X0 = New-Matrix -Unit $Shape
$X1 = $Data.Date | New-Matrix $Shape
$X = $X0.Augment($X1)
$Y = $Data.Capacity | New-Matrix $Shape
# fit the linear model with matrices
$B = ($X.Transpose() * $X).Inverse() * ($X.Transpose() * $Y)
```

Now we can figure out when the line crosses zero to determine when our laptop will die:

```PowerShell
# since Y = (B1 * X) + B0, when y = 0 we know X = -B0 / B1
$XIntercept = -1 * $B[0] / $B[1]
$BatteryDeathDate = [DateTime]::FromFileTime($XIntercept.Real)
```

> 🤓 The data in my battery report indicates that my Microsoft Surface Pro 6 battery may die sometime in 2028

After making a statistical inference, it is common practice to assess the quality of the estimation. We can calculate an estimator for the variance with the equation,

$$
s^{2} = \frac{\text{SSE}}{n - 2} = \frac{\textbf{Y}^{\text{T}}\textbf{Y} - \beta^{\text{T}}\textbf{X}^{T}\textbf{Y}}{n - 2}
$$

, and the associated code,

```PowerShell
$SSE = ($Y.Transpose() * $Y) - ($B.Transpose() * $X.Transpose() * $Y)
$Var = $SSE / ($Shape[0] - 2)
```

------

Example #3
----------
> Identify the phone carrier (ex: Verizon, ATT, etc...) of a given phone number

Suppose we have a phone number, `555-123-4567`. To get started we need to prepare a query object:

```PowerShell
$Query = @{
    npa = '555'
    nxx = '123'
    thoublock = '4567'
}
```

From here we will leverage the [fonfinder](http://fonefinder.net/) site to ascertain the phone carrier, albeit in a somewhat circumspect manner. First we need to get the anchor tags from the appropriate fonefinder URL. In the same step we will filter the content to only include the URL that contains the information we seek. A mildly complex regular expression is required:

```PowerShell
$Re = '(?<=(http://fonefinder[.]net/)).*(?=[.]php$)'
$Uri = 'http://www.fonefinder.net/findome.php'
$Href = basicauth -Uri $Uri -Query $Query |
    prop Content |
    Get-HtmlElement 'a' |
    prop href |
    ? { $_ -match $Re }
```

Finally, we liberate the carrier name from the URL found in the previous step with
```PowerShell
$Href -match $Re
$Matches[0] | Write-Color -Green
```

This code could easily be packaged as a cmdlet,

```PowerShell
function Get-Carrier {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $True, Position = 0)]
        [String] $PhoneNumber
    )
    $Npa, $Nxx, $Thoublock = $PhoneNumber -split '-'
    $Query = @{
        npa = $Npa
        nxx = $Nxx
        thoublock = $Thoublock
    }
    $Uri = 'http://www.fonefinder.net/findome.php'
    $Re = '(?<=(http://fonefinder[.]net/)).*(?=[.]php$)'
    $Href = Invoke-WebRequestBasicAuth -Uri $Uri -Query $Query |
        Get-Property 'Content' |
        Get-HtmlElement 'a' |
        Get-Property 'href' |
        Where-Object { $_ -match $Re }
    if ($Href -match $Re) {
        $Matches[0]
    } else {
        'Unknown'
    }
}
```
which would be used like this:

```PowerShell
"Your carrier is $(Get-Carrier '555-123-4567')" | Write-Color -Cyan
```

------

Example #4
----------
> Get current number of objects in space

The [Texas Advanced Computing Center (TACC)](tacc.utexas.edu) provides an updated count of space objects. We can easily scrape their website with

```PowerShell
basicauth -Uri 'http://astria.tacc.utexas.edu/compliance/default?' |
    prop 'Content' |
    Get-HtmlElement 'td' |
    prop 'innerText' |
    method 'Trim'
```

------

Example #5
----------
> Estimate the "Golden Ratio" using matrices and the Fibonacci Sequence

<div align="center">
    <a href="#"><img alt="Eigenvalues with matrices" src="http://www.jasonwohlgemuth.com/pwsh-prelude/images/eigenvalue.gif" alt="Eigenvalue with matrices" width="1280"/></a>
</div>

First, we model the [Fibonacci sequence](https://en.wikipedia.org/wiki/Fibonacci_number) using the equations, $F_{k + 2} = F_{k + 1} + F_{k}$ and $F_{k + 1} = F_{k + 1}$, which can be codified in matrix form as

$$
U_{k} = \begin{bmatrix}
F_{k + 1}\\
F_{k}\\
\end{bmatrix}
$$

and $U_{k + 1} = A \cdot U_{k}$, where

$$
A = \begin{bmatrix}
1 & 1\\
1 & 0\\
\end{bmatrix}
$$

The final step is a simple matter of calculating the dominant eigenvalue of ***A*** with the code,

```PowerShell
$A = 1, 1, 1, 0 | matrix
$Phi = $A.Eigenvalue()
# 1.6180339887482
```

------

Example #6
----------
> Solve system of equations using [Gaussian elimination](https://en.wikipedia.org/wiki/Gaussian_elimination)

$$
\text{Solve the system}
\begin{cases}
& 2\textit{x}_1 + \textit{x}_2 + 5\textit{x}_3 + \textit{x}_4 = 5 \\
& \textit{x}_1 + \textit{x}_2 - 3\textit{x}_3 - 4\textit{x}_4 = -1 \\
& 3\textit{x}_1 + 6\textit{x}_2 - 2\textit{x}_3 + \textit{x}_4 = 8 \\
& 2\textit{x}_1 + 2\textit{x}_2 + 2\textit{x}_3 - 3\textit{x}_4 = 2
\end{cases}
$$

Our plan is to solve the equation, $\mathbf{A}\textit{x}= \mathbf{b}$, where 

$$
\mathbf{A} =
\begin{bmatrix}
2 & 1 & 5 & 1\\
1 & 1 & -3 & -4\\
3 & 6 & -2 & 1\\
2 & 2 & 2 & -3\\
\end{bmatrix}
$$

and

$$
\mathbf{b} = \begin{bmatrix}
5\\
-4\\
1\\
-3\\
\end{bmatrix}
$$

Finally, we solve the equation by using Gaussian elimination on the associated [augmented matrix](https://en.wikipedia.org/wiki/Augmented_matrix).

This can be translated to code very easily as

```PowerShell
$A = 2, 1, 5, 1, 1, 1, -3, -4, 3, 6, -2, 1, 2, 2, 2, -3 | matrix 4,4
$B = 5, -1, 8, 2 | matrix 4,1
$X = [Matrix]::Solve($A, $B)
```

which yields the result,

$$
\mathbf{\textit{x}} =
\begin{bmatrix}
\textit{x}_1\\
\textit{x}_2\\
\textit{x}_3\\
\textit{x}_4\\
\end{bmatrix} =
\begin{bmatrix}
2\\
0.2\\
0\\
0.8\\
\end{bmatrix}
$$

------

Example #7
----------
> Analyze the game play tactics of the [Pandemic board game](https://www.amazon.com/Z-Man-Games-ZM7101-Pandemic/dp/B00A2HD40E)

👷‍♂️ ***UNDER CONSTRUCTION***
