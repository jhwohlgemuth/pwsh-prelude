Import-Module ./pwsh-handy-helpers.psm1

Write-Title "Kitchen Sink"
$fullname = Invoke-Input "Full Name?" -Indent 4
$username = Invoke-Input "Username?" -MaxLength 10 -Indent 4
$age = Invoke-Input "Age?" -Number -Indent 4
$pass = Invoke-Input "Password?" -Secret -Indent 4
$word = Invoke-Input "Favorite Saiya-jin?" -Autocomplete -Indent 4 -Choices `
@(
    'Goku'
    'Gohan'
    'Goten'
    'Vegeta'
    'Trunks'
)
Write-Label 'Favorite number?' -Indent 4 -NewLine
$choice = Invoke-Menu @('one'; 'two'; 'three') -SingleSelect -Indent 4
Write-Label 'Known mathematicians?' -Indent 4 -NewLine
$choice = Invoke-Menu @('Godel'; 'Gauss'; 'Cantor') -MultiSelect -Indent 4
Write-Label "{{#red Red}}, {{#white White}}, or {{#blue Blue}}?" -Indent 4 -NewLine
$color = Invoke-Menu @('red', 'white', 'blue') -Indent 4

$fullname
$username
$age
$pass
$word
$choice
$color