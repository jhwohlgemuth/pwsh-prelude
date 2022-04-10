// <copyright file="Item.cs" company="Jason Wohlgemuth">
// Copyright (c) 2022 Jason Wohlgemuth. All rights reserved.
// Licensed under the MIT license. See LICENSE file in the project root for full license information.
// </copyright>

namespace Prelude {
    /// <summary>
    /// Item class for use with <see cref="PriorityQueue"/>.
    /// </summary>
    public class Item {
        /// <summary>
        /// Initializes a new instance of the <see cref="Item"/> class.
        /// </summary>
        /// <param name="value">Double used to compare and sort item.</param>
        public Item(double value = 0) {
            Value = value;
        }

        /// <summary>
        /// Initializes a new instance of the <see cref="Item"/> class.
        /// </summary>
        /// <param name="node">Node value of item used in graph algorithms.</param>
        public Item(Node node) {
            Value = 0;
            Node = node;
        }

        /// <summary>
        /// Initializes a new instance of the <see cref="Item"/> class.
        /// </summary>
        /// <param name="node">Node value of item used in graph algorithms.</param>
        /// <param name="value">Double used to compare and sort item.</param>
        public Item(Node node, double value) {
            Value = value;
            Node = node;
        }

        /// <summary>
        /// Gets or sets value payload of the item.
        /// </summary>
        public double Value {
            get;
            set;
        }

        /// <summary>
        /// Gets or sets the node payload of the item.
        /// </summary>
        public Node Node {
            get;
            set;
        }

        public static bool operator ==(Item left, Item right) {
            if ((left is null) || (right is null))
                return Equals(left, right);
            return left.Equals(right);
        }

        public static bool operator !=(Item left, Item right) {
            if ((left is null) || (right is null))
                return !Equals(left, right);
            return !left.Equals(right);
        }

        public static bool operator <(Item left, Item right) {
            if (left == null || (right == null))
                return false;
            return left.Value < right.Value;
        }

        public static bool operator <=(Item left, Item right) {
            if (left == null || (right == null))
                return false;
            return left.Value <= right.Value;
        }

        public static bool operator >(Item left, Item right) {
            if (left == null || (right == null))
                return false;
            return left.Value > right.Value;
        }

        public static bool operator >=(Item left, Item right) {
            if (left == null || (right == null))
                return false;
            return left.Value >= right.Value;
        }

        /// <summary>
        /// Method for comparing an item with another item.
        /// </summary>
        /// <param name="other">Item to compare with.</param>
        /// <returns>True if equal, false otherwise.</returns>
        public bool Equals(Item other) {
            if (other == null)
                return false;
            return other.Value == Value;
        }

        /// <inheritdoc/>
        public override bool Equals(object obj) {
            Item a = obj as Item;
            return Equals(a);
        }

        /// <inheritdoc/>
        public override int GetHashCode() => Value.GetHashCode();
    }
}