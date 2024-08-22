@{
    ModuleVersion = '0.2.20'
    RootModule = 'Prelude.psm1'
    GUID = '5af3199a-e01b-4ed6-87ad-fdea39aa7e77'
    CompanyName = 'Wohlgemuth Technology Foundation'
    Author = 'Jason Wohlgemuth'
    Copyright = '(c) 2023 Jason Wohlgemuth. All rights reserved.'
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
        'impute'
        'ini'
        'input'
        'insert'
        'invert'
        'irc'
        'listenFor'
        'listenTo'
        'matmap'
        'matrix'
        'max'
        'mean'
        'median'
        'menu'
        'merge'
        'method'
        'min'
        'money'
        'omit'
        'on'
        'op'
        'pack'
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
        'reverse'
        'rf'
        'say'
        'sigmoid'
        'singular'
        'softmax'
        'sum'
        'tap'
        'take'
        'takeWhile'
        'title'
        'touch'
        'tpl'
        'toDegree'
        'toPair'
        'toRadian'
        'transform'
        'trigger'
        'unpack'
        'variance'
        'unzip'
        'zip'
        'zipWith'
    )
    FunctionsToExport = @(
        'Add-Metadata'
        'ConvertFrom-Base64'
        'ConvertFrom-ByteArray'
        'ConvertFrom-EpochDate'
        'ConvertFrom-FolderStructure'
        'ConvertFrom-Html'
        'ConvertFrom-Pair'
        'ConvertFrom-QueryString'
        'ConvertTo-AbstractSyntaxTree'
        'ConvertTo-Base64'
        'ConvertTo-ConsoleMarkup'
        'ConvertTo-Degree'
        'ConvertTo-OrderedDictionary'
        'ConvertTo-PowerShellSyntax'
        'ConvertTo-Iso8601'
        'ConvertTo-JavaScript'
        'ConvertTo-Pair'
        'ConvertTo-ParameterString'
        'ConvertTo-PlainText'
        'ConvertTo-QueryString'
        'ConvertTo-Radian'
        'Deny-Empty'
        'Deny-Null'
        'Deny-Value'
        'Enable-Remoting'
        'Export-EnvironmentFile'
        'Export-GraphData'
        'Find-Duplicate'
        'Find-FirstIndex'
        'Find-FirstTrueVariable'
        'Format-ComplexValue'
        'Format-FileSize'
        'Format-Json'
        'Format-MinimumWidth'
        'Format-MoneyValue'
        'Get-Covariance'
        'Get-DefaultBrowser'
        'Get-Extremum'
        'Get-Factorial'
        'Get-GithubOAuthToken'
        'Get-HostsContent'
        'Get-HtmlElement'
        'Get-InitializationFileContent'
        'Get-LogisticSigmoid'
        'Get-Maximum'
        'Get-Mean'
        'Get-Median'
        'Get-Minimum'
        'Get-ParameterList'
        'Get-Permutation'
        'Get-Plural'
        'Get-Property'
        'Get-Singular'
        'Get-Softmax'
        'Get-State'
        'Get-StateName'
        'Get-StringPath'
        'Get-SyllableCount'
        'Get-Sum'
        'Get-TemporaryDirectory'
        'Get-Variance'
        'Import-Excel'
        'Import-GraphData'
        'Import-Html'
        'Import-Raw'
        'Install-SshServer'
        'Invoke-Chunk'
        'Invoke-DropWhile'
        'Invoke-Flatten'
        'Invoke-FireEvent'
        'Invoke-GoogleSearch'
        'Invoke-Imputation'
        'Invoke-Input'
        'Invoke-InsertString'
        'Invoke-ListenTo'
        'Invoke-ListenForWord'
        'Invoke-MatrixMap'
        'Invoke-Menu'
        'Invoke-Method'
        'Invoke-NewDirectoryAndEnter'
        'Invoke-Normalize'
        'Invoke-NpmInstall'
        'Invoke-ObjectInvert'
        'Invoke-ObjectMerge'
        'Invoke-Omit'
        'Invoke-Once'
        'Invoke-Operator'
        'Invoke-Pack'
        'Invoke-Partition'
        'Invoke-Pick'
        'Invoke-PropertyTransform'
        'Invoke-Reduce'
        'Invoke-RemoteCommand'
        'Invoke-Repeat'
        'Invoke-Reverse'
        'Invoke-RunApplication'
        'Invoke-Speak'
        'Invoke-StopListen'
        'Invoke-TakeWhile'
        'Invoke-Tap'
        'Invoke-Unpack'
        'Invoke-Unzip'
        'Invoke-WebRequestBasicAuth'
        'Invoke-Zip'
        'Invoke-ZipWith'
        'Join-StringsWithGrammar'
        'Measure-Performance'
        'Measure-Readability'
        'New-ComplexValue'
        'New-DailyShutdownJob'
        'New-DesktopApplication'
        'New-Edge'
        'New-File'
        'New-GitlabRunner'
        'New-Graph'
        'New-Matrix'
        'New-RegexString'
        'New-Template'
        'New-TerminalApplicationTemplate'
        'New-WebApplication'
        'Open-Session'
        'Out-Browser'
        'Out-Tree'
        'Register-GitlabRunner'
        'Remove-Character'
        'Remove-DailyShutdownjob'
        'Remove-DirectoryForce'
        'Remove-HandlebarsHelper'
        'Remove-Indent'
        'Rename-FileExtension'
        'Save-File'
        'Save-JsonData'
        'Save-State'
        'Save-TemplateData'
        'Invoke-NewDirectoryAndEnter'
        'Test-Admin'
        'Test-ApplicationContext'
        'Test-Command'
        'Test-DiagonalMatrix'
        'Test-Empty'
        'Test-Enumerable'
        'Test-Equal'
        'Test-Installed'
        'Test-Matrix'
        'Test-Match'
        'Test-SquareMatrix'
        'Test-SymmetricMatrix'
        'Test-Url'
        'Update-Application'
        'Update-HostsFile'
        'Use-Grammar'
        'Use-Speech'
        'Use-Web'
        'Write-BarChart'
        'Write-Color'
        'Write-Label'
        'Write-Status'
        'Write-Title'
    )
    PrivateData = @{
        PSData = @{
            Tags = @('Windows', 'Linux', 'FunctionalProgramming', 'Helpers', 'Matrix', 'Graphs', 'LinearAlgebra', 'Statistics', 'Math', 'UI/UX', 'Productivity')
            LicenseUri = 'https://github.com/jhwohlgemuth/pwsh-prelude/blob/master/LICENSE'
            ProjectUri = 'https://github.com/jhwohlgemuth/pwsh-prelude'
        }
    }
}
