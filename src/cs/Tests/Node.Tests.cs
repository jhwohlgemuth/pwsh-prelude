using Xunit;
using Prelude;

namespace NodeTests {
    public class UnitTests {
        [Fact]
        public void Node_will_be_assigned_Id_Automatically() {
            var n = new Node("test");
            Assert.Equal(36, n.Id.ToString().Length);
            Assert.Equal("test", n.Name);
        }
    }
}