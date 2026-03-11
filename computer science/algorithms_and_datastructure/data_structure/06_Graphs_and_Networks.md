# Graphs and Networks: The Social Spotify Graph

> "A graph is a set of vertices and edges. It is the most general and powerful structure for modeling relationships." — *Tutor Lamport*

## 1. The Topology of Sound
At Spotify, you are a node. An artist you like is another node. The "Like" is the edge between you.
`User(A) --[Liked]--> Artist(B) --[Genre]--> Rock`

### Diagram: The Connectivity
```text
(User A) ---- (User B)  <-- Common Friends
   |           |
(Rock) <---- (Indie)  <-- Related Genres
```

### Metacognition: The Search Invariant
When traversing a graph, you must track **Visited Nodes**.
**Invariant:** Every node in the "Visited" set has already been processed, preventing infinite cycles.

## 2. Mnemonics for Graphs
**"B-E-S-T"** (BFS-Edges-Shortest-Traversal):
- **B**FS (Queue): For finding the **Shortest Path** (e.g., degree of separation between users).
- **D**FS (Recursion): For finding **Connectivity** or searching deep for a specific track.
- **S**ort (Topological): For dependencies (e.g., "Must listen to Album X before Album Y").
- **T**raversal: Always use an Adjacency List (Map of Lists) for performance.

## 3. Why Spotify?
Social recommendation. "Users who follow Artist A also follow Artist B." This is a **Bipartite Graph**. Finding the shortest path between you and a new artist helps Spotify recommend music that is "just outside" your current taste.

---

## Exercises: Mapping the Social Graph
| Problem | Difficulty | Technique | Link |
| :--- | :--- | :--- | :--- |
| Clone Graph | Medium | BFS / DFS Hash Map | [LeetCode 133](https://leetcode.com/problems/clone-graph/) |
| Course Schedule | Medium | Topological Sort (Kahn's) | [LeetCode 207](https://leetcode.com/problems/course-schedule/) |
| Number of Islands | Medium | BFS / DFS Traversal | [LeetCode 200](https://leetcode.com/problems/number-of-islands/) |
| Pacific Atlantic Water Flow | Medium | Multi-source BFS | [LeetCode 417](https://leetcode.com/problems/pacific-atlantic-water-flow/) |
| Cheapest Flights Within K Stops | Medium | Dijkstra / Bellman-Ford | [LeetCode 787](https://leetcode.com/problems/cheapest-flights-within-k-stops/) |
