Import-Module './pwsh-prelude.psm1'

$Space = ' '
$Indent = 4
$Color = 'Green'

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

'Favorite number?' | Write-Label -Indent $Indent -NewLine
$FavoriteNumber = 'one','two','three' | Invoke-Menu -SingleSelect -Indent $Indent

'Known mathematicians?' | Write-Label -Indent $Indent -NewLine
$Choice = 'Godel','Gauss','Cantor' | Invoke-Menu -MultiSelect -Indent $Indent

'{{#red Red}}, {{#white White}}, or {{#blue Blue}}?' | Write-Label -Indent $Indent -NewLine
$FavoriteColor = 'red','white','blue' | Invoke-Menu -Indent $Indent

$Space

'Results' | Write-Title -Magenta -TextColor White
$Fullname | Write-Label -Indent $Indent -Color $Color -NewLine
$Username | Write-Label -Indent $Indent -Color $Color -NewLine
$Age | Write-Label -Indent $Indent -Color $Color -NewLine
$Pass | Write-Label -Indent $Indent -Color $Color -NewLine
$FavoriteSaiyajin | Write-Label -Indent $Indent -Color $Color -NewLine
$FavoriteNumber | Write-Label -Indent $Indent -Color $Color -NewLine
(Join-StringsWithGrammar $Choice) | Write-Label -Indent $Indent -Color $Color -NewLine
$FavoriteColor | Write-Label -Indent $Indent -Color $Color -NewLine

$Space

'Show bar charts?' | Write-Label -NewLine
$Choice = 'yes','no' | Invoke-Menu
if ($Choice -eq 'yes') {
  'Bar Charts' | Write-Title -Blue
  Get-ChildItem -File | Invoke-Reduce -FileInfo | Show-BarChart
  Get-ChildItem -File | Invoke-Reduce -FileInfo | Show-BarChart -Alternate
  Get-ChildItem -File | Invoke-Reduce -FileInfo | Show-BarChart -ShowValues
  Get-ChildItem -File | Invoke-Reduce -FileInfo | Show-BarChart -ShowValues -Alternate
  Get-ChildItem -File | Invoke-Reduce -FileInfo | Show-BarChart -ShowValues -WithColor
  Get-ChildItem -File | Invoke-Reduce -FileInfo | Show-BarChart -ShowValues -WithColor -Alternate
}
