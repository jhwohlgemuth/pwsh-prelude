[Diagnostics.CodeAnalysis.SuppressMessageAttribute('RequireDirective', '')]
Param()
Remove-Module -Name Prelude
Import-Module './Prelude'

$Space = ' '
$Indent = 4
$LabelParameters = @{
    Indent = $Indent
    NewLine = $True
}
$ResultLabelParameters = @{
    Color = 'Green'
    Indent = $Indent
    NewLine = $True
}

Write-Title '   Kitchen Sink   ' -SubText '#allthethings' -Yellow

$Space

$Fullname = Invoke-Input 'Full Name?' -Indent $Indent
$Username = Invoke-Input 'Username?' -MaxLength 10 -Indent $Indent
$Age = Invoke-Input 'Age?' -Number -Indent $Indent
$Pass = Invoke-Input 'Password?' -Secret -Indent $Indent
$FavoriteSaiyajin = Invoke-Input 'Favorite Saiya-jin?' -Autocomplete -Indent $Indent -Choices `
@(
    'Goku'
    'Gohan'
    'Goten'
    'Vegeta'
    'Trunks'
)

'Favorite number?' | Write-Label @LabelParameters
$FavoriteNumberWord = 'one', 'two', 'three' | Invoke-Menu -SingleSelect -Indent $Indent

'Known mathematicians?' | Write-Label @LabelParameters
$Choice = 'Godel', 'Gauss', 'Cantor' | Invoke-Menu -MultiSelect -Indent $Indent

'{{#red Red}}, {{#white White}}, or {{#blue Blue}}?' | Write-Label @LabelParameters
$FavoriteColor = 'red', 'white', 'blue' | Invoke-Menu -Indent $Indent

'Favorite number between 1 and 100?' | Write-Label @LabelParameters
$Space
$FavoriteNumber = 1..100 | Invoke-Menu -Limit 10 -Indent $Indent

'Favorite index between 0 and 9?' | Write-Label @LabelParameters
$Space
$FavoriteIndex = 1..10 | Invoke-Menu -Limit 3 -Indent $Indent -ReturnIndex

$Space

'Results' | Write-Title -Magenta -TextColor White
$Fullname | Write-Label @ResultLabelParameters
$Username | Write-Label @ResultLabelParameters
$Age | Write-Label @ResultLabelParameters
$Pass | Write-Label @ResultLabelParameters
$FavoriteSaiyajin | Write-Label @ResultLabelParameters
$FavoriteNumberWord | Write-Label @ResultLabelParameters
(Join-StringsWithGrammar $Choice) | Write-Label @ResultLabelParameters
$FavoriteColor | Write-Label @ResultLabelParameters
$FavoriteNumber | Write-Label @ResultLabelParameters
$FavoriteIndex | Write-Label @ResultLabelParameters

$Space

'Show bar charts?' | Write-Label -NewLine
$Choice = 'no', 'yes' | Invoke-Menu
if ($Choice -eq 'yes') {
    'Bar Charts' | Write-Title -Blue
    Get-ChildItem -File | Invoke-Reduce -FileInfo | Write-BarChart
    Get-ChildItem -File | Invoke-Reduce -FileInfo | Write-BarChart -Alternate
    Get-ChildItem -File | Invoke-Reduce -FileInfo | Write-BarChart -ShowValues
    Get-ChildItem -File | Invoke-Reduce -FileInfo | Write-BarChart -ShowValues -Alternate
    Get-ChildItem -File | Invoke-Reduce -FileInfo | Write-BarChart -ShowValues -WithColor
    Get-ChildItem -File | Invoke-Reduce -FileInfo | Write-BarChart -ShowValues -WithColor -Alternate
}
