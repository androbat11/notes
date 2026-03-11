# Linked Lists: Single and Double Two-Way Timelines

> "A Doubly Linked List is a timeline that allows us to look into the past and future simultaneously." — *Tutor Lamport*

## 1. Single vs. Doubly Linked Lists
While a **Singly Linked List** only knows its `next` state, a **Doubly Linked List (DLL)** maintains two pointers per node: `next` and `prev`.

### Metacognition: The Bidirectional Invariant
**Invariant:** For any node $N$ (except head/tail), `N.next.prev == N` and `N.prev.next == N`.
If this invariant is broken, the list is corrupted.

### Diagram: The Doubly Linked Chain
```text
Null <- [ Prev | Val | Next ] <-> [ Prev | Val | Next ] -> Null
```

## 2. Mnemonics for Pointer Surgery
**"W-I-R-E"** (Wait-Identify-Reconnect-Exit):
- **W**ait: Never delete a node until you've saved its neighbors.
- **I**dentify: Clearly label `left_neighbor` and `right_neighbor`.
- **R**econnect: Connect `left_neighbor.next = right_neighbor` and `right_neighbor.prev = left_neighbor`.
- **E**rase: Only now is it safe to free the memory.

## 3. Why Spotify?
The Playback Controller. You have "Next Song" and "Previous Song." A Doubly Linked List is the natural structure for a playlist you are currently listening to, allowing for $O(1)$ navigation in both directions.

## 4. Implementation Examples

### Singly Linked List (Reversal Example)
```python
class Node:
    def __init__(self, val=0, next=None):
        self.val = val
        self.next = next

def reverse_playlist(head):
    # Invariant: prev always points to the last node processed
    prev = None
    curr = head
    while curr:
        nxt = curr.next  # Save state before modification
        curr.next = prev # The Surgery: Point backwards
        prev = curr      # Advance the pointer
        curr = nxt       # Move to next state
    return prev # New Head
```

### Doubly Linked List (Deletion Example)
```python
class DLLNode:
    def __init__(self, val=0, next=None, prev=None):
        self.val = val
        self.next = next
        self.prev = prev

def remove_track(node_to_remove):
    # The Surgery on a Two-Way Timeline
    # Invariant: Neighbors must point to each other after deletion
    left = node_to_remove.prev
    right = node_to_remove.next

    if left:
        left.next = right
    if right:
        right.prev = left
    
    # Clean up state for garbage collection
    node_to_remove.next = None
    node_to_remove.prev = None
```

| Problem | Difficulty | Structure | Link |
| :--- | :--- | :--- | :--- |
| Delete Node in a Linked List | Medium | Surgery | [LeetCode 237](https://leetcode.com/problems/delete-node-in-a-linked-list/) |
| Add Two Numbers | Medium | Single LL Summation | [LeetCode 2](https://leetcode.com/problems/add-two-numbers/) |
| Flatten a Multilevel DLL | Medium | DFS + DLL | [LeetCode 430](https://leetcode.com/problems/flatten-a-multilevel-doubly-linked-list/) |
| LRU Cache | Medium | DLL + Hash Map | [LeetCode 146](https://leetcode.com/problems/lru-cache/) |
| Rotate List | Medium | Single LL Rotation | [LeetCode 61](https://leetcode.com/problems/rotate-list/) |
