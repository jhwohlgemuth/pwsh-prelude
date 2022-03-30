function Measure-Readability {
    <#
    .SYNOPSIS
    Measure readability of input text.
    .DESCRIPTION
    This function can ingest text and return the minimum school grade level necessary to understand the text.
    The following tests are supported:
    - Flesch-Kincaid Grade Level (default)
    - Automated Readability Index (ARI)
    - Coleman-Liau Index (CLI)
    - Gunning Fog Index (GFI)
    - SMOG ("Simple Measure Of Gobbledygook")
    .PARAMETER Type
    Readability test type (ARI, CLI, etc...)
    > Note: The SMOG readability test requires that the input text contains at least 30 sentences.
    .EXAMPLE
    $Text = 'This is a sentence. This is another sentence.'
    $Text | Measure-Readability
    #>
    [CmdletBinding()]
    [OutputType([Int])]
    Param(
        [Parameter(Mandatory = $True, Position = 0, ValueFromPipeline = $True)]
        [String] $Text,
        [Parameter(Position = 1)]
        [ValidateSet('FleschKincaidGradeLevel', 'ARI', 'AutomatedReadabilityIndex', 'CLI', 'ColemanLiauIndex', 'GFI', 'GunningFogIndex', 'SMOG')]
        [String] $Type = 'FleschKincaidGradeLevel'
    )
    Process {
        $Sentences = ($Text -split '(?<=\w)\.') |
            ForEach-Object { $_.Trim() } |
            Where-Object { $_.Length -gt 0 }
        $Words = @()
        foreach ($Sentence in $Sentences) {
            $Words += $Sentence -split '\s+'
        }
        $Syllables = @()
        foreach ($Word in $Words) {
            $Syllables += (Get-SyllableCount $Word)
        }
        $Result = switch ($Type) {
            { $_ -in 'ARI', 'AutomatedReadabilityIndex' } {
                '==> Measuring readability with Automated Readability Index' | Write-Verbose
                $LetterCount = ($Text | Measure-Object -Character -IgnoreWhiteSpace).Characters
                "==> # of Sentences: $($Sentences.Count)" | Write-Verbose
                "==> # of Words: $($Words.Count)" | Write-Verbose
                "==> # of Letters: ${LetterCount}" | Write-Verbose
                (4.71 * ($LetterCount / $Words.Count)) + (0.5 * ($Words.Count / $Sentences.Count)) - 21.43
            }
            { $_ -in 'CLI', 'ColemanLiauIndex' } {
                '==> Measuring readability with Coleman-Liau Index' | Write-Verbose
                $LetterCount = ($Text | Measure-Object -Character -IgnoreWhiteSpace).Characters
                $L = 100 * ($LetterCount / $Words.Count)
                $S = 100 * ($Sentences.Count / $Words.Count)
                "==> L: ${L}" | Write-Verbose
                "==> S: ${S}" | Write-Verbose
                (0.0588 * $L) - (0.296 * $S) - 15.8
            }
            { $_ -in 'GFI', 'GunningFogIndex' } {
                '==> Measuring readability with Gunning Fog Index' | Write-Verbose
                $TotalWords = $Words.Count
                $ComplexWords = ($Syllables | Where-Object { $_ -ge 3 }).Count
                "==> # of Sentences: $($Sentences.Count)" | Write-Verbose
                "==> # of Words: ${TotalWords}" | Write-Verbose
                "==> # of Complex Words: ${ComplexWords}" | Write-Verbose
                0.4 * (($TotalWords / $Sentences.Count) + (100 * ($ComplexWords / $TotalWords)))
            }
            'SMOG' {
                if ($Sentences.Count -lt 30) {
                    '==> SMOG readability test is not accurate with less than 30 sentences' | Write-Warning
                }
                '==> Measuring readability with SMOG' | Write-Verbose
                $ComplexWords = ($Syllables | Where-Object { $_ -ge 3 }).Count
                "==> # of Sentences: $($Sentences.Count)" | Write-Verbose
                "==> # of Complex Words: ${ComplexWords}" | Write-Verbose
                (1.043 * [Math]::Sqrt($ComplexWords * (30 / $Sentences.Count))) + 3.1291
            }
            Default {
                # Flesch-Kincaid Grade Level
                '==> Measuring readability with Flesch-Kincaid Grade Level' | Write-Verbose
                $TotalWords = $Words.Count
                $TotalSyllables = Get-Sum $Syllables
                "==> # of Sentences: $($Sentences.Count)" | Write-Verbose
                "==> # of Words: ${TotalWords}" | Write-Verbose
                "==> # of Syllables: ${TotalSyllables}" | Write-Verbose
                (0.39 * ($TotalWords / $Sentences.Count)) + (11.8 * ($TotalSyllables / $TotalWords)) - 15.59
            }
        }
        [Math]::Round($Result, 1)
    }
}