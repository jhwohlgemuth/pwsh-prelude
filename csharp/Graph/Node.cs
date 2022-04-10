// <copyright file="Node.cs" company="Jason Wohlgemuth">
// Copyright (c) 2022 Jason Wohlgemuth. All rights reserved.
// Licensed under the MIT license. See LICENSE file in the project root for full license information.
// </copyright>

namespace Prelude {
    using System;
    using System.Collections.Generic;

    /// <summary>
    /// Node for use within a <see cref="Graph"/>.
    /// </summary>
    public class Node : IComparable<Node> {
        /// <summary>
        /// Initializes a new instance of the <see cref="Node"/> class.
        /// </summary>
        /// <param name="label">String label to assign to the node.</param>
        public Node(string label = "node") {
            Id = Guid.NewGuid();
            Label = label;
            Neighbors = new List<Node> { };
        }

        /// <summary>
        /// Initializes a new instance of the <see cref="Node"/> class.
        /// </summary>
        /// <param name="id">Valid GUID node identifier.</param>
        /// <param name="label">Node label string text.</param>
        public Node(Guid id, string label = "node") {
            Id = id;
            Label = label;
            Neighbors = new List<Node> { };
        }

        /// <summary>
        /// Initializes a new instance of the <see cref="Node"/> class.
        /// </summary>
        /// <param name="id">Node ID as string that will be coerced to a GUID.</param>
        /// <param name="label">Node label string text.</param>
        /// <remarks>
        /// The second parameter, label, is not optional. This is required to differentiate this constructor from the Node(string) constructor.
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
        /// Gets the identifier of the node.
        /// </summary>
        public Guid Id {
            get;
            private set;
        }

        /// <summary>
        /// Gets or sets the index of the node.
        /// </summary>
        public int Index {
            get;
            set;
        }

        /// <summary>
        /// Gets or sets the label of the node.
        /// </summary>
        public string Label {
            get;
            set;
        }

        /// <summary>
        /// Gets the degree of the node.
        /// </summary>
        /// <remarks>
        /// The degree is the count of the number of edges adjacent (connected) to the node.
        /// </remarks>
        public int Degree {
            get {
                return Neighbors.Count;
            }
        }

        /// <summary>
        /// Gets list of nodes connected to the node via an edge.
        /// </summary>
        public List<Node> Neighbors {
            get;
        }

        public static bool operator ==(Node left, Node right) {
            if ((left is null) || (right is null))
                return Equals(left, right);
            return left.Equals(right);
        }

        public static bool operator !=(Node left, Node right) {
            if ((left is null) || (right is null))
                return !Equals(left, right);
            return !left.Equals(right);
        }

        public static bool operator <(Node left, Node right) {
            if ((left is null) || (right is null))
                return false;
            return string.Compare(left.Id.ToString(), right.Id.ToString(), StringComparison.InvariantCulture) < 0;
        }

        public static bool operator >(Node left, Node right) {
            if ((left is null) || (right is null))
                return false;
            return string.Compare(left.Id.ToString(), right.Id.ToString(), StringComparison.InvariantCulture) > 0;
        }

        /// <summary>
        /// Check if value is a valid Node identifier.
        /// </summary>
        /// <param name="value">Object that may or may not be a valid GUID.</param>
        /// <returns>True if valid GUID, false otherwise.</returns>
        public static bool IsValidIdentifier(object value) => Guid.TryParse((string)value, out _);

        /// <summary>
        /// Method for comparing a node with another node.
        /// </summary>
        /// <param name="other">Node to compare with.</param>
        /// <returns>True if equal, false otherwise.</returns>
        public bool Equals(Node other) {
            if (other == null)
                return false;
            return other.Id == Id && other.Label == Label;
        }

        /// <inheritdoc/>
        public override bool Equals(object obj) {
            Node a = obj as Node;
            return Equals(a);
        }

        /// <inheritdoc/>
        public override int GetHashCode() => Id.GetHashCode();

        /// <summary>
        /// Set the text of the node label.
        /// </summary>
        /// <param name="text">Label text.</param>
        /// <returns>Node on which SetLabel was called.</returns>
        /// <remarks>This method supports a fluent interface.</remarks>
        public Node SetLabel(string text) {
            Label = text;
            return this;
        }

        /// <inheritdoc/>
        public int CompareTo(Node other) {
            if (other != null) {
                return Id.CompareTo(other.Id);
            } else {
                throw new ArgumentException("Parameter is not a Node");
            }
        }
    }
}