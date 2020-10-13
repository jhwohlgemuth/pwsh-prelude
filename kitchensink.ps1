Import-Module ./pwsh-handy-helpers.psm1

$Space = " "
$Indent = 4
$Color = "Green"

Write-Title "   Kitchen Sink   " -SubText "#allthethings" -Yellow
$Space
$Fullname = Invoke-Input "Full Name?" -Indent $Indent
$Username = Invoke-Input "Username?" -MaxLength 10 -Indent $Indent
$Age = Invoke-Input "Age?" -Number -Indent $Indent
$Pass = Invoke-Input "Password?" -Secret -Indent $Indent
$FavoriteSaiyajin = Invoke-Input "Favorite Saiya-jin?" -Autocomplete -Indent $Indent -Choices `
@(
    'Goku'
    'Gohan'
    'Goten'
    'Vegeta'
    'Trunks'
)
Write-Label 'Favorite number?' -Indent $Indent -NewLine
$choice = Invoke-Menu @('one'; 'two'; 'three') -SingleSelect -Indent $Indent
Write-Label 'Known mathematicians?' -Indent $Indent -NewLine
$choice = Invoke-Menu @('Godel'; 'Gauss'; 'Cantor') -MultiSelect -Indent $Indent
Write-Label "{{#red Red}}, {{#white White}}, or {{#blue Blue}}?" -Indent $Indent -NewLine
$FavoriteColor = Invoke-Menu @('red', 'white', 'blue') -Indent $Indent
$Space
Write-Title "Results" -Magenta -TextColor White
$Fullname | Write-Label -Indent $Indent -Color $Color -NewLine
$Username | Write-Label -Indent $Indent -Color $Color -NewLine
$Age | Write-Label -Indent $Indent -Color $Color -NewLine
$Pass | Write-Label -Indent $Indent -Color $Color -NewLine
$FavoriteSaiyajin | Write-Label -Indent $Indent -Color $Color -NewLine
(Join-StringsWithGrammar $choice) | Write-Label -Indent $Indent -Color $Color -NewLine
$FavoriteColor | Write-Label -Indent $Indent -Color $Color -NewLine