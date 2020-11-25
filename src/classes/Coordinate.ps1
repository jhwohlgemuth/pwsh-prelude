# Need to parameterize class with "id" in order to re-load class during local testing
$Id = if ($Env:ProjectName -eq 'pwsh-prelude' -and $Env:BuildSystem -eq 'Unknown') { 'Test' } else { '' }
$TypeDefinition = @"
  using System;

  public class Coordinate${Id} {

    // All lengths are in meters
    public const double SemiMajorAxis = 6378137.0;// a
    public const double SemiMinorAxis = 6356752.31424518;// b
    public const double FlatteningFactor = 298.257223563;// 1/f
    public const double LinearEccentricity = 521854.00842339;// E
    public const double Eccentricity = 0.0818191908426215;// e
    public const double Radius = 6371001;// mean radius
    public const double RadiusAuthalic = 6371007.1810;// radius constant surface area

    public double Latitude;
    public double Longitude;
    public double Height;

    public Coordinate${Id}() {
        this.Latitude = 0.0;
        this.Longitude = 0.0;
        this.Height = 0.0;
    }
    public Coordinate${Id}(double lat,double lon,double height = 0.0) {
        this.Latitude = lat;
        this.Longitude = lon;
        this.Height = height;
    }
    public static Coordinate${Id} FromCartesian(double x,double y,double z) {
        return new Coordinate${Id}();
    }
    public static double[] ToGeodetic(double x,double y,double z) {
      // double a = SemiMajorAxis;
      // double b = SemiMinorAxis;
      // double E = LinearEccentricity;
      // double E2 = Math.Pow(E,2);
      // double x2 = Math.Pow(x,2);
      // double y2 = Math.Pow(y,2);
      // double z2 = Math.Pow(z,2);
      // double r2 = x2 + y2 + z2;
      // double Q = Math.Sqrt(x2 + y2);
      double latitude = x;
      double longitude = y;
      double height = z;
      return new double[] { latitude,longitude,height };
    }
    public static double[] ToCartesian(double latitude,double longitude,double height = 0) {
        double a = SemiMajorAxis;
        double e2 = 0.006694379990141;
        double lat = Coordinate${Id}.ToRadian(latitude);
        double lon = Coordinate${Id}.ToRadian(longitude);
        double h = height;
        double v = a / Math.Sqrt(1 - (e2 * Math.Pow(Math.Sin(lat),2)));
        double x = Math.Cos(lat) * Math.Cos(lon) * (v + h);
        double y = Math.Cos(lat) * Math.Sin(lon) * (v + h);
        double z = Math.Sin(lat) * ((v * (1 - e2)) + h);
        return new double[] { x,y,z };
    }
    public static double ToRadian(double value) {
      return value * (Math.PI / 180);
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