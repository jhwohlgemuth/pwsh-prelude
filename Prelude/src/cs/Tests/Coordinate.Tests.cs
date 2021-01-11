using Xunit;
using Prelude.Geodetic;

namespace CoordinateTests {
    public class UnitTests {
        [Theory]
        [InlineData(0, 0, "N", "E")]
        [InlineData(37, -111, "N", "W")]
        [InlineData(-41.25, 96.4, "S", "E")]
        public void Can_Assign_Cardinal_Directions(double lat, double lon, string NS, string EW) {
            var A = new Coordinate(lat, lon);
            Assert.Equal(new string[] { NS, EW }, A.Hemisphere);
        }
        [Theory]
        [InlineData(41.25, 96.0, 0, -501980.22547, 4776022.81393, 4183337.2134)]
        [InlineData(41.25, 96.0, 1000, -502058.81413, 4776770.53508, 4183996.55921)]
        [InlineData(41.25, 96.0, 10000, -502766.11207, 4783500.02543, 4189930.67155)]
        [InlineData(41.25, 96.0, 100000, -509839.09144, 4850794.92896, 4249271.79491)]
        public void Can_Convert_Geodetic_to_Cartesian(double lat, double lon, double height, double x, double y, double z) {
            var cartesian = Coordinate.ToCartesian(lat, lon, height);
            Assert.Equal(x, cartesian[0], 5);
            Assert.Equal(y, cartesian[1], 5);
            Assert.Equal(z, cartesian[2], 5);
        }
        [Theory]
        [InlineData(-501980.22547, 4776022.81393, 4183337.2134, 41.25, 96, 0)]
        [InlineData(-502058.81413, 4776770.53508, 4183996.55921, 41.25, 96, 1000)]
        [InlineData(-502766.11207, 4783500.02543, 4189930.67155, 41.25, 96, 10000)]
        [InlineData(-509839.09144, 4850794.92896, 4249271.79491, 41.25, 96, 100000)]
        public void Can_Convert_Cartesian_to_Geodetic(double x, double y, double z, double lat, double lon, double height) {
            var geodetic = Coordinate.ToGeodetic(x, y, z);
            Assert.Equal(lat, geodetic[0], 2);
            Assert.Equal(lon, geodetic[1], 2);
            Assert.Equal(height, geodetic[2], 2);
        }
        [Theory]
        [InlineData(32.7157, 32, 42, 56.52)]
        [InlineData(96, 96, 0, 0)]
        [InlineData(116.7762, 116, 46, 34.32)]
        [InlineData(-116.7762, -116, 46, 34.32)]
        public void Can_Convert_to_Sexgesimal(double decimalDegrees, double degrees, double minutes, double seconds) {
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
        public void Can_Override_ToString(double lat, double lon, double height, string expected) {
            var latlon = new Coordinate(lat, lon, height);
            Assert.Equal(expected, latlon.ToString());
        }
    }
}