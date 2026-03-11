# Hash Maps and Sets: The O(1) Mapping

> "A hash map is a mathematical shortcut from a Key to a Value. It allows us to bypass search entirely." — *Tutor Lamport*

## 1. The Hash Function as a Clock
In distributed systems, we often hash data to determine where it lives. A hash map does this locally. It maps a set of potentially infinite keys to a finite array of buckets.

### Diagram: The Buckets of Music
```text
Key: "Bohemian Rhapsody" -> Hash(K) % N -> Index 42
[ 0 | ... | 41 | 42: TrackData | 43 | ... ]
```

### Metacognition: The Collision Invariant
No hash function is perfect. **Collision Resolution** (Chaining or Open Addressing) is the algorithm's plan for when two distinct keys share the same bucket.
**Invariant:** Even if keys collide, the data remains retrievable by verifying the full key.

## 2. Mnemonics for Hash Maps
**"C-A-K-E"** (Collision-Avoidance-Key-Efficiency):
- **C**omplementary: "What is the key I *need* but don't have?" (e.g., `target - current`).
- **A**ggregation: Using a map to count frequencies (e.g., Artist popularity).
- **K**ey Choice: Ensure your key is immutable (primitive types or frozen objects).
- **E**fficiency: Amortized $O(1)$ time is only true if the hash function distributes keys uniformly.

## 3. Why Spotify?
How do you check if a user has already "liked" a track? You don't scan their whole list ($O(n)$). You check their `LikedSet` in $O(1)$. This allows the "Heart" icon to toggle instantly.

---

## Exercises: Mapping the Library
| Problem | Difficulty | Technique | Link |
| :--- | :--- | :--- | :--- |
| Group Anagrams | Medium | Sorted Key Map | [LeetCode 49](https://leetcode.com/problems/group-anagrams/) |
| Top K Frequent Elements | Medium | Frequency Map + Heap | [LeetCode 347](https://leetcode.com/problems/top-k-frequent-elements/) |
| Longest Consecutive Sequence | Medium | Set + O(n) scan | [LeetCode 128](https://leetcode.com/problems/longest-consecutive-sequence/) |
| LRU Cache | Medium | Hash Map + Doubly Linked List | [LeetCode 146](https://leetcode.com/problems/lru-cache/) |
| Subarray Sum Equals K | Medium | Prefix Sum Map | [LeetCode 560](https://leetcode.com/problems/subarray-sum-equals-k/) |
