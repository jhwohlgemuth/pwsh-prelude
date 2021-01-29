using System;
using System.Collections.Generic;

namespace Prelude {
    public class Node : IComparable<Node> {
        public Guid Id;
        public string Label;
        public List<Node> Neighbors;
        public Node(string label = "node") {
            Id = Guid.NewGuid();
            Label = label;
        }
        public int CompareTo(Node other) {
            if (other != null) {
                return Id.CompareTo(other.Id);
            } else {
                throw new ArgumentException("Parameter is not a Node");
            }
        }
    }
}