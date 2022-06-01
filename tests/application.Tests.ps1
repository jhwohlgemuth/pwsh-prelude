& (Join-Path $PSScriptRoot '_setup.ps1') 'application'

Describe 'Application State' -Tag 'Local', 'Remote' {
    It 'can save and get state using ID' {
        $Name = 'pester-test'
        $Value = (New-Guid).Guid
        $State = @{ Data = @{ Value = $Value } }
        $Path = $State | Save-State $Name
        $Expected = Get-State $Name
        $Expected.Name | Should -Be $Name
        $Expected.Data.Value | Should -Be $Value
        Remove-Item $Path
    }
    It 'can save and get state using path' {
        $Path = Join-Path $TestDrive 'state.xml'
        $Id = (New-Guid).Guid
        $Name = 'My-State'
        $Value = (New-Guid).Guid
        $State = @{ Id = $Id; Data = @{ Value = $Value } }
        $State | Save-State -Name $Name -Path $Path
        $Expected = Get-State -Path $Path
        $Expected.Id | Should -Be $Id
        $Expected.Name | Should -Be $Name
        $Expected.Data.Value | Should -Be $Value
        Remove-Item $Path
    }
    It 'saves state name as a Base64 string' {
        $Name = 'Foo'
        $Expected = 'prelude-RgBvAG8A'
        $Name | Get-StateName | Should -Be $Expected
    }
    It 'can test save using -WhatIf switch' {
        Mock Write-Verbose {}
        $Path = Join-Path $TestDrive 'test.xml'
        @{ Data = 42 } | Save-State -Name 'whatif' -Path $Path -WhatIf
        (Test-Path $Path) | Should -BeFalse
    }
}
Describe 'ConvertTo-Base64 / ConvertFrom-Base64' {
    It 'can encode a string in Base64' {
        $Value = 'The answer is 42'
        $Expected = 'VABoAGUAIABhAG4AcwB3AGUAcgAgAGkAcwAgADQAMgA='
        ConvertTo-Base64 $Value | Should -Be $Expected
        $Value | ConvertTo-Base64 | Should -Be $Expected
    }
    It 'can encode an empty string' {
        $Value = ''
        $Expected = ''
        $Value | ConvertTo-Base64 | Should -Be $Expected
    }
    It 'will encode Null as empty string in Base64' {
        $Value = $Null
        $Expected = ''
        $Value | ConvertTo-Base64 | Should -Be $Expected
    }
    It 'can decode a string in Base64' {
        $Value = 'VABoAGUAIABhAG4AcwB3AGUAcgAgAGkAcwAgADQAMgA='
        $Expected = 'The answer is 42'
        $Value | ConvertFrom-Base64 | Should -Be $Expected
    }
}
Describe 'ConvertTo-PowerShellSyntax' -Tag 'Local', 'Remote' {
    It 'can act as pass-thru for normal strings' {
        $Expected = 'normal string with not mustache templates'
        $Expected | ConvertTo-PowerShellSyntax | Should -Be $Expected
    }
    It 'can convert strings with single mustache template' {
        $InputString = 'Hello {{ world }}'
        $Expected = 'Hello $($Data.world)'
        $InputString | ConvertTo-PowerShellSyntax | Should -Be $Expected
    }
    It 'can convert strings with multiple mustache templates without regard to spaces' {
        $Expected = '$($Data.hello) $($Data.world)'
        '{{ hello }} {{ world }}' | ConvertTo-PowerShellSyntax | Should -Be $Expected
        '{{ hello }} {{ world}}' | ConvertTo-PowerShellSyntax | Should -Be $Expected
        '{{hello }} {{world}}' | ConvertTo-PowerShellSyntax | Should -Be $Expected
    }
    It 'will not convert mustache helper templates' {
        $Expected = 'The sky is {{#blue blue }}'
        $Expected | ConvertTo-PowerShellSyntax | Should -Be $Expected
        $Expected = '{{#red greet }}, my name $($Data.foo) $($Data.foo) is $($Data.name)'
        '{{#red greet }}, my name {{foo }} {{foo}} is {{ name }}' | ConvertTo-PowerShellSyntax | Should -Be $Expected
        '{{#red Red}} {{#blue Blue}}' | ConvertTo-PowerShellSyntax | Should -Be '{{#red Red}} {{#blue Blue}}'
    }
    It 'supports template variables within mustache helper templates' {
        '{{#green Hello}} {{#red {{ name }}}}' | ConvertTo-PowerShellSyntax | Should -Be '{{#green Hello}} {{#red $($Data.name)}}'
        '{{#green Hello}} {{#red {{ name }} }}' | ConvertTo-PowerShellSyntax | Should -Be '{{#green Hello}} {{#red $($Data.name) }}'
        '{{#green Hello}} {{#red {{ foo }}{{ bar }}}}' | ConvertTo-PowerShellSyntax | Should -Be '{{#green Hello}} {{#red $($Data.foo)$($Data.bar)}}'
        '{{#green Hello}} {{#red {{foo}}{{bar}}}}' | ConvertTo-PowerShellSyntax | Should -Be '{{#green Hello}} {{#red $($Data.foo)$($Data.bar)}}'
        '{{#green Hello}} {{#red {{ a }} b {{ c }} }}' | ConvertTo-PowerShellSyntax | Should -Be '{{#green Hello}} {{#red $($Data.a) b $($Data.c) }}'
        '{{#green Hello}} {{#red {{a}}b{{c}}}}' | ConvertTo-PowerShellSyntax | Should -Be '{{#green Hello}} {{#red $($Data.a)b$($Data.c)}}'
        '{{#green Hello}} {{#red {{ a }} b {{ c }} d}}' | ConvertTo-PowerShellSyntax | Should -Be '{{#green Hello}} {{#red $($Data.a) b $($Data.c) d}}'
        '{{#green Hello}} {{#red {{a}}b{{c}}d}}' | ConvertTo-PowerShellSyntax | Should -Be '{{#green Hello}} {{#red $($Data.a)b$($Data.c)d}}'
    }
}
Describe 'Format-Json' {
    It 'can format string input' {
        $Expected = '{
    "answer": 42,
    "numbers": [
        1,
        2,
        3,
        4,
        5
    ]
}'
        '{"answer":42,"numbers":[1,2,3,4,5]}' | Format-Json -Indentation 4 | Should -Be $Expected
    }
    It 'can format file content in-place' {
        $Expected = '{
  "answer": 43,
  "numbers": [
    1,
    2,
    3,
    4,
    5
  ]
}
'
        $Filename = 'format.json'
        $Path = Join-Path $TestDrive $Filename
        '{"answer":43,"numbers":[1,2,3,4,5]}' | Set-Content $Path -Encoding utf8 -NoNewline
        $Path | Format-Json -InPlace
        Get-Content $Path -Raw | Should -Be $Expected
    }
}
Describe -Skip 'Invoke-ListenTo' -Tag 'Local', 'Remote' {
    AfterEach {
        'TestEvent' | Invoke-StopListen
    }
    It 'can listen to custom events and trigger actions' {
        function Test-Callback {}
        $EventName = 'TestEvent'
        $Times = 5
        Mock Test-Callback {}
        { Test-Callback } | Invoke-ListenTo $EventName
        1..$Times | ForEach-Object { Invoke-FireEvent $EventName -Data 'test' }
        Assert-MockCalled Test-Callback -Times $Times
    }
    It 'can listen to custom events and trigger one-time action' {
        function Test-Callback {}
        $EventName = 'TestEvent'
        Mock Test-Callback {}
        { Test-Callback } | Invoke-ListenTo $EventName -Once
        1..10 | ForEach-Object { Invoke-FireEvent $EventName -Data 'test' }
        Assert-MockCalled Test-Callback -Times 1
    }
}
Describe 'Invoke-RunApplication' -Tag 'Local', 'Remote' {
    It 'can pass state to Init/Loop functions and execute Loop one time' {
        $Script:Count = 0
        $Init = {
            $State = $Args[0]
            $State.Id.Length | Should -Be 36
            $State.Data = 'hello world'
            $Script:Count++
        }
        $Loop = {
            $State = $Args[0]
            $State.Data | Should -Be 'hello world'
            $Script:Count++
        }
        Invoke-RunApplication $Init $Loop -SingleRun
        $Script:Count | Should -Be 2
    }
    It 'can persist state with -Id switch and clear state with -ClearState switch' {
        # First run with initial state passed to Invoke-RunApplication
        $Script:Count = 0
        $Script:Name = 'My-Tui'
        $Script:Value = (New-Guid).Guid
        $InitialState = @{ Data = @{ Value = $Script:Value }; Name = $Script:Name }
        $Init = {
            $Script:Count++
        }
        $Loop = {
            $State = $Args[0]
            $State | Save-State $Script:Name -Force | Out-Null
            $Script:Count++
        }
        $Script:ApplicationId = Invoke-RunApplication $Init $Loop $InitialState -SingleRun
        $Script:Count | Should -Be 2
        # Second run that loads state with Get-State
        $Init = {
            $State = $Args[0]
            $State.Name | Should -Be $Script:Name
            $State.Data.Value | Should -Be $Script:Value
            $Script:Count++
        }
        $Loop = {
            $State = $Args[0]
            $State.Name | Should -Be $Script:Name
            $State.Data.Value | Should -Be $Script:Value
            $Script:Count++
        }
        Invoke-RunApplication $Init $Loop -SingleRun -Name $Script:Name
        $Script:Count | Should -Be 4
        # Third run that should clear state
        $Init = {
            $State = $Args[0]
            $State.Name | Should -Be $Script:Name
            $State.Data.Value | Should -BeNullOrEmpty
            $Script:Count++
        }
        $Loop = {
            $Script:Count++
        }
        $TempRoot = if ($IsLinux) { '/tmp' } else { $Env:temp }
        $Filename = $Script:Name | Get-StateName
        $Path = Join-Path $TempRoot "${Filename}.xml"
        (Test-Path $Path) | Should -BeTrue
        Invoke-RunApplication $Init $Loop -SingleRun -Name $Script:Name -ClearState
        (Test-Path $Path) | Should -BeFalse
        $Script:Count | Should -Be 6
    }
    It 'can accept initial state value' {
        $Script:Count = 0
        $Script:Value = (New-Guid).Guid
        $Init = {
            $State = $Args[0]
            $State.Id.Length | Should -Be 36
            $State.Data.Value | Should -Be $Script:Value
            $Script:Count++
        }
        $Loop = {
            $State = $Args[0]
            $State.Data.Value | Should -Be $Script:Value
            $Script:Count++
        }
        $InitialState = @{ Data = @{ Value = $Script:Value } }
        Invoke-RunApplication $Init $Loop $InitialState -SingleRun
        $Script:Count | Should -Be 2
    }
}
Describe 'New-Template' -Tag 'Local', 'Remote' {
    Context 'when passed an empty object' {
        $Script:Expected = '<div>Hello </div>'
        It 'can return function that accepts positional parameter' {
            $Function:Render = New-Template '<div>Hello {{ name }}</div>'
            Render @{} | Should -Be $Expected
        }
        It 'can return function when instantiated as function variable' {
            $Function:Render = New-Template -Template '<div>Hello {{ name }}</div>'
            Render @{} | Should -Be $Expected
        }
        It 'can return function when instantiated as normal variable' {
            $Render = New-Template -Template '<div>Hello {{ name }}</div>'
            & $Render @{} | Should -Be $Expected
        }
        It 'can support default values' {
            $Function:Render = '<div>Hello {{ name }}</div>' | New-Template -DefaultValues @{ name = 'Default' }
            Render | Should -Be '<div>Hello Default</div>'
            $Data = @{ name = 'Not Default' }
            Render $Data | Should -Be '<div>Hello Not Default</div>'
            'Hello {{ name }}' | New-Template -Data $Data -DefaultValues @{ name = 'Default' } | Should -Be 'Hello Not Default'
        }
    }
    It 'can accept templates that start with double quotes' {
        $Data = @{ Value = 'double quotes' }
        $Expected = 'This string has "double quotes"'
        $Function:Render = 'This string has "{{ Value }}"' | New-Template
        Render @{ Value = 'double quotes' } | Should -Be $Expected
        'This string has "{{ Value }}"' | New-Template -Data $Data | Should -Be $Expected
    }
    It 'can accept template from a file' {
        $Data = @{ location = 'World'; type = 'file' }
        $Path = Join-Path $TestDrive 'test.ps1'
        New-Item $Path
        'Hello {{ location }} from a {{ type }}' | Set-Content $Path -NoNewline
        New-Template -File $Path -Data $Data | Should -Be 'Hello World from a file'
        New-Template -File $Path -Data $Data -PassThru | Should -Be 'Hello {{ location }} from a {{ type }}'
        $Path = Join-Path $PSScriptRoot '\fixtures\template.txt'
        New-Template -File $Path -Data $Data | Should -Be '{
    ''Name'' = ''Jason''
    "Location" = World
    $Type = file
}'
    }
    It 'can support multiple template functions at once' {
        $Function:Div = '<div>{{ text }}</div>' | New-Template -DefaultValues @{ text = 'default' }
        $Function:Span = '<span>{{ text }}</span>' | New-Template -DefaultValues @{ text = 'default' }
        "$(Div @{ text = Span @{ text = 'hello' }})" | Should -Be '<div><span>hello</span></div>'
    }
    It 'supports PowerShell variables' {
        '$Foo = {{ Foo }}' | New-Template -Data @{ Foo = 42 } | Should -Be '$Foo = 42'
        '${Bar} = {{ Bar }}' | New-Template -Data @{ Bar = 7 } | Should -Be '${Bar} = 7'
        '$Foo = {{ Foo }}; ${Bar} = {{ Bar }}' | New-Template -Data @{ Foo = 42; Bar = 7 } | Should -Be '$Foo = 42; ${Bar} = 7'
    }
    It 'can return a string when passed -Data parameter' {
        $Data = @{ name = 'World' }
        'Hello {{ name }}' | New-Template -Data $Data | Should -Be 'Hello World'
        'Hello {{ name }} and {{ name }}' | New-Template -Data $Data | Should -Be 'Hello World and World'
        'Hello {{ name }} and {{ name }}' | New-Template -Data $Data | Should -Be 'Hello World and World'
        $Data = @{ a = 'FOO'; b = 'BAR' }
        '{{ a }}{{ b }}' | New-Template -Data $Data | Should -Be 'FOOBAR'
    }
    It 'can skip color template entities, {{#color text }}' {
        '{{#green Hello}} {{ name }}' | New-Template -Data @{ name = 'World' } | Should -Be '{{#green Hello}} World'
        'Hello {{#green {{ place }} }}' | New-Template -Data @{ place = 'World' } | Should -Be 'Hello {{#green World }}'
    }
    It 'can execute code when {{= ... }} is used' {
        'The answer is {{= $Value + 2 }}' | New-Template -Data @{ Value = 40 } | Should -Be 'The answer is 42'
        $Function:Render = 'The answer is {{= $Value + 2 }}' | New-Template -DefaultValues @{ Value = 100 }
        Render | Should -Be 'The answer is 102'
        $Env:SomeRandomValue = 'woof'
        'The fox says {{= $Env:SomeRandomValue }}!!!' | New-Template -NoData | Should -Be 'The fox says woof!!!'
    }
    It 'supports comments using {{- ... }} syntax' {
        'Hello {{- This is a comment and will not show up in the output }}World' | New-Template -NoData | Should -Be 'Hello World'
        $Function:Render = 'Hello {{- Some random comment }}{{ name }}' | New-Template
        Render @{ name = 'World' } | Should -Be 'Hello World'
    }
    It 'can create function from template string using mustache notation' {
        $Expected = '<div>Hello World!</div>'
        $Function:Render = New-Template '<div>Hello {{ name }}!</div>'
        Render @{ name = 'World' } | Should -Be $Expected
        @{ name = 'World' } | Render | Should -Be $Expected
    }
    It 'can be nested within other templates' {
        $Expected = '<section>
      <h1>Title</h1>
      <div>Hello World!</div>
    </section>'
        $Div = New-Template -Template '<div>{{ text }}</div>'
        $Section = New-Template "<section>
      <h1>{{ title }}</h1>
      $(& $Div @{text = 'Hello World!'})
    </section>"
        & $Section @{ title = 'Title' } | Should -Be $Expected
        $Function:Div = '<div>{{ text }}</div>' | New-Template
        $Function:Section = "<section>
      <h1>{{ title }}</h1>
      $(Div @{ text = 'Hello World!' })
    </section>" | New-Template
        Section @{ title = 'Title' } | Should -Be $Expected
    }
    It 'can support partial templates' {
        $Expected = '<div>FOO {{ bar }}</div>'
        $Template = '<div>{{ foo }} {{ bar }}</div>'
        $Function:Render = $Template | New-Template
        Render @{ foo = 'FOO' } -Partial | Should -Be $Expected
        Render @{ foo = 'FOO' } -Partial -PassThru | Should -Be $Template
        $Function:Element = '<{{ tag }}>{{ t }}</{{ tag }}>' | New-Template
        $Function:Div = Element @{ tag = 'div' } -Partial | New-Template
        Div @{ t = 'Hello World' } | Should -Be '<div>Hello World</div>'
    }
    It 'can return pass-thru function that does no string interpolation' {
        $Template = 'Hello {{ name }}'
        $Data = @{ name = 'Jason' }
        $Template | New-Template -Data $Data | Should -Be 'Hello Jason'
        $Template | New-Template -Data $Data -PassThru | Should -Be 'Hello {{ name }}'
        $Function:Render = $Template | New-Template
        Render -Data $Data | Should -Be 'Hello Jason'
        Render -Data $Data -PassThru | Should -Be 'Hello {{ name }}'
        '$Foo = {{ Foo }}' | New-Template -PassThru -NoData | Should -Be '$Foo = {{ Foo }}'
    }
}
Describe 'New-TerminalApplicationTemplate' -Tag 'Local', 'Remote' {
    It 'can interpolate values into template string' {
        New-TerminalApplicationTemplate | Should -Match '#Requires -Modules Prelude'
        New-TerminalApplicationTemplate | Should -Match '\$Init = {'
        New-TerminalApplicationTemplate | Should -Match '{{#green \$Name}}'
        New-TerminalApplicationTemplate | Should -Match '\$Init \$Loop \$InitialState'
        New-TerminalApplicationTemplate | Should -Not -Match '  \$State = {'
    }
}
Describe 'New-WebApplication' -Tag 'Local', 'Remote' {
    It 'can be created using Webpack and <Library>' -TestCases @(
        @{ Bundler = 'Webpack'; Library = $Null }
        @{ Bundler = 'Webpack'; Library = 'React' }
        @{ Bundler = 'Webpack'; Library = 'Solid' }
    ) {
        $Files = @(
            'public'
            'src'
            '__tests__'
            '.editorconfig'
            '.eslintrc.json'
            'babel.config.json'
            'package.json'
            'postcss.config.js'
            'webpack.config.js'
        )
        New-WebApplication -Bundler $Bundler -Library $Library -Parent $TestDrive -NoInstall -Silent -Force
        Get-ChildItem (Join-Path $TestDrive 'webapp') | Should -Be $Files
        Remove-Item -Path (Join-Path $TestDrive 'webapp') -Recurse -Force
    }
    It -Skip 'can be created using Parcel and <Library>' -TestCases @(
        @{ Bundler = 'Parcel'; Library = 'Vanilla' }
        @{ Bundler = 'Parcel'; Library = 'React' }
        @{ Bundler = 'Parcel'; Library = 'Solid' }
    ) {
        $Files = @(
            'public'
            'src'
            '__tests__'
            '.editorconfig'
            '.eslintrc.json'
            'babel.config.json'
            'package.json'
            'postcss.config.js'
            'webpack.config.js'
        )
        New-WebApplication -Bundler $Bundler -Library $Library -Parent $TestDrive -NoInstall -Silent -Force
        Get-ChildItem (Join-Path $TestDrive 'webapp') | Should -Be $Files
        Remove-Item -Path (Join-Path $TestDrive 'webapp') -Recurse -Force
    }
    It -Skip 'can be created using Rollup and <Library>' -TestCases @(
        @{ Bundler = 'Rollup'; Library = 'Vanilla' }
        @{ Bundler = 'Rollup'; Library = 'React' }
        @{ Bundler = 'Rollup'; Library = 'Solid' }
    ) {
        $Files = @(
            'public'
            'src'
            '__tests__'
            '.editorconfig'
            '.eslintrc.json'
            'babel.config.json'
            'package.json'
            'postcss.config.js'
            'webpack.config.js'
        )
        New-WebApplication -Bundler $Bundler -Library $Library -Parent $TestDrive -NoInstall -Silent -Force
        Get-ChildItem (Join-Path $TestDrive 'webapp') | Should -Be $Files
        Remove-Item -Path (Join-Path $TestDrive 'webapp') -Recurse -Force
    }
    It -Skip 'can be created using Snowpack and <Library>' -TestCases @(
        @{ Bundler = 'Snowpack'; Library = 'Vanilla' }
        @{ Bundler = 'Snowpack'; Library = 'React' }
        @{ Bundler = 'Snowpack'; Library = 'Solid' }
    ) {
        $Files = @(
            'public'
            'src'
            '__tests__'
            '.editorconfig'
            '.eslintrc.json'
            'babel.config.json'
            'package.json'
            'postcss.config.js'
        )
        New-WebApplication -Bundler $Bundler -Library $Library -Parent $TestDrive -NoInstall -Silent -Force
        Get-ChildItem (Join-Path $TestDrive 'webapp') | Should -Be $Files
        Remove-Item -Path (Join-Path $TestDrive 'webapp') -Recurse -Force
    }
    It 'can be created using a <Config> object' -TestCases @(
        @{ Config = @{ Name = 'MyApp'; Bundler = 'Webpack' } }
        @{ Config = @{ Name = 'MyApp'; Bundler = 'Parcel'; Library = 'React' } }
    ) {
        $Path = Join-Path $TestDrive "/$($Config.Name)/package.json"
        Test-Path -Path $Path | Should -BeFalse
        $Config | New-WebApplication -Parent $TestDrive -NoInstall -Silent -Force
        Test-Path -Path $Path | Should -BeTrue
        $State = $Config.Name | Get-State
        $State.Name | Should -Be $Config.Name
        Remove-Item -Path (Join-Path $TestDrive $Config.Name) -Recurse -Force
    }
    It 'can be created interactively' {
        Mock Write-Title {} -ModuleName Prelude
        Mock Write-Label {} -ModuleName Prelude
        Mock Invoke-Menu {
            switch ($HighlightColor) {
                'Cyan' { 'Webpack' }
                'Yellow' { 'React' }
                'Magenta' { 'Cesium' }
            }
        } -ModuleName Prelude
        New-WebApplication -Interactive -Parent $TestDrive -NoInstall -Silent -Force
        Remove-Item -Path (Join-Path $TestDrive 'webapp') -Recurse -Force
    }
}
Describe 'Remove-Indent' -Tag 'Local', 'Remote' {
    It 'can handle empty strings' {
        '' | Remove-Indent | Should -BeNullOrEmpty
        '' | Remove-Indent -Size 0 | Should -Be ''
    }
    It 'can remove leading spaces from single-line strings' {
        '    foobar' | Remove-Indent | Should -Be 'foobar'
        '     foobar' | Remove-Indent -Size 5 | Should -Be 'foobar'
        'foobar' | Remove-Indent -Size 0 | Should -Be 'foobar'
    }
    It 'can remove leading spaces from multi-line strings' {
        "`n    foo`n    bar`n" | Remove-Indent | Should -Be "`nfoo`nbar"
        "`n  foo`n  bar`n" | Remove-Indent -Size 2 | Should -Be "`nfoo`nbar"
    }
    It 'can process an array of strings' {
        '    foobar', "`n    foo`n    bar`n" | Remove-Indent | Should -Be 'foobar', "`nfoo`nbar"
    }
}
Describe 'Test-ApplicationContext' -Tag 'Local', 'Remote' {
    Describe 'JavaScript Compiler (Babel)' {
        It 'knows when configuration file, <File>, exists' -TestCases @(
            @{ File = 'babel.config.json' }
            @{ File = 'babel.config.js' }
            @{ File = 'babel.config.cjs' }
            @{ File = 'babel.config.mjs' }
            @{ File = '.babelrc' }
            @{ File = '.babelrc.json' }
            @{ File = '.babelrc.js' }
            @{ File = '.babelrc.cjs' }
            @{ File = '.babelrc.mjs' }
        ) {
            $Path = Join-Path $TestDrive $File
            New-Item -Type File -Path $Path
            $Results = Test-ApplicationContext -Parent $TestDrive
            $Results.Node.Compiler | Should -BeTrue
            $Results.Node.Linter | Should -BeFalse
            Remove-Item -Path $Path
        }
    }
    Describe 'JavaScript Linter (ESLint)' {
        It 'knows when configuration file, <File>, exists' -TestCases @(
            @{ File = '.eslintrc' }
            @{ File = '.eslintrc.js' }
            @{ File = '.eslintrc.cjs' }
            @{ File = '.eslintrc.yaml' }
            @{ File = '.eslintrc.yml' }
            @{ File = '.eslintrc.json' }
        ) {
            $Path = Join-Path $TestDrive $File
            New-Item -Type File -Path $Path
            $Results = Test-ApplicationContext -Parent $TestDrive
            $Results.Node.Compiler | Should -BeFalse
            $Results.Node.Linter | Should -BeTrue
            Remove-Item -Path $Path
        }
    }
}
Describe -Skip 'Write-Status' {
    It 'can print "done" message' {
        'done' | Write-Status
        'done' | Write-Status -Color Green
    }
    It 'can print "fail" message' {
        'fail' | Write-Status
        'fail' | Write-Status -PassThru | Write-Color -Yellow
    }
    It 'can print "pass" message' {
        'pass' | Write-Status
    }
}