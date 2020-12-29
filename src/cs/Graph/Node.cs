using System;

namespace Prelude {
    public class Node {
        public Guid Id;
        public string Name;
        public Node(string name) {
            Id = Guid.NewGuid();
            Name = name;
        }
    }
}
