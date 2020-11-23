# Need to parameterize class with "id" in order to re-load class during local testing
$Id = if ($Env:ProjectName -eq 'pwsh-prelude' -and $Env:BuildSystem -eq 'Unknown') { 'Test' } else { '' }
$TypeDefinition = @"
  using System;
  using System.Collections.ObjectModel;
  using System.Management.Automation;

  public static class Prelude${Id} {

      public static PSObject Invoke(string command,double value) {
        Collection<PSObject> results = PowerShell.Create().AddCommand(command).AddArgument(value).Invoke();
        return results[0];
      }
      public static PSObject Hav(double value) {
        return Prelude.Invoke("Get-Haversine",value);
      }
      public static PSObject Ahav(double value) {
        return Prelude.Invoke("Get-ArcHaversine",value);
      }
      public static PSObject Sigmoid(double value) {
        return Prelude.Invoke("Get-LogisticSigmoid",value);
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