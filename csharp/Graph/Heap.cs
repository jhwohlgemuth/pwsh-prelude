using System;
using System.Collections.Generic;

namespace Prelude {
    public class Heap {
        public List<Node> Nodes;
        public Heap() {
            Nodes = new List<Node> { };
        }
        public static Heap From(IEnumerable<Node> values) {
            throw new NotImplementedException();
        }
        private Heap SiftDown(int start = 0) {
            int position = Nodes.Count - 1;
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
            return this;
        }
        private Heap SiftUp() {
            throw new NotImplementedException();
        }
        public Heap Push() {
            throw new NotImplementedException();
        }
        public Node Pop() {
            throw new NotImplementedException();
        }
        public Heap Update(Node value) {
            throw new NotImplementedException();
        }
    }
}
