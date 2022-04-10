// <copyright file="Datum.cs" company="Jason Wohlgemuth">
// Copyright (c) 2022 Jason Wohlgemuth. All rights reserved.
// Licensed under the MIT license. See LICENSE file in the project root for full license information.
// </copyright>

namespace Prelude.Geodetic {
    /// <summary>
    /// Container class for World Geodetic System 1984 (WGS84) paramters.
    /// </summary>
    public static class Datum {
        /// <summary>
        /// Semi major axis of the WGS84 ellipsoid, a (in meters).
        /// </summary>
        public const double SemiMajorAxis = 6378137.0;

        /// <summary>
        /// Semi minor axis of the WGS84 ellipsoid, b (in meters).
        /// </summary>
        public const double SemiMinorAxis = 6356752.31424518;

        /// <summary>
        /// Flattening factor of the WGS84 ellipsoid, 1/f.
        /// </summary>
        public const double FlatteningFactor = 298.257223563;

        /// <summary>
        /// Linear eccentricity of the WGS84 ellipsoid, E (in meters).
        /// </summary>
        public const double LinearEccentricity = 521854.00842339;

        /// <summary>
        /// Eccentricity of WGS84 ellipsoid, e.
        /// </summary>
        public const double Eccentricity = 0.0818191908426215;

        /// <summary>
        /// Eccentricity squared, e^2.
        /// </summary>
        public const double EccentricitySquared = 0.006694379990141;

        /// <summary>
        /// Earth mean radius (in meters).
        /// </summary>
        public const double Radius = 6371001;

        /// <summary>
        /// Earth constant surface area radius (in meters).
        /// </summary>
        public const double RadiusAuthalic = 6371007.1810;
    }
}