& (Join-Path $PSScriptRoot '_setup.ps1') 'web'

$HtmlFileSupported = try {
    New-Object -ComObject 'HTMLFile'
    $True
} catch {
    $False
}

Describe 'Add-Metadata' -Tag 'Local', 'Remote' {
    It 'can convert an unstructured string to HTML' {
        $Text = '[25 12 2022] On 25 Dec 2021, I changed my email listed on my website, https://resume.jasonwohlgemuth.com, from FOO.BAR@baz.com to foo@bar.com.'
        $Text | Add-Metadata | Write-Color -Cyan
        # $Data = Get-Content (Join-Path $PSScriptRoot '\fixtures\NAV21181.txt') -Raw | Add-Metadata
        # $Data | Write-Color -Yellow
    }
}
Describe 'ConvertFrom-ByteArray' -Tag 'Local', 'Remote' {
    It 'can convert an array of bytes to text' {
        $Expected = 'hello world'
        $Bytes = [System.Text.Encoding]::Unicode.GetBytes($Expected)
        $Bytes | ConvertFrom-ByteArray | Should -Be $Expected
        ConvertFrom-ByteArray -Data $Bytes | Should -Be $Expected
    }
    It 'can provide pass-thru for string values' {
        $Expected = 'hello world'
        $Expected | ConvertFrom-ByteArray | Should -Be $Expected
        ConvertFrom-ByteArray -Data $Expected | Should -Be $Expected
    }
}
Describe -Skip:(-not $HtmlFileSupported) 'ConvertFrom-Html / Import-Html' -Tag 'Local', 'Remote' {
    It 'can convert HTML strings' {
        $Html = '<html>
      <body>
        <a href="#">foo</a>
        <a href="#">bar</a>
        <a href="#">baz</a>
      </body>
    </html>' | ConvertFrom-Html
        $Html.all.tags('a') | ForEach-Object textContent | Should -Be 'foo', 'bar', 'baz'
    }
    It 'can import local HTML file' {
        $Path = Join-Path $TestDrive 'foo.html'
        '<html>
      <body>
        <a href="#">foo</a>
        <a href="#">bar</a>
        <a href="#">baz</a>
      </body>
    </html>' | Out-File $Path
        $Html = Import-Html -Path $Path
        $Html.all.tags('a') | ForEach-Object textContent | Should -Be 'foo', 'bar', 'baz'
    }
    It 'can import more complex local HTML file' {
        $Path = Join-Path $PSScriptRoot '\fixtures\example.html'
        $Html = Import-Html -Path $Path
        $Html.title | Should -Be 'Example Webpage'
        $Html.bgColor | Should -Be '#663399' # rebeccapurple
        $Html.styleSheets[0].href | Should -Be 'style.css'
        $Html.images[0].id | Should -Be 'foobar'
        $Html.all.tags('a') | ForEach-Object textContent | Should -Be 'Kitsch 8-bit taxidermy', 'A', 'B', 'C'
        $Html.all.tags('meta') | ForEach-Object name | Should -Contain 'description'
        $Html.all.tags('meta') | ForEach-Object name | Should -Contain 'keywords'
    }
}
Describe 'ConvertFrom-QueryString' -Tag 'Local', 'Remote' {
    It 'can parse single-value inputs as strings' {
        $Expected = 'hello world'
        $Expected | ConvertFrom-QueryString | Should -Be $Expected
        'foo', 'bar', 'baz' | ConvertFrom-QueryString | Should -Be 'foo', 'bar', 'baz'
    }
    It 'can parse complex query strings as objects' {
        $DeviceCode = 'ac921e83b6d04d0709a627f4ede70dee1f86204f'
        $UserCode = '7B7F-4F10'
        $InputString = "device_code=${DeviceCode}&expires_in=8999&interval=5&user_code=${UserCode}&verification_uri=https%3A%2F%2Fgithub.com%2Flogin%2Fdevice"
        $Result = $InputString | ConvertFrom-QueryString
        $Result['device_code'] | Should -Be $DeviceCode
        $Result['expires_in'] | Should -Be '8999'
        $Result['user_code'] | Should -Be $UserCode
    }
    It 'can easily be chained with other conversions' {
        $Result = [System.Text.Encoding]::Unicode.GetBytes('first=1&second=2&third=last') |
            ConvertFrom-ByteArray |
            ConvertFrom-QueryString
        $Result.Keys | Sort-Object | Should -Be 'first', 'second', 'third'
        $Result.Values | Sort-Object | Should -Be '1', '2', 'last'
    }
}
Describe 'ConvertTo-Iso8601' -Tag 'Local', 'Remote' {
    It 'can convert values to ISO-8601 format' {
        $Expected = '2020-07-04T00:00:00.000Z'
        'July 4, 2020' | ConvertTo-Iso8601 | Should -Be $Expected
        '07/04/2020' | ConvertTo-Iso8601 | Should -Be $Expected
        '04JUL20' | ConvertTo-Iso8601 | Should -Be $Expected
        '2020-07-04' | ConvertTo-Iso8601 | Should -Be $Expected
    }
}
Describe 'ConvertTo-JavaScript' -Tag 'Local', 'Remote' {
    It 'can convert coordinate types' {
        $Expected = "{latitude: 42.42, longitude: 43, height: 0, hemisphere: 'NE'}"
        $A = [Coordinate]@{ Latitude = 42.42; Longitude = 43 }
        ConvertTo-JavaScript $A | Should -Be $Expected
        $A | ConvertTo-JavaScript | Should -Be $Expected
    }
    It 'can convert matrix types' {
        $A = 1..4 | New-Matrix
        $A | ConvertTo-JavaScript | Should -Be '[[1, 2], [3, 4]]'
        $A = 1..9 | New-Matrix 3, 3
        $A | ConvertTo-JavaScript | Should -Be '[[1, 2, 3], [4, 5, 6], [7, 8, 9]]'
        $A = 1..8 | New-Matrix 2, 4
        $A | ConvertTo-JavaScript | Should -Be '[[1, 2, 3, 4], [5, 6, 7, 8]]'
    }
    It 'can convert node types' {
        $A = [Node]::New('9f0a2929-9991-4c3a-943f-de235d9fcd37', 'A')
        $B = [Node]::New('bd0da46a-511d-4c90-8a1d-3546b1693a52', 'B')
        $A | ConvertTo-JavaScript | Should -Be "{id: '9f0a2929-9991-4c3a-943f-de235d9fcd37', label: 'A'}"
        $B | ConvertTo-JavaScript | Should -Be "{id: 'bd0da46a-511d-4c90-8a1d-3546b1693a52', label: 'B'}"
        $A, $B | ConvertTo-JavaScript | Should -Be "[{id: '9f0a2929-9991-4c3a-943f-de235d9fcd37', label: 'A'}, {id: 'bd0da46a-511d-4c90-8a1d-3546b1693a52', label: 'B'}]"
        $Nodes = $A, $B
        $Nodes | ConvertTo-JavaScript | Should -Be "[{id: '9f0a2929-9991-4c3a-943f-de235d9fcd37', label: 'A'}, {id: 'bd0da46a-511d-4c90-8a1d-3546b1693a52', label: 'B'}]"
    }
    It 'can convert edge types' {
        $Expected = "{source: {id: '9f0a2929-9991-4c3a-943f-de235d9fcd37', label: 'A'}, target: {id: 'bd0da46a-511d-4c90-8a1d-3546b1693a52', label: 'B'}}"
        $A = [Node]::New('9f0a2929-9991-4c3a-943f-de235d9fcd37', 'A')
        $B = [Node]::New('bd0da46a-511d-4c90-8a1d-3546b1693a52', 'B')
        $AB = New-Edge $A $B
        $AB | ConvertTo-JavaScript | Should -Be $Expected
    }
    It 'can convert directed edge types' {
        $Expected = "{source: {id: '9f0a2929-9991-4c3a-943f-de235d9fcd37', label: 'A'}, target: {id: 'bd0da46a-511d-4c90-8a1d-3546b1693a52', label: 'B'}}"
        $A = [Node]::New('9f0a2929-9991-4c3a-943f-de235d9fcd37', 'A')
        $B = [Node]::New('bd0da46a-511d-4c90-8a1d-3546b1693a52', 'B')
        $AB = New-Edge $A $B -Directed
        $AB | ConvertTo-JavaScript | Should -Be $Expected
    }
    It 'can convert graph types' {
        $Expected = "{nodes: [{id: '9f0a2929-9991-4c3a-943f-de235d9fcd37', label: 'A'}, {id: 'bd0da46a-511d-4c90-8a1d-3546b1693a52', label: 'B'}], edges: {source: {id: '9f0a2929-9991-4c3a-943f-de235d9fcd37', label: 'A'}, target: {id: 'bd0da46a-511d-4c90-8a1d-3546b1693a52', label: 'B'}}}"
        $A = [Node]::New('9f0a2929-9991-4c3a-943f-de235d9fcd37', 'A')
        $B = [Node]::New('bd0da46a-511d-4c90-8a1d-3546b1693a52', 'B')
        $AB = New-Edge $A $B
        $G = $AB | New-Graph
        $G | ConvertTo-JavaScript | Should -Be $Expected
    }
    It 'will act like ConvertTo-Json for non-Prelude types' {
        $A = @{ a = 'one' }
        $B = @{ b = 'two' }
        ConvertTo-JavaScript $A | Should -Be '{"a":"one"}'
        $A | ConvertTo-JavaScript | Should -Be '{"a":"one"}'
        ConvertTo-JavaScript $A, $B | Should -Be '[{"a":"one"}, {"b":"two"}]'
        $A, $B | ConvertTo-JavaScript | Should -Be '[{"a":"one"}, {"b":"two"}]'
    }
}
Describe 'ConvertTo-QueryString' -Tag 'Local', 'Remote' {
    It 'can handle empty objects' {
        @{} | ConvertTo-QueryString | Should -Be ''
        @{} | ConvertTo-QueryString -UrlEncode | Should -Be ''
    }
    It 'can convert objects into URL-encoded query strings' {
        @{ foo = '' } | ConvertTo-QueryString | Should -Be 'foo='
        @{ foo = 'bar' } | ConvertTo-QueryString | Should -Be 'foo=bar'
        @{ a = 1; b = 2; c = 3 } | ConvertTo-QueryString | Should -Be 'a=1&b=2&c=3'
        @{ per_page = 100; page = 3 } | ConvertTo-QueryString | Should -Be 'page=3&per_page=100'
    }
    It 'can convert objects into query strings' {
        @{ foo = '' } | ConvertTo-QueryString -UrlEncode | Should -Be 'foo%3d'
        @{ foo = 'a' }, @{ bar = 'b' } | ConvertTo-QueryString -UrlEncode | Should -Be 'foo%3da', 'bar%3db'
        @{ foo = 'bar' } | ConvertTo-QueryString -UrlEncode | Should -Be 'foo%3dbar'
        @{ a = 1; b = 2; c = 3 } | ConvertTo-QueryString -UrlEncode | Should -Be 'a%3d1%26b%3d2%26c%3d3'
        @{ per_page = 100; page = 3 } | ConvertTo-QueryString -UrlEncode | Should -Be 'page%3d3%26per_page%3d100'
    }
}
Describe -Skip:(-not $HtmlFileSupported) 'Get-HtmlElement' -Tag 'Local', 'Remote' {
    It 'can get elements from HTML string' {
        $Html = '<html><div id="foo">foo</div><div class="foo">bar</div></html>'
        ($Html | Get-HtmlElement 'div').innerText | Should -Be 'foo', 'bar'
        ($Html | Get-HtmlElement '#foo').innerText | Should -Be 'foo'
        ($Html | Get-HtmlElement '.foo').innerText | Should -Be 'bar'
    }
    It 'can get elements from HTML string' {
        $Html = '<html><div id="foo">foo</div><div class="foo">bar</div></html>' | ConvertFrom-Html
        ($Html | Get-HtmlElement 'div').innerText | Should -Be 'foo', 'bar'
        ($Html | Get-HtmlElement '#foo').innerText | Should -Be 'foo'
        ($Html | Get-HtmlElement '.foo').innerText | Should -Be 'bar'
    }
}
Describe 'Invoke-WebRequestBasicAuth' -Tag 'Local', 'Remote', 'WindowsOnly' {
    It 'can make a simple request' {
        Mock Invoke-WebRequest { $Args } -ModuleName 'Prelude'
        $Token = 'token'
        $Uri = 'https://example.com/'
        $Request = Invoke-WebRequestBasicAuth $Token -Uri $Uri
        $Values = $Request[1, 3, 5] | Sort-Object
        $Values | Where-Object { $_ -is [Hashtable] } | ForEach-Object { $_.Authorization | Should -Be "Bearer $Token" }
        $Values | Should -Contain 'Get'
        $Values | Should -Contain $Uri
    }
    It 'can make a simple request with a username and password' {
        Mock Invoke-WebRequest { $Args } -ModuleName 'Prelude'
        $Username = 'user'
        $Token = 'token'
        $Uri = 'https://example.com/'
        $Request = Invoke-WebRequestBasicAuth $Username -Password $Token -Uri $Uri
        $Values = $Request[1, 3, 5] | Sort-Object
        $Values | Where-Object { $_ -is [Hashtable] } | ForEach-Object { $_.Authorization | Should -Be 'Basic dXNlcjp0b2tlbg==' }
        $Values | Should -Contain 'Get'
        $Values | Should -Contain $Uri
    }
    It 'can make a simple request with query parameters' {
        Mock Invoke-WebRequest { $Args } -ModuleName 'Prelude'
        $Token = 'token'
        $Uri = 'https://example.com/'
        $Query = @{ foo = 'bar' }
        $Request = Invoke-WebRequestBasicAuth $Token -Uri $Uri -Query $Query
        $Values = $Request[1, 3, 5] | Sort-Object
        $Values | Where-Object { $_ -is [Hashtable] } | ForEach-Object { $_.Authorization | Should -Be "Bearer $Token" }
        $Values | Should -Contain 'Get'
        $Values | Should -Contain "${Uri}?foo=bar"
    }
    It 'can make a simple request with URL-encoded query parameters' {
        Mock Invoke-WebRequest { $Args } -ModuleName 'Prelude'
        $Token = 'token'
        $Uri = 'https://example.com/'
        $Query = @{ answer = 42 }
        $Request = Invoke-WebRequestBasicAuth $Token -Uri $Uri -Query $Query -UrlEncode
        $Values = $Request[1, 3, 5] | Sort-Object
        $Values | Where-Object { $_ -is [Hashtable] } | ForEach-Object { $_.Authorization | Should -Be "Bearer $Token" }
        $Values | Should -Contain 'Get'
        $Values | Where-Object { $_ -match $Uri } | Should -Match "$Uri\?answer(=|%3d)42$"
    }
    It 'can make a simple PUT request' {
        Mock Invoke-WebRequest { $Args } -ModuleName 'Prelude'
        $Token = 'token'
        $Uri = 'https://example.com/'
        $Data = @{ answer = 42 }
        $Request = Invoke-WebRequestBasicAuth $Token -Put -Uri $Uri -Data $Data
        $Values = $Request[1, 3, 5, 7] | Sort-Object
        $Values | Where-Object { $_ -is [Hashtable] } | ForEach-Object { $_.Authorization | Should -Be "Bearer $Token" }
        $Values | Should -Contain 'Put'
        $Values | Should -Contain $Uri
        $Values | Should -Contain (ConvertTo-Json $Data)
    }
}
Describe 'Test-Url' -Tag 'Local', 'Remote' {
    It 'can test if google is accessible' {
        'google.com', 'https://google.com', 'https://www.google.com' | Test-Url | Should -Be $True, $True, $True
        'google.com', 'https://google.com', 'https://www.google.com' | Test-Url -Code | Should -Be '200', '200', '200'
    }
    It 'will return 404 if URL does not exist' {
        'https://ifhtisSiteEverExistsIwillQuitTheInter.net' | Test-Url | Should -Be $False
        'https://ifhtisSiteEverExistsIwillQuitTheInter.net' | Test-Url -Code | Should -Be '404'
    }
}