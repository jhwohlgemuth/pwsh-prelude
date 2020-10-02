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
$choice = menu @('one'; 'two'; 'three') -Indent 4

$fullname
$username
$age
$pass
$word
$choice