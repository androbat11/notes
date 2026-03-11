# Sorting Algorithms: The Physics of Order (Advanced)

> "Sorting is not a single problem, but a family of constraints. The 'best' sort depends on the physics of your data." — *Tutor Lamport*

## 1. Selection Sort: The Minimum Finder
Selection sort finds the minimum element and swaps it into the front.
**Invariant:** After $i$ steps, the first $i$ elements are the $i$ smallest in sorted order.
**Mnemonic: "M-I-N"**
- **M**ark the current index.
- **I**dentify the minimum in the rest of the array.
- **N**ext: Swap and increment.

## 2. Bubble Sort: The Sinking Sort
Bubble sort repeatedly swaps adjacent elements if they are in the wrong order.
**Invariant:** After $i$ steps, the $i$ largest elements have "bubbled" to their correct final positions at the end.
**Complexity:** $O(n^2)$. Only useful for educational purposes or nearly sorted data.

## 3. Advanced Sorts: Heap and Radix
- **Heap Sort:** Uses a Max Heap to sort in-place ($O(n \log n)$).
- **Radix Sort:** Sorts by digits or bits ($O(nk)$). This is non-comparative and can be faster than $O(n \log n)$ for specific data types.

---

## Exercises: Organizing the Library
| Problem | Difficulty | Algorithm | Link |
| :--- | :--- | :--- | :--- |
| Sort Characters By Frequency | Medium | Bucket Sort / Heap | [LeetCode 451](https://leetcode.com/problems/sort-characters-by-frequency/) |
| Largest Number | Medium | Custom Comparator | [LeetCode 179](https://leetcode.com/problems/largest-number/) |
| H-Index | Medium | Counting Sort | [LeetCode 274](https://leetcode.com/problems/h-index/) |
| Car Fleet | Medium | Sorting by Position | [LeetCode 853](https://leetcode.com/problems/car-fleet/) |
| Relative Sort Array | Easy | Frequency Sort | [LeetCode 1122](https://leetcode.com/problems/relative-sort-array/) |
