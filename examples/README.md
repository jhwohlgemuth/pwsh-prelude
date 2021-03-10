Examples
========

1. [Use GitHub API to retrieve notifications](#example1)
1. [Calculate when your laptop will die](#example2)
1. [Perform Markov transition matrix calculations](#example3)
1. [Solve system of linear equations](#example4)
1. [Calculate eccentricity of earth using classical method](#example5)
1. [Analyze Pandemic game play using graph theory](#example6)

Example #1
----------
> UNDER CONSTRUCTION

Example #2
----------
> Calculate when your laptop will die

First, generate a battery report:

```PowerShell
powercfg /batteryreport
```

The previous command should have created the file, `battery-report.html` in your current directory.

Next, import the HTML file and pull out the necessary data:

```PowerShell
$Html = [String](Get-Content .\battery-report.html) | ConvertFrom-Html
$Raw = $Html.all.tags('table')[5].all.tags('td') |
    prop innerText |
    chunk -s 3 |
    op join ';' |
    ConvertFrom-Csv -Delimiter ';' |
    Select-Object 'PERIOD', 'FULL CHARGE CAPACITY '
```

This data is good, but it needs to be cleanup up a bit. We simply create `$Lookup` to map the field names and `$Reducer` to format the values in each column. Then we transform (see `help transform -examples`) the data and filter out empty rows:

```PowerShell
$Lookup = @{
    date = 'PERIOD'
    capacity = 'FULL CHARGE CAPACITY '
}
$Reducer = {
    Param($Name, $Value)
    switch ($Name) {
        'PERIOD' {
            # Format date values
            [DateTime]($Value -split ' - ')[0]
        }
        'FULL CHARGE CAPACITY ' {
            # Format capacity values as integers
            $Value | takeWhile { $Args[0] -ne ' ' } | method ToInteger
        }
    }
}
$Data = $Raw | transform $Lookup $Reducer | ? { $_.capacity -gt 0 }
```

We can now fit a line to the data:

```PowerShell
# UNDER CONSTRUCTION
```

Finally, we can figure out when the line crosses zero to determine when our laptop will die:

```PowerShell
# UNDER CONSTRUCTION
```

**Full Script**
```PowerShell

```


Example #3
----------
> UNDER CONSTRUCTION

Example #4
----------
> UNDER CONSTRUCTION

Example #5
----------
> UNDER CONSTRUCTION

Example #6
----------
> UNDER CONSTRUCTION
