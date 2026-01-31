& (Join-Path $PSScriptRoot '_setup.ps1') 'web'

$HtmlFileSupported = try {
    New-Object -ComObject 'HTMLFile'
    $True
} catch {
    $False
}

Describe 'Add-Metadata' -Tag 'Local', 'Remote', 'WindowsOnly' {
    It 'can add metadata to an unstructured string' {
        $Text = '[25 12 2022] On 25 Dec 2021, I changed my email listed on my website, https://resume.jasonwohlgemuth.com, from FOO.BAR@baz.com to foo@bar.com.'
        $Result = '[<time datetime="2022-12-25T00:00:00.000Z">25 12 2022</time>] On <time datetime="2021-12-25T00:00:00.000Z">25 Dec 2021</time>, I changed my email listed on my website, <a href="https://resume.jasonwohlgemuth.com">https://resume.jasonwohlgemuth.com</a>, from <a href="mailto:FOO.BAR@baz.com">FOO.BAR@baz.com</a> to <a href="mailto:foo@bar.com">foo@bar.com</a>.'
        $Text | Add-Metadata | Should -Be $Result
        $Text = 'email = foo@BAR.com; url = https://google.com; date = 8 30 2021;'
        $Text | Add-Metadata -Disable 'email' | Should -Be 'email = foo@BAR.com; url = <a href="https://google.com">https://google.com</a>; date = 8 30 2021;'
        $Text | Add-Metadata -Disable 'date' | Should -Be 'email = <a href="mailto:foo@BAR.com">foo@BAR.com</a>; url = <a href="https://google.com">https://google.com</a>; date = 8 30 2021;'
        $Text | Add-Metadata -Disable 'email' | Should -Be 'email = foo@BAR.com; url = <a href="https://google.com">https://google.com</a>; date = 8 30 2021;'
        $Text = 'The quick brown fox jumped over the gate'
        $Text | Add-Metadata -Keyword 'fox' | Should -Be 'The quick brown <span class="keyword" data-keyword="fox">fox</span> jumped over the gate'
        $Text | Add-Metadata -Keyword 'jump.{2}' | Should -Be 'The quick brown fox <span class="keyword" data-keyword="jumped">jumped</span> over the gate'
        $Text | Add-Metadata -Keyword '[tT]he', 'fox' | Should -Be '<span class="keyword" data-keyword="The">The</span> quick brown <span class="keyword" data-keyword="fox">fox</span> jumped over <span class="keyword" data-keyword="the">the</span> gate'
        $Text = 'email = foo@BAR.com; url = 192.168.1.157; date = 7 September 2021;'
        $Text | Add-Metadata -Disable 'email' | Should -Be 'email = foo@BAR.com; url = <a class="ip" href="192.168.1.157">192.168.1.157</a>; date = <time datetime="2021-09-07T00:00:00.000Z">7 September 2021</time>;'
        $Text | Add-Metadata -Disable 'all' | Should -Be $Text
    }
    It 'can add metadata to unstructured string that contains the duration, <Value>' -TestCases @(
        @{ Value = '1230Z - 1345'; Zulu = $True }
        @{ Value = '1230 - 1345Z'; Zulu = $True }
        @{ Value = '1230Z - 1345Z'; Zulu = $True }
        @{ Value = '1230Z- 1345Z'; Zulu = $True }
        @{ Value = '1230Z -1345Z'; Zulu = $True }
        @{ Value = '1230 - 1345'; Zulu = $False }
    ) {
        $Text = "The event will last ${Value}."
        $Text | Add-Metadata -Disable 'duration' | Should -Be $Text
        if ($Zulu) {
            $Text | Add-Metadata | Should -Be 'The event will last <span class="duration" data-timezone="Zulu"><time datetime="1230">1230</time> - <time datetime="1345">1345</time></span>.'
            $Text | Add-Metadata -Microformat | Should -Be 'The event will last <span itemscope itemprop="event" itemtype="https://schema.org/Event" class="duration dt-event" data-timezone="Zulu"><time itemscope itemprop="startTime" itemtype="https://schema.org/Time" class="dt-start" datetime="1230">1230</time> - <time itemscope itemprop="endTime" itemtype="https://schema.org/Time" class="dt-end" datetime="1345">1345</time></span>.'
        } else {
            $Text | Add-Metadata | Should -Be 'The event will last <span class="duration"><time datetime="1230">1230</time> - <time datetime="1345">1345</time></span>.'
            $Text | Add-Metadata -Microformat | Should -Be 'The event will last <span itemscope itemprop="event" itemtype="https://schema.org/Event" class="duration dt-event"><time itemscope itemprop="startTime" itemtype="https://schema.org/Time" class="dt-start" datetime="1230">1230</time> - <time itemscope itemprop="endTime" itemtype="https://schema.org/Time" class="dt-end" datetime="1345">1345</time></span>.'
        }
    }
    It 'can add metadata to an unstructured text file' {
        $Text = Get-Content (Join-Path $PSScriptRoot '\fixtures\NAV21181.txt') -Raw
        $Text | Add-Metadata | Should -Match '<a href="mailto:JAKE.T.WADSLEY.MIL@US.NAVY.MIL">JAKE.T.WADSLEY.MIL@US.NAVY.MIL</a>'
    }
    It 'can add abbreviations from a passed hashtable' {
        $Text = 'Welcome to the USN!'
        $Data = @{
            'United States Navy' = '(u|U)SN'
        }
        $Text | Add-Metadata -Abbreviations $Data | Should -Be 'Welcome to the <abbr title="United States Navy">USN</abbr>!'
        $Text | Add-Metadata -Keyword 'Welcome' -Abbreviations $Data | Should -Be '<span class="keyword" data-keyword="Welcome">Welcome</span> to the <abbr title="United States Navy">USN</abbr>!'
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
Describe 'ConvertFrom-EpochDate' -Tag 'Local', 'Remote' {
    It 'can convert an epoch date (in seconds) to a datetime' {
        $Epoch = '1577836800'
        $Expected = [DateTime]'1/1/20'
        $Epoch | ConvertFrom-EpochDate | Should -Be $Expected
        ConvertFrom-EpochDate $Epoch | Should -Be $Expected
        $Expected = '1/1/20'
        $Epoch | ConvertFrom-EpochDate -AsString | Should -Be $Expected
        ConvertFrom-EpochDate -Value $Epoch -AsString | Should -Be $Expected
    }
    It 'can convert an epoch date (in milliseconds) to a datetime' {
        $Epoch = '1577836800000'
        $Expected = '1/1/20'
        $Epoch | ConvertFrom-EpochDate -Milliseconds -AsString | Should -Be $Expected
        ConvertFrom-EpochDate -Value $Epoch -Milliseconds -AsString | Should -Be $Expected
    }
    It 'can convert an epoch date (in microseconds) to a datetime' {
        $Epoch = '1577836800000000'
        $Expected = '1/1/20'
        $Epoch | ConvertFrom-EpochDate -AsString -Microseconds | Should -Be $Expected
        ConvertFrom-EpochDate -Value $Epoch -Microseconds -AsString | Should -Be $Expected
    }
}
Describe -Skip:(-not $HtmlFileSupported) 'ConvertFrom-Html / Import-Html' -Tag 'Local' {
    It 'can convert HTML strings' {
        $Html = '<html>
      <body>
        <a href="#">foo</a>
        <a href="#">bar</a>
        <a href="#">baz</a>
      </body>
    </html>' | ConvertFrom-Html
        $Html.all.tags('a') | ForEach-Object innerText | Should -Be 'foo', 'bar', 'baz'
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
        $Html.all.tags('a') | ForEach-Object innerText | Should -Be 'foo', 'bar', 'baz'
    }
    It 'can import more complex local HTML file' {
        $Path = Join-Path $PSScriptRoot '\fixtures\example.html'
        $Html = Import-Html -Path $Path
        $Html.title | Should -Be 'Example Webpage'
        $Html.bgColor | Should -Be '#663399' # rebeccapurple
        $Html.styleSheets[0].href | Should -Be 'style.css'
        $Html.images[0].id | Should -Be 'foobar'
        $Html.all.tags('a') | ForEach-Object innerText | Should -Be 'Kitsch 8-bit taxidermy', 'A', 'B', 'C'
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
Describe 'Get-HostsContent / Update-HostsFile' -Tag 'Local', 'Remote' {
    BeforeEach {
        $Path = Join-Path $TestDrive 'hosts'
        New-Item $Path
    }
    AfterEach {
        $Path = Join-Path $TestDrive 'hosts'
        Remove-Item $Path
    }
    It 'can get content of hosts file from path' {
        $Hostnames = 'foo', 'bar', 'foo.bar.baz', 'foo bar baz', 'foo.bar.baz', 'foo bar baz'
        $Adresses = '192.168.0.111', '127.0.0.1', '192.168.0.2', '192.168.0.3', '192.168.0.4', '192.168.0.5'
        $Comments = '', 'some random comment', '', '', 'some comment', 'some other comment'
        $Content = Get-HostsContent (Join-Path $PSScriptRoot 'fixtures/hosts')
        $Content.Count | Should -Be 6
        $Content | ForEach-Object Hostname | Should -Be $Hostnames
        $Content | ForEach-Object IPAddress | Should -Be $Adresses
        $Content | ForEach-Object Comment | Should -Be $Comments
        $Content = (Join-Path $PSScriptRoot 'fixtures/hosts') | Get-HostsContent
        $Content.Count | Should -Be 6
        $Content | ForEach-Object Hostname | Should -Be $Hostnames
        $Content | ForEach-Object IPAddress | Should -Be $Adresses
        $Content | ForEach-Object Comment | Should -Be $Comments
    }
    It 'can add an entry to a hosts file' {
        $A = @{
            Hostname = 'home'
            IPAddress = '127.0.0.1'
        }
        $B = @{
            Hostname = 'foo'
            IPAddress = '127.0.0.2'
            Comment = 'bar'
        }
        $NewIpAddress = '127.0.0.42'
        $NewComment = 'this is an updated comment'
        $Updated = $A.Clone(), @{ IPAddress = $NewIpAddress; Comment = $NewComment } | Invoke-ObjectMerge -Force
        Update-HostsFile @A -Path $Path
        $Content = Get-HostsContent $Path
        $Content.LineNumber | Should -Be 1
        $Content.IPAddress | Should -Be $A.IPAddress
        $Content.IsValidIP | Should -Be $True
        $Content.Hostname | Should -Be $A.Hostname
        $Content.Comment | Should -Be ''
        Update-HostsFile @B -Path $Path
        $Content = Get-HostsContent $Path
        $Content[0].LineNumber | Should -Be 1
        $Content[0].IPAddress | Should -Be $A.IPAddress
        $Content[0].IsValidIP | Should -Be $True
        $Content[0].Hostname | Should -Be $A.Hostname
        $Content[0].Comment | Should -Be ''
        $Content[1].LineNumber | Should -Be 3
        $Content[1].IPAddress | Should -Be $B.IPAddress
        $Content[1].IsValidIP | Should -Be $True
        $Content[1].Hostname | Should -Be $B.Hostname
        $Content[1].Comment | Should -Be $B.Comment
        Update-HostsFile @Updated -Path $Path
        $Content = Get-HostsContent $Path
        $Content[0].LineNumber | Should -Be 1
        $Content[0].IPAddress | Should -Be $NewIpAddress
        $Content[0].IsValidIP | Should -Be $True
        $Content[0].Hostname | Should -Be $A.Hostname
        $Content[0].Comment | Should -Be $NewComment
        $Content[1].LineNumber | Should -Be 3
        $Content[1].IPAddress | Should -Be $B.IPAddress
        $Content[1].IsValidIP | Should -Be $True
        $Content[1].Hostname | Should -Be $B.Hostname
        $Content[1].Comment | Should -Be $B.Comment
        $Content = Update-HostsFile @B -Path $Path -PassThru
        $Content[0].LineNumber | Should -Be 1
        $Content[0].IPAddress | Should -Be $NewIpAddress
        $Content[0].IsValidIP | Should -Be $True
        $Content[0].Hostname | Should -Be $A.Hostname
        $Content[0].Comment | Should -Be $NewComment
        $Content[1].LineNumber | Should -Be 3
        $Content[1].IPAddress | Should -Be $B.IPAddress
        $Content[1].IsValidIP | Should -Be $True
        $Content[1].Hostname | Should -Be $B.Hostname
        $Content[1].Comment | Should -Be $B.Comment
    }
    It 'can add multi-name item to hosts file' {
        $NoComment = @{
            Hostname = 'foo bar baz'
            IPAddress = '127.0.0.1'
        }
        $WithComment = @{
            Hostname = 'dev cdn web-client'
            IPAddress = '127.0.0.2'
            Comment = 'no place like it'
        }
        Update-HostsFile @NoComment -Path $Path
        $Content = Get-HostsContent $Path
        $Content.LineNumber | Should -Be 1
        $Content.IPAddress | Should -Be $NoComment.IPAddress
        $Content.IsValidIP | Should -Be $True
        $Content.Hostname | Should -Be $NoComment.Hostname
        $Content.Comment | Should -Be ''
        Update-HostsFile @WithComment -Path $Path
        $Content = (Get-HostsContent $Path)[1]
        $Content.LineNumber | Should -Be 3
        $Content.IPAddress | Should -Be $WithComment.IPAddress
        $Content.IsValidIP | Should -Be $True
        $Content.Hostname | Should -Be $WithComment.Hostname
        $Content.Comment | Should -Be $WithComment.Comment
    }
    It 'supports WhatIf parameter' {
        Mock Write-Color {} -ModuleName 'Prelude'
        $A = @{
            Hostname = 'home'
            IPAddress = '127.0.0.1'
        }
        $B = @{
            Hostname = 'home'
            IPAddress = '192.168.1.1'
        }
        $C = @{
            Hostname = 'foo'
            IPAddress = '127.0.0.2'
            Comment = 'bar'
        }
        Update-HostsFile @A -Path $Path
        { Update-HostsFile @B -Path $Path -WhatIf | Out-Null } | Should -Not -Throw
        { Update-HostsFile @C -Path $Path -WhatIf | Out-Null } | Should -Not -Throw
    }
}
Describe -Skip:(-not $HtmlFileSupported) 'Get-HtmlElement' -Tag 'Local' {
    It 'can get elements from HTML string' {
        $Html = '<html><div id="foo">foo</div><div class="foo">bar</div></html>'
        ($Html | Get-HtmlElement 'div').innerText | Should -Be 'foo', 'bar'
        ($Html | Get-HtmlElement '#foo').innerText | Should -Be 'foo'
        ($Html | Get-HtmlElement '.foo').innerText | Should -Be 'bar'
    }
    It 'can get elements from HTML object' {
        $Html = '<html><div id="foo">foo</div><div class="foo">bar</div></html>' | ConvertFrom-Html
        ($Html | Get-HtmlElement 'div').innerText | Should -Be 'foo', 'bar'
        ($Html | Get-HtmlElement '#foo').innerText | Should -Be 'foo'
        ($Html | Get-HtmlElement '.foo').innerText | Should -Be 'bar'
    }
}
Describe 'Invoke-WebRequestBasicAuth' -Tag 'Local', 'Remote', 'WindowsOnly' {
    It 'will not do anything when passed -WhatIf' {
        Mock Write-Color {} -ModuleName 'Prelude'
        $Uri = 'https://example.com/'
        Invoke-WebRequestBasicAuth $Uri -ParseContent -WhatIf
        Should -Invoke Write-Color -Exactly 3 -ModuleName 'Prelude'
    }
    It 'can make a simple request' {
        Mock Invoke-WebRequest { $Args } -ModuleName 'Prelude'
        $Token = 'token'
        $Uri = 'https://example.com/'
        $Request = Invoke-WebRequestBasicAuth $Uri -Token $Token
        $Values = $Request | Sort-Object
        $Values | Where-Object { $_ -is [Hashtable] } | ForEach-Object { $_.Authorization | Should -Be "Bearer $Token" }
        $Values | Should -Contain 'Get'
        $Values | Should -Contain $Uri
        $Request = Invoke-WebRequestBasicAuth -Uri $Uri -Token $Token
        $Values = $Request | Sort-Object
        $Values | Where-Object { $_ -is [Hashtable] } | ForEach-Object { $_.Authorization | Should -Be "Bearer $Token" }
        $Values | Should -Contain 'Get'
        $Values | Should -Contain $Uri
    }
    It 'can make a simple request with a username and password' {
        Mock Invoke-WebRequest { $Args } -ModuleName 'Prelude'
        $Username = 'user'
        $Token = 'token'
        $Uri = 'https://example.com/'
        $Request = Invoke-WebRequestBasicAuth $Uri -Username $Username -Password $Token -DisableSession
        $Values = $Request | Sort-Object
        $Values | Where-Object { $_ -is [Hashtable] } | ForEach-Object { $_.Authorization | Should -Be 'Basic dXNlcjp0b2tlbg==' }
        $Values | Should -Contain 'Get'
        $Values | Should -Contain $Uri
    }
    It 'can make a simple request with query parameters' {
        Mock Invoke-WebRequest { $Args } -ModuleName 'Prelude'
        $Token = 'token'
        $Uri = 'https://example.com/'
        $Query = @{ foo = 'bar' }
        $Request = Invoke-WebRequestBasicAuth -Uri $Uri -Token $Token -Query $Query -DisableSession
        $Values = $Request | Sort-Object
        $Values | Where-Object { $_ -is [Hashtable] } | ForEach-Object { $_.Authorization | Should -Be "Bearer $Token" }
        $Values | Should -Contain 'Get'
        $Values | Should -Contain "${Uri}?foo=bar"
    }
    It 'can make a simple request with URL-encoded query parameters' {
        Mock Invoke-WebRequest { $Args } -ModuleName 'Prelude'
        $Token = 'token'
        $Uri = 'https://example.com/'
        $Query = @{ answer = 42 }
        $Request = Invoke-WebRequestBasicAuth -Uri $Uri -Token $Token -Query $Query -UrlEncode -DisableSession
        $Values = $Request | Sort-Object
        $Values | Where-Object { $_ -is [Hashtable] } | ForEach-Object { $_.Authorization | Should -Be "Bearer $Token" }
        $Values | Should -Contain 'Get'
        $Values | Where-Object { $_ -match $Uri } | Should -Match "$Uri\?answer(=|%3d)42$"
    }
    It 'can make a simple PUT request' {
        Mock Invoke-WebRequest { $Args } -ModuleName 'Prelude'
        $Token = 'token'
        $Uri = 'https://example.com/'
        $Data = @{ answer = 42 }
        $Request = Invoke-WebRequestBasicAuth -Uri $Uri -Token $Token -Put -Data $Data -DisableSession
        $Values = $Request | Sort-Object
        $Values | Where-Object { $_ -is [Hashtable] } | ForEach-Object { $_.Authorization | Should -Be "Bearer $Token" }
        $Values | Should -Contain 'Put'
        $Values | Should -Contain $Uri
        $Values | Should -Contain (ConvertTo-Json $Data)
    }
    It 'can parse HTML (<Type>) content' -TestCases @(
        @{ Type = 'text/html' },
        @{ Type = 'text/html; charset=UTF-8' },
        @{ Type = 'application/xhtml+xml' }
    ) {
        $Uri = 'https://example.com/'
        $Content = '<html><a href="#">Foo</a><a href="#">Bar</a></html>'
        $Response = @{
            Headers = @{
                'Content-Type' = $Type
            }
            Content = $Content
        }
        Mock Invoke-WebRequest { $Response } -ModuleName 'Prelude'
        $Result = Invoke-WebRequestBasicAuth $Uri -ParseContent
        $Result.links | Get-Property 'innerHTML' | Should -Be 'Foo', 'Bar'
    }
    It 'can parse JSON (<Type>) content' -TestCases @(
        @{ Type = 'application/json' },
        @{ Type = 'application/json; charset=UTF-8' }
    ) {
        $Uri = 'https://example.com/'
        $Content = '{"foo": "bar"}'
        $Response = @{
            Headers = @{
                'Content-Type' = $Type
            }
            Content = $Content
        }
        Mock Invoke-WebRequest { $Response } -ModuleName 'Prelude'
        $Result = Invoke-WebRequestBasicAuth $Uri -ParseContent
        $Result.foo | Should -Be 'bar'
    }
    It 'can parse CSV (<Type>) content' -TestCases @(
        @{ Type = 'text/csv' },
        @{ Type = 'text/csv; charset=UTF-8' }
    ) {
        $Uri = 'https://example.com/'
        $Content = "name, level`nGoku, 9001"
        $Response = @{
            Headers = @{
                'Content-Type' = $Type
            }
            Content = $Content
        }
        Mock Invoke-WebRequest { $Response } -ModuleName 'Prelude'
        $Result = Invoke-WebRequestBasicAuth $Uri -ParseContent
        $Result.name | Should -Be 'Goku'
    }
    It 'will not parse <Type> content' -TestCases @(
        @{ Type = 'text/plain' },
        @{ Type = 'text/css' },
        @{ Type = 'text/javascript' },
        @{ Type = 'audio/webm' },
        @{ Type = 'image/png' },
        @{ Type = 'video/javascript' },
        @{ Type = 'model/vrml' }
    ) {
        Mock Write-Verbose { } -ModuleName 'Prelude'
        $Uri = 'https://example.com/'
        $Content = 'This will not be parsed'
        $Response = @{
            Headers = @{
                'Content-Type' = $Type
            }
            Content = $Content
        }
        Mock Invoke-WebRequest { $Response } -ModuleName 'Prelude'
        $Result = Invoke-WebRequestBasicAuth $Uri -ParseContent
        $Result | Should -Be $Content
        Should -Invoke Write-Verbose -Exactly 3 -ModuleName 'Prelude'
    }
    It 'will not parse content with unknown content-type, <Type>' -TestCases @(
        @{ Type = 'not real content-type' }
    ) {
        Mock Write-Warning { } -ModuleName 'Prelude'
        $Uri = 'https://example.com/'
        $Content = 'This will not be parsed'
        $Response = @{
            Headers = @{
                'Content-Type' = $Type
            }
            Content = $Content
        }
        Mock Invoke-WebRequest { $Response } -ModuleName 'Prelude'
        $Result = Invoke-WebRequestBasicAuth $Uri -ParseContent
        $Result | Should -Be $Content
        Should -Invoke Write-Warning -Exactly 1 -ModuleName 'Prelude'
    }
    It 'can download web assets' {
        Mock Invoke-WebRequest { $Args } -ModuleName 'Prelude'
        $File = 'thing.png'
        $Uri = "https://example.com/${File}"
        $Request = Invoke-WebRequestBasicAuth $Uri -Download -Folder $TestDrive
        $Index = $Request | Find-FirstIndex -Predicate { Param($X) $X -eq '-Uri:' }
        $Request[$Index + 1] | Should -Be $Uri
        $Index = $Request | Find-FirstIndex -Predicate { Param($X) $X -eq '-OutFile:' }
        $Request[$Index + 1] | Should -Be (Join-Path $TestDrive $File)
        $Index = $Request | Find-FirstIndex -Predicate { Param($X) $X -eq '-Method:' }
        $Request[$Index + 1] | Should -Be 'Get'
    }
}
Describe 'Save-File' -Tag 'Local', 'Remote', 'WindowsOnly' {
    BeforeAll {
        Set-Location $TestDrive
    }
    AfterAll {
        Set-Location $PSScriptRoot
    }
    It 'can save a file from a remote web address (with BitsTransfer)' {
        Get-ChildItem $TestDrive -File | Remove-Item
        Mock Start-BitsTransfer {}
        $Uri = 'https://example.com/'
        $File = 'a.txt'
        $Uri | Save-File $File
        (Get-ChildItem $TestDrive).Name | Should -Be $File
        $Uri | Save-File $File
        (Get-ChildItem $TestDrive).Name | Should -HaveCount 2
    }
    It 'can save a file from a remote web address (with .NET Web Client)' {
        Get-ChildItem $TestDrive -File | Remove-Item
        $Uri = 'https://example.com/'
        $File = 'a.txt'
        $Uri | Save-File $File -WebClient
        (Get-ChildItem $TestDrive).Name | Should -Be $File
        $Uri | Save-File $File -WebClient
        (Get-ChildItem $TestDrive).Name | Should -HaveCount 2
    }
    It 'can save files from a remote web address' {
        Get-ChildItem $TestDrive -File | Remove-Item
        Mock Start-BitsTransfer { $Args }
        $Uri = 'https://example.com'
        $Names = 'foo.txt', 'bar.txt', 'baz.txt'
        $Job = $Uri, $Uri, $Uri | Save-File $Names
        $Job | Write-Color -Cyan
        (Get-ChildItem $TestDrive).Name | Sort-Object | Should -Be 'bar.txt', 'baz.txt', 'foo.txt'
    }
    It 'can asynchronously save a file from a remote web address' {
        Get-ChildItem $TestDrive -File | Remove-Item
        $Uri = 'https://example.com/'
        $File = 'b.txt'
        $Job = $Uri | Save-File $File -Asynchronous -PassThru
        $Job.DisplayName | Should -Be 'PreludeBitsJob'
    }
    It -Skip 'can asynchronously save multiple files from a remote web address' {
        Get-ChildItem $TestDrive -File | Remove-Item
        $DisplayName = 'PreludeBitsJob'
        $Uri = 'https://example.com'
        $Names = 'foo.txt', 'bar.txt', 'baz.txt'
        $Job = $Uri, $Uri, $Uri | Save-File $Names -Asynchronous -PassThru
        $Job.DisplayName | Should -Be @($DisplayName, $DisplayName, $DisplayName)
    }
}
Describe 'Test-Url' -Tag 'Local', 'Remote' {
    It 'can test if google is accessible' {
        'google.com', 'https://google.com', 'https://www.google.com' | Test-Url | Should -Be $True, $True, $True
        'google.com', 'https://google.com', 'https://www.google.com' | Test-Url -Code | Should -Be '200', '200', '200'
    }
    It 'will return 404 if URL does not exist' {
        'https://ifthisSiteEverExistsIwillQuitTheInter.net' | Test-Url | Should -Be $False
        'https://ifthisSiteEverExistsIwillQuitTheInter.net' | Test-Url -Code | Should -Be '404'
    }
}
Describe 'Use-Web' -Tag 'Local', 'Remote', 'WindowsOnly' {
    It 'can load web browser types' {
        Use-Web -Browser | Should -BeNullOrEmpty
        Use-Web -Browser -PassThru | Should -BeTrue
    }
}