using Xunit;
using FsCheck;
using FsCheck.Xunit;
using System;
using System.Linq;
using Prelude;

namespace GraphTests {
    public class UnitTests {
        [Fact]
        public void Graph_Can_Be_Created() {
            var g = new Graph();
            Assert.Equal(36, g.Id.ToString().Length);
        }
        [Fact]
        public void FsCheck_Test() {
            Func<int[], bool> revRevIsOrig = xs => xs.Reverse().Reverse().SequenceEqual(xs);
            Prop.ForAll(revRevIsOrig).QuickCheck();
        }
    }
}