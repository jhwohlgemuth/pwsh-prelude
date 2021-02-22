using System;
using System.Collections.Generic;

namespace Prelude {
    public class Node : IComparable<Node> {
        public Guid Id;
        public int Index;
        public string Label;
        public int Degree {
            get {
                return Neighbors.Count;
            }
        }
        public List<Node> Neighbors;
        /// <summary>
        /// Constructor
        /// </summary>
        /// <param name="label">String label to assign to node</param>
        public Node(string label = "node") {
            Id = Guid.NewGuid();
            Label = label;
            Neighbors = new List<Node> { };
        }
        /// <summary>
        /// Allows nodes to be ordered within lists
        /// </summary>
        /// <param name="other">Node to compare with</param>
        /// <returns>zero (equal) or 1 (not equal)</returns>
        public int CompareTo(Node other) {
            if (other != null) {
                return Id.CompareTo(other.Id);
            } else {
                throw new ArgumentException("Parameter is not a Node");
            }
        }
    }
}