$ClassName = 'Constant'
# Need to parameterize class with "id" in order to re-load class during local testing
$Id = if ($Env:ProjectName -eq 'pwsh-prelude' -and $Env:BuildSystem -eq 'Unknown') { 'Test' } else { '' }
$TypeDefinition = @"
  public static class ${ClassName}${Id} {

      // Also known as "Napier's Constant" 
      public const double Euler = 2.71828182845904523536028747135266249775724709369995;
      
      // Also known as the "Golden Ratio"
      public const double Phi = 1.6180339887;

      // Earth radius at equator (in meters)
      public const double EarthRadiusEquator = 6378137;

      // Mean (average) earth radius (in meters)
      public const double EarthRadiusMean = 6371001;

      // Radius of a sphere with the same surface area (in meters)
      public const double EarthRadiusAuthalic = 6371007;

      // Semi-major axis parameter of Earth ellipsoid WGS84 datum characterization (in meters)
      public const double EarthSemiMajorAxis = 6378137;

      // Flattening parameter of Earth ellipsoid WGS84 datum characterization
      public const double EarthFlattening = 0.0033528106718309896;
  }
"@
if ("${ClassName}${Id}" -as [Type]) {
  return
} else {
  Add-Type -TypeDefinition $TypeDefinition
  if ($Env:BuildSystem -eq 'Travis CI') {
    $Accelerators = [PowerShell].Assembly.GetType('System.Management.Automation.TypeAccelerators')
    $Accelerators::Add("${ClassName}${Id}", $ClassName)
  }
}