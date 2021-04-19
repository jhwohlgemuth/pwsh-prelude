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
        private Heap SiftDown() {
            throw new NotImplementedException();
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
