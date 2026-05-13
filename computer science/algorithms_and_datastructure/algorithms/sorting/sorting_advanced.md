---
title: 'Sorting Algorithms: The Physics of Order (Advanced)'
description: ''
author: Manuel
created: 2026-04-17T20:35:17.044014+00:00
remargin_pending: 1
remargin_pending_for:
- Manuel
remargin_last_activity: 2026-04-17T20:39:42.420485+00:00
---

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
```remargin
---
id: zta
author: Manuel
type: human
ts: 2026-04-17T20:35:17.043953+00:00
checksum: sha256:eab134c09ba98a2cbd9afbf93af3c4094d67c7c6053024e17785ceaeaea89430
ack:
  - Manuel@2026-04-17T20:38:19.758178+00:00
---
Bubble sort is one of the most inefficient sorting algorithms in practice. Its $O(n^2)$ time complexity means that doubling the input size quadruples the work — on 10,000 elements it performs ~50 million comparisons, where Merge Sort would do ~130,000. Even with the early-exit optimization for nearly sorted data, it's outperformed by Insertion Sort in that same scenario, which has better cache behavior and fewer swaps. Bubble sort's only real value is pedagogical: the invariant is easy to visualize and reason about. Never use it in production code.
```

```remargin
---
id: 4it
author: Manuel
type: human
ts: 2026-04-17T20:38:19.758178+00:00
checksum: sha256:254d774a6beb23c681a2af3831520a71c09f38b6794ee48e380960408635ab99
to: [Manuel]
reply-to: zta
thread: zta
ack:
  - Manuel@2026-04-17T20:39:42.420485+00:00
---
Agreed on all counts. Worth adding some concrete intuition for *why* the cache behavior difference matters: Insertion Sort shifts elements one position at a time in a tight inner loop, which is sequential memory access — the CPU prefetcher handles it well. Bubble sort's adjacent-swap pattern is similar, but it performs up to $O(n^2)$ swaps vs. Insertion Sort's $O(n)$ shifts on nearly sorted data, since a shift moves one element while a swap moves two. The write pressure alone makes bubble sort slower in practice even when the comparison counts are close.

Also worth noting: the $O(n^2)$ label undersells the constant factor problem. Many algorithms are technically $O(n^2)$ but fast in practice due to low constants. Bubble sort manages to have *both* a bad asymptotic complexity and poor constants — a rare double loss.
```

```remargin
---
id: rin
author: Manuel
type: human
ts: 2026-04-17T20:39:42.420485+00:00
checksum: sha256:821f8772152424f4bab4bd864c50e0c23de5b8774584ff3b5e689e8e1e50a113
to: [Manuel]
reply-to: 4it
thread: zta
---
The "double loss" framing is apt. To make the constant factor point concrete: in a random array, bubble sort performs $\frac{n(n-1)}{2}$ comparisons *and* up to $\frac{n(n-1)}{2}$ swaps — each swap being three writes (temp, a←b, b←temp). Insertion sort performs the same number of comparisons in the worst case, but its inner loop does only *shifts* (one write per step), and crucially stops early once the element is in place. The total number of shifts equals the number of inversions in the array, which for random data averages $\frac{n(n-1)}{4}$ — half as many memory writes, all sequential.

On the prefetcher point: modern CPUs can sustain sequential write throughput near memory bandwidth limits, but random or stride-2 patterns break that. Bubble sort's swap pattern touches each element twice per pass with no locality gain, while insertion sort's shift runs are a single contiguous backward scan — exactly what a hardware prefetcher is tuned for.

The practical upshot: even if you ignore asymptotic complexity entirely and only care about raw throughput on small arrays, insertion sort wins on the hardware model alone.
```



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
