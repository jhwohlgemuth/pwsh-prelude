using System;
using System.Linq;
using System.Collections.Generic;

namespace Prelude {
    public class Item {
        public int Value;
        public Item(int value = 0) {
            Value = value;
        }
        public bool Equals(Item other) {
            if (other == null)
                return false;
            return other.Value == Value;
        }
        public override bool Equals(object obj) {
            Item a = obj as Item;
            return Equals(a);
        }
        public override int GetHashCode() => Value.GetHashCode();
        public static bool operator ==(Item left, Item right) {
            if ((left is null) || (right is null))
                return Equals(left, right);
            return left.Equals(right);
        }
        public static bool operator !=(Item left, Item right) {
            if ((left is null) || (right is null))
                return !Equals(left, right);
            return !(left.Equals(right));
        }
        public static bool operator <(Item left, Item right) {
            if (left == null || (right == null))
                return false;
            return left.Value < right.Value;
        }
        public static bool operator <=(Item left, Item right) {
            if (left == null || (right == null))
                return false;
            return left.Value <= right.Value;
        }
        public static bool operator >(Item left, Item right) {
            if (left == null || (right == null))
                return false;
            return left.Value > right.Value;
        }
        public static bool operator >=(Item left, Item right) {
            if (left == null || (right == null))
                return false;
            return left.Value >= right.Value;
        }
    }
    public class Heap {
        public List<Item> Nodes;

        public int Count => Nodes.Count;
        public Item this[int index] {
            get {
                if (index < 0 || index > this.Count || this.Count == 0) {
                    throw new IndexOutOfRangeException();
                }
                return Nodes[index];
            }
        }
        public Heap() {
            Nodes = new List<Item> { };
        }
        public static Heap From(IEnumerable<Item> items) {
            throw new NotImplementedException();
        }
        public static Heap From(IEnumerable<int> values) {
            var heap = new Heap();
            foreach (var value in values)
                heap.Push(new Item(value));
            return heap;
        }
        private Item SiftDown(int position, int start = 0) {
            var item = Nodes[position];
            while (position > start) {
                var parentPosition = (position - 1) >> 1;
                var parent = Nodes[parentPosition];
                if (item < parent) {
                    Nodes[position] = parent;
                    position = parentPosition;
                    continue;
                }
                break;
            }
            Nodes[position] = item;
            return item;
        }
        private Item SiftUp(int position = 0) {
            int start = position;
            int end = Nodes.Count;
            var item = Nodes[position];
            int childPosition = (2 * position) + 1;
            while (childPosition < end) {
                int right = childPosition + 1;
                if (right < end && !(Nodes[childPosition] < Nodes[right])) {
                    childPosition = right;
                }
                Nodes[position] = Nodes[childPosition];
                position = childPosition;
                childPosition = (2 * position) + 1;
            }
            Nodes[position] = item;
            return SiftDown(position, start);
        }
        public bool Contains(Item value) => Nodes.Contains(value);
        public bool Contains(int value) => Nodes.Contains(new Item(value));
        public Item Push(Item item) {
            Nodes.Add(item);
            return SiftDown((Nodes.Count - 1));
        }
        public Item Pop() {
            Item result;
            var last = Nodes.Last();
            if (Nodes.Count > 0)
                Nodes.RemoveAt(Nodes.Count - 1);
            if (Nodes.Count > 0) {
                result = Nodes.First();
                Nodes[0] = last;
                SiftUp();
            } else {
                result = last;
            }
            return result;
        }
        public Heap Update(Node value) {
            throw new NotImplementedException();
        }
    }
}
