@{
    ExcludeRules = @(
        'PSAvoidUsingWriteHost'
        'PSUseBOMForUnicodeEncodedFile'
        'PSAvoidOverwritingBuiltInCmdlets'
        'PSUseProcessBlockForPipelineCommand'
        'PSUseShouldProcessForStateChangingFunctions'
    )
    CustomRulePath = 'PSScriptAnalyzerCustomRules.psm1'
    IncludeDefaultRules = $True
    Rules = @{
        PSAvoidGlobalFunctions = @{
            Enable = $True
        }
        PSAvoidLongLines = @{
            Enable = $False
            MaximumLineLength = 150
        }
        PSAvoidUsingDoubleQuotesForConstantString = @{
            Enable = $True
        }
        PSAvoidUsingDeprecatedManifestFields = @{
            Enable = $True
        }
        PSPlaceOpenBrace = @{
            Enable = $True
            OnSameLine = $True
            NewLineAfter = $True
            IgnoreOneLineBlock = $True
        }
        PSPlaceCloseBrace = @{
            Enable = $True
            NoEmptyLineBefore = $True
            IgnoreOneLineBlock = $True
            NewLineAfter = $False
        }
        PSUseCompatibleSyntax = @{
            Enable = $True
            TargetVersions = @('5.1')
        }
        PSUseConsistentIndentation = @{
            Enable = $True
            IndentationSize = 4
            PipelineIndentation = 'IncreaseIndentationForFirstPipeline'
            Kind = 'space'
        }
        PSUseConsistentWhitespace = @{
            Enable = $True
            CheckInnerBrace = $True
            CheckOpenBrace = $True
            CheckOpenParen = $True
            CheckOperator = $True
            CheckSeparator = $True
            CheckParameter = $True
            CheckPipe = $True
            CheckPipeForRedundantWhitespace = $True
        }
        PSUseCorrectCasing = @{
            Enable = $True
        }
    }
}