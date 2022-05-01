[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '', Scope = 'Function', Target = 'Invoke-ListenForWord')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '', Scope = 'Function', Target = 'Invoke-ListenForWord')]
Param()

function Invoke-ListenForWord {
    <#
    .SYNOPSIS
    Start loop that listens for trigger words and execute passed functions when recognized
    .DESCRIPTION
    This function uses the Windows Speech Recognition. For best results, you should first improve speech recognition via Speech Recognition Voice Training.
    .EXAMPLE
    Invoke-Listen -Triggers 'hello' -Actions { Write-Color 'Welcome' -Green }
    .EXAMPLE
    Invoke-Listen -Triggers 'hello','quit' -Actions { say 'Welcome' | Out-Null; $True }, { say 'Goodbye' | Out-Null; $False }

    # An action will stop listening when it returns a "falsy" value like $True or $Null. Conversely, returning "truthy" values will continue the listening loop.
    #>
    [CmdletBinding()]
    [Alias('listenFor')]
    Param(
        [Parameter(Mandatory = $True)]
        [String[]] $Triggers,
        [ScriptBlock[]] $Actions,
        [Double] $Threshhold = 0.85
    )
    Use-Speech
    $Engine = Use-Grammar -Words $Triggers
    $Continue = $True;
    Write-Color 'Listening for trigger words...' -Cyan
    while ($Continue) {
        $Recognizer = $Engine.Recognize();
        $Confidence = $Recognizer.Confidence;
        $Text = $Recognizer.text;
        if ($Text.Length -gt 0) {
            Write-Verbose "==> Heard `"$Text`""
        }
        $Index = 0
        $Triggers | ForEach-Object {
            if ($Text -match $_ -and [Double]$Confidence -gt $Threshhold) {
                $Continue = & $Actions[$Index]
            }
            $Index++
        }
    }
}
function Use-Grammar {
    <#
    .SYNOPSIS
    Create speech recognition engine, load grammars for words, and return the engine
    #>
    [CmdletBinding()]
    [OutputType([System.Speech.Recognition.SpeechRecognitionEngine])]
    Param(
        [Parameter(Mandatory = $True)]
        [String[]] $Words
    )
    Write-Verbose '==> Creating Speech Recognition Engine'
    $Engine = New-Object 'System.Speech.Recognition.SpeechRecognitionEngine';
    $Engine.InitialSilenceTimeout = 15
    $Engine.SetInputToDefaultAudioDevice();
    foreach ($Word in $Words) {
        "==> Loading grammar for $Word" | Write-Verbose
        $Grammar = New-Object 'System.Speech.Recognition.GrammarBuilder';
        $Grammar.Append($Word)
        $Engine.LoadGrammar($Grammar)
    }
    $Engine
}