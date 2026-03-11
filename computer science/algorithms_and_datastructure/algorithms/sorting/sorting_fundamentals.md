# Sorting Algorithms: The Physics of Order

> "Sorting is the process of arranging a sequence of states such that a total ordering relation holds. It is the prerequisite for efficiency." — *Tutor Lamport*

## 1. Insertion Sort: The "Manual Library"
Insertion Sort is how a human sorts a hand of cards. You take one element and "insert" it into its correct position in the already-sorted prefix.

### Metacognition: The Sorted Prefix Invariant
**Invariant:** At step $i$, the subarray `A[0...i-1]` is always sorted.
**Mnemonic: "S-I-F-T"**
- **S**can the next element.
- **I**dentify the target position in the sorted prefix.
- **F**ind the gap by shifting elements right.
- **T**uck the element into place.

### Diagram: Insertion at Scale
```text
[ 2 | 5 | 8 ] | 3 | 1  (Prefix 2,5,8 is sorted)
          ^-----'
[ 2 | 3 | 5 | 8 ] | 1  (3 is tucked, prefix grows)
```

## 2. Merge Sort: Divide and Conquer
Merge Sort is a recursive state machine. It splits the problem until it is trivial (1 element) and then "merges" them back using a stable comparison.

### Metacognition: The Merge Invariant
**Invariant:** After `merge(left, right)`, the resulting array contains all elements from both, in total order.
**Complexity:** $O(n \log n)$ - Guaranteed. Perfect for Spotify's massive distributed datasets where predictability is key.

### Diagram: The Recursive Tree
```text
      [ 8 | 3 | 2 | 9 ]
      /             \
  [ 8 | 3 ]       [ 2 | 9 ]
   /     \         /     \
 [8]     [3]     [2]     [9]
   \     /         \     /
  [ 3 | 8 ]       [ 2 | 9 ]
      \             /
      [ 2 | 3 | 8 | 9 ]
```

## 3. Quick Sort: The Pivot Strategy
Quick Sort selects a `pivot` and partitions the state space into "less than" and "greater than."

**Complexity:** $O(n \log n)$ average, but $O(n^2)$ worst-case. In-place, meaning it uses no extra memory (unlike Merge Sort).

## 4. Implementation Examples

### Merge Sort (Divide & Conquer)
```python
def merge_sort(arr):
    # Invariant: Arrays of size 1 are already sorted
    if len(arr) <= 1:
        return arr
        
    mid = len(arr) // 2
    # Divide the state space
    left = merge_sort(arr[:mid])
    right = merge_sort(arr[mid:])
    
    return merge(left, right)

def merge(left, right):
    # Combine two sorted states into one
    result = []
    i = j = 0
    while i < len(left) and j < len(right):
        if left[i] < right[j]:
            result.append(left[i]); i += 1
        else:
            result.append(right[j]); j += 1
    # Attach leftovers
    result.extend(left[i:])
    result.extend(right[j:])
    return result
```

### Quick Sort (In-Place Partition)
```python
def quicksort(arr, low, high):
    # In-place modification of state
    if low < high:
        p = partition(arr, low, high)
        quicksort(arr, low, p - 1)
        quicksort(arr, p + 1, high)

def partition(arr, low, high):
    # Invariant: All elements to the left of pivot <= pivot
    pivot = arr[high]
    i = low # Target index for swap
    for j in range(low, high):
        if arr[j] <= pivot:
            arr[i], arr[j] = arr[j], arr[i]
            i += 1
    # Move pivot to center
    arr[i], arr[high] = arr[high], arr[i]
    return i
```

| Problem | Difficulty | Algorithm | Link |
| :--- | :--- | :--- | :--- |
| Sort an Array | Medium | Merge / Quick Sort | [LeetCode 912](https://leetcode.com/problems/sort-an-array/) |
| Kth Largest Element | Medium | Quick Select (Pivot) | [LeetCode 215](https://leetcode.com/problems/kth-largest-element-in-an-array/) |
| Sort Colors | Medium | Dutch National Flag | [LeetCode 75](https://leetcode.com/problems/sort-colors/) |
| Merge Sorted Array | Easy | Two Pointers | [LeetCode 88](https://leetcode.com/problems/merge-sorted-array/) |
| Insertion Sort List | Medium | Linked List Insertion | [LeetCode 147](https://leetcode.com/problems/insertion-sort-list/) |
