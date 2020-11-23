# Need to parameterize class with "id" in order to re-load class during local testing
$Id = if ($Env:ProjectName -eq 'pwsh-prelude' -and $Env:BuildSystem -eq 'Unknown') { 'Test' } else { '' }
$TypeDefinition = @"
  using System;
  using System.Collections.ObjectModel;
  using System.Management.Automation;

  public static class Prelude${Id} {

      public static PSObject Hav(double theta) {
        Collection<PSObject> results = PowerShell.Create().AddCommand("Get-Haversine").AddArgument(theta).Invoke();
        return results[0];
      }
      public static PSObject Ahav(double value) {
        Collection<PSObject> results = PowerShell.Create().AddCommand("Get-ArcHaversine").AddArgument(value).Invoke();
        return results[0];
      }
  }
"@
if ("Prelude${Id}" -as [Type]) {
  return
} else {
  Add-Type -TypeDefinition $TypeDefinition
  if ($Env:BuildSystem -eq 'Travis CI') {
    $Accelerators = [PowerShell].Assembly.GetType('System.Management.Automation.TypeAccelerators')
    $Accelerators::Add('PreludeTest', 'Prelude')
  }
}