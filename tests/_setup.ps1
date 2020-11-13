Set-BuildEnvironment -VariableNamePrefix '' -Force

if (Get-Module -Name $Env:ProjectName) {
  Remove-Module -Name $Env:ProjectName
}
$Path = Join-Path $Env:ProjectPath "${Env:ProjectName}.psm1"
Import-Module $Path -Force
if ($Env:BuildSystem -eq 'Travis CI' -and -not "MatrixTest" -as [Type]) {
  $Accelerators = [PowerShell].Assembly.GetType("System.Management.Automation.TypeAccelerators")
  $Accelerators::Add('MatrixTest', 'Matrix')
}