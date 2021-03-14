using System;

namespace Prelude {
    public class DirectedEdge : Edge {
        /// <summary>
        /// This is essentially the only difference between the DirectedEdge and Edge classes.
        /// </summary>
        public override bool IsDirected {
            get {
                return true;
            }
        }
        /// <summary>
        /// Constructor
        /// </summary>
        /// <param name="source">Direction of edge is from this node</param>
        /// <param name="target">Direction of edge is to this node</param>
        /// <param name="weight">Edge weight</param>
        public DirectedEdge(Node source, Node target, double weight = 1) : base(source, target, weight) {
            Id = Guid.NewGuid();
            Source = source;
            Target = target;
            Weight = weight;
        }
    }
}