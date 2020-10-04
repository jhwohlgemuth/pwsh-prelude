Import-Module ./pwsh-handy-helpers.psm1

$fullname = input "Full Name?" -Indent 4
$username = input "Username?" -MaxLength 10 -Indent 4
$age = input "Age?" -Number -Indent 4
$pass = input "Password?" -Secret -Indent 4
$word = input "Favorite Saiya-jin?" -Autocomplete -Indent 4 -Choices `
@(
    'Goku'
    'Gohan'
    'Goten'
    'Vegeta'
    'Trunks'
)
Write-Label 'Favorite number?' -Indent 4 -NewLine
$choice = menu @('one'; 'two'; 'three') -SingleSelect -Indent 4
Write-Label 'Known mathematicians?' -Indent 4 -NewLine
$choice = menu @('Godel'; 'Gauss'; 'Cantor') -MultiSelect -Indent 4
Write-Label "{{#red Red}}, {{#white White}}, or {{#blue Blue}}?" -Indent 4 -NewLine
$color = menu @('red', 'white', 'blue') -Indent 4

$fullname
$username
$age
$pass
$word
$choice
$color