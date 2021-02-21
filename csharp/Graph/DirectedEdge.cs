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
        /// <param name="source"></param>
        /// <param name="destination"></param>
        /// <param name="weight"></param>
        public DirectedEdge(Node source, Node destination, double weight = 1) : base(source, destination, weight) {
            Id = Guid.NewGuid();
            Source = source;
            Destination = destination;
            Weight = weight;
        }
    }
}