& (Join-Path $PSScriptRoot '_setup.ps1') 'web'

Describe 'ConvertFrom-ByteArray' {
    it 'can convert an array of bytes to text' {
        $Expected = 'hello world'
        $Bytes = [System.Text.Encoding]::Unicode.GetBytes($Expected)
        $Bytes | ConvertFrom-ByteArray | Should -Be $Expected
        ConvertFrom-ByteArray -Data $Bytes | Should -Be $Expected
    }
    it 'can provide pass-thru for string values' {
        $Expected = 'hello world'
        $Expected | ConvertFrom-ByteArray | Should -Be $Expected
        ConvertFrom-ByteArray -Data $Expected | Should -Be $Expected
    }
}
Describe 'ConvertFrom-Html / Import-Html' {
    It 'can convert HTML strings' {
        try {
            $Supported = New-Object -ComObject "HTMLFile"
        } catch {
            $Supported = $null
        }
        if ($null -ne $Supported) {
            $Html = '<html>
                <body>
                    <a href="#">foo</a>
                    <a href="#">bar</a>
                    <a href="#">baz</a>
                </body>
            </html>' | ConvertFrom-Html
            $Html.all.tags('a') | ForEach-Object textContent | Should -Be 'foo','bar','baz'
        }
    }
    It 'can import local HTML file' {
        try {
            $Supported = New-Object -ComObject "HTMLFile"
        } catch {
            $Supported = $null
        }
        if ($null -ne $Supported) {
            $Path = Join-Path $TestDrive 'foo.html'
            '<html>
                <body>
                    <a href="#">foo</a>
                    <a href="#">bar</a>
                    <a href="#">baz</a>
                </body>
            </html>' | Out-File $Path
            $Html = Import-Html -Path $Path
            $Html.all.tags('a') | ForEach-Object textContent | Should -Be 'foo','bar','baz'
        }
    }
}
Describe 'ConvertTo-Iso8601' {
    It 'can convert values to ISO-8601 format' {
        $Expected = '2020-07-04T00:00:00.000Z'
        'July 4, 2020' | ConvertTo-Iso8601 | Should -Be $Expected
        '07/04/2020' | ConvertTo-Iso8601 | Should -Be $Expected
        '04JUL20' | ConvertTo-Iso8601 | Should -Be $Expected
        '2020-07-04' | ConvertTo-Iso8601 | Should -Be $Expected
    }
}
Describe 'ConvertTo-QueryString' {
    It 'can convert objects into URL-encoded query strings' {
        @{} | ConvertTo-QueryString | Should -Be ''
        @{ foo = '' } | ConvertTo-QueryString | Should -Be 'foo='
        @{ foo = 'bar' } | ConvertTo-QueryString | Should -Be 'foo=bar'
        @{ a = 1; b = 2; c = 3 } | ConvertTo-QueryString | Should -Be 'a=1&b=2&c=3'
        @{ per_page = 100; page = 3 } | ConvertTo-QueryString  | Should -Be 'page=3&per_page=100'
    }
    It 'can convert objects into query strings' {
        @{} | ConvertTo-QueryString -UrlEncode | Should -Be ''
        @{ foo = '' } | ConvertTo-QueryString -UrlEncode | Should -Be 'foo%3d'
        @{ foo = 'a' },@{ bar = 'b'} | ConvertTo-QueryString -UrlEncode | Should -Be 'foo%3da','bar%3db'
        @{ foo = 'bar' } | ConvertTo-QueryString -UrlEncode | Should -Be 'foo%3dbar'
        @{ a = 1; b = 2; c = 3 } | ConvertTo-QueryString -UrlEncode | Should -Be 'a%3d1%26b%3d2%26c%3d3'
        @{ per_page = 100; page = 3 } | ConvertTo-QueryString -UrlEncode | Should -Be 'page%3d3%26per_page%3d100'
    }
}
InModuleScope pwsh-prelude {
    Describe 'Invoke-WebRequestBasicAuth' {
        It 'can make a simple request' {
            Mock Invoke-WebRequest { $args }
            $Token = 'token'
            $Uri = 'https://example.com/'
            $Request = Invoke-WebRequestBasicAuth $Token -Uri $Uri
            # Headers
            $Request[1].Authorization | Should -Be "Bearer $Token"
            # Method
            $Request[3] | Should -Be 'Get'
            # Uri
            $Request[5] | Should -Be $Uri
        }
        It 'can make a simple request with a username and password' {
            Mock Invoke-WebRequest { $args }
            $Username = 'user'
            $Token = 'token'
            $Uri = 'https://example.com/'
            $Request = Invoke-WebRequestBasicAuth $Username -Password $Token -Uri $Uri
            # Headers
            $Request[1].Authorization | Should -Be 'Basic dXNlcjp0b2tlbg=='
            # Method
            $Request[3] | Should -Be 'Get'
            # Uri
            $Request[5] | Should -Be $Uri
        }
        It 'can make a simple request with query parameters' {
            Mock Invoke-WebRequest { $args }
            $Token = 'token'
            $Uri = 'https://example.com/'
            $Query = @{ foo = 'bar' }
            $Request = Invoke-WebRequestBasicAuth $Token -Uri $Uri -Query $Query
            $Request[1].Authorization | Should -Be "Bearer $Token"
            $Request[5] | Should -Be "${Uri}?foo=bar"
        }
        It 'can make a simple request with URL-encoded query parameters' {
            Mock Invoke-WebRequest { $args }
            $Token = 'token'
            $Uri = 'https://example.com/'
            $Query = @{ answer = 42 }
            $Request = Invoke-WebRequestBasicAuth $Token -Uri $Uri -Query $Query -UrlEncode
            $Request[1].Authorization | Should -Be "Bearer $Token"
            $Request[5] | Should -Be "${Uri}?answer=42"
        }
        It 'can make a simple PUT request' {
            Mock Invoke-WebRequest { $args }
            $Token = 'token'
            $Uri = 'https://example.com/'
            $Request = Invoke-WebRequestBasicAuth $Token -Put -Uri $Uri -Data @{ answer = 42 }
            $Request[1] | Should -Match '"answer": '
            $Request[3].Authorization | Should -Be "Bearer $Token"
            $Request[5] | Should -Be 'Put'
            $Request[7] | Should -Be $Uri
        }
    }
}