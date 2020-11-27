# Need to parameterize class with "id" in order to re-load class during local testing
$Id = if ($Env:ProjectName -eq 'pwsh-prelude' -and $Env:BuildSystem -eq 'Unknown') { 'Test' } else { '' }
$TypeDefinition = @"
  using System;
  using System.Collections.ObjectModel;
  using System.Management.Automation;

  public class Coordinate${Id} {

    // All lengths are in meters
    public const double SemiMajorAxis = 6378137.0;// a
    public const double SemiMinorAxis = 6356752.31424518;// b
    public const double FlatteningFactor = 298.257223563;// 1/f
    public const double LinearEccentricity = 521854.00842339;// E
    public const double Eccentricity = 0.0818191908426215;// e
    public const double EccentricitySquared = 0.006694379990141;// e2
    public const double Radius = 6371001;// mean radius
    public const double RadiusAuthalic = 6371007.1810;// radius constant surface area

    private double _Latitude;
    private double _Longitude;
    private string[] _Hemisphere = new string[] { "N","E" };
    public string[] Hemisphere {
      get {
        return _Hemisphere;
      }
      private set {
        _Hemisphere = value;
      }
    }
    public double Latitude {
      get {
        return _Latitude;
      }
      set {
        this.Hemisphere[0] = value < 0 ? "S" : "N";
        _Latitude = value;
      }
    }
    public double Longitude {
      get {
        return _Longitude;
      }
      set {
        this.Hemisphere[1] = value < 0 ? "W" : "E";
        _Longitude = value;
      }
    }
    public double Height;

    private static double ToDegree(double value) {
      return value * (180 / Math.PI);
    }
    private static double ToRadian(double value) {
      return value * (Math.PI / 180);
    }
    private static double Hav(double value) {
      return 0.5 * (1 - Math.Cos(ToRadian(value)));
    }
    public static double[] ToSexagesimal(double value) {
      double fractionalPart = Math.Abs(value - Math.Truncate(value));
      double degree = Math.Truncate(value);
      double minute = Math.Truncate(fractionalPart * 60);
      double second = Math.Round(((fractionalPart * 60) - minute) * 60,2);
      return new double[] { degree,minute,second };
    }
    public Coordinate${Id}() {
      this.Latitude = 0.0;
      this.Longitude = 0.0;
      this.Height = 0.0;
    }
    public Coordinate${Id}(double latitude,double longitude,double height = 0.0) {
      this.Latitude = latitude;
      this.Longitude = longitude;
      this.Height = height;
    }
    public static Coordinate${Id} FromCartesian(double x,double y,double z) {
        double[] geodetic = ToGeodetic(x,y,z);
        double latitude = geodetic[0];
        double longitude = geodetic[1];
        double height = geodetic[2];
        return new Coordinate${Id}(latitude,longitude,height);
    }
    public static double[] ToGeodetic(double x,double y,double z) {
        double a = SemiMajorAxis;
        double b = SemiMinorAxis;
        double E = LinearEccentricity;
        double E2 = Math.Pow(E,2);
        double x2 = Math.Pow(x,2),y2 = Math.Pow(y,2),z2 = Math.Pow(z,2);
        double r2 = x2 + y2 + z2;
        double Q = Math.Sqrt(x2 + y2);
        double u = Math.Sqrt((0.5 * (r2 - E2)) + (0.5 * Math.Sqrt(Math.Pow(r2 - E2,2) + (4 * E2 * z2))));
        double u2 = Math.Pow(u,2);
        double beta = Math.Atan((Math.Sqrt(u2 + E2) * z) / (u * Q));
        double latitude = Math.Atan((a / b) * Math.Tan(beta));
        double longitude = Math.Atan2(y,x);
        double height = Math.Sqrt(Math.Pow(z - (b * Math.Sin(beta)),2) + Math.Pow(Q - (a * Math.Cos(beta)),2));
        return new double[] { ToDegree(latitude),ToDegree(longitude),height };
    }
    public static double[] ToCartesian(double latitude,double longitude,double height = 0) {
        double a = SemiMajorAxis;
        double e2 = EccentricitySquared;
        double lat = ToRadian(latitude);
        double lon = ToRadian(longitude);
        double h = height;
        double v = a / Math.Sqrt(1 - (e2 * Math.Pow(Math.Sin(lat),2)));
        double x = Math.Cos(lat) * Math.Cos(lon) * (v + h);
        double y = Math.Cos(lat) * Math.Sin(lon) * (v + h);
        double z = Math.Sin(lat) * ((v * (1 - e2)) + h);
        return new double[] { x,y,z };
    }
    public override string ToString() {
        double latitude = Math.Abs(this.Latitude);
        double longitude = Math.Abs(this.Longitude);
        string NS = this.Hemisphere[0];
        string WE = this.Hemisphere[1];
        string[] lat = Array.ConvertAll(ToSexagesimal(latitude),Convert.ToString);
        string[] lon = Array.ConvertAll(ToSexagesimal(longitude),Convert.ToString);
        return lat[0] + "°" + lat[1] + "'" + lat[2] + "\"" + NS + " " + lon[0] + "°" + lon[1] + "'" + lon[2] + "\"" + WE;
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