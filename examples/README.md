Examples
========

1. [Use GitHub API to retrieve notifications](#example1)
1. [Fit data with linear model using matrices](#example2)
1. [Perform Markov transition matrix calculations](#example3)
1. [Solve system of linear equations](#example4)
1. [Calculate eccentricity of earth using classical method](#example5)
1. [Analyze Pandemic game play using graph theory](#example6)

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
> Fit data with linear model using matrices

👷‍♂️ ***UNDER CONSTRUCTION***

------

Example #3
----------
> Calculate probabilities using Markov transition matrices

👷‍♂️ ***UNDER CONSTRUCTION***

------

Example #4
----------
> Solve a system of linear equations

👷‍♂️ ***UNDER CONSTRUCTION***

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
