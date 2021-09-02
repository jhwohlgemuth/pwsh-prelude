﻿@{
    ModuleVersion = '0.0.85'
    RootModule = 'Prelude.psm1'
    GUID = '5af3199a-e01b-4ed6-87ad-fdea39aa7e77'
    CompanyName = 'Wohlgemuth Technology Foundation'
    Author = 'Jason Wohlgemuth'
    Copyright = '(c) 2020 Jason Wohlgemuth. All rights reserved.'
    Description = 'A "standard" library for PowerShell inspired by the preludes of other languages'
    PowerShellVersion = '5.0'
    FileList = @()
    CmdletsToExport = @()
    VariablesToExport = @()
    FormatsToProcess = @(
        'formats/Complex.Format.ps1xml',
        'formats/Matrix.Format.ps1xml',
        'formats/Graph.Format.ps1xml'
    )
    TypesToProcess = @(
        'types\Int.Types.ps1xml'
        'types\String.Types.ps1xml'
        'types\Array.Types.ps1xml'
        'types\Hashtable.Types.ps1xml'
        'types\Matrix.Types.ps1xml'
        'types\FileInfo.Types.ps1xml'
    )
    AliasesToExport = @(
        'basicauth'
        'complex'
        'chunk'
        'covariance'
        'dropWhile'
        'edge'
        'equal'
        'flatten'
        'fromPair'
        'google'
        'input'
        'insert'
        'invert'
        'irc'
        'listenFor'
        'listenTo'
        'matrix'
        'max'
        'mean'
        'median'
        'menu'
        'merge'
        'method'
        'min'
        'money'
        'on'
        'op'
        'partition'
        'permute'
        'pick'
        'plain'
        'plural'
        'prop'
        're'
        'reduce'
        'remove'
        'repeat'
        'rf'
        'say'
        'sigmoid'
        'singular'
        'softmax'
        'sum'
        'tap'
        'takeWhile'
        'title'
        'touch'
        'tpl'
        'toDegree'
        'toPair'
        'toRadian'
        'transform'
        'trigger'
        'screenshot'
        'variance'
        'unzip'
        'zip'
        'zipWith'
    )
    FunctionsToExport = @(
        'Add-Metadata'
        'ConvertFrom-ByteArray'
        'ConvertFrom-Html'
        'ConvertFrom-Pair'
        'ConvertFrom-QueryString'
        'ConvertTo-AbstractSyntaxTree'
        'ConvertTo-Degree'
        'ConvertTo-PowershellSyntax'
        'ConvertTo-Iso8601'
        'ConvertTo-JavaScript'
        'ConvertTo-Pair'
        'ConvertTo-PlainText'
        'ConvertTo-QueryString'
        'ConvertTo-Radian'
        'Deny-Empty'
        'Deny-Null'
        'Deny-Value'
        'Enable-Remoting'
        'Export-GraphData'
        'Find-Duplicate'
        'Find-FirstIndex'
        'Format-ComplexValue'
        'Find-FirstTrueVariable'
        'Format-MoneyValue'
        'Get-Covariance'
        'Get-DefaultBrowser'
        'Get-Extremum'
        'Get-Factorial'
        'Get-GithubOAuthToken'
        'Get-HostsContent'
        'Get-HtmlElement'
        'Get-LogisticSigmoid'
        'Get-Maximum'
        'Get-Mean'
        'Get-Median'
        'Get-Minimum'
        'Get-ParameterList'
        'Get-Permutation'
        'Get-Plural'
        'Get-Property'
        'Get-Screenshot'
        'Get-Singular'
        'Get-Softmax'
        'Get-State'
        'Get-SyllableCount'
        'Get-Sum'
        'Get-Variance'
        'Import-Excel'
        'Import-GraphData'
        'Import-Html'
        'Import-Raw'
        'Invoke-Chunk'
        'Invoke-DropWhile'
        'Invoke-Flatten'
        'Invoke-FireEvent'
        'Invoke-GoogleSearch'
        'Invoke-Input'
        'Invoke-InsertString'
        'Invoke-ListenTo'
        'Invoke-ListenForWord'
        'Invoke-Menu'
        'Invoke-Method'
        'Invoke-Normalize'
        'Invoke-ObjectInvert'
        'Invoke-ObjectMerge'
        'Invoke-Once'
        'Invoke-Operator'
        'Invoke-Partition'
        'Invoke-Pick'
        'Invoke-PropertyTransform'
        'Invoke-Reduce'
        'Invoke-RemoteCommand'
        'Invoke-Repeat'
        'Invoke-RunApplication'
        'Invoke-Speak'
        'Invoke-TakeWhile'
        'Invoke-Tap'
        'Invoke-Unzip'
        'Invoke-WebRequestBasicAuth'
        'Invoke-Zip'
        'Invoke-ZipWith'
        'Join-StringsWithGrammar'
        'Measure-Performance'
        'Measure-Readability'
        'New-ApplicationTemplate'
        'New-ComplexValue'
        'New-Edge'
        'New-File'
        'New-Graph'
        'New-Matrix'
        'New-RegexString'
        'New-Template'
        'Open-Session'
        'Out-Browser'
        'Remove-Character'
        'Remove-DirectoryForce'
        'Remove-Indent'
        'Rename-FileExtension'
        'Save-State'
        'Take'
        'Test-Admin'
        'Test-Command'
        'Test-DiagonalMatrix'
        'Test-Empty'
        'Test-Equal'
        'Test-Installed'
        'Test-Matrix'
        'Test-Match'
        'Test-SquareMatrix'
        'Test-SymmetricMatrix'
        'Test-Url'
        'Update-HostsFile'
        'Use-Grammar'
        'Use-Speech'
        'Use-Web'
        'Write-BarChart'
        'Write-Color'
        'Write-Label'
        'Write-Title'
    )
    PrivateData = @{
        PSData = @{
            Tags = @('dev', 'helpers', 'git', 'docker', 'fp', 'cli', 'app', 'scrapp')
            LicenseUri = 'https://github.com/jhwohlgemuth/pwsh-prelude/blob/master/LICENSE'
            ProjectUri = 'https://github.com/jhwohlgemuth/pwsh-prelude'
        }
    }
}
