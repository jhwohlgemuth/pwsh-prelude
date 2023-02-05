[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWriteHost', '', Scope = 'Function', Target = 'Write-Color')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '', Scope = 'Function', Target = 'Invoke-Input')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '', Scope = 'Function', Target = 'Update-Autocomplete')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '', Scope = 'Function', Target = 'Invoke-Input')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '', Scope = 'Function', Target = 'Invoke-Menu')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '', Scope = 'Function', Target = 'Update-MenuSelection')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '', Scope = 'Function', Target = 'Write-BarChart')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '', Scope = 'Function', Target = 'Write-Color')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseOutputTypeCorrectly', '', Scope = 'Function', Target = 'Invoke-Menu')]
Param()


function Format-FileSize {
    <#
    .SYNOPSIS
    Format a file size in bytes to a human readable string
    .EXAMPLE
    2000 | Format-FileSize
    # '1.95KB'
    #>
    [CmdletBinding()]
    [OutputType([String])]
    Param(
        [Parameter(Position = 1, ValueFromPipeline = $True)]
        [Float] $Value = ''
    )
    Process {
        $Units = ''
        switch ($Value) {
            { $_ -lt 1KB } {
                $Units = 'B'
                $Denominator = 1
            }
            { ($_ -ge 1KB) -and ($_ -lt 1MB) } {
                $Units = 'KB'
                $Denominator = 1KB
            }
            { ($_ -ge 1MB) -and ($_ -lt 1GB) } {
                $Units = 'MB'
                $Denominator = 1MB
            }
            { ($_ -ge 1GB) -and ($_ -lt 1TB) } {
                $Units = 'GB'
                $Denominator = 1GB
            }
            Default {
                $Units = 'TB'
                $Denominator = 1TB
            }
        }
        [Math]::Round($Value / $Denominator, 1).ToString('0.0') + $Units
    }
}
function Format-MinimumWidth {
    <#
    .SYNOPSIS
    Pad a string to ensure it is at least a certain width.
    .EXAMPLE
    'foo' | Format-MinimumWidth 5
    # ' foo '
    #>
    [CmdletBinding()]
    [OutputType([String])]
    Param(
        [Parameter(Position = 1, ValueFromPipeline = $True)]
        [String] $Value = '',
        [Parameter(Position = 0)]
        [Int] $Width,
        [String] $Padding = ' ',
        [String] $Align = 'Center',
        [Switch] $Template
    )
    Process {
        $Value = if ($Template) { $Value | Remove-HandlebarsHelper } else { $Value }
        $Actual = $Value.Length
        $Desired = $Width
        $Diff = if ($Actual -gt $Desired) { 0 } else { $Desired - $Actual }
        if ($Actual -eq 0) {
            return $Padding * $Width
        }
        if ($Diff -gt 0) {
            if (($Diff % 2) -eq 0) {
                $Pad = $Padding * ($Diff / 2)
                switch ($Align) {
                    'Left' {
                        "${Value}$($Padding * $Diff)"
                    }
                    'Right' {
                        "$($Padding * $Diff)${Value}"
                    }
                    Default {
                        "${Pad}${Value}${Pad}"
                    }
                }
            } else {
                $Pad = $Padding * (($Diff - 1) / 2)
                switch ($Align) {
                    'Left' {
                        "${Value}$($Padding * $Diff)"
                    }
                    'Right' {
                        "$($Padding * $Diff)${Value}"
                    }
                    Default {
                        "${Pad}${Value}${Pad}${Padding}"
                    }
                }
            }
        } else {
            $Value
        }
    }
}
function Invoke-Input {
    <#
    .SYNOPSIS
    A fancy Read-Host replacement meant to for use making CLI applications.
    .PARAMETER Secret
    Displayed characters replaced with asterisks
    .PARAMETER Number
    Switch to designate numerical input
    .EXAMPLE
    $Fullname = input 'Full Name?'
    $Username = input 'Username?' -MaxLength 10 -Indent 4
    $Age = input 'Age?' -Number -MaxLength 2 -Indent 4
    $Pass = input 'Password?' -Secret -Indent 4

    # Make a simple terminal form with a few inputs
    .EXAMPLE
    $Choices = @('Goku', 'Gohan', 'Goten', 'Vegeta', 'Trunks')
    $Word = input 'Favorite Saiya-jin?' -Indent 4 -Autocomplete -Choices $Choices

    # Autocomplete will make suggestions. Press tab once to select suggestion, press tab again to cycle through matches.
    .EXAMPLE
    Invoke-Input 'Folder name?' -Autocomplete -Choices (Get-ChildItem -Directory | Select-Object -ExpandProperty Name)

    # Leverage autocomplete to input a folder name
    .EXAMPLE
    $Name = input 'What is your {{#blue name}}?'

    # Input labels can be customized with mustache color helpers
    #>
    [CmdletBinding()]
    [Alias('input')]
    Param(
        [Parameter(Position = 0, ValueFromPipeline = $True)]
        [String] $LabelText = 'input:',
        [Switch] $Secret,
        [Switch] $Number,
        [Switch] $Autocomplete,
        [Array] $Choices,
        [Int] $Indent,
        [Int] $MaxLength = 0,
        [String] $Placeholder = ''
    )
    Write-Label -Text $LabelText -Indent $Indent
    $Global:PreviousRegularExpression = $Null
    $Result = ''
    $CurrentIndex = 0
    $AutocompleteMatches = @()
    $StartPosition = [Console]::CursorLeft
    function Clear-Placeholder {
        Param()
        [Console]::SetCursorPosition($StartPosition, [Console]::CursorTop)
        Write-Color (' ' * $Placeholder.Length) -NoNewLine
        [Console]::SetCursorPosition($StartPosition, [Console]::CursorTop)
    }
    function Write-Placeholder {
        Param()
        Write-Color $Placeholder -NoNewLine -DarkGray
    }
    function Format-Output {
        Param(
            [Parameter(Mandatory = $True, Position = 0)]
            [String] $Value
        )
        if ($Secret) {
            '*' * $Value.Length
        } else {
            $Value
        }
    }
    function Invoke-OutputDraw {
        Param(
            [Parameter(Mandatory = $True, Position = 0)]
            [String] $Output,
            [Int] $Left = 0
        )
        [Console]::SetCursorPosition($StartPosition, [Console]::CursorTop)
        if ($MaxLength -gt 0 -and $Output.Length -gt $MaxLength) {
            Write-Color $Output.Substring(0, $MaxLength) -NoNewLine
            Write-Color $Output.Substring($MaxLength, $Output.Length - $MaxLength) -NoNewLine -Red
        } else {
            Write-Color $Output -NoNewLine
            if ($Autocomplete) {
                Update-Autocomplete -Output $Output
            }
        }
        [Console]::SetCursorPosition($Left + 1, [Console]::CursorTop)
    }
    function Update-Autocomplete {
        Param(
            [AllowEmptyString()]
            [String] $Output
        )
        $Global:PreviousRegularExpression = "^${Output}"
        $AutocompleteMatches = $Choices | Where-Object { $_ -match $Global:PreviousRegularExpression }
        if ($Null -eq $AutocompleteMatches -or $Output.Length -eq 0) {
            $Left = [Console]::CursorLeft
            [Console]::SetCursorPosition($Left, [Console]::CursorTop)
            Write-Color (' ' * 30) -NoNewLine
            [Console]::SetCursorPosition($Left, [Console]::CursorTop)
        } else {
            if ($AutocompleteMatches -is [String]) {
                $BestMatch = $AutocompleteMatches
            } else {
                $BestMatch = $AutocompleteMatches[0]
            }
            $Left = [Console]::CursorLeft
            [Console]::SetCursorPosition($StartPosition + $Output.Length, [Console]::CursorTop)
            Write-Color $BestMatch.Substring($Output.Length) -NoNewLine -Green
            Write-Color (' ' * 30) -NoNewLine
            [Console]::SetCursorPosition($Left, [Console]::CursorTop)
        }
    }
    Write-Placeholder
    [Console]::SetCursorPosition($StartPosition, [Console]::CursorTop)
    do {
        $KeyInfo = [Console]::ReadKey($True)
        $KeyChar = $KeyInfo.KeyChar
        if ($Result.Length -eq 0) {
            Clear-Placeholder
        }
        switch ($KeyInfo.Key) {
            'Backspace' {
                if (-not $Secret) {
                    $Left = [Console]::CursorLeft
                    if ($Left -gt $StartPosition) {
                        [Console]::SetCursorPosition($StartPosition, [Console]::CursorTop)
                        $Updated = $Result | Remove-Character -At ($Left - $StartPosition - 1)
                        $Result = $Updated
                        if ($MaxLength -eq 0) {
                            Write-Color $Updated -NoNewLine
                            if ($Autocomplete) {
                                Update-Autocomplete -Output $Updated
                            } else {
                                Write-Color ' ' -NoNewLine
                            }
                        } else {
                            [Console]::SetCursorPosition($StartPosition, [Console]::CursorTop)
                            if ($Result.Length -le $MaxLength) {
                                Write-Color "$Updated " -NoNewLine
                            } else {
                                Write-Color $Updated.Substring(0, $MaxLength) -NoNewLine
                                Write-Color ($Updated.Substring($MaxLength, $Updated.Length - $MaxLength) + ' ') -NoNewLine -Red
                            }
                        }
                        [Console]::SetCursorPosition([Math]::Max(0, $Left - 1), [Console]::CursorTop)
                    }
                }
            }
            'Delete' {
                if (-not $Secret) {
                    if ($Result.Length -gt 0) {
                        $Left = [Console]::CursorLeft
                        [Console]::SetCursorPosition($StartPosition, [Console]::CursorTop)
                        $Updated = $Result | Remove-Character -At ($Left - $StartPosition)
                        $Result = $Updated
                        if ($MaxLength -eq 0) {
                            Write-Color "$Updated " -NoNewLine
                        } else {
                            [Console]::SetCursorPosition($StartPosition, [Console]::CursorTop)
                            if ($Result.Length -le $MaxLength) {
                                Write-Color "$Updated " -NoNewLine
                            } else {
                                Write-Color $Updated.Substring(0, $MaxLength) -NoNewLine
                                Write-Color ($Updated.Substring($MaxLength, $Updated.Length - $MaxLength) + ' ') -NoNewLine -Red
                            }
                        }
                        if ($Autocomplete) {
                            Update-Autocomplete -Output $Updated
                        }
                        [Console]::SetCursorPosition([Math]::Max(0, $Left), [Console]::CursorTop)
                    }
                }
            }
            'DownArrow' {
                if ($Number) {
                    $Value = ($Result -as [Int]) - 1
                    if (($MaxLength -eq 0) -or ($MaxLength -gt 0 -and $Value -gt (-1 * [Math]::Pow(10, $MaxLength)))) {
                        $Left = [Console]::CursorLeft
                        $Result = "$Value"
                        [Console]::SetCursorPosition($StartPosition, [Console]::CursorTop)
                        Write-Color $Result -NoNewLine
                        [Console]::SetCursorPosition($Left, [Console]::CursorTop)
                    }
                }
            }
            'Enter' {
                # Do nothing
            }
            'LeftArrow' {
                if (-not $Secret) {
                    $Left = [Console]::CursorLeft
                    if ($Left -gt $StartPosition) {
                        [Console]::SetCursorPosition($Left - 1, [Console]::CursorTop)
                    }
                }
            }
            'RightArrow' {
                if (-not $Secret) {
                    $Left = [Console]::CursorLeft
                    if ($Left -lt ($StartPosition + $Result.Length)) {
                        [Console]::SetCursorPosition($Left + 1, [Console]::CursorTop)
                    }
                }
            }
            'Tab' {
                if ($Autocomplete -and $Result.Length -gt 0 -and -not ($Number -or $Secret) -and $Null -ne $AutocompleteMatches) {
                    $AutocompleteMatches = $Choices | Where-Object { $_ -match $Global:PreviousRegularExpression }
                    [Console]::SetCursorPosition($StartPosition, [Console]::CursorTop)
                    if ($AutocompleteMatches -is [String]) {
                        $Result = $AutocompleteMatches
                    } else {
                        $CurrentMatch = $AutocompleteMatches[$CurrentIndex]
                        if ($Result -eq $PreviousMatch) {
                            $Result = $PreviousSearch[$CurrentIndex]
                        } else {
                            $Result = $CurrentMatch
                            $PreviousMatch = $CurrentMatch
                            $PreviousSearch = $AutocompleteMatches
                        }
                        $CurrentIndex = ($CurrentIndex + 1) % $AutocompleteMatches.Length
                    }
                    Write-Color "$Result $(' ' * 30)" -NoNewLine -Green
                    [Console]::SetCursorPosition($StartPosition + $Result.Length, [Console]::CursorTop)
                }
            }
            'UpArrow' {
                if ($Number) {
                    $Value = ($Result -as [Int]) + 1
                    if (($MaxLength -eq 0) -or ($MaxLength -gt 0 -and $Value -lt [Math]::Pow(10, $MaxLength))) {
                        $Left = [Console]::CursorLeft
                        $Result = "$Value"
                        [Console]::SetCursorPosition($StartPosition, [Console]::CursorTop)
                        Write-Color "$Result " -NoNewLine
                        [Console]::SetCursorPosition($Left, [Console]::CursorTop)
                    }
                }
            }
            Default {
                $Left = [Console]::CursorLeft
                $OnlyNumbers = [Regex]'^-?[0-9]*$'
                if ($Left -eq $StartPosition) {
                    # prepend character
                    if ($Number) {
                        if ($KeyChar -match $OnlyNumbers) {
                            $Result = "${KeyChar}$Result"
                            Invoke-OutputDraw -Output (Format-Output $Result) -Left $Left
                        }
                    } else {
                        $Result = "${KeyChar}$Result"
                        Invoke-OutputDraw -Output (Format-Output $Result) -Left $Left
                    }
                } elseif ($Left -gt $StartPosition -and $Left -lt ($StartPosition + $Result.Length)) {
                    # insert character
                    if ($Number) {
                        if ($KeyChar -match $OnlyNumbers) {
                            $Result = $Result | Invoke-InsertString $KeyChar -At ($Left - $StartPosition)
                            Invoke-OutputDraw -Output $Result -Left $Left
                        }
                    } else {
                        $Result = $Result | Invoke-InsertString $KeyChar -At ($Left - $StartPosition)
                        Invoke-OutputDraw -Output $Result -Left $Left
                    }
                } else {
                    # append character
                    if ($Number) {
                        if ($KeyChar -match $OnlyNumbers) {
                            $Result += $KeyChar
                            $ShouldHighlight = ($MaxLength -gt 0) -and [Console]::CursorLeft -gt ($StartPosition + $MaxLength - 1)
                            Write-Color (Format-Output $KeyChar) -NoNewLine -Red:$ShouldHighlight
                            if ($Autocomplete) {
                                Update-Autocomplete -Output ($Result -as [String])
                            }
                        }
                    } else {
                        $Result += $KeyChar
                        $ShouldHighlight = ($MaxLength -gt 0) -and [Console]::CursorLeft -gt ($StartPosition + $MaxLength - 1)
                        Write-Color (Format-Output $KeyChar) -NoNewLine -Red:$ShouldHighlight
                        if ($Autocomplete) {
                            Update-Autocomplete -Output ($Result -as [String])
                        }
                    }
                }
            }
        }
        if ($Result.Length -eq 0) {
            Write-Placeholder
            [Console]::SetCursorPosition($StartPosition, [Console]::CursorTop)
        }
    } until ($KeyInfo.Key -eq 'Enter' -or $KeyInfo.Key -eq 'Escape')
    Write-Color ''
    if ($KeyInfo.Key -ne 'Escape') {
        if ($Number) {
            $Result -as [Int]
        } else {
            if ($MaxLength -gt 0) {
                $Result.Substring(0, [Math]::Min($Result.Length, $MaxLength))
            } else {
                $Result
            }
        }
    } else {
        $Null
    }
}
function Invoke-Menu {
    <#
    .SYNOPSIS
    Create custimizable and interactive single, multi-select, or single-select list menu.
    .DESCRIPTION
    Default Controls:
      - Select item with ENTER key
      - Move up with UP arrow key
      - Move DOWN with down arrow key or TAB key
      - Multi-select and single-select with SPACE key
      - Next page with RIGHT arrow key (see Limit help)
      - Previous page with LEFT arrow key (see Limit help)

    Vim Controls (using -Vim parameter):
      - Select item with ENTER key
      - Move up with "j" key
      - Move DOWN with "k" key
      - Multi-select and single-select with SPACE key
      - Next page with 'l' key (see Limit help)
      - Previous page with 'h' key (see Limit help)
    .PARAMETER ReturnIndex
    Return the index of the selected item within the array of items.
    Note: If ReturnIndex is used with pagination (see Limit help), the index within the visible items will be returned.
    .PARAMETER Limit
    Maximum number of items per page
    If Limit is greater than zero and less than the number of items, pagination will be activated with "Limit" number of items per page.
    Note: When Limit is larger than the number of menu items, the menu will behave as though no limit value was passed.
    .PARAMETER FolderContent
    Use this switch to populate the menu with folder contents of current directory (see examples)
    .PARAMETER SelectedMarker
    Use custom string to indicate which item is selected.
    Note: The NoMarker parameter overrides this parameter.
    .PARAMETER Vim
    Use Vim hotkeys for up, down, left, and right navigation.
    .PARAMETER Unwrap
    For items that are formatted with handlebar helper syntax, return unwrapped value when selected
    .EXAMPLE
    Invoke-Menu 'one','two','three'
    .EXAMPLE
    Invoke-Menu 'one','two','three' -HighlightColor Blue -NoMarker

    # Change the highlight color and remove the marker
    .EXAMPLE
    'one','two','three' | Invoke-Menu -MultiSelect -ReturnIndex | Sort-Object
    .EXAMPLE
    1, 2, 3, 4, 5 | menu
    .EXAMPLE
    1..10 | menu -SingleSelect

    # The SingleSelect switch allows for only one item to be selected at a time (like a radio input)
    .EXAMPLE
    1..100 | menu -Limit 10

    # Create paginated lists using the -Limit parameter
    .EXAMPLE
    Invoke-Menu -FolderContent | Invoke-Item

    # Open a folder via an interactive list menu populated with folder content
    .EXAMPLE
    '{{#red red}}','white','{{#blue blue}}' | menu -Unwrap

    # Unwrap formatted values
    #>
    [CmdletBinding()]
    [Alias('menu')]
    Param(
        [Parameter(Position = 0, ValueFromPipeline = $True)]
        [Array] $Items,
        [Switch] $MultiSelect,
        [Switch] $SingleSelect,
        [ValidateSet('White', 'Black', 'DarkBlue', 'DarkGreen', 'DarkCyan', 'DarkRed', 'DarkMagenta', 'DarkYellow', 'Gray', 'DarkGray', 'Blue', 'Green', 'Cyan', 'Red', 'Magenta', 'Yellow')]
        [String] $HighlightColor = 'Cyan',
        [Switch] $ReturnIndex = $False,
        [Switch] $FolderContent,
        [Int] $Limit = 0,
        [Int] $Indent = 2,
        [String] $SelectedMarker = '>  ',
        [Switch] $NoMarker,
        [Switch] $Vim,
        [Switch] $Unwrap
    )
    Begin {
        $ModeWidth = 8
        $SizeWidth = 8
        function Invoke-MenuDraw {
            Param(
                [Array] $VisibleItems,
                [Int] $Position,
                [Int] $PageNumber,
                [Array] $Selection,
                [Switch] $MultiSelect,
                [Switch] $SingleSelect,
                [Switch] $ShowHeader,
                [Int] $Indent = 0
            )
            $Index = 0
            $LengthValues = $Items | Remove-HandlebarsHelper | ForEach-Object { $_.ToString().Length }
            $MaxLength = (Get-Maximum $LengthValues) + $ModeWidth
            $MinLength = Get-Minimum $LengthValues
            $Clear = ' ' | Invoke-Repeat -Times ($MaxLength - $MinLength) | Invoke-Reduce -Add
            $LeftPadding = ' ' | Invoke-Repeat -Times $Indent | Invoke-Reduce -Add
            if ($ShowHeader) {
                $TextLength = $TotalPages.ToString().Length
                $CurrentPage = ($PageNumber + 1).ToString().PadLeft($TextLength, '0')
                "${LeftPadding}<<prev  {{#${HighlightColor} ${CurrentPage}}}/${TotalPages}  next>>" | Write-Color -DarkGray
                $Clear | Write-Color -Cyan
            }
            $Output = ''
            foreach ($Item in $VisibleItems) {
                if ($Null -ne $Item) {
                    $ModularIndex = ($PageNumber * $Limit) + $Index
                    if ($MultiSelect) {
                        $Item = if ($Selection -contains $ModularIndex) { "[x] $Item$Clear" } else { "[ ] $Item$Clear" }
                    } else {
                        if ($SingleSelect) {
                            $Item = if ($Selection -contains $ModularIndex) { "(o) $Item$Clear" } else { "( ) $Item$Clear" }
                        }
                    }
                    $IsSelected = $Index -eq $Position
                    $Marker = if ($NoMarker) {
                        ''
                    } else {
                        if ($IsSelected) { $SelectedMarker } else { ' ' * $SelectedMarker.Length }
                    }
                    $Text = if ($IsSelected) {
                        # TODO: Figure out how to enable selected highlighting
                        # $Item | Remove-HandlebarsHelper
                        if ($FolderContent) {
                            $Item
                        } else {
                            "{{#${HighlightColor} ${Item}}}"
                        }
                    } else {
                        $Item
                    }
                    $Output += if ($Index -eq 0) {
                        "${LeftPadding}${Marker}${Text}${Clear}"
                    } else {
                        "`n${LeftPadding}${Marker}${Text}${Clear}"
                    }
                }
                $Index++
            }
            $Output | Write-Color
        }
        function Update-MenuSelection {
            Param(
                [Int] $Position,
                [Int] $PageNumber,
                [Array] $Selection,
                [Switch] $MultiSelect,
                [Switch] $SingleSelect
            )
            $ModularPosition = (($PageNumber * $Limit) + $Position)
            if ($Selection -contains $ModularPosition) {
                $Result = $Selection | Where-Object { $_ -ne $ModularPosition }
            } else {
                if ($MultiSelect) {
                    $Selection += $ModularPosition
                } else {
                    $Selection = , $ModularPosition
                }
                $Result = $Selection
            }
            $Result
        }
        [Console]::CursorVisible = $False
        $LeftCode = if ($Vim) { 72 } else { 37 }
        $UpCode = if ($Vim) { 74 } else { 38 }
        $DownCode = if ($Vim) { 75 } else { 40 }
        $RightCode = if ($Vim) { 76 } else { 39 }
        $Keycodes = @{
            enter = 13
            escape = 27
            left = $LeftCode
            right = $RightCode
            space = 32
            tab = 9
            up = $UpCode
            down = $DownCode
        }
        $Keycode = 0
        $Position = 0
        $Selection = @()
    }
    End {
        if ($Input.Length -gt 0) {
            $Items = $Input
        }
        if ($FolderContent) {
            $Unwrap = $True
            $Padding = ' '
            $Spacer = $Padding | Invoke-Repeat -Times $SizeWidth | Invoke-Reduce -Add
            $Folders = Get-ChildItem -Directory | ForEach-Object {
                $Mode = $_.Mode | Format-MinimumWidth $ModeWidth -Padding $Padding
                "{{#darkGray ${Mode}}} ${Spacer} {{#magenta $($_.Name)/}}"
            }
            $Files = Get-ChildItem -File | ForEach-Object {
                $Mode = $_.Mode | Format-MinimumWidth $ModeWidth -Padding $Padding
                $Size = $_.Length | Format-FileSize | Format-MinimumWidth $SizeWidth -Align Right -Padding $Padding
                "{{#darkGray ${Mode}}} {{#darkGray ${Size}}} $($_.Name)"
            }
            $Items = $Folders + $Files
        }
        $PageNumber = 0
        $TotalPages = if ($Limit -eq 0) { 1 } else { [Math]::Ceiling($Items.Length / $Limit) }
        $ShouldPaginate = $Limit -in 1..($Items.Count - 1)
        $OriginalItems = $Items
        if ($ShouldPaginate) {
            $ExtraItemCount = $Limit - ($Items.Count % $Limit)
            for ($Index = 0; $Index -lt $ExtraItemCount; $Index++) {
                $Items += '...'
            }
        }
        $VisibleItems = if ($ShouldPaginate) {
            $StartIndex = $PageNumber * $Limit
            $Items[$StartIndex..($StartIndex + $Limit - 1)]
        } else {
            $Items
        }
        [Console]::SetCursorPosition(0, [Console]::CursorTop)
        $Parameters = @{
            VisibleItems = $VisibleItems
            Position = $Position
            Selection = $Selection
            MultiSelect = $MultiSelect
            SingleSelect = $SingleSelect
            ShowHeader = $ShouldPaginate
            PageNumber = $PageNumber
            Indent = $Indent
        }
        Invoke-MenuDraw @Parameters
        while ($Keycode -notin $Keycodes.enter, $Keycodes.escape) {
            $Keycode = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown').virtualkeycode
            switch ($Keycode) {
                $Keycodes.escape {
                    $Position = $Null
                }
                $Keycodes.space {
                    $Parameters = @{
                        Position = $Position
                        PageNumber = $PageNumber
                        Selection = $Selection
                        MultiSelect = $MultiSelect
                        SingleSelect = $SingleSelect
                    }
                    $Selection = Update-MenuSelection @Parameters
                }
                $Keycodes.tab {
                    if (-not $Vim) {
                        $Position = ($Position + 1) % $VisibleItems.Length
                    }
                }
                $Keycodes.up {
                    if ($Limit -in 1..($Items.Count - 1) -and $TotalPages -gt 1) {
                        $StartIndex = $PageNumber * $Limit
                        $VisibleItems = $Items[$StartIndex..($StartIndex + $Limit - 1)]
                    }
                    $Position = (($Position - 1) + $VisibleItems.Length) % $VisibleItems.Length
                }
                $Keycodes.down {
                    if ($Limit -in 1..($Items.Count - 1) -and $TotalPages -gt 1) {
                        $StartIndex = $PageNumber * $Limit
                        $VisibleItems = $Items[$StartIndex..($StartIndex + $Limit - 1)]
                    }
                    $Position = ($Position + 1) % $VisibleItems.Length
                }
                $Keycodes.left {
                    if ($Limit -in 1..($Items.Count - 1) -and $TotalPages -gt 1) {
                        $PageNumber = (($PageNumber - 1) + $TotalPages) % $TotalPages
                        $StartIndex = $PageNumber * $Limit
                        $VisibleItems = $Items[$StartIndex..($StartIndex + $Limit - 1)]
                    }
                }
                $Keycodes.right {
                    if ($Limit -in 1..($Items.Count - 1) -and $TotalPages -gt 1) {
                        $PageNumber = ($PageNumber + 1) % $TotalPages
                        $StartIndex = $PageNumber * $Limit
                        $VisibleItems = $Items[$StartIndex..($StartIndex + $Limit - 1)]
                    }
                }
            }
            If ($Null -ne $Position) {
                $StartPosition = if ($ShouldPaginate) {
                    [Console]::CursorTop - $VisibleItems.Count - 2
                } else {
                    [Console]::CursorTop - $Items.Count
                }
                [Console]::SetCursorPosition(0, $StartPosition)
                $Parameters = @{
                    VisibleItems = $VisibleItems
                    Position = $Position
                    Selection = $Selection
                    MultiSelect = $MultiSelect
                    SingleSelect = $SingleSelect
                    ShowHeader = $ShouldPaginate
                    PageNumber = $PageNumber
                    Indent = $Indent
                }
                Invoke-MenuDraw @Parameters
            }
        }
        [Console]::CursorVisible = $True
        if ($Null -eq $Position) {
            return $Null
        }
        $AbsolutePosition = $Position + ($PageNumber * $Limit)
        $Output = if ($ReturnIndex) {
            if ($MultiSelect -or $SingleSelect) {
                $Selection | Where-Object { $_ -lt $OriginalItems.Count }
            } else {
                $AbsolutePosition
            }
        } else {
            if ($MultiSelect -or $SingleSelect) {
                if ($Selection.Length -gt 0) {
                    $OriginalItems[$Selection]
                } else {
                    $Null
                }
            } else {
                $OriginalItems[$AbsolutePosition]
            }
        }
        if ($FolderContent) {
            $NotSpace = { Param($X) $X -ne ' ' }
            $Output = $Output |
                Remove-HandlebarsHelper |
                Invoke-Method 'Substring' $ModeWidth |
                Invoke-DropWhile $NotSpace |
                Invoke-Method 'Trim'
        }
        if ($Unwrap) {
            $Output | Remove-HandlebarsHelper
        } else {
            $Output
        }
    }
}
function Remove-HandlebarsHelper {
    <#
    .SYNOPSIS
    Unwrap template string
    .EXAMPLE
    '{{#red Hello World}}' | Remove-HandlebarsHelper
    # Hello World
    #>
    [CmdletBinding()]
    [OutputType([String])]
    Param(
        [Parameter(Position = 0, ValueFromPipeline = $True)]
        [String] $Value
    )
    Begin {
        $Pattern = '(?<HELPER>){{(?<indicator>(=|-|#)) *((?!}}).)*}}'
    }
    Process {
        $Result = ''
        $Position = 0
        $Value | Select-String -Pattern $Pattern -AllMatches | ForEach-Object Matches | ForEach-Object {
            $Result += $Value.Substring($Position, $_.Index - $Position)
            $HelperTemplate = $Value.Substring($_.Index, $_.Length)
            $Arr = $HelperTemplate | ForEach-Object { $_ -replace '{{#', '' } | ForEach-Object { $_ -replace ' *}}', '' } | ForEach-Object { $_ -split ' +' }
            $Result += ($Arr[1..$Arr.Length] -join ' ')
            $Position = $_.Index + $_.Length
        }
        if ($Position -lt $Value.Length) {
            $Result += $Value.Substring($Position, $Value.Length - $Position)
        }
        $Result
    }
}
function Write-BarChart {
    <#
    .SYNOPSIS
    Function to create horizontal bar chart of passed data object
    .PARAMETER Width
    Maximum value used for data normization. Also corresponds to actual width of longest bar (in characters)
    .PARAMETER Alternate
    Alternate row color between light and dark.
    .PARAMETER ShowValues
    Whether or not to show data values to right of each bar
    .EXAMPLE
    @{ red = 55; white = 30; blue = 200 } | Write-BarChart -WithColor -ShowValues
    .EXAMPLE
    Write-Title 'Colors'
    @{ red = 55; white = 30; blue = 200 } | Write-BarChart -Alternate -ShowValues
    Write-Color ''

    # Can be used with Write-Title to create goo looking reports in the terminal
    .EXAMPLE
    Get-ChildItem -File | Invoke-Reduce -FileInfo | Write-BarChart -ShowValues -WithColor

    # Easily display a bar chart of files using Invoke-Reduce
    .EXAMPLE
    1..8 | matrix 4,2 | Write-BarChart

    # Use a 2-column matrix as input (names must be numbers)
    .EXAMPLE
    'red', 55, 'white', 30, 'blue', 200 | Write-BarChart

    # Use an array of values as input - name, value, name, value, etc...
    .EXAMPLE
    @('red', 'white', 'blue'), @(55, 30, 200) | zip | Write-BarChart

    # Works with the output of zip too
    #>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $True, Position = 0, ValueFromPipeline = $True)]
        $InputObject,
        [Int] $Width = 100,
        [Switch] $ShowValues,
        [Switch] $Alternate,
        [Switch] $WithColor
    )
    Begin {
        $Tee = ([Char]9508).ToString()
        $Marker = ([Char]9608).ToString()
        function Write-Bar {
            Param(
                [String] $Name,
                [Int] $Value,
                [Int] $Index,
                [String] $LongestName = '#',
                [Int] $LargestValue = 1
            )
            $NormalizedValue = ($Value / $LargestValue) * $Width
            $Bar = $Marker | Invoke-Repeat -Times $NormalizedValue | Invoke-Reduce -Add
            $ValueLabel = if ($ShowValues) { " $Value" } else { '' }
            $IsEven = ($Index % 2) -eq 0
            if ($WithColor) {
                $Color = @{
                    Cyan = $($IsEven -and $Alternate)
                    DarkCyan = $((-not $IsEven -and $Alternate) -or (-not $Alternate))
                }
            } else {
                $Color = @{
                    White = $($IsEven -and $Alternate)
                    Gray = $(-not $IsEven -and $Alternate)
                }
            }
            $PaddedName = $Name.PadLeft($LongestName.Length, ' ')
            " {{#white $PaddedName $Tee}}$Bar" | Write-Color @Color -NoNewLine
            $ValueLabel | Write-Color @Color
        }
    }
    End {
        $Index = 0
        if ($Input.Count -gt 1) {
            $Names, $Values = $Input | Invoke-Flatten | Invoke-Chunk -Size 2 | Invoke-Unzip
            $LongestName = $Names | Sort-Object { $_.ToString().Length } -Descending | Select-Object -First 1
            $LargestValue = $Values | Get-Maximum
            $Data = for ($Index = 0; $Index -lt $Names.Count; ++$Index) {
                @{
                    Name = $Names[$Index]
                    Value = $Values[$Index]
                }
            }
            $Data | Sort-Object { $_.Value } | ForEach-Object {
                $Name = $_.Name
                $Value = $_.Value
                Write-Bar -Name $Name -Value $Value -Index ($Index++) -LongestName $LongestName -LargestValue $LargestValue
            }
        } else {
            switch ($InputObject.GetType().Name) {
                'Matrix' {
                    $Columns = $InputObject.Columns()
                    $LongestName = $Columns[0].Real | Sort-Object { $_.ToString().Length } -Descending | Select-Object -First 1
                    $LargestValue = $Columns[1].Real | Get-Maximum
                    $InputObject.Rows | Sort-Object { $_[1].Real } | ForEach-Object {
                        $Name, $Value = $_.Real
                        Write-Bar -Name $Name -Value $Value -Index ($Index++) -LongestName $LongestName -LargestValue $LargestValue
                    }
                }
                Default {
                    $Data = [PSCustomObject]$InputObject
                    $LongestName = $Data.PSObject.Properties.Name | Sort-Object { $_.Length } -Descending | Select-Object -First 1
                    $LargestValue = $Data.PSObject.Properties | Select-Object -ExpandProperty Value | Sort-Object -Descending | Select-Object -First 1
                    $Data.PSObject.Properties | Sort-Object { $_.Value } | ForEach-Object {
                        $Name = $_.Name
                        $Value = $_.Value
                        Write-Bar -Name $Name -Value $Value -Index ($Index++) -LongestName $LongestName -LargestValue $LargestValue
                    }
                }
            }
        }
    }
}
function Write-Color {
    <#
    .SYNOPSIS
    Basically Write-Host with the ability to color parts of the output by using template strings
    .PARAMETER Color
    Performs the function Write-Host's -ForegroundColor. Useful for programmatically setting text color.
    .EXAMPLE
    '{{#red this will be red}} and {{#blue this will be blue}}' | Write-Color
    .EXAMPLE
    'You can color entire string using switch parameters' | Write-Color -Green
    .EXAMPLE
    'You can color entire string using Color parameter' | Write-Color -Color Green
    .EXAMPLE
    '{{#green Hello}} {{#blue {{ name }}}}' |
        New-Template -Data @{ name = 'World' } |
        Write-Color
    #>
    [CmdletBinding()]
    [OutputType([Void])]
    [OutputType([String])]
    Param(
        [Parameter(Mandatory = $True, ValueFromPipeline = $True)]
        [AllowEmptyString()]
        [String] $Text,
        [ValidateSet('White', 'Black', 'DarkBlue', 'DarkGreen', 'DarkCyan', 'DarkRed', 'DarkMagenta', 'DarkYellow', 'Gray', 'DarkGray', 'Blue', 'Green', 'Cyan', 'Red', 'Magenta', 'Yellow')]
        [String] $Color,
        [Switch] $NoNewLine,
        [Switch] $Black,
        [Switch] $Blue,
        [Switch] $DarkBlue,
        [Switch] $DarkGreen,
        [Switch] $DarkCyan,
        [Switch] $DarkGray,
        [Switch] $DarkRed,
        [Switch] $DarkMagenta,
        [Switch] $DarkYellow,
        [Switch] $Cyan,
        [Switch] $Gray,
        [Switch] $Green,
        [Switch] $Red,
        [Switch] $Magenta,
        [Switch] $Yellow,
        [Switch] $White,
        [Switch] $PassThru
    )
    if ($Text.Length -eq 0) {
        Write-Host '' -NoNewline:$NoNewLine
    } else {
        if (-not $Color) {
            $Color = Find-FirstTrueVariable 'White', 'Black', 'DarkBlue', 'DarkGreen', 'DarkCyan', 'DarkRed', 'DarkMagenta', 'DarkYellow', 'Gray', 'DarkGray', 'Blue', 'Green', 'Cyan', 'Red', 'Magenta', 'Yellow'
        }
        $Position = 0
        $Text | Select-String -Pattern '(?<HELPER>){{#((?!}}).)*}}' -AllMatches | ForEach-Object Matches | ForEach-Object {
            Write-Host $Text.Substring($Position, $_.Index - $Position) -ForegroundColor $Color -NoNewline
            $HelperTemplate = $Text.Substring($_.Index, $_.Length)
            $Arr = $HelperTemplate | ForEach-Object { $_ -replace '{{#', '' } | ForEach-Object { $_ -replace '}}', '' } | ForEach-Object { $_ -split ' ' }
            Write-Host ($Arr[1..$Arr.Length] -join ' ') -ForegroundColor $Arr[0] -NoNewline
            $Position = $_.Index + $_.Length
        }
        if ($Position -lt $Text.Length) {
            Write-Host $Text.Substring($Position, $Text.Length - $Position) -ForegroundColor $Color -NoNewline:$NoNewLine
        }
    }
    if ($PassThru) {
        $Text
    }
}
function Write-Label {
    <#
    .SYNOPSIS
    Meant to be used with Invoke-Input or Invoke-Menu
    .EXAMPLE
    Write-Label 'Favorite number?' -NewLine
    $Choice = menu @('one'; 'two'; 'three')
    .EXAMPLE
    '{{#red Message? }}' | Write-Label -NewLine

    # Labels can be customized using mustache color helper templates
    #>
    [CmdletBinding()]
    Param(
        [Parameter(Position = 0, ValueFromPipeline = $True)]
        [String] $Text = 'label',
        [ValidateSet('White', 'Black', 'DarkBlue', 'DarkGreen', 'DarkCyan', 'DarkRed', 'DarkMagenta', 'DarkYellow', 'Gray', 'DarkGray', 'Blue', 'Green', 'Cyan', 'Red', 'Magenta', 'Yellow')]
        [String] $Color = 'Cyan',
        [Int] $Indent = 0,
        [Switch] $NewLine
    )
    Write-Color (' ' * $Indent) -NoNewLine
    Write-Color "$Text " -Color $Color -NoNewLine:$(-not $NewLine)
}
function Write-Title {
    <#
    .SYNOPSIS
    Function to print text with a border. Useful for displaying section titles for CLI apps.
    .PARAMETER Template
    Tells Write-Title to expect mustache color templates (see Get-Help Write-Color -Examples)
    .PARAMETER Fallback
    Use "+" and "-" to draw title border
    .PARAMETER Indent
    Add spaces to left of title box to align with input elements
    .EXAMPLE
    'Hello World' | Write-Title
    .EXAMPLE
    'Hello World' | Write-Title -Green

    # Easily change border and title text color
    .EXAMPLE
    'Hello World' | Write-Title -Width 20 -TextColor Red

    # Change only the color of title text with -TextColor
    .EXAMPLE
    'Hello World' | Write-Title -Width 20

    # Titles can have set widths
    .EXAMPLE
    'Hello World' | Write-Title -Fallback

    # If your terminal does not have the fancy characters needed for a proper border, fallback to "+" and "-"
    .EXAMPLE
    '{{#magenta Hello}} World' | Write-Title -Template

    # Write-Title accepts same input as Write-Color and can be used to customize title text.
    #>
    [CmdletBinding()]
    [Alias('title')]
    [OutputType([Void])]
    [OutputType([String])]
    Param(
        [Parameter(Mandatory = $True, Position = 0, ValueFromPipeline = $True)]
        [String] $Text,
        [String] $TextColor,
        [String] $SubText = '',
        [Switch] $Template,
        [Switch] $Fallback,
        [Switch] $Blue,
        [Switch] $Cyan,
        [Switch] $DarkBlue,
        [Switch] $DarkCyan,
        [Switch] $DarkGreen,
        [Switch] $DarkGray,
        [Switch] $DarkRed,
        [Switch] $DarkMagenta,
        [Switch] $DarkYellow,
        [Switch] $Green,
        [Switch] $Magenta,
        [Switch] $Red,
        [Switch] $White,
        [Switch] $Yellow,
        [Int] $Width,
        [Int] $Indent = 0,
        [Switch] $PassThru
    )
    if ($Template) {
        $TextLength = ($Text -replace '{{#\w*\s', '' | ForEach-Object { $_ -replace '}}', '' }).Length
    } else {
        $TextLength = $Text.Length
    }
    if ($Width -lt $TextLength) {
        $Width = $TextLength + 4
    }
    $Space = ' '
    if ($Fallback) {
        $TopLeft = '+'
        $TopEdge = '-'
        $TopRight = '+'
        $LeftEdge = $RightEdge = '|'
        $BottomLeft = '+'
        $BottomEdge = $TopEdge
        $BottomRight = '+'
    } else {
        $TopLeft = [Char]9484
        $TopEdge = [Char]9472
        $TopRight = [Char]9488
        $LeftEdge = $RightEdge = [Char]9474
        $BottomLeft = [Char]9492
        $BottomEdge = $TopEdge
        $BottomRight = [Char]9496
    }
    $PaddingLength = [Math]::Floor(($Width - $TextLength - 2) / 2)
    $Padding = $Space | Invoke-Repeat -Times $PaddingLength | Invoke-Reduce -Add
    $WidthInside = (2 * $PaddingLength) + $TextLength
    $BorderColor = @{
        Cyan = $Cyan
        Red = $Red
        Blue = $Blue
        Green = $Green
        Yellow = $Yellow
        Magenta = $Magenta
        White = $White
        DarkBlue = $DarkBlue
        DarkGreen = $DarkGreen
        DarkGray = $DarkGray
        DarkCyan = $DarkCyan
        DarkRed = $DarkRed
        DarkMagenta = $DarkMagenta
        DarkYellow = $DarkYellow
    }
    $TitleIndent = $Space | Invoke-Repeat -Times $Indent | Invoke-Reduce -Add
    $TitleTopLine = "$TopEdge" | Invoke-Repeat -Times ($WidthInside + 2) | Invoke-Reduce -Add
    $TitleBottomLine = "$BottomEdge" | Invoke-Repeat -Times ($WidthInside - $SubText.Length + 2) | Invoke-Reduce -Add
    Write-Color "$TitleIndent$TopLeft$TitleTopLine$TopRight" @BorderColor
    if ($TextColor) {
        Write-Color "$TitleIndent$LeftEdge$Padding{{#$TextColor $Text}}$Padding$RightEdge" @BorderColor
    } else {
        Write-Color "$TitleIndent$LeftEdge$Padding$Text$Padding$RightEdge" @BorderColor
    }
    Write-Color "$TitleIndent$BottomLeft$TitleBottomLine$SubText$BottomRight" @BorderColor
    if ($PassThru) {
        $Text
    }
}