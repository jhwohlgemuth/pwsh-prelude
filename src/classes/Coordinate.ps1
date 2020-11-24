# Need to parameterize class with "id" in order to re-load class during local testing
$Id = if ($Env:ProjectName -eq 'pwsh-prelude' -and $Env:BuildSystem -eq 'Unknown') { 'Test' } else { '' }
$TypeDefinition = @"
  using System;

  public class Coordinate${Id} {

    public double Latitude;
    public double Longitude;
    public double Height;

    public Coordinate${Id}() {
        this.Latitude = 0.0;
        this.Longitude = 0.0;
        this.Height = 0.0;
    }
    public static Coordinate${Id} FromCartesian(double x,double y,double z) {
        return new Coordinate${Id}();
    }
    public Coordinate${Id}(double lat,double lon,double height = 0.0) {
        this.Latitude = lat;
        this.Longitude = lon;
        this.Height = height;
    }
    public double[] ToCartesian() {
        var coord = new double[] { this.Latitude,this.Longitude,this.Height };
        return coord;
    }
    public override string ToString() {
        return "hello world";
    }
  }
"@
if ("Coordinate${Id}" -as [Type]) {
  return
} else {
  Add-Type -TypeDefinition $TypeDefinition
  if ($Env:BuildSystem -eq 'Travis CI') {
    $Accelerators = [PowerShell].Assembly.GetType('System.Management.Automation.TypeAccelerators')
    $Accelerators::Add('CoordinateTest', 'Coordinate')
  }
}