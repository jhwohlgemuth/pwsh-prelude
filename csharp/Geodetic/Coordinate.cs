// <copyright file="Coordinate.cs" company="Jason Wohlgemuth">
// Copyright (c) 2022 Jason Wohlgemuth. All rights reserved.
// Licensed under the MIT license. See LICENSE file in the project root for full license information.
// </copyright>

namespace Prelude.Geodetic {
    using System;
    using static System.Math;

    /// <summary>
    /// Represents a geodetic coordinate.
    /// </summary>
    public class Coordinate : IEquatable<Coordinate>, IComparable<Coordinate> {
        private double latitude;
        private double longitude;
        private string[] hemisphere = new string[] { "N", "E" };

        /// <summary>
        /// Initializes a new instance of the <see cref="Coordinate"/> class.
        /// </summary>
        public Coordinate() {
            Latitude = 0.0;
            Longitude = 0.0;
            Height = 0.0;
        }

        /// <summary>
        /// Initializes a new instance of the <see cref="Coordinate"/> class.
        /// </summary>
        /// <param name="latitude">Geodetic latitude in degrees.</param>
        /// <param name="longitude">Geodetic longitude in degrees.</param>
        /// <param name="height">Height in meters.</param>
        public Coordinate(double latitude, double longitude, double height = 0.0) {
            Latitude = latitude;
            Longitude = longitude;
            Height = height;
        }

        /// <summary>
        /// Gets property for hemisphere value which is described by two cardinal directions, North (N) or South (S) and East (E) or West (W).
        /// </summary>
        public string[] Hemisphere {
            get {
                return hemisphere;
            }

            private set {
                hemisphere = value;
            }
        }

        /// <summary>
        /// Gets or sets property for latitude value which specifies the North–South position of a point on the Earth's surface.
        /// </summary>
        public double Latitude {
            get {
                return latitude;
            }

            set {
                Hemisphere[0] = value < 0 ? "S" : "N";
                latitude = value;
            }
        }

        /// <summary>
        /// Gets or sets property for longitude value which specifies the East–West position of a point on the Earth's surface.
        /// </summary>
        public double Longitude {
            get {
                return longitude;
            }

            set {
                Hemisphere[1] = value < 0 ? "W" : "E";
                longitude = value;
            }
        }

        /// <summary>
        /// Gets or sets property for distance from Earth's surface (in meters).
        /// </summary>
        public double Height {
            get;
            set;
        }

        public static bool operator ==(Coordinate left, Coordinate right) {
            if (((object)left) == null || ((object)right == null))
                return Equals(left, right);
            return left.Equals(right);
        }

        public static bool operator !=(Coordinate left, Coordinate right) {
            if (((object)left) == null || ((object)right == null))
                return !Equals(left, right);
            return !left.Equals(right);
        }

        public static double operator -(Coordinate a, Coordinate b) => HaversineDistance(a, b);

        /// <summary>
        /// Convert coordinate to cartesion format, (x, y, z).
        /// </summary>
        /// <param name="latitude">Geodetic latitude in degrees.</param>
        /// <param name="longitude">Geodetic longitude in degrees.</param>
        /// <param name="height">Height in meters.</param>
        /// <returns>A coordinate value in the form, double[] { x, y, z }.</returns>
        public static double[] ToCartesian(double latitude, double longitude, double height = 0) {
            double a = Datum.SemiMajorAxis;
            double eSquared = Datum.EccentricitySquared;
            double lat = ToRadian(latitude);
            double lon = ToRadian(longitude);
            double h = height;
            double v = a / Sqrt(1 - (eSquared * Pow(Sin(lat), 2)));
            double x = Cos(lat) * Cos(lon) * (v + h);
            double y = Cos(lat) * Sin(lon) * (v + h);
            double z = Sin(lat) * ((v * (1 - eSquared)) + h);
            return new double[] { x, y, z };
        }

        /// <summary>
        /// Convert coordinate to sexagesimal format.
        /// </summary>
        /// <param name="value">Input in decimal format.</param>
        /// <returns>A coordinate value in the form, double[] { degree, minute, second }.</returns>
        public static double[] ToSexagesimal(double value) {
            double fractionalPart = Abs(value - Truncate(value));
            double degree = Truncate(value);
            double minute = Truncate(fractionalPart * 60);
            double second = Round(((fractionalPart * 60) - minute) * 60, 2);
            return new double[] { degree, minute, second };
        }

        /// <summary>
        /// Convert coordinate to geodetic format, (latitude, longitude, height).
        /// </summary>
        /// <param name="x">X value of coordinate.</param>
        /// <param name="y">Y value of coordinate.</param>
        /// <param name="z">Z value of coordinate.</param>
        /// <returns>A geodetic coordinate value in the form, double[] { latitude, longitude, height } (in degrees).</returns>
        public static double[] ToGeodetic(double x, double y, double z) {
            double a = Datum.SemiMajorAxis;
            double b = Datum.SemiMinorAxis;
            double e = Datum.LinearEccentricity;
            double eSquared = Pow(e, 2);
            double x2 = Pow(x, 2), y2 = Pow(y, 2), z2 = Pow(z, 2);
            double r2 = x2 + y2 + z2;
            double q = Sqrt(x2 + y2);
            double u = Sqrt(0.5 * ((r2 - eSquared) + Sqrt(Pow(r2 - eSquared, 2) + (4 * eSquared * z2))));
            double u2 = Pow(u, 2);
            double beta = Atan(Sqrt(u2 + eSquared) * z / (u * q));
            double latitude = Atan(a / b * Tan(beta));
            double longitude = Atan2(y, x);
            double height = Sqrt(Pow(z - (b * Sin(beta)), 2) + Pow(q - (a * Cos(beta)), 2));
            return new double[] { ToDegree(latitude), ToDegree(longitude), height };
        }

