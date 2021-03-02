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
        /// Constructor
        /// </summary>
        /// <param name="id">GUID Node Id</param>
        /// <param name="label">Node label string text</param>
        public Node(Guid id, string label = "node") {
            Id = id;
            Label = label;
            Neighbors = new List<Node> { };
        }
        /// <summary>
        /// Construction
        /// </summary>
        /// <param name="id">Node ID as string that will be coerced to a GUID</param>
        /// <param name="label">Node label string text</param>
        /// <remarks>
        /// The second parameter, label, is not optional. This is required to differentiate this constructor from the Node(string) constructor
        /// </remarks>
        /// <see cref="Node(string)"/>
        public Node(string id, string label) {
            if (IsValidIdentifier(id))
                Id = new Guid(id);
            else
                throw new ArgumentException("Node ID must have valid GUID format");
            Label = label;
            Neighbors = new List<Node> { };
        }
        /// <summary>
        /// Check if value is a valid Node identifier
        /// </summary>
        /// <param name="value"></param>
        /// <returns>Boolean</returns>
        public static bool IsValidIdentifier(object value) => Guid.TryParse((string)value, out _);
        /// <summary>
        /// Set the text of the Node label
        /// </summary>
        /// <param name="text"></param>
        /// <returns>Node</returns>
        /// <remarks>This method supports a fluent interface</remarks>
        public Node SetLabel(string text) {
            Label = text;
            return this;
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