# Recursion and Dynamic Programming: The Inductive State

> "Dynamic Programming is simply recursion with memory. It is the art of solving a problem once and never repeating the effort." — *Tutor Lamport*

## 1. The Principle of Optimality
To solve a large problem $P(n)$, you must first solve a smaller version of it, $P(n-1)$.
If you have already solved $P(n-1)$, you should store it in a table (**Memoization**) so you don't calculate it again.

### Diagram: The Decision Tree
If you can choose to skip a track or listen to it:
```text
           [ Start Playlist ]
           /                \
      Listen Track 1       Skip Track 1
       /       \           /        \
  Listen 2   Skip 2    Listen 2   Skip 2
```
*Notice how paths converge. DP "merges" these nodes.*

### Metacognition: The Overlapping Invariant
If a problem can be broken into subproblems, but the same subproblem is called multiple times, use DP.
**Invariant:** $DP[i]$ represents the optimal solution for the state at index $i$.

## 2. Mnemonics for DP
**"R-E-A-D"** (Recurrence-Entry-Array-Done):
- **R**ecurrence: What is the formula? e.g., $DP[i] = DP[i-1] + DP[i-2]$.
- **E**ntry Point: What are the base cases? e.g., $DP[0] = 0$.
- **A**rray / Memo: Where do you store the results?
- **D**irection: Bottom-up (Iterative) or Top-down (Recursive with Memo).

## 3. Why Spotify?
Recommendation Engines. Finding the "Minimal Edit Distance" between two user taste profiles. If User A likes Rock and User B likes Rock+Indie, the distance is 1 (Add Indie). DP calculates these distances at scale.

---

## Exercises: The Optimization Table
| Problem | Difficulty | Technique | Link |
| :--- | :--- | :--- | :--- |
| Climbing Stairs | Easy | Fibonacci DP | [LeetCode 70](https://leetcode.com/problems/climbing-stairs/) |
| Coin Change | Medium | Unbounded Knapsack | [LeetCode 322](https://leetcode.com/problems/coin-change/) |
| Longest Increasing Subsequence | Medium | State Comparison | [LeetCode 300](https://leetcode.com/problems/longest-increasing-subsequence/) |
| House Robber | Medium | Pick vs. Skip | [LeetCode 198](https://leetcode.com/problems/house-robber/) |
| Word Break | Medium | Boolean DP Table | [LeetCode 139](https://leetcode.com/problems/word-break/) |
