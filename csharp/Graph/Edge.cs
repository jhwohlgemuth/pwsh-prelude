// <copyright file="Edge.cs" company="Jason Wohlgemuth">
// Copyright (c) 2022 Jason Wohlgemuth. All rights reserved.
// Licensed under the MIT license. See LICENSE file in the project root for full license information.
// </copyright>

namespace Prelude {
    using System;

    /// <summary>
    /// Directed edge for use within a <see cref="Graph"/>.
    /// </summary>
    public class Edge : IComparable<Edge> {
        /// <summary>
        /// Initializes a new instance of the <see cref="Edge"/> class.
        /// </summary>
        /// <param name="source">For a directed edge, the direction is from the node.</param>
        /// <param name="target">For a directed edge, the direction is to the node.</param>
        /// <param name="weight">Node weight.</param>
        public Edge(Node source, Node target, double weight = 1) {
            Id = Guid.NewGuid();
            Source = source;
            Target = target;
            Weight = weight;
        }

        /// <summary>
        /// Gets or sets the unique identifier of the edge.
        /// </summary>
        public Guid Id {
            get;
            set;
        }

        /// <summary>
        /// Gets or sets the source node.
        /// </summary>
        public Node Source {
            get;
            set;
        }

        /// <summary>
        /// Gets or sets the target node.
        /// </summary>
        public Node Target {
            get;
            set;
        }

        /// <summary>
        /// Gets or sets the weight of the edge.
        /// </summary>
        public double Weight {
            get;
            set;
        }

        /// <summary>
        /// Gets a value indicating whether the edge is directed or not.
        /// </summary>
        public virtual bool IsDirected {
            get {
                return false;
            }
        }

        public static bool operator ==(Edge left, Edge right) {
            if ((left is null) || (right is null))
                return Equals(left, right);
            return left.Equals(right);
        }

        public static bool operator !=(Edge left, Edge right) {
            if ((left is null) || (right is null))
                return !Equals(left, right);
            return !left.Equals(right);
        }

        /// <summary>
        /// Method for comparing an edge with another edge.
        /// </summary>
        /// <param name="other">Edge to compare with.</param>
        /// <returns>True if equal, false otherwise.</returns>
        public bool Equals(Edge other) {
            if (other == null)
                return false;
            return other.Source == Source && other.Target == Target && other.Weight == Weight && other.IsDirected == IsDirected;
        }

        /// <inheritdoc/>
        public override bool Equals(object obj) {
            Edge a = obj as Edge;
            return Equals(a);
        }

        /// <inheritdoc/>
        public override int GetHashCode() => Id.GetHashCode();

        /// <summary>
        /// Create an edge clone.
        /// </summary>
        /// <returns>Edge clone.</returns>
        public Edge Clone() => new(Source, Target, Weight);

        /// <summary>
        /// Check if an edge contains a node (source or target).
        /// </summary>
        /// <param name="node">Node to check for.</param>
        /// <returns>True if the edge contains the node, false otherwise.</returns>
        public bool Contains(Node node) {
            return Source == node || Target == node;
        }

        /// <inheritdoc/>
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
        /// Return new edge with source and target nodes swapped.
        /// </summary>
        /// <returns>Edge with swapped nodes.</returns>
        public Edge Reverse() => new(Target, Source, Weight);
    }
}