        /// <summary>
        /// Create coordinate from cartesion input, (x, y, z).
        /// </summary>
        /// <param name="x">X value of coordinate.</param>
        /// <param name="y">Y value of coordinate.</param>
        /// <param name="z">Z value of coordinate.</param>
        /// <returns>A coordinate value.</returns>
        public static Coordinate FromCartesian(double x, double y, double z) {
            double[] geodetic = ToGeodetic(x, y, z);
            double latitude = geodetic[0];
            double longitude = geodetic[1];
            double height = geodetic[2];
            return new Coordinate(latitude, longitude, height);
        }

        /// <summary>
        /// Get Earth radius at a given latitude, in degrees.
        /// </summary>
        /// <param name="latitude">Geodetic latitude, in degrees.</param>
        /// <returns>Earth radius, in meters.</returns>
        public static double GetEarthRadius(double latitude = 0) {
            var a = Datum.SemiMajorAxis;
            var b = Datum.SemiMinorAxis;
            var beta = ToRadian(latitude);
            return Sqrt((Pow(Pow(a, 2) * Cos(beta), 2) + Pow(Pow(b, 2) * Sin(beta), 2)) / (Pow(a * Cos(beta), 2) + Pow(b * Sin(beta), 2)));
        }

        /// <summary>
        /// GetEarthRadius that accepts a Coordinate value as input.
        /// </summary>
        /// <param name="a">Input coordinate.</param>
        /// <returns>Earth radius, in meters.</returns>
        /// <see cref="GetEarthRadius(double)"/>
        public static double GetEarthRadius(Coordinate a) {
            return GetEarthRadius(a.Latitude);
        }

        /// <summary>
        /// Calculate Haversine distance between two coordinate points.
        /// </summary>
        /// <param name="from">Coordinate value distance should be calculated from.</param>
        /// <param name="to">Coordinate value distance should be calculated to.</param>
        /// <returns>Distance, in meters, between coordinates.</returns>
        /// <seealso cref="operator-"/>
        public static double HaversineDistance(Coordinate from, Coordinate to) {
            var radius = (GetEarthRadius(from.Latitude) + GetEarthRadius(to.Latitude)) / 2;
            var radicand = Haversine(to.Latitude - from.Latitude) + (Cos(ToRadian(from.Latitude)) * Cos(ToRadian(to.Latitude)) * Haversine(to.Longitude - from.Longitude));
            return 2 * radius * Asin(Sqrt(radicand));
        }

        /// <summary>
        /// Instance method version of ToCartesian.
        /// </summary>
        /// <returns>Cartesian coordinates in the form, double[] { x, y, z }.</returns>
        /// <see cref="ToCartesian(double, double, double)"/>
        public double[] ToCartesian() {
            return ToCartesian(Latitude, Longitude, Height);
        }

        /// <inheritdoc/>
        public override string ToString() {
            double latitude = Abs(Latitude);
            double longitude = Abs(Longitude);
            string northsouth = Hemisphere[0];
            string westeast = Hemisphere[1];
            string[] lat = Array.ConvertAll(ToSexagesimal(latitude), Convert.ToString);
            string[] lon = Array.ConvertAll(ToSexagesimal(longitude), Convert.ToString);
            return $"{lat[0]}°{lat[1]}'{lat[2]}\"{northsouth} {lon[0]}°{lon[1]}'{lon[2]}\"{westeast}";
        }

        /// <inheritdoc/>
        public int CompareTo(Coordinate other) {
            if (other != null) {
                return this == other ? 0 : 1;
            } else {
                throw new ArgumentException("Parameter is not a Coordinate");
            }
        }

        /// <summary>
        /// Determines if two coordinates are equal.
        /// </summary>
        /// <param name="other">This is the coordinate to check equality with.</param>
        /// <seealso cref="operator=="/>
        /// <seealso cref="operator!="/>
        /// <seealso cref="GetHashCode"/>
        /// <returns>True if equal, false otherwise.</returns>
        public bool Equals(Coordinate other) {
            if (other == null)
                return false;
            return other.Latitude == Latitude && other.Longitude == Longitude && other.Height == Height;
        }

        /// <inheritdoc/>
        public override bool Equals(object obj) {
            Coordinate a = obj as Coordinate;
            return Equals(a);
        }

        /// <inheritdoc/>
        public override int GetHashCode() => ToString().GetHashCode();

        private static double Haversine(double value) => 0.5 * (1 - Cos(ToRadian(value)));

        private static double ToDegree(double value) => value * (180 / PI);

        private static double ToRadian(double value) => value * (PI / 180);
    }
}