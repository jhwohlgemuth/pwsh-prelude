using System;

namespace Prelude {
    public class Edge : IComparable<Edge> {
        public Guid Id;
        public Node Source;
        public Node Target;
        public double Weight = 1;
        public virtual bool IsDirected {
            get {
                return false;
            }
        }
        /// <summary>
        /// Constructor
        /// </summary>
        /// <param name="source">For directed edge, the direction is from this node</param>
        /// <param name="target">For directed edge, the direction is to this node</param>
        /// <param name="weight">Node weight</param>
        public Edge(Node source, Node target, double weight = 1) {
            Id = Guid.NewGuid();
            Source = source;
            Target = target;
            Weight = weight;
        }
        public bool Equals(Edge other) {
            if (other == null)
                return false;
            return other.Source == Source && other.Target == Target && other.Weight == Weight && other.IsDirected == IsDirected;
        }
        /// <summary>
        /// Determines if two edges are equal
        /// </summary>
        /// <param name="obj"></param>
        /// <seealso cref="operator=="/>
        /// <seealso cref="operator!="/>
        /// <seealso cref="GetHashCode"/>
        public override bool Equals(object obj) {
            Edge a = obj as Edge;
            return Equals(a);
        }
        public override int GetHashCode() => Id.GetHashCode();
        public static bool operator ==(Edge left, Edge right) {
            if ((left is null) || (right is null))
                return Equals(left, right);
            return left.Equals(right);
        }
        public static bool operator !=(Edge left, Edge right) {
            if ((left is null) || (right is null))
                return !Equals(left, right);
            return !(left.Equals(right));
        }
        /// <summary>
        /// Return clone of calling edge
        /// </summary>
        /// <returns>Edge</returns>
        public Edge Clone() => new Edge(Source, Target, Weight);
        /// <summary>
        /// Check if an edge contains a node (source or target)
        /// </summary>
        /// <param name="node">Node to check for</param>
        /// <returns></returns>
        public bool Contains(Node node) {
            return Source == node || Target == node;
        }
        /// <summary>
        /// Allows edges to be ordered within lists
        /// </summary>
        /// <param name="other">Edge to compare with</param>
        /// <returns>zero (equal) or 1 (not equal)</returns>
        public int CompareTo(Edge other) {
            if (other != null) {
                var sameSource = Source == other.Source;
                var sameTarget = Target == other.Target;
                if (sameSource && sameTarget) {
                    return Weight.CompareTo(other.Weight);
                } else {
                    return -1;
                }
            } else {
                throw new ArgumentException("Parameter is not an Edge");
            }
        }
        /// <summary>
        /// Return new edge with source and target nodes swapped
        /// </summary>
        /// <returns>Edge</returns>
        public Edge Reverse() => new Edge(Target, Source, Weight);
    }
}