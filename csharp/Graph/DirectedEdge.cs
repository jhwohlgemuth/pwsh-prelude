// <copyright file="DirectedEdge.cs" company="Jason Wohlgemuth">
// Copyright (c) 2022 Jason Wohlgemuth. All rights reserved.
// Licensed under the MIT license. See LICENSE file in the project root for full license information.
// </copyright>

namespace Prelude {
    using System;

    /// <summary>
    /// Directed edge for use within a <see cref="Graph"/>.
    /// </summary>
    public class DirectedEdge : Edge {
        /// <summary>
        /// Initializes a new instance of the <see cref="DirectedEdge"/> class.
        /// </summary>
        /// <param name="source">Direction of edge is from the node.</param>
        /// <param name="target">Direction of edge is to the node.</param>
        /// <param name="weight">Weight of the edge.</param>
        public DirectedEdge(Node source, Node target, double weight = 1) : base(source, target, weight) {
            Id = Guid.NewGuid();
            Source = source;
            Target = target;
            Weight = weight;
        }

        /// <summary>
        /// Gets a value indicating whether the edge is directed.
        /// </summary>
        /// <remarks>
        /// Essentially the only difference between the DirectedEdge and Edge classes.
        /// </remarks>
        public override bool IsDirected {
            get {
                return true;
            }
        }
    }
}