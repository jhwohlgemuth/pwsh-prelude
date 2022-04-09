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
}