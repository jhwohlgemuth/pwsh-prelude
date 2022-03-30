[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingPlainTextforPassword', '', Scope = 'Function', Target = 'Import-Excel')]
Param()

# Nouns with the same singular and plural forms
$SameSingularPlural = @(
    'accommodation'
    'advice'
    'alms'
    'aircraft'
    'aluminum'
    'barracks'
    'bison'
    'binoculars'
    'bourgeois'
    'breadfruit'
    'buffalo'
    'cannon'
    'caribou'
    'chalk'
    'chassis'
    'chinos'
    'clippers'
    'clothing'
    'cod'
    'concrete'
    'corps'
    'correspondence'
    'crossroads'
    'data'
    'deer'
    'doldrums'
    'dungarees'
    'education'
    'eggfruit'
    'elk'
    'equipment'
    'eyeglasses'
    'fish'
    'flares'
    'flour'
    'food'
    'fruit'
    'furniture'
    'gallows'
    'goldfish'
    'grapefruit'
    'greenfly'
    'grouse'
    'haddock'
    'halibut'
    'head'
    'headquarters'
    'help'
    'homework'
    'hovercraft'
    'ides'
    'information'
    'insignia'
    'jackfruit'
    'jeans'
    'knickers'
    'knowledge'
    'kudos'
    'leggings'
    'lego'
    'luggage'
    'mathematics'
    'money'
    'moose'
    'monkfish'
    'mullet'
    'nailclippers'
    'news'
    'nitrogen'
    'offspring'
    'oxygen'
    'pants'
    'pyjamas'
    'passionfruit'
    'pike'
    'pliers'
    'police'
    'premises'
    'reindeer'
    'rendezvous'
    'rice'
    'salmon'
    'scissors'
    'series'
    'shambles'
    'sheep'
    'shellfish'
    'shorts'
    'shrimp'
    'smithereens'
    'spacecraft'
    'species'
    'squid'
    'staff'
    'starfruit'
    'statistics'
    'stone'
    'sugar'
    'swine'
    'tights'
    'tongs'
    'traffic'
    'trousers'
    'trout'
    'tuna'
    'tweezers'
    'wheat'
    'whitebait'
    'wood'
    'you'
)
# Nouns with irregular singular/plural forms
$Irregular = @{
    'child' = 'children'
    'cow' = 'cattle'
    'foot' = 'feet'
    'goose' = 'geese'
    'man' = 'men'
    'move' = 'moves'
    'person' = 'people'
    'radius' = 'radii'
    'sex' = 'sexes'
    'tooth' = 'teeth'
    'woman' = 'women'
}
function Format-MoneyValue {
    <#
    .SYNOPSIS
    Helper function to create human-readable money (USD) values as strings.
    .EXAMPLE
    42 | ConvertTo-MoneyString
    # Returns "$42.00"
    .EXAMPLE
    55000123.50 | ConvertTo-MoneyString -Symbol ¥
    # Returns '¥55,000,123.50'
    .EXAMPLE
    700 | ConvertTo-MoneyString -Symbol £ -Postfix
    # Returns '700.00£'
    #>
    [CmdletBinding()]
    [Alias('money')]
    [OutputType([String])]
    Param(
        [Parameter(Mandatory = $True, Position = 0, ValueFromPipeline = $True)]
        $Value,
        [String] $Symbol = '$',
        [Switch] $AsNumber,
        [Switch] $Postfix
    )
    Process {
        function Get-Magnitude {
            Param($Value)
            [Math]::Log([Math]::Abs($Value), 10)
        }
        switch -Wildcard ($Value.GetType()) {
            'Int*' {
                $Sign = [Math]::Sign($Value)
                $Output = [Math]::Abs($Value).ToString()
                $OrderOfMagnitude = Get-Magnitude $Value
                if ($OrderOfMagnitude -gt 3) {
                    $Position = 3
                    $Length = $Output.Length
                    for ($Index = 1; $Index -le [Math]::Floor($OrderOfMagnitude / 3); $Index++) {
                        $Output = $Output | Invoke-InsertString ',' -At ($Length - $Position)
                        $Position += 3
                    }
                }
                if ($Postfix) {
                    "$(if ($Sign -lt 0) { '-' } else { '' })${Output}.00$Symbol"
                } else {
                    "$(if ($Sign -lt 0) { '-' } else { '' })$Symbol${Output}.00"
                }
            }
            'Double' {
                $Sign = [Math]::Sign($Value)
                $Output = [Math]::Abs($Value).ToString('#.##')
                $OrderOfMagnitude = Get-Magnitude $Value
                if (($Output | ForEach-Object { $_ -split '\.' } | Select-Object -Skip 1).Length -eq 1) {
                    $Output += '0'
                }
                if (($Value - [Math]::Truncate($Value)) -ne 0) {
                    if ($OrderOfMagnitude -gt 3) {
                        $Position = 6
                        $Length = $Output.Length
                        for ($Index = 1; $Index -le [Math]::Floor($OrderOfMagnitude / 3); $Index++) {
                            $Output = $Output | Invoke-InsertString ',' -At ($Length - $Position)
                            $Position += 3
                        }
                    }
                    if ($Postfix) {
                        "$(if ($Sign -lt 0) { '-' } else { '' })$Output$Symbol"
                    } else {
                        "$(if ($Sign -lt 0) { '-' } else { '' })$Symbol$Output"
                    }
                } else {
                    ($Value.ToString() -as [Int]) | Format-MoneyValue
                }
            }
            'String' {
                $Value = $Value -replace ',', ''
                $Sign = if (([Regex]'\-\$').Match($Value).Success) { -1 } else { 1 }
                if (([Regex]'\$').Match($Value).Success) {
                    $Output = (([Regex]'(?<=(\$))[0-9]*\.?[0-9]{0,2}').Match($Value)).Value
                } else {
                    $Output = (([Regex]'[\-]?[0-9]*\.?[0-9]{0,2}').Match($Value)).Value
                }
                $Type = if ($Output.Contains('.')) { [Double] } else { [Int] }
                $Output = $Sign * ($Output -as $Type)
                if (-not $AsNumber) {
                    $Output = $Output | Format-MoneyValue
                }
                $Output
            }
            Default { throw 'Format-MoneyValue only accepts strings and numbers' }
        }
    }
}
function Get-Plural {
    <#
    .SYNOPSIS
    Return plural form of a word
    .EXAMPLE
    'boot' | plural
    # returns 'boots'
    .NOTES
    Adapted from the PHP library, [Text-Statistics](https://github.com/DaveChild/Text-Statistics)
    #>
    [CmdletBinding()]
    [Alias('plural')]
    [OutputType([String])]
    Param(
        [Parameter(Mandatory = $True, Position = 0, ValueFromPipeline = $True)]
        [String] $Word
    )
    Begin {
        $Plural = @(
            ('(quiz)$', '${1}zes')
            ('^(ox)$', '${1}en')
            ('([m|l])ouse$', '${1}ice')
            ('(matr|ind|vert)[i|e]x$', '${1}ices')
            ('(x|ch|ss|sh)$', '${1}es')
            ('([^aeiouy]|qu)y$', '${1}ies')
            ('(hive)$', '${1}s')
            ('(?:([^f])fe|([lr])f)$', '${1}${2}ves')
            ('(shea|lea|loa|thie)f$', '${1}ves')
            ('sis$', 'ses')
            ('([ti])um$', '${1}a')
            ('(tomat|potat|ech|her|vet)o$', '${1}oes')
            ('(bu)s$', '${1}ses')
            ('(alias)$', '${1}es')
            ('(octop)us$', '${1}i')
            ('(ax|test)is$', '${1}es')
            ('(us)$', '${1}es')
            ('s$', 's')
        )
    }
    Process {
        switch ($Word.ToLower()) {
            { $_ -in $SameSingularPlural } {
                $Word
                Break
            }
            { $_ -in $Irregular.Keys } {
                $Irregular.$_
                Break
            }
            { $_ -in $Irregular.Values } {
                $Word
                Break
            }
            Default {
                $Result = "${Word}s"
                $Pairs = Invoke-Chunk $Plural -Size 2
                foreach ($Pair in $Pairs) {
                    [Regex]$Re, $PluralVersion = $Pair
                    if ($Word -match $Re) {
                        $Result = $Word -replace $Re, $PluralVersion
                        Break
                    }
                }
                $Result
            }
        }
    }
}
function Get-Singular {
    <#
    .SYNOPSIS
    Return singular form of a word
    .EXAMPLE
    'boots' | singular
    # returns 'boot'
    .NOTES
    Adapted from the PHP library, [Text-Statistics](https://github.com/DaveChild/Text-Statistics)
    #>
    [CmdletBinding()]
    [Alias('singular')]
    [OutputType([String])]
    Param(
        [Parameter(Mandatory = $True, Position = 0, ValueFromPipeline = $True)]
        [String] $Word
    )
    Begin {
        $Singular = @(
            ('(quiz)zes$', '${1}')
            ('(matr)ices$', '${1}ix')
            ('(vert|ind)ices$', '${1}ex')
            ('^(ox)en$', '${1}')
            ('(alias)es$', '${1}')
            ('(octop|vir)i$', '${1}us')
            ('(cris|ax|test)es$', '${1}is')
            ('(shoe)s$', '${1}')
            ('(o)es$', '${1}')
            ('(bus)es$', '${1}')
            ('([m|l])ice$', '${1}ouse')
            ('(x|ch|ss|sh)es$', '${1}')
            ('(m)ovies$', '${1}ovie')
            ('(s)eries$', '${1}eries')
            ('([^aeiouy]|qu)ies$', '${1}y')
            ('([lr])ves$', '${1}f')
            ('(tive)s$', '${1}')
            ('(hive)s$', '${1}')
            ('(li|wi|kni)ves$', '${1}fe')
            ('(shea|loa|lea|thie)ves$', '${1}f')
            ('(^analy)ses$', '${1}sis')
            ('((a)naly|(b)a|(d)iagno|(p)arenthe|(p)rogno|(s)ynop|(t)he)ses$', '${1}${2}sis')
            ('([ti])a$', '${1}um')
            ('(n)ews$', '${1}ews')
            ('(h|bl)ouses$', '${1}ouse')
            ('(corpse)s$', '${1}')
            ('(us)es$', '${1}')
            ('s$', '')
        )
    }
    Process {
        switch ($Word.ToLower()) {
            { $_ -in $SameSingularPlural } {
                $Word
                Break
            }
            { $_ -in $Irregular.Keys } {
                $Word
                Break
            }
            { $_ -in $Irregular.Values } {
                ($Irregular | Invoke-ObjectInvert).$_
                Break
            }
            Default {
                $Result = $Word
                $Pairs = Invoke-Chunk $Singular -Size 2
                foreach ($Pair in $Pairs) {
                    [Regex]$Re, $SingularVersion = $Pair
                    if ($Word -match $Re) {
                        $Result = $Word -replace $Re, $SingularVersion
                        Break
                    }
                }
                $Result
            }
        }
    }
}
function Get-SyllableCount {
    <#
    .SYNOPSIS
    Get number of syllables in an English word (used within Get-Readability function)
    .EXAMPLE
    'hello' | Get-SylallableCount
    # returns 2
    .NOTES
    Adapted from Node.js library, [words/syllable](https://github.com/words/syllable#inspiration),
    which was based on the PHP library, [Text-Statistics](https://github.com/DaveChild/Text-Statistics),
    which was inspired by the Perl module, [Lingua::EN::Syllable](https://metacpan.org/pod/Lingua::EN::Syllable)
    #>
    [CmdletBinding()]
    [OutputType([Int])]
    Param(
        [Parameter(Position = 0, ValueFromPipeline = $True)]
        [AllowEmptyString()]
        [String] $Word
    )
    Begin {
        # Match single syllable pre- and suffixes
        $Single = [Regex]'^(?:un|fore|ware|none?|out|post|sub|pre|pro|dis|side|some)|(?:ly|less|some|ful|ers?|ness|cians?|ments?|ettes?|villes?|ships?|sides?|ports?|shires?|[gnst]ion(?:ed|s)?)$'
        # Match double syllable pre- and suffixes
        $Double = [Regex]'^(?:above|anti|ante|counter|hyper|afore|agri|infra|intra|inter|over|semi|ultra|under|extra|dia|micro|mega|kilo|pico|nano|macro|somer)|(?:fully|berry|woman|women|edly|union|((?:[bcdfghjklmnpqrstvwxz])|[aeiou])ye?ing)$'
        # Match triple syllabble suffixes
        $Triple = [Regex]'(creations?|ology|ologist|onomy|onomist)$'
        # Counted as two, but should be one
        $SingleSyllabicOne = [Regex]'awe($|d|so)|cia(?:l|$)|tia|cius|cious|[^aeiou]giu|[aeiouy][^aeiouy]ion|iou|sia$|eous$|[oa]gue$|.[^aeiuoycgltdb]{2,}ed$|.ely$|^jua|uai|eau|^busi$|(?:[aeiouy](?:[bcfgklmnprsvwxyz]|ch|dg|g[hn]|lch|l[lv]|mm|nch|n[cgn]|r[bcnsv]|squ|s[chkls]|th)ed$)|(?:[aeiouy](?:[bdfklmnprstvy]|ch|g[hn]|lch|l[lv]|mm|nch|nn|r[nsv]|squ|s[cklst]|th)es$)'
        $SingleSyllabicTwo = [Regex]'[aeiouy](?:[bcdfgklmnprstvyz]|ch|dg|g[hn]|l[lv]|mm|n[cgns]|r[cnsv]|squ|s[cklst]|th)e$'
        # Counted as one, but should be two
        $DoubleSyllabicOne = [Regex]'(?:([^aeiouy])\\1l|[^aeiouy]ie(?:r|s?t)|[aeiouym]bl|eo|ism|asm|thm|dnt|snt|uity|dea|gean|oa|ua|react?|orbed|shred|eings?|[aeiouy]sh?e[rs])$'
        $DoubleSyllabicTwo = [Regex]'creat(?!u)|[^gq]ua[^auieo]|[aeiou]{3}|^(?:ia|mc|coa[dglx].)|^re(app|es|im|us)|(th|d)eist'
        $DoubleSyllabicThree = [Regex]'[^aeiou]y[ae]|[^l]lien|riet|dien|iu|io|ii|uen|[aeilotu]real|real[aeilotu]|iell|eo[^aeiou]|[aeiou]y[aeiou]'
        $DoubleSyllabicFour = [Regex]'[^s]ia'
        # Nouns with problematic syllables
        $Problematic = @{
            'abalone' = 4
            'abare' = 3
            'abbruzzese' = 4
            'abed' = 2
            'aborigine' = 5
            'abruzzese' = 4
            'acreage' = 3
            'adame' = 3
            'adieu' = 2
            'adobe' = 3
            'anemone' = 4
            'anyone' = 3
            'apache' = 3
            'aphrodite' = 4
            'apostrophe' = 4
            'ariadne' = 4
            'cafe' = 2
            'café' = 2
            'calliope' = 4
            'catastrophe' = 4
            'chile' = 2
            'chloe' = 2
            'circe' = 2
            'cliche' = 2
            'cliché' = 2
            'contrariety' = 4
            'coyote' = 3
            'daphne' = 2
            'epitome' = 4
            'eurydice' = 4
            'euterpe' = 3
            'every' = 2
            'everywhere' = 3
            'forever' = 3
            'gethsemane' = 4
            'guacamole' = 4
            'hermione' = 4
            'hyperbole' = 4
            'jesse' = 2
            'jukebox' = 2
            'karate' = 3
            'machete' = 3
            'maybe' = 2
            'naive' = 2
            'newlywed' = 3
            'ninety' = 2
            'penelope' = 4
            'people' = 2
            'persephone' = 4
            'phoebe' = 2
            'pulse' = 1
            'queue' = 1
            'recipe' = 3
            'reptilian' = 4
            'resumé' = 2
            'riverbed' = 3
            'scotia' = 3
            'sesame' = 3
            'shoreline' = 2
            'simile' = 3
            'snuffleupagus' = 5
            'sometimes' = 2
            'syncope' = 3
            'tamale' = 3
            'waterbed' = 3
            'wednesday' = 2
            'viceroyship' = 3
            'yosemite' = 4
            'zoë' = 2
        }
        $NeedToBeFixed = @{ # all counts are (correct - 1)
            'ayo' = 2
            'australian' = 3
            'dionysius' = 5
            'disbursement' = 3
            'discouragement' = 4
            'disenfranchisement' = 5
            'disengagement' = 4
            'disgraceful' = 3
            'diskette' = 2
            'displacement' = 3
            'distasteful' = 3
            'distinctiveness' = 4
            'distraction' = 3
            'geoffrion' = 4
            'mcquaid' = 2
            'mcquaide' = 2
            'mcquaig' = 2
            'mcquain' = 2
            'nonbusiness' = 3
            'nonetheless' = 3
            'nonmanagement' = 4
            'outplacement' = 3
            'outrageously' = 4
            'postponement' = 3
            'preemption' = 3
            'preignition' = 4
            'preinvasion' = 4
            'preisler' = 3
            'preoccupation' = 5
            'prevette' = 2
            'probusiness' = 3
            'procurement' = 3
            'pronouncement' = 3
            'sidewater' = 3
            'sidewinder' = 3
            'ungerer' = 3
        }
        $Apostrophe = [Regex]"['’]"
        $NonAlphabetic = [Regex]'[^a-z]'
        $Count = 0
    }
    Process {
        $Syllables = {
            Param($Word)
            switch ($Word) {
                { $_.Length -eq 0 } {
                    0
                    Break
                }
                { $_.Length -in 1, 2 } {
                    1
                    Break
                }
                { $_ -in $Problematic.Keys } {
                    $Problematic.$_
                    Break
                }
                { (Get-Singular $_) -in $Problematic.Keys } {
                    $Word = (Get-Singular $_)
                    $Problematic.$Word
                    Break
                }
                { $_ -in $NeedToBeFixed.Keys } {
                    $NeedToBeFixed.$_
                    Break
                }
                { (Get-Singular $_) -in $NeedToBeFixed.Keys } {
                    $Word = Get-Singular $_
                    $NeedToBeFixed.$Word
                    Break
                }
                Default {
                    $Count += (3 * ($Word | Select-String -Pattern $Triple).Matches.Value.Count)
                    $Word = $Word -replace $Triple, ''
                    $Count += (2 * ($Word | Select-String -Pattern $Double).Matches.Value.Count)
                    $Word = $Word -replace $Double, ''
                    $Count += (1 * ($Word | Select-String -Pattern $Single).Matches.Value.Count)
                    $Word = $Word -replace $Single, ''
                    $Count -= ($Word | Select-String -Pattern $SingleSyllabicOne).Matches.Value.Count
                    $Count -= ($Word | Select-String -Pattern $SingleSyllabicTwo).Matches.Value.Count
                    $Count += ($Word | Select-String -Pattern $DoubleSyllabicOne).Matches.Value.Count
                    $Count += ($Word | Select-String -Pattern $DoubleSyllabicTwo).Matches.Value.Count
                    $Count += ($Word | Select-String -Pattern $DoubleSyllabicThree).Matches.Value.Count
                    $Count += ($Word | Select-String -Pattern $DoubleSyllabicFour).Matches.Value.Count
                    $Count += ($Word -split [Regex]'[^aeiouy]+' | Where-Object { $_ -ne '' }).Count
                    $Count
                }
            }
        }
        $TotalSyllables = 0
        $Parts = (($Word -replace $Apostrophe, '') -split '\b')
        foreach ($Part in $Parts) {
            $Part = $Part.ToLower() -replace $NonAlphabetic, ''
            $TotalSyllables += (& $Syllables $Part)
        }
        $TotalSyllables
    }
}
function Import-Excel {
    <#
    .SYNOPSIS
    Import the rows of an Excel worksheet as a 2-dimensional array
    .PARAMETER ColumnHeaders
    Custom values to be used as header names. Must have same count as Excel data columns.
    .PARAMETER FirstRowHeaders
    Treat first row as headers. Exclude first row cells from Cells and Rows in output.
    Note: When an empty cell is encountered, a placeholder will be used of the form, column<COLUMN NUMBER>
    .PARAMETER Peek
    Return first row of data only. Useful for quickly identifying the shape of the data without importing the entire file.
    #>
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    Param(
        [Parameter(Mandatory = $True)]
        [String] $Path,
        [String] $WorksheetName,
        [Array] $ColumnHeaders,
        [String] $Password,
        [Switch] $FirstRowHeaders,
        [String] $EmptyValue = 'EMPTY',
        [Switch] $ShowProgress,
        [Switch] $Peek
    )
    $FileName = Get-StringPath $Path
    $Excel = New-Object -ComObject 'Excel.Application'
    $Excel.Visible = $False
    if ($ShowProgress) {
        Write-Progress -Activity 'Importing Excel data' -Status "Loading $FileName"
    }
    $Workbook = if (-not $Password) {
        $Excel.workbooks.open($FileName)
    } else {
        $Excel.workbooks.open($FileName, 0, 0, $True, $Password)
    }
    $Worksheet = if ($WorksheetName) {
        $Workbook.Worksheets.Item($WorksheetName)
    } else {
        $Workbook.Worksheets(1)
    }
    $RowCount = if ($Peek) { 1 } else { $Worksheet.UsedRange.Rows.Count }
    $ColumnCount = $Worksheet.UsedRange.Columns.Count
    $StartIndex = if ($FirstRowHeaders) { 2 } else { 1 }
    $Headers = if ($FirstRowHeaders) {
        $RowCount--
        1..$ColumnCount | ForEach-Object {
            $Name = $Worksheet.Cells.Item(1, $_).Value2
            if ($Null -eq $Name) { "Column${_}" } else { $Name }
        }
    } elseif ($ColumnHeaders.Count -eq $ColumnCount) {
        $ColumnHeaders
    } else {
        1..$ColumnCount | ForEach-Object { "Column${_}" }
    }
    $Rows = New-Object 'System.Collections.ArrayList'
    $Cells = @()
    for ($RowIndex = $StartIndex; $RowIndex -le $RowCount; $RowIndex++) {
        if ($ShowProgress) {
            Write-Progress -Activity 'Importing Excel data' -Status "Processing row ($RowIndex of ${RowCount})" -PercentComplete (($RowIndex / $RowCount) * 100)
        }
        $Row = @{}
        for ($ColumnIndex = 1; $ColumnIndex -le $ColumnCount; $ColumnIndex++) {
            $Value = $Worksheet.Cells.Item($RowIndex, $ColumnIndex).Value2
            $Element = if ($Null -eq $Value) { $EmptyValue } else { $Value }
            $Row[$Headers[$ColumnIndex - 1]] = $Element
            $Cells += $Element
        }
        [Void]$Rows.Add($Row)
    }
    if ($ShowProgress) {
        Write-Progress -Activity 'Importing Excel data' -Completed
    }
    $Workbook.Close()
    $Excel.Quit()
    @{
        Size = @($RowCount, $ColumnCount)
        Headers = $Headers
        Cells = $Cells
        Rows = $Rows
    }
}
function Import-Raw {
    <#
    .SYNOPSIS
    Import large files as lines of raw text using StreamReader
    Note: For large files, this function can be 2-10 times faster than Get-Content or Import-Csv
    .PARAMETER Transform
    Function that will be applied to every line.
    .PARAMETER Peek
    Return only the first line.
    .EXAMPLE
    Import-Raw -File 'data.csv' -Transform { Param($Line) $Line -split ',' }
    .EXAMPLE
    Import-Raw 'data.csv' -Peek
    #>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $True, Position = 0)]
        [ValidateScript({ Test-Path $_ })]
        [String] $File,
        [Parameter(Position = 1)]
        [ScriptBlock] $Transform,
        [Switch] $Peek
    )
    $Stream = New-Object -Type System.IO.StreamReader -ArgumentList (Get-Item $File)
    do {
        $Line = $Stream.ReadLine()
        if ($Transform) {
            & $Transform $Line
        } else {
            $Line
        }
    } while (-not $Peek -and $Stream.Peek() -ge 0)
    [Void]$Stream.Dispose()
}