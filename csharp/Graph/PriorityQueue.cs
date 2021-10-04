using System;
using System.Collections.Generic;

namespace Prelude {
    public class PriorityQueue {
        public int CurrentSize;
        public List<Item> Items = new() { };
        public Dictionary<Node, int> Position = new();

        public PriorityQueue() {
            CurrentSize = 0;
        }
        private static int Left(int i) {
            return (2 * i) + 1;
        }
        private static int Parent(double value) {
            return Convert.ToInt32(Math.Floor(value / 2));
        }
        private static int Right(int i) {
            return (2 * i) + 2;
        }
        public void DecreaseKey(Node node, double value) {
            var idx = Position[node];
            Items[idx] = new Item(node, value);
            while ((idx > 0) && (Items[Parent(idx)] > Items[idx])) {
                var index = Parent(idx);
                Swap(idx, index);
                idx = index;
            }
        }
        public Node ExtractMinimum() {
            Node minimum = Items[0].Node;
            Items[0] = Items[CurrentSize - 1];
            CurrentSize -= 1;
            MinimumHeapify(1);
            Position.Remove(minimum);
            return minimum;
        }
        public void Insert(double index, Node node) {
            Position[node] = CurrentSize;
            CurrentSize += 1;
            var item = new Item(node, int.MaxValue);
            Items.Add(item);
            DecreaseKey(node, index);
        }
        public bool IsEmpty() {
            return CurrentSize == 0;
        }
        public void MinimumHeapify(int idx) {
            var lc = Left(idx);
            var rc = Right(idx);
            var smallest = idx;
            if (lc < CurrentSize && Items[lc] < Items[idx])
                smallest = lc;
            if (rc < CurrentSize && Items[rc] < Items[smallest])
                smallest = rc;
            if (smallest != idx) {
                Swap(idx, smallest);
                MinimumHeapify(smallest);
            }
        }
        public void Swap(int i, int j) {
            Position[Items[i].Node] = j;
            Position[Items[j].Node] = i;
            var temp = Items[i];
            Items[i] = Items[j];
            Items[j] = temp;
        }
    }
}