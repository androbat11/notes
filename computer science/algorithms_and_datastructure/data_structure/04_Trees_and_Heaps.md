# Trees and Heaps: Hierarchical State

> "A tree is a graph where there is exactly one path between any two nodes. It is the structure of choice for organizing complexity." — *Tutor Lamport*

## 1. The Power of Logarithms
Binary Search Trees (BST) allow us to search in $O(\log n)$ by discarding half the state space at each step. This is the difference between searching 1,000,000 tracks (Linear: 1M steps) vs searching only 20 (Log: 20 steps).

### Diagram: The Heap (Priority)
Heaps are for finding the "Best" or "Worst" item instantly. Perfect for "Trending Tracks."
```text
      [ 99: Track Popularity ]  <- Max Heap (Top trending)
      /      \
    [ 70 ]  [ 85 ]
    /  \    /  \
  [10] [5] [50] [30]
```

### Metacognition: The Level Order Invariant
In a tree, children must obey the property of their parent (BST: left < parent < right; Heap: parent > children).
**Invariant:** Every subtree is also a valid tree of the same type.

## 2. Mnemonics for Trees
**"P-I-L-E"** (Parent-Inorder-Level-Exhaustive):
- **P**re-order / **I**n-order / Post-order: The three ways to "visit" the state.
- **I**n-order of BST is always Sorted.
- **L**evel-Order: Use a **Queue** (BFS) to visit neighbors level-by-level.
- **E**xhaustive DFS: Use **Recursion** (Stack) to go deep into a single branch.

## 3. Why Spotify?
Autocomplete Search. As you type "Beat...", a Prefix Tree (Trie) narrows down the possibilities. This is how Spotify predicts you want "The Beatles" before you finish typing.

---

## Exercises: Navigating the Genre Tree
| Problem | Difficulty | Technique | Link |
| :--- | :--- | :--- | :--- |
| Invert Binary Tree | Easy | Recursive DFS | [LeetCode 226](https://leetcode.com/problems/invert-binary-tree/) |
| Binary Tree Level Order Traversal | Medium | Queue (BFS) | [LeetCode 102](https://leetcode.com/problems/binary-tree-level-order-traversal/) |
| Validate Binary Search Tree | Medium | Range Invariant | [LeetCode 98](https://leetcode.com/problems/validate-binary-search-tree/) |
| Kth Smallest Element in a BST | Medium | In-order traversal | [LeetCode 230](https://leetcode.com/problems/kth-smallest-element-in-a-bst/) |
| Lowest Common Ancestor of a BST | Medium | Path Invariant | [LeetCode 235](https://leetcode.com/problems/lowest-common-ancestor-of-a-binary-search-tree/) |
