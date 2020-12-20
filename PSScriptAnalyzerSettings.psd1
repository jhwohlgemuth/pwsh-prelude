@{
  ExcludeRules = @(
    'PSAvoidUsingWriteHost'
    'PSUseBOMForUnicodeEncodedFile'
    'PSAvoidOverwritingBuiltInCmdlets'
    'PSUseProcessBlockForPipelineCommand'
    'PSUseShouldProcessForStateChangingFunctions'
  )
  CustomRulePath = 'PSScriptAnalyzerCustomRules.psm1'
}