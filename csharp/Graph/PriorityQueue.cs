// <copyright file="PriorityQueue.cs" company="Jason Wohlgemuth">
// Copyright (c) 2022 Jason Wohlgemuth. All rights reserved.
// Licensed under the MIT license. See LICENSE file in the project root for full license information.
// </copyright>

namespace Prelude {
    using System;
    using System.Collections.Generic;

    /// <summary>
    /// Priority queue class for use within <see cref="Graph"/> algorithms.
    /// </summary>
    public class PriorityQueue {
        /// <summary>
        /// Initializes a new instance of the <see cref="PriorityQueue"/> class.
        /// </summary>
        public PriorityQueue() {
            CurrentSize = 0;
            Items = new() { };
            Position = new();
        }

        /// <summary>
        /// Gets the current size of the priority queue.
        /// </summary>
        public int CurrentSize {
            get;
            private set;
        }

        /// <summary>
        /// Gets or sets item list of the priority queue.
        /// </summary>
        public List<Item> Items {
            get;
            set;
        }

        /// <summary>
        /// Gets or sets the dictionary for node positions within the priority queue.
        /// </summary>
        public Dictionary<Node, int> Position {
            get;
            set;
        }

        /// <summary>
        /// Decrease key of a given node until it is properly located within the priority queue.
        /// </summary>
        /// <param name="node">Node of item to be decreased.</param>
        /// <param name="value">Value payload of new item.</param>
        public void DecreaseKey(Node node, double value) {
            var idx = Position[node];
            Items[idx] = new Item(node, value);
            while ((idx > 0) && (Items[Parent(idx)] > Items[idx])) {
                var index = Parent(idx);
                Swap(idx, index);
                idx = index;
            }
        }

        /// <summary>
        /// Extract minimum item from the priority queue.
        /// </summary>
        /// <returns>Minimum item from priority queue.</returns>
        public Node ExtractMinimum() {
            Node minimum = Items[0].Node;
            Items[0] = Items[CurrentSize - 1];
            CurrentSize -= 1;
            MinimumHeapify(1);
            Position.Remove(minimum);
            return minimum;
        }

        /// <summary>
        /// Insert an item into the priority queue.
        /// </summary>
        /// <param name="index">Index within queue where item should be inserted.</param>
        /// <param name="node">Node payload of item to be inserted.</param>
        public void Insert(double index, Node node) {
            Position[node] = CurrentSize;
            CurrentSize += 1;
            var item = new Item(node, int.MaxValue);
            Items.Add(item);
            DecreaseKey(node, index);
        }

        /// <summary>
        /// Test if the priority queue has items or not.
        /// </summary>
        /// <returns>True if the priority queue contains more than zero items, false otherwise.</returns>
        public bool IsEmpty() {
            return CurrentSize == 0;
        }

        /// <summary>
        /// Sort items within the queue such that every parent item is less than its children items.
        /// </summary>
        /// <param name="idx">Index to perform operation at.</param>
        public void MinimumHeapify(int idx) {
            var lc = Left(idx);
            var rc = Right(idx);
            var smallest = idx;
            if (lc < CurrentSize && Items[lc] < Items[idx])
                smallest = lc;
            if (rc < CurrentSize && Items[rc] < Items[smallest])
                smallest = rc;
            if (smallest != idx) {
                Swap(idx, smallest);
                MinimumHeapify(smallest);
            }
        }

        /// <summary>
        /// Swap two items within the priority queue.
        /// </summary>
        /// <param name="i">Index of first item.</param>
        /// <param name="j">Index of second item.</param>
        /// <remarks>
        /// This method swaps items in place and returns void.
        /// </remarks>
        public void Swap(int i, int j) {
            Position[Items[i].Node] = j;
            Position[Items[j].Node] = i;
            (Items[j], Items[i]) = (Items[i], Items[j]);
        }

        private static int Left(int i) {
            return (2 * i) + 1;
        }

        private static int Parent(double value) {
            return Convert.ToInt32(Math.Floor(value / 2));
        }

        private static int Right(int i) {
            return (2 * i) + 2;
        }
    }
}