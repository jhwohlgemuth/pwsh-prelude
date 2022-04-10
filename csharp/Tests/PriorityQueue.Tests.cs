// <copyright file="PriorityQueue.Tests.cs" company="Jason Wohlgemuth">
// Copyright (c) 2022 Jason Wohlgemuth. All rights reserved.
// Licensed under the MIT license. See LICENSE file in the project root for full license information.
// </copyright>

namespace PriorityQueueTests {
    using Prelude;
    using Xunit;

    public class UnitTests {
        [Fact]
        public void Can_be_created_with_no_arguments() {
            var q = new PriorityQueue();
            Assert.Equal(0, q.CurrentSize);
            Assert.True(q.IsEmpty());
        }

        [Fact]
        public void Can_add_items() {
            var q = new PriorityQueue();
            Node u = new("u");
            Node v = new("v");
            q.Insert(1, u);
            Assert.Equal(1, q.CurrentSize);
            q.Insert(2, v);
            Assert.Equal(2, q.CurrentSize);
        }

        [Fact]
        public void Can_swap_items() {
            var q = new PriorityQueue();
            Node a = new("a");
            Node b = new("b");
            Node c = new("c");
            q.Insert(1, a);
            q.Insert(2, b);
            q.Insert(3, c);
            Assert.Equal(a, q.Items[0].Node);
            Assert.Equal(b, q.Items[1].Node);
            Assert.Equal(c, q.Items[2].Node);
            q.Swap(0, 2);
            Assert.Equal(c, q.Items[0].Node);
            Assert.Equal(b, q.Items[1].Node);
            Assert.Equal(a, q.Items[2].Node);
        }
    }
}