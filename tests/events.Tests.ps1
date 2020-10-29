if (Get-Module -Name 'pwsh-prelude') {
    Remove-Module -Name 'pwsh-prelude'
}
$Path = Join-Path $PSScriptRoot '..\pwsh-prelude.psm1'
Import-Module $Path -Force

# Describe 'Invoke-ListenTo' {
#     AfterEach {
#         'TestEvent' | Invoke-StopListen
#     }
#     It 'can listen to custom events and trigger actions' {
#         function Test-Callback {}
#         $EventName = 'TestEvent'
#         $Times = 5
#         Mock Test-Callback {}
#         { Test-Callback } | Invoke-ListenTo $EventName
#         1..$Times | ForEach-Object { Invoke-FireEvent $EventName -Data 'test' }
#         Assert-MockCalled Test-Callback -Times $Times
#     }
#     It 'can listen to custom events and trigger one-time action' {
#         function Test-Callback {}
#         $EventName = 'TestEvent'
#         Mock Test-Callback {}
#         { Test-Callback } | Invoke-ListenTo $EventName -Once
#         1..10 | ForEach-Object { Invoke-FireEvent $EventName -Data 'test' }
#         Assert-MockCalled Test-Callback -Times 1
#     }
# }