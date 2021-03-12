Examples
========

1. [Use GitHub API to retrieve notifications](#example-1)
1. [Estimate when your laptop will die](#example-2)
1. [under construction](#example-3)
1. [Solve a system of linear equations](#example-4)
1. [Calculate eccentricity of earth using classical method](#example-5)
1. [Analyze Pandemic game play using graph theory](#example-6)

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
$Data = basicauth $Token -Uri $Uri -Query $Query | prop Content | ConvertFrom-Json

# Print the notification titles
$Data | prop 'subject.title'
```

> ***NOTE***: The results are paginated. Use the `page` key in your query to retrieve more results.

You can also make changes like marking notifications as read using `Invoke-WebRequestBasicAuth` with the `-Put` and `-Data` parameters:

```PowerShell
# Send request to mark ALL notifications as "read"
$Uri = "https://api.github.com/notifications"
@{ last_read_at = '' } | basicauth $Token -Uri $Uri -Put
```

------

Example #2
----------
> Estimate when your laptop battery will die

First, generate a battery report:

```PowerShell
powercfg /batteryreport
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

We can now fit the data with a simple linear model using matrices:

```PowerShell
$X0 = matrix $Data.Count,1 -Unit
$X1 = $Data.Date
$X = $X0.Augment($X1)
$Y = $Data.Capacity | matrix $Data.Count, 1

# fit linear model with matrices
$B = ($X.Transpose() * $X).Inverse() * ($X.Transpose() * $Y)
```

Finally, we can figure out when the line crosses zero to determine when our laptop will die:

```PowerShell
# since Y = (B1 * X) + B0, when y = 0 we know X = -B0 / B1
$XIntercept = -1 * $B[0, 0] / $B[0, 1]
$BatteryDeathDate = [DateTime]::FromFileTime($XIntercept)
```

> The data in my battery report indicates that my Microsoft Surface Pro 6 battery may die sometime in 2028

------

Example #3
----------
> ???

👷‍♂️ ***UNDER CONSTRUCTION***

------

Example #4
----------
> Solve system of equations using [Gaussian elimination](https://en.wikipedia.org/wiki/Gaussian_elimination)

<a href="https://www.codecogs.com/eqnedit.php?latex=\inline&space;\text{Solve&space;the&space;system}&space;\begin{cases}&space;&&space;2\textit{x}_1&space;&plus;&space;\textit{x}_2&space;&plus;&space;5\textit{x}_3&space;&plus;&space;\textit{x}_4&space;=&space;5&space;\\&space;&&space;\textit{x}_1&space;&plus;&space;\textit{x}_2&space;-&space;3\textit{x}_3&space;-&space;4\textit{x}_4&space;=&space;-1&space;\\&space;&&space;3\textit{x}_1&space;&plus;&space;6\textit{x}_2&space;-&space;2\textit{x}_3&space;&plus;&space;\textit{x}_4&space;=&space;8&space;\\&space;&&space;2\textit{x}_1&space;&plus;&space;2\textit{x}_2&space;&plus;&space;2\textit{x}_3&space;-&space;3\textit{x}_4&space;=&space;2&space;\end{cases}" target="_blank"><img src="https://latex.codecogs.com/gif.latex?\inline&space;\text{Solve&space;the&space;system}&space;\begin{cases}&space;&&space;2\textit{x}_1&space;&plus;&space;\textit{x}_2&space;&plus;&space;5\textit{x}_3&space;&plus;&space;\textit{x}_4&space;=&space;5&space;\\&space;&&space;\textit{x}_1&space;&plus;&space;\textit{x}_2&space;-&space;3\textit{x}_3&space;-&space;4\textit{x}_4&space;=&space;-1&space;\\&space;&&space;3\textit{x}_1&space;&plus;&space;6\textit{x}_2&space;-&space;2\textit{x}_3&space;&plus;&space;\textit{x}_4&space;=&space;8&space;\\&space;&&space;2\textit{x}_1&space;&plus;&space;2\textit{x}_2&space;&plus;&space;2\textit{x}_3&space;-&space;3\textit{x}_4&space;=&space;2&space;\end{cases}" title="\text{Solve the system} \begin{cases} & 2\textit{x}_1 + \textit{x}_2 + 5\textit{x}_3 + \textit{x}_4 = 5 \\ & \textit{x}_1 + \textit{x}_2 - 3\textit{x}_3 - 4\textit{x}_4 = -1 \\ & 3\textit{x}_1 + 6\textit{x}_2 - 2\textit{x}_3 + \textit{x}_4 = 8 \\ & 2\textit{x}_1 + 2\textit{x}_2 + 2\textit{x}_3 - 3\textit{x}_4 = 2 \end{cases}" /></a>

Our plan is to solve the equation,

<a href="https://www.codecogs.com/eqnedit.php?latex=\inline&space;\mathbf{A}\textit{x}=&space;\mathbf{b}" target="_blank"><img src="https://latex.codecogs.com/gif.latex?\inline&space;\mathbf{A}\textit{x}=&space;\mathbf{b}" title="\mathbf{A}\textit{x}= \mathbf{b}" /></a>

where

<a href="https://www.codecogs.com/eqnedit.php?latex=\inline&space;\mathbf{A}&space;=&space;\begin{bmatrix}&space;2&space;&&space;1&space;&&space;5&space;&&space;1\\&space;1&space;&&space;1&space;&&space;-3&space;&&space;-4\\&space;3&space;&&space;6&space;&&space;-2&space;&&space;1\\&space;2&space;&&space;2&space;&&space;2&space;&&space;-3&space;\end{bmatrix}&space;\text{,&space;}&space;\mathbf{b}&space;=&space;\begin{bmatrix}&space;5\\&space;-4\\&space;1\\&space;-3&space;\end{bmatrix}" target="_blank"><img src="https://latex.codecogs.com/gif.latex?\inline&space;\mathbf{A}&space;=&space;\begin{bmatrix}&space;2&space;&&space;1&space;&&space;5&space;&&space;1\\&space;1&space;&&space;1&space;&&space;-3&space;&&space;-4\\&space;3&space;&&space;6&space;&&space;-2&space;&&space;1\\&space;2&space;&&space;2&space;&&space;2&space;&&space;-3&space;\end{bmatrix}&space;\text{,&space;}&space;\mathbf{b}&space;=&space;\begin{bmatrix}&space;5\\&space;-4\\&space;1\\&space;-3&space;\end{bmatrix}" title="\mathbf{A} = \begin{bmatrix} 2 & 1 & 5 & 1\\ 1 & 1 & -3 & -4\\ 3 & 6 & -2 & 1\\ 2 & 2 & 2 & -3 \end{bmatrix} \text{, } \mathbf{b} = \begin{bmatrix} 5\\ -4\\ 1\\ -3 \end{bmatrix}" /></a>

and then solve the equation by using Gaussian elimination on the associated [augmented matrix](https://en.wikipedia.org/wiki/Augmented_matrix).

This can be translated to code very easily as

```PowerShell
$A = 2, 1, 5, 1, 1, 1, -3, -4, 3, 6, -2, 1, 2, 2, 2, -3 | matrix 4,4
$B = 5, -1, 8, 2 | matrix 4,1
$X = [Matrix]::Solve($A, $B)
```

which yields the result,

<a href="https://www.codecogs.com/eqnedit.php?latex=\inline&space;\mathbf{\textit{x}}&space;=&space;\begin{bmatrix}&space;\textit{x}_1\\&space;\textit{x}_2\\&space;\textit{x}_3\\&space;\textit{x}_4&space;\end{bmatrix}&space;=&space;\begin{bmatrix}&space;2\\&space;0.2\\&space;0\\&space;0.8&space;\end{bmatrix}" target="_blank"><img src="https://latex.codecogs.com/gif.latex?\inline&space;\mathbf{\textit{x}}&space;=&space;\begin{bmatrix}&space;\textit{x}_1\\&space;\textit{x}_2\\&space;\textit{x}_3\\&space;\textit{x}_4&space;\end{bmatrix}&space;=&space;\begin{bmatrix}&space;2\\&space;0.2\\&space;0\\&space;0.8&space;\end{bmatrix}" title="\mathbf{\textit{x}} = \begin{bmatrix} \textit{x}_1\\ \textit{x}_2\\ \textit{x}_3\\ \textit{x}_4 \end{bmatrix} = \begin{bmatrix} 2\\ 0.2\\ 0\\ 0.8 \end{bmatrix}" /></a>

------

Example #5
----------
> Use classical methods to calculate the eccentricity of the earth

👷‍♂️ ***UNDER CONSTRUCTION***

------

Example #6
----------
> Analyze the game play tactics of the [Pandemic board game](https://www.amazon.com/Z-Man-Games-ZM7101-Pandemic/dp/B00A2HD40E)

👷‍♂️ ***UNDER CONSTRUCTION***
