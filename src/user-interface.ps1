function Invoke-Input {
  <#
  .SYNOPSIS
  A fancy Read-Host replacement meant to be used to make CLI applications.
  .PARAMETER Secret
  Displayed characters are replaced with asterisks
  .PARAMETER Number
  Switch to designate input is numerical
  .EXAMPLE
  $fullname = input 'Full Name?'
  $username = input 'Username?' -MaxLength 10 -Indent 4
  $age = input 'Age?' -Number -MaxLength 2 -Indent 4
  $pass = input 'Password?' -Secret -Indent 4
  .EXAMPLE
  $word = input 'Favorite Saiya-jin?' -Indent 4 -Autocomplete -Choices `
  @(
      'Goku'
      'Gohan'
      'Goten'
      'Vegeta'
      'Trunks'
  )

  Autocomplete will make suggestions. Press tab once to select suggestion, press tab again to cycle through matches.
  .EXAMPLE
  Invoke-Input 'Folder name?' -Autocomplete -Choices (Get-ChildItem -Directory | Select-Object -ExpandProperty Name)

  Leverage autocomplete to input a folder name
  .EXAMPLE
  $name = input 'What is your {{#blue name}}?'

  Input labels can be customized with mustache color helpers
  #>
  [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', 'global:PreviousRegularExpression')]
  [CmdletBinding()]
  [Alias('input')]
  Param(
    [Parameter(Position=0, ValueFromPipeline=$true)]
    [String] $LabelText = 'input:',
    [Switch] $Secret,
    [Switch] $Number,
    [Switch] $Autocomplete,
    [Array] $Choices,
    [Int] $Indent,
    [Int] $MaxLength = 0
  )
  Write-Label -Text $LabelText -Indent $Indent
  $Global:PreviousRegularExpression = $null
  $Result = ''
  $CurrentIndex = 0
  $AutocompleteMatches = @()
  $StartPosition = [Console]::CursorLeft
  function Format-Output {
    Param(
      [Parameter(Mandatory=$true, Position=0)]
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
      [Parameter(Mandatory=$true, Position=0)]
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
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', 'global:PreviousRegularExpression')]
    Param(
      [AllowEmptyString()]
      [String] $Output
    )
    $Global:PreviousRegularExpression = "^${Output}"
    $AutocompleteMatches = $Choices | Where-Object { $_ -match $Global:PreviousRegularExpression }
    if ($null -eq $AutocompleteMatches -or $Output.Length -eq 0) {
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
  Do  {
    $KeyInfo = [Console]::ReadKey($true)
    $KeyChar = $KeyInfo.KeyChar
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
      'DownArrow' {
        if ($Number) {
          $Value = ($Result -as [Int]) - 1
          if (($MaxLength -eq 0) -or ($MaxLength -gt 0 -and $Value -gt -[Math]::Pow(10, $MaxLength))) {
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
        if ($Autocomplete -and $Result.Length -gt 0 -and -not ($Number -or $Secret) -and $null -ne $AutocompleteMatches) {
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
        if ($Left -eq $StartPosition) {# prepend character
          if ($Number) {
            if ($KeyChar -match $OnlyNumbers) {
              $Result = "${KeyChar}$Result"
              Invoke-OutputDraw -Output (Format-Output $Result) -Left $Left
            }
          } else {
            $Result = "${KeyChar}$Result"
            Invoke-OutputDraw -Output (Format-Output $Result) -Left $Left
          }
        } elseif ($Left -gt $StartPosition -and $Left -lt ($StartPosition + $Result.Length)) {# insert character
          if ($Number) {
            if ($KeyChar -match $OnlyNumbers) {
              $Result = $KeyChar | Invoke-InsertString -To $Result -At ($Left - $StartPosition)
              Invoke-OutputDraw -Output $Result -Left $Left
            }
          } else {
            $Result = $KeyChar | Invoke-InsertString -To $Result -At ($Left - $StartPosition)
            Invoke-OutputDraw -Output $Result -Left $Left
          }
        } else {# append character
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
  } Until ($KeyInfo.Key -eq 'Enter' -or $KeyInfo.Key -eq 'Escape')
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
    $null
  }
}
function Invoke-Menu {
  <#
  .SYNOPSIS
  Create interactive single, multi-select, or single-select list menu.

  Controls:
  - Select item with ENTER key
  - Move up with up arrow key
  - Move down with down arrow key or TAB key
  - Multi-select and single-select with SPACE key
  .PARAMETER FolderContent
  Use this switch to populate the menu with folder contents of current directory (see examples)
  .EXAMPLE
  Invoke-Menu 'one','two','three'
  .EXAMPLE
  Invoke-Menu 'one','two','three' -HighlightColor Blue
  .EXAMPLE
  'one','two','three' | Invoke-Menu -MultiSelect -ReturnIndex | Sort-Object
  .EXAMPLE
  1,2,3,4,5 | menu
  .EXAMPLE
  1..10 | menu -SingleSelect

  The SingleSelect switch allows for only one item to be selected at a time
  .EXAMPLE
  Invoke-Menu -FolderContent | Invoke-Item

  Open a folder via an interactive list menu populated with folder content
  #>
  [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'HighlightColor')]
  [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseOutputTypeCorrectly', '')]
  [CmdletBinding()]
  [Alias('menu')]
  Param (
    [Parameter(Position=0, ValueFromPipeline=$true)]
    [Array] $Items,
    [Switch] $MultiSelect,
    [Switch] $SingleSelect,
    [String] $HighlightColor = 'cyan',
    [Switch] $ReturnIndex = $false,
    [Switch] $FolderContent,
    [Int] $Indent = 0
  )
  Begin {
    function Invoke-MenuDraw {
      [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '', Scope='Function')]
      [CmdletBinding()]
      Param (
        [Array] $Items,
        [Int] $Position,
        [Array] $Selection,
        [Switch] $MultiSelect,
        [Switch] $SingleSelect,
        [Int] $Indent = 0
      )
      $Index = 0
      $Items | ForEach-Object {
        $Item = $_
        if ($null -ne $Item) {
          if ($MultiSelect) {
            $Item = if ($Selection -contains $Index) { "[x] $Item" } else { "[ ] $Item" }
          } else {
            if ($SingleSelect) {
              $Item = if ($Selection -contains $Index) { "(o) $Item" } else { "( ) $Item" }
            }
          }
          if ($Index -eq $Position) {
            Write-Color "$(' ' * $Indent)> $Item" -Color $HighlightColor
          } else {
            Write-Color "$(' ' * $Indent)  $Item"
          }
        }
        $Index++
      }
    }
    function Update-MenuSelection {
      [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'SingleSelect')]
      [CmdletBinding()]
      Param (
        [Int] $Position,
        [Array] $Selection,
        [Switch] $MultiSelect,
        [Switch] $SingleSelect
      )
      if ($Selection -contains $Position) {
        $Result = $Selection | Where-Object { $_ -ne $Position }
      } else {
        if ($MultiSelect) {
          $Selection += $Position
        } else {
          $Selection = ,$Position
        }
        $Result = $Selection
      }
      $Result
    }
    [Console]::CursorVisible = $false
    $Keycodes = @{
      enter = 13
      escape = 27
      space = 32
      tab = 9
      up = 38
      down = 40
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
      $Items = Get-ChildItem -Directory | Select-Object -ExpandProperty Name | ForEach-Object { "$_/" }
      $Items += (Get-ChildItem -File | Select-Object -ExpandProperty Name)
    }
    Invoke-MenuDraw -Items $Items -Position $Position -Selection $Selection -MultiSelect:$MultiSelect -SingleSelect:$SingleSelect -Indent $Indent
    While ($Keycode -ne $Keycodes.enter -and $Keycode -ne $Keycodes.escape) {
      $Keycode = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown').virtualkeycode
      switch ($Keycode) {
        $Keycodes.escape {
          $Position = $null
        }
        $Keycodes.space {
          $Selection = Update-MenuSelection -Position $Position -Selection $Selection -MultiSelect:$MultiSelect -SingleSelect:$SingleSelect
        }
        $Keycodes.tab {
          $Position = ($Position + 1) % $Items.Length
        }
        $Keycodes.up {
          $Position = (($Position - 1) + $Items.Length) % $Items.Length
        }
        $Keycodes.down {
          $Position = ($Position + 1) % $Items.Length
        }
      }
      If ($null -ne $Position) {
        $StartPosition = [Console]::CursorTop - $Items.Length
        [Console]::SetCursorPosition(0, $StartPosition)
        Invoke-MenuDraw -Items $Items -Position $Position -Selection $Selection -MultiSelect:$MultiSelect -SingleSelect:$SingleSelect -Indent $Indent
      }
    }
    [Console]::CursorVisible = $true
    if ($ReturnIndex -eq $false -and $null -ne $Position) {
      if ($MultiSelect -or $SingleSelect) {
        if ($Selection.Length -gt 0) {
          return $Items[$Selection]
        } else {
          return $null
        }
      } else {
        return $Items[$Position]
      }
    } else {
      if ($MultiSelect -or $SingleSelect) {
        return $Selection
      } else {
        return $Position
      }
    }
  }
}
function Show-BarChart {
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
  @{red = 55; white = 30; blue = 200} | Show-BarChart -WithColor -ShowValues
  .EXAMPLE
  Write-Title 'Colors'
  @{red = 55; white = 30; blue = 200} | Show-BarChart -Alternate -ShowValues
  Write-Color ''

  Can be used with Write-Title to create goo looking reports in the terminal
  .EXAMPLE
  Get-ChildItem -File | Invoke-Reduce -FileInfo | Show-BarChart -ShowValues -WithColor

  Easily display a bar chart of files using Invoke-Reduce
  #>
  [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '', Scope='Function')]
  [CmdletBinding()]
  Param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [PSObject] $InputObject,
    [Int] $Width = 100,
    [Switch] $ShowValues,
    [Switch] $Alternate,
    [Switch] $WithColor
  )
  $Data = [PSCustomObject]$InputObject
  $Space = ' '
  $Tee = ([Char]9508).ToString()
  $Marker = ([Char]9608).ToString()
  $LargestValue = $Data.PSObject.Properties | Select-Object -ExpandProperty Value | Sort-Object -Descending | Select-Object -First 1
  $LongestNameLength = ($Data.PSObject.Properties.Name | Sort-Object { $_.Length } -Descending | Select-Object -First 1).Length
  $Index = 0
  $Data.PSObject.Properties | Sort-Object { $_.Value } | ForEach-Object {
    $Name = $_.Name
    $Value = ($_.Value / $LargestValue) * $Width
    $IsEven = ($Index % 2) -eq 0
    $Padding = $Space | Write-Repeat -Times ($LongestNameLength - $Name.Length)
    $Bar = $Marker | Write-Repeat -Times $Value
    $ValueLabel = & { if ($ShowValues) { " $($Data.$Name)" } else { '' } }
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
    "$Padding{{#white $Name $Tee}}$Bar" | Write-Color @Color -NoNewLine
    $ValueLabel | Write-Color @Color
    $Index++
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
  '{{#green Hello}} {{#blue {{ name }}}}' | New-Template -Data @{ name = 'World' } | Write-Color
  #>
  [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '', Scope='Function')]
  [Diagnostics.CodeAnalysis.SuppressMessageAttribute('AvoidUsingWriteHost', '', Scope='Function')]
  [CmdletBinding()]
  [OutputType([Void])]
  [OutputType([String])]
  Param(
    [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
    [AllowEmptyString()]
    [String] $Text,
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
      $Color = Find-FirstTrueVariable 'White','Black','DarkBlue','DarkGreen','DarkCyan','DarkRed','DarkMagenta','DarkYellow','Gray','DarkGray','Blue','Green','Cyan','Red','Magenta','Yellow'
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
  $choice = menu @('one'; 'two'; 'three')
  .EXAMPLE
  '{{#red Message? }}' | Write-Label -NewLine

  Labels can be customized using mustache color helper templates
  #>
  [CmdletBinding()]
  Param(
    [Parameter(Position=0, ValueFromPipeline=$true)]
    [String] $Text = 'label',
    [String] $Color = 'Cyan',
    [Int] $Indent = 0,
    [Switch] $NewLine
  )
  Write-Color (' ' * $Indent) -NoNewLine
  Write-Color "$Text " -Color $Color -NoNewLine:$(-not $NewLine)
}
function Write-Repeat {
  [CmdletBinding()]
  [Alias('repeat')]
  Param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [AllowEmptyString()]
    [String] $Value,
    [Parameter(Position=1)]
    [Alias('x')]
    [Int] $Times = 1
  )
  Process {
    Write-Output ($Value * $Times)
  }
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

  Easily change border and title text color
  .EXAMPLE
  'Hello World' | Write-Title -Width 20 -TextColor Red

  Change only the color of title text with -TextColor
  .EXAMPLE
  'Hello World' | Write-Title -Width 20

  Titles can have set widths
  .EXAMPLE
  'Hello World' | Write-Title -Fallback

  If your terminal does not have the fancy characters needed for a proper border, fallback to "+" and "-"
  .EXAMPLE
  '{{#magenta Hello}} World' | Write-Title -Template

  Write-Title accepts same input as Write-Color and can be used to customize title text.
  #>
  [CmdletBinding()]
  [Alias('title')]
  [OutputType([Void])]
  [OutputType([String])]
  Param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
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
  if ($Width -lt  $TextLength) {
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
  $Padding = $Space | Write-Repeat -Times $PaddingLength
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
    DarkCyan = $DarkCyan
    DarkRed = $DarkRed
    DarkMagenta = $DarkMagenta
    DarkYellow = $DarkYellow
  }
  Write-Color "$(Write-Repeat $Space -Times $Indent)$TopLeft$(Write-Repeat "$TopEdge" -Times $WidthInside)$TopRight" @BorderColor
  if ($TextColor) {
    Write-Color "$(Write-Repeat $Space -Times $Indent)$LeftEdge$Padding{{#$TextColor $Text}}$Padding$RightEdge" @BorderColor
  } else {
    Write-Color "$(Write-Repeat $Space -Times $Indent)$LeftEdge$Padding$Text$Padding$RightEdge" @BorderColor
  }
  Write-Color "$(Write-Repeat $Space -Times $Indent)$BottomLeft$(Write-Repeat "$BottomEdge" -Times ($WidthInside - $SubText.Length))$SubText$BottomRight" @BorderColor
  if ($PassThru) {
    $Text
  }
}