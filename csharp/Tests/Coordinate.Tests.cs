using Xunit;
using System;
using System.Collections.Generic;
using Prelude.Geodetic;

namespace CoordinateTests {
    public class UnitTests {
        [Theory]
        [InlineData(0, 0, "N", "E")]
        [InlineData(37, -111, "N", "W")]
        [InlineData(-41.25, 96.4, "S", "E")]
        public void Can_assign_cardinal_directions(double lat, double lon, string NS, string EW) {
            var A = new Coordinate(lat, lon);
            Assert.Equal(new string[] { NS, EW }, A.Hemisphere);
        }
        [Theory]
        [InlineData(41.25, 96.0, 0, -501980.22547, 4776022.81393, 4183337.2134)]
        [InlineData(41.25, 96.0, 1000, -502058.81413, 4776770.53508, 4183996.55921)]
        [InlineData(41.25, 96.0, 10000, -502766.11207, 4783500.02543, 4189930.67155)]
        [InlineData(41.25, 96.0, 100000, -509839.09144, 4850794.92896, 4249271.79491)]
        public void Can_convert_geodetic_to_cartesian(double lat, double lon, double height, double x, double y, double z) {
            var cartesian = Coordinate.ToCartesian(lat, lon, height);
            Assert.Equal(x, cartesian[0], 5);
            Assert.Equal(y, cartesian[1], 5);
            Assert.Equal(z, cartesian[2], 5);
            var coordinate = new Coordinate(lat, lon, height);
            cartesian = coordinate.ToCartesian();
            Assert.Equal(x, cartesian[0], 5);
            Assert.Equal(y, cartesian[1], 5);
            Assert.Equal(z, cartesian[2], 5);
        }
        [Theory]
        [InlineData(-501980.22547, 4776022.81393, 4183337.2134, 41.25, 96, 0)]
        [InlineData(-502058.81413, 4776770.53508, 4183996.55921, 41.25, 96, 1000)]
        [InlineData(-502766.11207, 4783500.02543, 4189930.67155, 41.25, 96, 10000)]
        [InlineData(-509839.09144, 4850794.92896, 4249271.79491, 41.25, 96, 100000)]
        public void Can_convert_Cartesian_to_geodetic(double x, double y, double z, double lat, double lon, double height) {
            var geodetic = Coordinate.ToGeodetic(x, y, z);
            Assert.Equal(lat, geodetic[0], 2);
            Assert.Equal(lon, geodetic[1], 2);
            Assert.Equal(height, geodetic[2], 2);
        }
        [Theory]
        [InlineData(-501980.22547, 4776022.81393, 4183337.2134, 41.25, 96, 0)]
        [InlineData(-502058.81413, 4776770.53508, 4183996.55921, 41.25, 96, 1000)]
        [InlineData(-502766.11207, 4783500.02543, 4189930.67155, 41.25, 96, 10000)]
        [InlineData(-509839.09144, 4850794.92896, 4249271.79491, 41.25, 96, 100000)]
        public void Can_be_created_from_Cartesian_values(double x, double y, double z, double lat, double lon, double height) {
            var a = Coordinate.FromCartesian(x, y, z);
            Assert.Equal(lat, a.Latitude, 2);
            Assert.Equal(lon, a.Longitude, 2);
            Assert.Equal(height, a.Height, 2);
        }
        [Theory]
        [InlineData(32.7157, 32, 42, 56.52)]
        [InlineData(96, 96, 0, 0)]
        [InlineData(116.7762, 116, 46, 34.32)]
        [InlineData(-116.7762, -116, 46, 34.32)]
        public void Can_convert_to_sexgesimal(double decimalDegrees, double degrees, double minutes, double seconds) {
            var sexagesimal = Coordinate.ToSexagesimal(decimalDegrees);
            Assert.Equal(degrees, sexagesimal[0]);
            Assert.Equal(minutes, sexagesimal[1]);
            Assert.Equal(seconds, sexagesimal[2]);
        }
        [Theory]
        [InlineData(0, 0, 0, "0°0'0\"N 0°0'0\"E")]
        [InlineData(42.62, -123, 10, "42°37'12\"N 123°0'0\"W")]
        [InlineData(-12.75, 77, 10, "12°45'0\"S 77°0'0\"E")]
        [Trait("Category", "Instance")]
        public void Can_override_ToString(double lat, double lon, double height, string expected) {
            var latlon = new Coordinate(lat, lon, height);
            Assert.Equal(expected, latlon.ToString());
        }
        [Fact]
        public void Can_create_coordinate_at_origin_by_default() {
            var coordinate = new Coordinate();
            Assert.Equal(0, coordinate.Latitude);
            Assert.Equal(0, coordinate.Longitude);
            Assert.Equal(0, coordinate.Height);
        }
        [Fact]
        public void Can_throw_an_exception_for_null_comparisons() {
            var a = new Coordinate(89, 123);
            var ex = Assert.Throws<ArgumentException>(() => a.CompareTo(null));
            var message = "Parameter is not a Coordinate";
            Assert.Equal(message, ex.Message);
        }
        [Fact]
        public void Can_be_compared_in_various_contexts() {
            var a = new Coordinate(41.25, -96);
            var b = new Coordinate(89, 123);
            Assert.True(a.Equals(a));
            Assert.False(a.Equals(b));
            Assert.False(a.Equals(null));
            Assert.True(Equals(a, a));
            Assert.False(Equals(a, b));
            Assert.False(Equals(null, a));
            Assert.False(Equals(a, null));
            Assert.True(Equals(null, null));
            Assert.Equal(0, a.CompareTo(a));
            Assert.Equal(1, a.CompareTo(b));
#pragma warning disable CS1718 // Comparison made to same variable
            Assert.True(a == a);
            Assert.False(a != a);
#pragma warning restore CS1718 // Comparison made to same variable
            Assert.False(a == b);
            Assert.True(a != b);
            Assert.True(a != null);
            Assert.True(null != a);
            var values = new List<Coordinate> { a, b };
            values.Sort();
            Assert.Contains(a, values);
            values = new List<Coordinate> { a, b, null };
            Assert.Throws<InvalidOperationException>(() => values.Sort());
            Assert.Equal(a.GetHashCode(), a.GetHashCode());
        }
        [Fact]
        public void Can_caluculate_earth_radius_at_given_latitude() {
            Assert.Equal(Datum.SemiMinorAxis, Coordinate.GetEarthRadius(90));
            Assert.Equal(6367489.543863465, Coordinate.GetEarthRadius(45));
            Assert.Equal(6374777.820875008, Coordinate.GetEarthRadius(23.437055555555556));
            Assert.Equal(Datum.SemiMajorAxis, Coordinate.GetEarthRadius());
            Assert.Equal(Datum.SemiMinorAxis, Coordinate.GetEarthRadius(-90));
            var coordinate = new Coordinate(90, 0);
            Assert.Equal(Datum.SemiMinorAxis, Coordinate.GetEarthRadius(coordinate));
            coordinate = new Coordinate(0, 0);
            Assert.Equal(Datum.SemiMajorAxis, Coordinate.GetEarthRadius(coordinate));
            coordinate = new Coordinate(-90, 0);
            Assert.Equal(Datum.SemiMinorAxis, Coordinate.GetEarthRadius(coordinate));
        }
        [Fact]
        public void Can_calculate_Haversine_distance() {
            var a = new Coordinate();
            var b = new Coordinate();
            Assert.Equal(0, a - b);
            Assert.Equal(0, Coordinate.HaversineDistance(a, b));
            var omaha = new Coordinate(41.25, -96);
            var sandiego = new Coordinate(32.7157, -117.1611);
            Assert.Equal(2097705.740066118, omaha - sandiego);
            Assert.Equal(2097705.740066118, sandiego - omaha);
            Assert.Equal(2097705.740066118, Coordinate.HaversineDistance(omaha, sandiego));
        }
        [Fact]
        public void Can_compare_coordinates() {
            var a = new Coordinate(42, -96);
            var b = new Coordinate(-30, 77);
            var c = new Coordinate(42, -96);
            var d = new Coordinate(42, -96, 100);
            Assert.Equal(a, a);
            Assert.Equal(a, c);
            Assert.NotEqual(a, b);
            Assert.NotEqual(a, d);
        }
    }
}