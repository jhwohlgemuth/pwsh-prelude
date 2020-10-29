if (Get-Module -Name 'pwsh-prelude') {
    Remove-Module -Name 'pwsh-prelude'
}
$Path = Join-Path $PSScriptRoot '..\pwsh-prelude.psm1'
Import-Module $Path -Force

Describe 'Application State' {
    It 'can save and get state using ID' {
        $Id = 'pester-test'
        $Value = (New-Guid).Guid
        $State = @{ Data = @{ Value = $Value }}
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
        $State = @{ Id = $Id; Data = @{ Value = $Value }}
        $State | Save-State -Path $Path
        $Expected = Get-State -Path $Path
        $Expected.Id | Should -Be $Id
        $Expected.Data.Value | Should -Be $Value
        Remove-Item $Path
    }
    It 'can test save using -WhatIf switch' {
        Mock Write-Verbose {}
        $Path = Join-Path $TestDrive 'test.xml'
        @{ Data = 42 } | Save-State -Path $Path -WhatIf
        (Test-Path $Path) | Should -Be $false
    }
}
Describe 'Invoke-RunApplication' {
    It 'can pass state to Init/Loop functions and execute Loop one time' {
        $Script:Count = 0
        $Init = {
            $State = $args[0]
            $State.Id.Length | Should -Be 36
            $State.Data = 'hello world'
            $Script:Count++
        }
        $Loop = {
            $State = $args[0]
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
        $InitialState = @{ Data = @{ Value = $Script:Value }}
        $Init = {
            $Script:Count++
        }
        $Loop = {
            $State = $args[0]
            $State | Save-State $State.Id | Out-Null
            $Script:Count++
        }
        $Script:ApplicationId = Invoke-RunApplication $Init $Loop $InitialState -SingleRun
        $Script:Count | Should -Be 2
        # Second run that loads state with Get-State
        $Init = {
            $State = $args[0]
            $State.Id | Should -Be $Script:ApplicationId
            $State.Data.Value | Should -Be $Script:Value
            $Script:Count++
        }
        $Loop = {
            $State = $args[0]
            $State.Id | Should -Be $Script:ApplicationId
            $State.Data.Value | Should -Be $Script:Value
            $Script:Count++
        }
        Invoke-RunApplication $Init $Loop -SingleRun -Id $Script:ApplicationId
        $Script:Count | Should -Be 4
        # Third run that should clear state
        $Init = {
            $State = $args[0]
            $State.Id | Should -Be $Script:ApplicationId
            $State.Data.Value | Should -Be $null
            $Script:Count++
        }
        $Loop = {
            $Script:Count++
        }
        $Path = Join-Path $Env:temp "state-$Script:ApplicationId.xml"
        (Test-Path $Path) | Should -Be $true
        Invoke-RunApplication $Init $Loop -SingleRun -Id $Script:ApplicationId -ClearState
        (Test-Path $Path) | Should -Be $false
        $Script:Count | Should -Be 6
    }
    It 'can accept initial state value' {
        $Script:Count = 0
        $Script:Value = (New-Guid).Guid
        $Init = {
            $State = $args[0]
            $State.Id.Length | Should -Be 36
            $State.Data.Value | Should -Be $Script:Value
            $Script:Count++
        }
        $Loop = {
            $State = $args[0]
            $State.Data.Value | Should -Be $Script:Value
            $Script:Count++
        }
        $InitialState = @{ Data = @{ Value = $Script:Value }}
        Invoke-RunApplication $Init $Loop $InitialState -SingleRun
        $Script:Count | Should -Be 2
    }
}
Describe 'New-ApplicationTemplate' {
    It 'can interpolate values into template string' {
        New-ApplicationTemplate | Should -Match 'Start-App'
        New-ApplicationTemplate | Should -Match '\$Init = {'
        New-ApplicationTemplate | Should -Match '\$Init \$Loop \$InitialState'
        New-ApplicationTemplate | Should -not -Match '  \$State = {'
        New-ApplicationTemplate -Name 'Invoke-Awesome' | Should -Match 'Invoke-Awesome'
        New-ApplicationTemplate -Name 'Invoke-Awesome' | Should -not -Match 'Start-App.ps1'
    }
    It 'can be saved to disk' {
        $Name = 'Invoke-Awesome'
        $Path = Join-Path $TestDrive "${Name}.ps1"
        (Test-Path $Path) | Should -Be $false
        New-ApplicationTemplate -Name $Name -Save -Root $TestDrive
        (Test-Path $Path) | Should -Be $true
    }
}
Describe 'New-Template' {
    Context 'when passed an empty object' {
        $script:Expected = '<div>Hello </div>'
        It 'can return function that accepts positional parameter' {
            $function:render = New-Template '<div>Hello {{ name }}</div>'
            render @{} | Should -Be $Expected
        }
        It 'can return function when instantiated as function variable' {
            $function:render = New-Template -Template '<div>Hello {{ name }}</div>'
            render @{} | Should -Be $Expected
        }
        It 'can return function when instantiated as normal variable' {
            $renderVariable = New-Template -Template '<div>Hello {{ name }}</div>'
            & $renderVariable @{} | Should -Be $Expected
        }
        It 'can support default values' {
            $renderVariable = New-Template -Template '<div>Hello {{ name }}</div>' -DefaultValues @{ name = 'Default' }
            & $renderVariable | Should -Be '<div>Hello Default</div>'
            & $renderVariable @{ name = 'Not Default' } | Should -Be '<div>Hello Not Default</div>'
        }
    }
    It 'can return a string when passed -Data paramter' {
        'Hello {{ name }}' | New-Template -Data @{ name = 'World' } | Should -Be 'Hello World'
        '{{#green Hello}} {{ name }}' | New-Template -Data @{ name = 'World' } | Should -Be '{{#green Hello}} World'
    }
    It 'can create function from template string using mustache notation' {
        $Expected = '<div>Hello World!</div>'
        $function:render = New-Template '<div>Hello {{ name }}!</div>'
        render @{ name = 'World' } | Should -Be $Expected
        @{ name = 'World' } | render | Should -Be $Expected
    }
    It 'can create function from template string using Powershell syntax' {
        $Expected = '<div>Hello World!</div>'
        $function:render = New-Template '<div>Hello $($Data.name)!</div>'
        render @{ name = 'World' } | Should -Be $Expected
        @{ name = 'World' } | render | Should -Be $Expected
    }
    It 'can be nested within other templates' {
        $Expected = '<section>
            <h1>Title</h1>
            <div>Hello World!</div>
        </section>'
        $div = New-Template -Template '<div>{{ text }}</div>'
        $section = New-Template "<section>
            <h1>{{ title }}</h1>
            $(& $div @{text = 'Hello World!'})
        </section>"
        & $section @{ title = 'Title' } | Should -Be $Expected
    }
    It 'can be nested within other templates (with Powershell syntax)' {
        $Expected = '<section>
            <h1>Title</h1>
            <div>Hello World!</div>
        </section>'
        $div = New-Template -Template '<div>{{ text }}</div>'
        $section = New-Template "<section>
            <h1>`$(`$Data.title)</h1>
            $(& $div @{text = 'Hello World!'})
        </section>"
        & $section @{ title = 'Title' } | Should -Be $Expected
    }
    It 'can return pass-thru function that does no string interpolation' {
        $Function:render = '{{#green Hello}} {{ name }}' | New-Template
        render -Data @{ name = 'Jason' } | Should -Be '{{#green Hello}} Jason'
        render -Data @{ name = 'Jason' } -PassThru | Should -Be '{{#green Hello}} {{ name }}'
    }
}