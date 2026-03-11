# Searching Algorithms: Navigating the State Space

> "Search is the process of finding a specific state within a set of all possible states. It is the core of Spotify's search engine." — *Tutor Lamport*

## 1. Binary Search: The Power of Halving
Binary search is only possible on sorted sequences. It is a divide-and-conquer algorithm that reduces the search space by half in each step.

### Metacognition: The Range Invariant
**Invariant:** At any step, the target is always within the interval `[low, high]`.
**Complexity:** $O(\log n)$. For 1 billion tracks, you only need 30 steps.

### Diagram: The Binary Decision
```text
[ 1 | 3 | 5 | 8 | 12 | 15 | 18 ] Target: 15
  L           M              H   (8 < 15, so L = M + 1)
                  L     M    H   (15 = 15, FOUND)
```

## 2. Mnemonics for Search
**"C-U-T"** (Compare-Update-Target):
- **C**ompare the middle element to the target.
- **U**pdate the boundary (`low` or `high`) based on the comparison.
- **T**erminate when the element is found or the range is empty.

## 3. Why Spotify?
When you search for a track, Spotify doesn't look through every file. It uses an **Index** (often a B-Tree or Hash Map) to perform a fast logarithmic search or constant-time lookup.

## 4. Implementation Examples

### Linear Search (The Baseline)
```python
def linear_search(arr, target):
    # Search the entire state space O(n)
    for i in range(len(arr)):
        if arr[i] == target:
            return i # Found
    return -1 # Not found
```

### Binary Search (Recursive vs. Iterative)
```python
# Iterative: Efficient in memory
def binary_search_iter(arr, target):
    low, high = 0, len(arr) - 1
    while low <= high:
        mid = (low + high) // 2
        # State Invariant check
        if arr[mid] == target:
            return mid
        elif arr[mid] < target:
            low = mid + 1
        else:
            high = mid - 1
    return -1

# Recursive: Elegant, uses Stack Memory
def binary_search_rec(arr, target, low, high):
    if low > high:
        return -1
    mid = (low + high) // 2
    if arr[mid] == target:
        return mid
    elif arr[mid] < target:
        return binary_search_rec(arr, target, mid + 1, high)
    else:
        return binary_search_rec(arr, target, low, mid - 1)
```

| Problem | Difficulty | Search Type | Link |
| :--- | :--- | :--- | :--- |
| Binary Search | Easy | Standard Log(n) | [LeetCode 704](https://leetcode.com/problems/binary-search/) |
| Search in Rotated Sorted Array | Medium | Modified Binary | [LeetCode 33](https://leetcode.com/problems/search-in-rotated-sorted-array/) |
| First and Last Position | Medium | Range Binary | [LeetCode 34](https://leetcode.com/problems/find-first-and-last-position-of-element-in-sorted-array/) |
| Search a 2D Matrix | Medium | Binary over Rows/Cols | [LeetCode 74](https://leetcode.com/problems/search-a-2d-matrix/) |
| Find Minimum in Rotated Array | Medium | Pivot Binary Search | [LeetCode 153](https://leetcode.com/problems/find-minimum-in-rotated-sorted-array/) |
