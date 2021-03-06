﻿& (Join-Path $PSScriptRoot '_setup.ps1') 'application'

Describe 'Application State' -Tag 'Local', 'Remote' {
    It 'can save and get state using ID' {
        $Id = 'pester-test'
        $Value = (New-Guid).Guid
        $State = @{ Data = @{ Value = $Value } }
        $Path = $State | Save-State $Id
        $Expected = Get-State $Id
        $Expected.Id | Should -Be $Id
        $Expected.Data.Value | Should -Be $Value
        Remove-Item $Path
    }
    It 'can save and get state using path' {
        $Path = Join-Path $TestDrive 'state.xml'
        $Id = (New-Guid).Guid
        $Value = (New-Guid).Guid
        $State = @{ Id = $Id; Data = @{ Value = $Value } }
        $State | Save-State -Id $Id -Path $Path
        $Expected = Get-State -Path $Path
        $Expected.Id | Should -Be $Id
        $Expected.Data.Value | Should -Be $Value
        Remove-Item $Path
    }
    It 'can test save using -WhatIf switch' {
        Mock Write-Verbose {}
        $Path = Join-Path $TestDrive 'test.xml'
        @{ Data = 42 } | Save-State -Id 'whatif' -Path $Path -WhatIf
        (Test-Path $Path) | Should -BeFalse
    }
}
Describe 'ConvertTo-PowershellSyntax' -Tag 'Local', 'Remote' {
    It 'can act as pass-thru for normal strings' {
        $Expected = 'normal string with not mustache templates'
        $Expected | ConvertTo-PowershellSyntax | Should -Be $Expected
    }
    It 'can convert strings with single mustache template' {
        $InputString = 'Hello {{ world }}'
        $Expected = 'Hello $($Data.world)'
        $InputString | ConvertTo-PowershellSyntax | Should -Be $Expected
    }
    It 'can convert strings with multiple mustache templates without regard to spaces' {
        $Expected = '$($Data.hello) $($Data.world)'
        '{{ hello }} {{ world }}' | ConvertTo-PowershellSyntax | Should -Be $Expected
        '{{ hello }} {{ world}}' | ConvertTo-PowershellSyntax | Should -Be $Expected
        '{{hello }} {{world}}' | ConvertTo-PowershellSyntax | Should -Be $Expected
    }
    It 'will not convert mustache helper templates' {
        $Expected = 'The sky is {{#blue blue }}'
        $Expected | ConvertTo-PowershellSyntax | Should -Be $Expected
        $Expected = '{{#red greet }}, my name $($Data.foo) $($Data.foo) is $($Data.name)'
        '{{#red greet }}, my name {{foo }} {{foo}} is {{ name }}' | ConvertTo-PowershellSyntax | Should -Be $Expected
        '{{#red Red}} {{#blue Blue}}' | ConvertTo-PowershellSyntax | Should -Be '{{#red Red}} {{#blue Blue}}'
    }
    It 'supports template variables within mustache helper templates' {
        '{{#green Hello}} {{#red {{ name }}}}' | ConvertTo-PowershellSyntax | Should -Be '{{#green Hello}} {{#red $($Data.name)}}'
        '{{#green Hello}} {{#red {{ name }} }}' | ConvertTo-PowershellSyntax | Should -Be '{{#green Hello}} {{#red $($Data.name) }}'
        '{{#green Hello}} {{#red {{ foo }}{{ bar }}}}' | ConvertTo-PowershellSyntax | Should -Be '{{#green Hello}} {{#red $($Data.foo)$($Data.bar)}}'
        '{{#green Hello}} {{#red {{foo}}{{bar}}}}' | ConvertTo-PowershellSyntax | Should -Be '{{#green Hello}} {{#red $($Data.foo)$($Data.bar)}}'
        '{{#green Hello}} {{#red {{ a }} b {{ c }} }}' | ConvertTo-PowershellSyntax | Should -Be '{{#green Hello}} {{#red $($Data.a) b $($Data.c) }}'
        '{{#green Hello}} {{#red {{a}}b{{c}}}}' | ConvertTo-PowershellSyntax | Should -Be '{{#green Hello}} {{#red $($Data.a)b$($Data.c)}}'
        '{{#green Hello}} {{#red {{ a }} b {{ c }} d}}' | ConvertTo-PowershellSyntax | Should -Be '{{#green Hello}} {{#red $($Data.a) b $($Data.c) d}}'
        '{{#green Hello}} {{#red {{a}}b{{c}}d}}' | ConvertTo-PowershellSyntax | Should -Be '{{#green Hello}} {{#red $($Data.a)b$($Data.c)d}}'
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
        $Script:Value = (New-Guid).Guid
        $InitialState = @{ Data = @{ Value = $Script:Value } }
        $Init = {
            $Script:Count++
        }
        $Loop = {
            $State = $Args[0]
            $State | Save-State $State.Id | Out-Null
            $Script:Count++
        }
        $Script:ApplicationId = Invoke-RunApplication $Init $Loop $InitialState -SingleRun
        $Script:Count | Should -Be 2
        # Second run that loads state with Get-State
        $Init = {
            $State = $Args[0]
            $State.Id | Should -Be $Script:ApplicationId
            $State.Data.Value | Should -Be $Script:Value
            $Script:Count++
        }
        $Loop = {
            $State = $Args[0]
            $State.Id | Should -Be $Script:ApplicationId
            $State.Data.Value | Should -Be $Script:Value
            $Script:Count++
        }
        Invoke-RunApplication $Init $Loop -SingleRun -Id $Script:ApplicationId
        $Script:Count | Should -Be 4
        # Third run that should clear state
        $Init = {
            $State = $Args[0]
            $State.Id | Should -Be $Script:ApplicationId
            $State.Data.Value | Should -BeNullOrEmpty
            $Script:Count++
        }
        $Loop = {
            $Script:Count++
        }
        $TempRoot = if ($IsLinux) { '/tmp' } else { $Env:temp }
        $Path = Join-Path $TempRoot "state-$Script:ApplicationId.xml"
        (Test-Path $Path) | Should -BeTrue
        Invoke-RunApplication $Init $Loop -SingleRun -Id $Script:ApplicationId -ClearState
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
Describe 'New-ApplicationTemplate' -Tag 'Local', 'Remote' {
    It 'can interpolate values into template string' {
        New-ApplicationTemplate | Should -Match '#Requires -Modules Prelude'
        New-ApplicationTemplate | Should -Match '\$Init = {'
        New-ApplicationTemplate | Should -Match '{{#green My-App}}'
        New-ApplicationTemplate | Should -Match '\$Init \$Loop \$InitialState'
        New-ApplicationTemplate | Should -Not -Match '  \$State = {'
    }
}
Describe 'New-Template' -Tag 'Local', 'Remote' {
    Context 'when passed an empty object' {
        $Script:Expected = '<div>Hello </div>'
        It 'can return function that accepts positional parameter' {
            $Function:render = New-Template '<div>Hello {{ name }}</div>'
            render @{} | Should -Be $Expected
        }
        It 'can return function when instantiated as function variable' {
            $Function:render = New-Template -Template '<div>Hello {{ name }}</div>'
            render @{} | Should -Be $Expected
        }
        It 'can return function when instantiated as normal variable' {
            $RenderVariable = New-Template -Template '<div>Hello {{ name }}</div>'
            & $RenderVariable @{} | Should -Be $Expected
        }
        It 'can support default values' {
            $RenderVariable = New-Template -Template '<div>Hello {{ name }}</div>' -DefaultValues @{ name = 'Default' }
            & $RenderVariable | Should -Be '<div>Hello Default</div>'
            & $RenderVariable @{ name = 'Not Default' } | Should -Be '<div>Hello Not Default</div>'
        }
    }
    It 'can return a string when passed -Data paramter' {
        'Hello {{ name }}' | New-Template -Data @{ name = 'World' } | Should -Be 'Hello World'
        '{{#green Hello}} {{ name }}' | New-Template -Data @{ name = 'World' } | Should -Be '{{#green Hello}} World'
    }
    It 'can create function from template string using mustache notation' {
        $Expected = '<div>Hello World!</div>'
        $Function:render = New-Template '<div>Hello {{ name }}!</div>'
        render @{ name = 'World' } | Should -Be $Expected
        @{ name = 'World' } | render | Should -Be $Expected
    }
    It 'can create function from template string using Powershell syntax' {
        $Expected = '<div>Hello World!</div>'
        $Function:render = New-Template '<div>Hello $($Data.name)!</div>'
        render @{ name = 'World' } | Should -Be $Expected
        @{ name = 'World' } | render | Should -Be $Expected
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
    }
    It 'can be nested within other templates (with Powershell syntax)' {
        $Expected = '<section>
      <h1>Title</h1>
      <div>Hello World!</div>
    </section>'
        $Div = New-Template -Template '<div>{{ text }}</div>'
        $Section = New-Template "<section>
      <h1>`$(`$Data.title)</h1>
      $(& $Div @{text = 'Hello World!'})
    </section>"
        & $Section @{ title = 'Title' } | Should -Be $Expected
    }
    It 'can return pass-thru function that does no string interpolation' {
        $Function:render = '{{#green Hello}} {{ name }}' | New-Template
        render -Data @{ name = 'Jason' } | Should -Be '{{#green Hello}} Jason'
        render -Data @{ name = 'Jason' } -PassThru | Should -Be '{{#green Hello}} {{ name }}'
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