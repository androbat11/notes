# Linear Structures: Arrays, Strings, and Sequential State

> "An array is a memory region with a fixed stride. A string is an array of characters. Both represent sequential states in time." — *Tutor Lamport*

## 1. The Geometry of Sequential Access
Arrays are contiguous. This provides $O(1)$ access because the memory address is simply:
`Address(i) = Base_Address + (i * Stride_Size)`

### Diagram: The Sliding Window
Imagine a Spotify playlist. You want to find the longest sequence of songs with unique genres.
```text
[ Rock | Pop | Pop | Jazz | Rock | Indie ]
  ^------L------^ R -> (Genre Map: Rock:1, Pop:2)
          L moved forward because Pop repeated.
```

## 2. Mnemonics for Array Patterns
**"F-A-S-T"** (Fundamental Array Strategy Tool):
- **F**requency Mapping: Use a Hash Map to count occurrences.
- **A**nchors & Runners: Two pointers moving at different speeds (e.g., detecting cycles).
- **S**liders: Fixed or variable length windows (e.g., contiguous subarrays).
- **T**wo Pointers: Converging from both ends (e.g., `left` and `right` for sorting).

## 3. Metacognition: The Cache Locality
Accessing `Array[i]` and `Array[i+1]` is fast because CPUs fetch blocks of memory. Jumping between distant memory addresses (like in Linked Lists) is a "logical" step but a "physical" crawl.

---

## Exercises: The Playlist Sequences
| Problem | Difficulty | Technique | Link |
| :--- | :--- | :--- | :--- |
| Valid Palindrome | Easy | Two Pointers | [LeetCode 125](https://leetcode.com/problems/valid-palindrome/) |
| Longest Substring Without Repeating Characters | Medium | Sliding Window | [LeetCode 3](https://leetcode.com/problems/longest-substring-without-repeating-characters/) |
| Container With Most Water | Medium | Converging Pointers | [LeetCode 11](https://leetcode.com/problems/container-with-most-water/) |
| 3Sum | Medium | Sort + Two Pointers | [LeetCode 15](https://leetcode.com/problems/3sum/) |
| Minimum Window Substring | Hard | Sliding Window Map | [LeetCode 76](https://leetcode.com/problems/minimum-window-substring/) |
