using System;
using static System.Math;

namespace Prelude.Geodetic {
    public static class Datum {
        public const double SemiMajorAxis = 6378137.0; // a (in meters)
        public const double SemiMinorAxis = 6356752.31424518; // b (in meters)
        public const double FlatteningFactor = 298.257223563; // 1/f
        public const double LinearEccentricity = 521854.00842339; // E (in meters)
        public const double Eccentricity = 0.0818191908426215; // e
        public const double EccentricitySquared = 0.006694379990141; // e2
        public const double Radius = 6371001; // mean radius (in meters)
        public const double RadiusAuthalic = 6371007.1810; // radius constant surface area (in meters)
    }
    public class Coordinate {
        private double _Latitude;
        private double _Longitude;
        private string[] _Hemisphere = new string[] { "N", "E" };
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
                Hemisphere[0] = value < 0 ? "S" : "N";
                _Latitude = value;
            }
        }
        public double Longitude {
            get {
                return _Longitude;
            }
            set {
                Hemisphere[1] = value < 0 ? "W" : "E";
                _Longitude = value;
            }
        }
        public double Height;
        private static double ToDegree(double value) => value * (180 / PI);
        private static double ToRadian(double value) => value * (PI / 180);
        public static double[] ToSexagesimal(double value) {
            double fractionalPart = Abs(value - Truncate(value));
            double degree = Truncate(value);
            double minute = Truncate(fractionalPart * 60);
            double second = Round(((fractionalPart * 60) - minute) * 60, 2);
            return new double[] { degree, minute, second };
        }
        public Coordinate() {
            Latitude = 0.0;
            Longitude = 0.0;
            Height = 0.0;
        }
        public Coordinate(double latitude, double longitude, double height = 0.0) {
            Latitude = latitude;
            Longitude = longitude;
            Height = height;
        }
        public static Coordinate FromCartesian(double x, double y, double z) {
            double[] geodetic = ToGeodetic(x, y, z);
            double latitude = geodetic[0];
            double longitude = geodetic[1];
            double height = geodetic[2];
            return new Coordinate(latitude, longitude, height);
        }
        public static double[] ToGeodetic(double x, double y, double z) {
            double a = Datum.SemiMajorAxis;
            double b = Datum.SemiMinorAxis;
            double E = Datum.LinearEccentricity;
            double E2 = Pow(E, 2);
            double x2 = Pow(x, 2), y2 = Pow(y, 2), z2 = Pow(z, 2);
            double r2 = x2 + y2 + z2;
            double Q = Sqrt(x2 + y2);
            double u = Sqrt(0.5 * (r2 - E2) + 0.5 * Sqrt(Pow(r2 - E2, 2) + (4 * E2 * z2)));
            double u2 = Pow(u, 2);
            double beta = Atan(Sqrt(u2 + E2) * z / (u * Q));
            double latitude = Atan(a / b * Tan(beta));
            double longitude = Atan2(y, x);
            double height = Sqrt(Pow(z - (b * Sin(beta)), 2) + Pow(Q - a * Cos(beta), 2));
            return new double[] { ToDegree(latitude), ToDegree(longitude), height };
        }
        public static double[] ToCartesian(double latitude, double longitude, double height = 0) {
            double a = Datum.SemiMajorAxis;
            double e2 = Datum.EccentricitySquared;
            double lat = ToRadian(latitude);
            double lon = ToRadian(longitude);
            double h = height;
            double v = a / Sqrt(1 - (e2 * Pow(Sin(lat), 2)));
            double x = Cos(lat) * Cos(lon) * (v + h);
            double y = Cos(lat) * Sin(lon) * (v + h);
            double z = Sin(lat) * ((v * (1 - e2)) + h);
            return new double[] { x, y, z };
        }
        public override string ToString() {
            double latitude = Abs(Latitude);
            double longitude = Abs(Longitude);
            string NS = Hemisphere[0];
            string WE = Hemisphere[1];
            string[] lat = Array.ConvertAll(ToSexagesimal(latitude), Convert.ToString);
            string[] lon = Array.ConvertAll(ToSexagesimal(longitude), Convert.ToString);
            return $"{lat[0]}°{lat[1]}'{lat[2]}\"{NS} {lon[0]}°{lon[1]}'{lon[2]}\"{WE}";
        }
    }
}