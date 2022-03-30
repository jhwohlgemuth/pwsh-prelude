function Invoke-Normalize {
    <#
    .SYNOPSIS
    Return string with characters with accents replaced with plain UTF-8 counterpart (ex: "á" becomes "a")
    Note: Capitalization is maintained
    .EXAMPLE
    'resumé' | Invoke-Normalize
    # returns "resume"
    #>
    [CmdletBinding()]
    [OutputType([String])]
    Param(
        [Parameter(Mandatory = $True, Position = 0, ValueFromPipeline = $True)]
        $Text
    )
    Begin {
        $CharacterMap = @{
            'ß' = 'ss'
            'à' = 'a'
            'á' = 'a'
            'â' = 'a'
            'ã' = 'a'
            'ä' = 'a'
            'å' = 'a'
            'æ' = 'ae'
            'ç' = 'c'
            'è' = 'e'
            'é' = 'e'
            'ê' = 'e'
            'ë' = 'e'
            'ì' = 'i'
            'í' = 'i'
            'î' = 'i'
            'ï' = 'i'
            'ð' = 'd'
            'ñ' = 'n'
            'ò' = 'o'
            'ó' = 'o'
            'ô' = 'o'
            'õ' = 'o'
            'ö' = 'o'
            'ø' = 'o'
            'ù' = 'u'
            'ú' = 'u'
            'û' = 'u'
            'ü' = 'u'
            'ý' = 'y'
        }
    }
    Process {
        # [Text.Encoding]::ASCII.GetString([Text.Encoding]::GetEncoding("Cyrillic").GetBytes($Text))
        $Output = $Text
        foreach ($Key in $CharacterMap.Keys) {
            $Output = $Output.Replace($Key, $CharacterMap.$Key).Replace($Key.ToUpper(), $CharacterMap.$Key.ToUpper())
        }
        $Output
    }
}