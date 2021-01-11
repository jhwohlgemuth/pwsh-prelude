using System;

namespace Prelude {
    public class Edge {
        public Guid Id;
        public string To;
        public string From;
        public double Weight = 1;
        public Edge(string to, string from, double weight = 1) {
            Id = Guid.NewGuid();
            To = to;
            From = from;
            Weight = weight;
        }
        public Edge(int to, int from, double weight = 1) {
            Id = Guid.NewGuid();
            To = to.ToString();
            From = from.ToString();
            Weight = weight;
        }
    }
}