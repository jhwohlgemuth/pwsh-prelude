using Xunit;
using Prelude;

namespace PriorityQueueTests {
    public class UnitTests {
        [Fact]
        public void Can_be_created_with_no_arguments() {
            var q = new PriorityQueue();
            Assert.Equal(0, q.CurrentSize);
        }
        [Fact]
        public void Can_add_items() {
            var q = new PriorityQueue();
            var u = new Node("u");
            var v = new Node("v");
            q.Insert(1, u);
            Assert.Equal(1, q.CurrentSize);
            q.Insert(2, v);
            Assert.Equal(2, q.CurrentSize);
        }
    }
}