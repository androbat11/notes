# Complexity Analysis and Invariants

> "To be correct, a program must satisfy its specification. To be efficient, it must respect the physics of the machine." — *Tutor Lamport*

## 1. The State Machine View
In algorithms, we don't just "run code." We transition from an input state $S_0$ to an output state $S_{final}$. Complexity ($O(n)$) is simply the count of transitions required to reach the goal.

### Metacognition: The "Cost of Scale"
At Spotify, $O(n^2)$ is the difference between a playlist loading in 10ms or crashing the mobile app for 100 million users.

### Diagram: The Growth of Functions
```text
Steps (Log scale)
^
|          /  O(n!) - The Heat Death of the Universe
|         /   O(2^n) - Exponential Explosion
|        /    O(n^2) - The Quadratic Trap
|       /     O(n log n) - The Sorting Standard
|      /      O(n) - Linear Progress
|     /       O(log n) - The Binary Search Miracle
|____/________ O(1) - The Constant Ideal
|__________________________> Input Size (n)
```

## 2. Mnemonics for Complexity
**"B-O-L-T"** (Big-O Logic Tool):
- **B**oundaries: What is the smallest ($n=1$) and largest ($n=10^9$) input?
- **O**perations: What is inside the innermost loop?
- **L**ayers: How many nested loops (states) are we tracking?
- **T**rade-offs: Can we spend Memory (Space) to buy Time?

## 3. The Lamport Invariant
An **Invariant** is a property that is *always true* at a specific point in the algorithm.
*Example (Binary Search):* "The target is always between `low` and `high` indices."

---

## Exercises: The Spotify Scale Challenge
| Problem | Difficulty | Logic Pattern | Link |
| :--- | :--- | :--- | :--- |
| Contains Duplicate | Easy | Hash Set / Invariant | [LeetCode 217](https://leetcode.com/problems/contains-duplicate/) |
| Valid Anagram | Easy | Frequency Mapping | [LeetCode 242](https://leetcode.com/problems/valid-anagram/) |
| Two Sum | Easy | Complementary State | [LeetCode 1](https://leetcode.com/problems/two-sum/) |
| Maximum Subarray | Medium | Kadane's Invariant | [LeetCode 53](https://leetcode.com/problems/maximum-subarray/) |
| Product of Array Except Self | Medium | Prefix/Suffix States | [LeetCode 238](https://leetcode.com/problems/product-of-array-except-self/) |
