using System;
using System.Collections.Generic;

namespace Prelude {
    public class Node {
        public Guid Id;
        public string Label;
        public List<Node> Neighbors;
        public Node(string label = "node") {
            Id = Guid.NewGuid();
            Label = label;
        }
    }
}