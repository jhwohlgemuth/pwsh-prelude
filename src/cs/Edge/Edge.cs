using System;

public class Edge {
    public Guid Id;
    public string To;
    public string From;
    public double Weight = 1;
    public Edge(string to, string from, double weight = 1) {
        this.Id = Guid.NewGuid();
        this.To = to;
        this.From = from;
        this.Weight = weight;
    }
    public Edge(int to, int from, double weight = 1) {
        this.Id = Guid.NewGuid();
        this.To = to.ToString();
        this.From = from.ToString();
        this.Weight = weight;
    }
}