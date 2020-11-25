﻿# Need to parameterize class with "id" in order to re-load class during local testing
$Id = if ($Env:ProjectName -eq 'pwsh-prelude' -and $Env:BuildSystem -eq 'Unknown') { 'Test' } else { '' }
$TypeDefinition = @"
  public static class Constant${Id} {

      // Also known as "Napier's Constant"
      public const double Euler = 2.71828182845904523536028747135266249775724709369995;

      // Also known as the "Golden Ratio"
      public const double Phi = 1.6180339887;
  }
"@
if ("Constant${Id}" -as [Type]) {
  return
} else {
  Add-Type -TypeDefinition $TypeDefinition
  if ($Env:BuildSystem -eq 'Travis CI') {
    $Accelerators = [PowerShell].Assembly.GetType('System.Management.Automation.TypeAccelerators')
    $Accelerators::Add('ConstantTest', 'Constant')
  }
}