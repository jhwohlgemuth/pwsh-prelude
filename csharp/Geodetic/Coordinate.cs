﻿// <copyright file="Coordinate.cs" company="PlaceholderCompany">
// Copyright (c) PlaceholderCompany. All rights reserved.
// </copyright>

namespace Prelude.Geodetic {
    using System;
    using static System.Math;

    public class Coordinate : IEquatable<Coordinate>, IComparable<Coordinate> {
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
        private static double Haversine(double value) => 0.5 * (1 - Cos(ToRadian(value)));
        private static double ToDegree(double value) => value * (180 / PI);
        private static double ToRadian(double value) => value * (PI / 180);
        /// <summary>
        /// Convert coordinate to sexagesimal format
        /// </summary>
        /// <param name="value">Input in decimal format</param>
        /// <returns>double[] { degree, minute, second }</returns>
        public static double[] ToSexagesimal(double value) {
            double fractionalPart = Abs(value - Truncate(value));
            double degree = Truncate(value);
            double minute = Truncate(fractionalPart * 60);
            double second = Round(((fractionalPart * 60) - minute) * 60, 2);
            return new double[] { degree, minute, second };
        }
        /// <summary>
        /// Constructor to create coordinate at 0,0,0
        /// </summary>
        public Coordinate() {
            Latitude = 0.0;
            Longitude = 0.0;
            Height = 0.0;
        }
        /// <summary>
        /// Constructor to create coordinate at passed latitude, longitude, and height
        /// </summary>
        /// <param name="latitude">Geodetic latitude in degrees</param>
        /// <param name="longitude">Geodetic longitude in degrees</param>
        /// <param name="height">Height in meters</param>
        public Coordinate(double latitude, double longitude, double height = 0.0) {
            Latitude = latitude;
            Longitude = longitude;
            Height = height;
        }
        /// <summary>
        /// Determines if two coordinates are equal
        /// </summary>
        /// <param name="obj"></param>
        /// <seealso cref="operator=="/>
        /// <seealso cref="operator!="/>
        /// <seealso cref="GetHashCode"/>
        public bool Equals(Coordinate other) {
            if (other == null)
                return false;
            return other.Latitude == Latitude && other.Longitude == Longitude && other.Height == Height;
        }
        public override bool Equals(object obj) {
            Coordinate a = obj as Coordinate;
            return Equals(a);
        }
        public override int GetHashCode() => ToString().GetHashCode();
        public static bool operator ==(Coordinate left, Coordinate right) {
            if (((object)left) == null || ((object)right == null))
                return Equals(left, right);
            return left.Equals(right);
        }
        public static bool operator !=(Coordinate left, Coordinate right) {
            if (((object)left) == null || ((object)right == null))
                return !Equals(left, right);
            return !(left.Equals(right));
        }
        /// <summary>
        /// Create coordinate from cartesion input, (x, y, z)
        /// </summary>
        /// <param name="x">X value of coordinate</param>
        /// <param name="y">Y value of coordinate</param>
        /// <param name="z">Z value of coordinate</param>
        /// <returns>Coordinate</returns>
        public static Coordinate FromCartesian(double x, double y, double z) {
            double[] geodetic = ToGeodetic(x, y, z);
            double latitude = geodetic[0];
            double longitude = geodetic[1];
            double height = geodetic[2];
            return new Coordinate(latitude, longitude, height);
        }
        /// <summary>
        /// Get Earth radius at a given latitude, in degrees
        /// </summary>
        /// <param name="latitude">Geodetic latitude, in degrees</param>
        /// <returns>Earth radius, in meters</returns>
        public static double GetEarthRadius(double latitude = 0) {
            var a = Datum.SemiMajorAxis;
            var b = Datum.SemiMinorAxis;
            var B = ToRadian(latitude);
            return Sqrt((Pow((Pow(a, 2) * Cos(B)), 2) + Pow((Pow(b, 2) * Sin(B)), 2)) / (Pow((a * Cos(B)), 2) + Pow((b * Sin(B)), 2)));
        }
        /// <summary>
        /// GetEarthRadius that accepts Coordinate as input
        /// </summary>
        /// <param name="a">Input coordinate</param>
        /// <returns>Earth radius, in meters</returns>
        /// <see cref="GetEarthRadius(double)"/>
        public static double GetEarthRadius(Coordinate a) {
            return GetEarthRadius(a.Latitude);
        }
        /// <summary>
        /// Calculate Haversine distance between two coordinate points
        /// </summary>
        /// <param name="from"></param>
        /// <param name="to"></param>
        /// <returns>Distance, in meters, between coordinates</returns>
        /// <seealso cref="operator-"/>
        public static double HaversineDistance(Coordinate from, Coordinate to) {
            var radius = (GetEarthRadius(from.Latitude) + GetEarthRadius(to.Latitude)) / 2;
            var radicand = Haversine(to.Latitude - from.Latitude) + Cos(ToRadian(from.Latitude)) * Cos(ToRadian(to.Latitude)) * Haversine(to.Longitude - from.Longitude);
            return 2 * radius * Asin(Sqrt(radicand));
        }
        public static double operator -(Coordinate a, Coordinate b) => HaversineDistance(a, b);
        /// <summary>
        /// Convert coordinate to geodetic format, (latitude, longitude, height)
        /// </summary>
        /// <param name="x">X value of coordinate</param>
        /// <param name="y">Y value of coordinate</param>
        /// <param name="z">Z value of coordinate</param>
        /// <returns>double[] { latitude, longitude, height } (in degrees)</returns>
        public static double[] ToGeodetic(double x, double y, double z) {
            double a = Datum.SemiMajorAxis;
            double b = Datum.SemiMinorAxis;
            double E = Datum.LinearEccentricity;
            double E2 = Pow(E, 2);
            double x2 = Pow(x, 2), y2 = Pow(y, 2), z2 = Pow(z, 2);
            double r2 = x2 + y2 + z2;
            double Q = Sqrt(x2 + y2);
            double u = Sqrt(0.5 * ((r2 - E2) + Sqrt(Pow(r2 - E2, 2) + (4 * E2 * z2))));
            double u2 = Pow(u, 2);
            double beta = Atan(Sqrt(u2 + E2) * z / (u * Q));
            double latitude = Atan(a / b * Tan(beta));
            double longitude = Atan2(y, x);
            double height = Sqrt(Pow(z - (b * Sin(beta)), 2) + Pow(Q - (a * Cos(beta)), 2));
            return new double[] { ToDegree(latitude), ToDegree(longitude), height };
        }
        /// <summary>
        /// Convert coordinate to cartesion format, (x, y, z)
        /// </summary>
        /// <param name="latitude">Geodetic latitude in degrees</param>
        /// <param name="longitude">Geodetic longitude in degrees</param>
        /// <param name="height">Height in meters</param>
        /// <returns>double[] { x, y, z }</returns>
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
        /// <summary>
        /// Instance method version of ToCartesian
        /// </summary>
        /// <returns>double[] { x, y, z }</returns>
        /// <see cref="ToCartesian(double, double, double)"/>
        public double[] ToCartesian() {
            return ToCartesian(Latitude, Longitude, Height);
        }
        /// <summary>
        /// Convert coordinate to string output
        /// </summary>
        /// <example>
        ///     var x = new Coordinate();
        ///     Console.WriteLine(x);
        ///     // 0°0'0"N 0°0'0"E
        /// </example>
        /// <returns>String representation of coordinate data</returns>
        public override string ToString() {
            double latitude = Abs(Latitude);
            double longitude = Abs(Longitude);
            string NS = Hemisphere[0];
            string WE = Hemisphere[1];
            string[] lat = Array.ConvertAll(ToSexagesimal(latitude), Convert.ToString);
            string[] lon = Array.ConvertAll(ToSexagesimal(longitude), Convert.ToString);
            return $"{lat[0]}°{lat[1]}'{lat[2]}\"{NS} {lon[0]}°{lon[1]}'{lon[2]}\"{WE}";
        }
        public int CompareTo(Coordinate other) {
            if (other != null) {
                return (this == other ? 0 : 1);
            } else {
                throw new ArgumentException("Parameter is not a Coordinate");
            }
        }
    }
}