using Xunit;
using System.Linq;
using System.Collections.Generic;
using Prelude;

namespace HeapTests {
    public class UnitTests {
        [Fact]
        public void can_be_created_with_no_arguments() {
            var h = new Heap();
            Assert.Empty(h.Nodes);
        }
        [Fact]
        public void can_be_created_from_list_of_integers() {
            var a = Heap.From(new List<int> { 1, 2, 3, 4, 5, 6 });
            var b = Heap.From(new List<int> { 6, 2, 1, 3, 4, 5 });
            var c = Heap.From(new List<int> { 6, 3, 1, 3, 1, 5 });
            foreach (var heap in (new List<Heap> { a, b, c })) {
                Helpers.CheckInvariant(heap);
                Assert.Equal(6, heap.Count);
            }
        }
        [Fact]
        public void should_sort_values_using_push_and_pop() {
            var values = new List<int> { 6, 2, 1, 3, 4, 5 };
            var result = new List<Item> { };
            var h = new Heap();
            foreach (var value in values)
                h.Push(new Item(value));
            Assert.Equal(6, h.Count);
            while (h.Count > 0)
                result.Add(h.Pop());
            Assert.Equal(new List<int> { 1, 2, 3, 4, 5, 6 }, result.Select(x => x.Value));
        }

        [Fact]
        public void can_check_if_heap_contains_value_with_contains() {
            var h = Heap.From(new List<int> { 1, 2, 3, 4, 5, 6 });
            Assert.True(h.Contains(new Item(1)));
            Assert.True(h.Contains(new Item(3)));
            Assert.True(h.Contains(new Item(6)));
            Assert.False(h.Contains(new Item(7)));
            Assert.True(h.Contains(1));
            Assert.True(h.Contains(3));
            Assert.True(h.Contains(6));
            Assert.False(h.Contains(7));
        }
        public class Helpers {
            public static void CheckInvariant(Heap heap) {
                for (var position = 1; position < heap.Nodes.Count; ++position)
                    Assert.True(heap.Nodes[((position - 1) >> 1)] <= heap.Nodes[position]);
            }
        }
    }
}