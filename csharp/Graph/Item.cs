namespace Prelude {
    public class Item {
        public double Value;
        public Node Node;
        public Item(double value = 0) {
            Value = value;
        }
        public Item(Node node) {
            Value = 0;
            Node = node;
        }
        public Item(Node node, double value) {
            Value = value;
            Node = node;
        }
        public bool Equals(Item other) {
            if (other == null)
                return false;
            return other.Value == Value;
        }
        public override bool Equals(object obj) {
            Item a = obj as Item;
            return Equals(a);
        }
        public override int GetHashCode() => Value.GetHashCode();
        public static bool operator ==(Item left, Item right) {
            if ((left is null) || (right is null))
                return Equals(left, right);
            return left.Equals(right);
        }
        public static bool operator !=(Item left, Item right) {
            if ((left is null) || (right is null))
                return !Equals(left, right);
            return !(left.Equals(right));
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
    }
}