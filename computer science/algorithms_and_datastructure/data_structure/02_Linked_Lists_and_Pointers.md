# Linked Lists and Pointers: Temporal Ordering

> "A linked list is a sequence of events where each event knows its successor. It is the logical antithesis of the array." — *Tutor Lamport*

## 1. The Logic of Decoupling
In an array, memory position *is* index. In a Linked List, memory position is irrelevant; only the `next` pointer defines the order.

### Diagram: The Chain of State
```text
Head -> [ Val | Next ] -> [ Val | Next ] -> [ Val | Null ]
           ^                 ^
         State 1           State 2
```

### Metacognition: The Pointer Invariant
When you reverse a list or remove a node, you are performing a surgery on the graph of states.
**Invariant:** `Current.next` must always point to the logical successor, or the "timeline" is broken.

## 2. Mnemonics for Linked Lists
**"D-U-M-B"** (Dummy-Universal-Management-Block):
- **D**ummy Node: Always create a `dummy` node pointing to `head`. It simplifies edge cases (like removing the head).
- **U**nlink carefully: Save the `next` node before you overwrite the current pointer.
- **M**oving Pointers: Slow and Fast (Runner technique) to find the middle or detect a cycle.
- **B**reak the Cycle: Set the tail's `next` to `null` to prevent infinite loops in the "state machine."

## 3. Why Spotify?
Linked lists are the foundation for **Queues** (Song Playback Queues) and **Stacks** (Undo actions in the UI). When you "add to queue," you are essentially appending to a dynamic linked structure.

---

## Exercises: The Playback Queue
| Problem | Difficulty | Technique | Link |
| :--- | :--- | :--- | :--- |
| Reverse Linked List | Easy | Pointer Reversal | [LeetCode 206](https://leetcode.com/problems/reverse-linked-list/) |
| Linked List Cycle | Easy | Fast & Slow Pointers | [LeetCode 141](https://leetcode.com/problems/linked-list-cycle/) |
| Merge Two Sorted Lists | Easy | Dummy Node + Pointers | [LeetCode 21](https://leetcode.com/problems/merge-two-sorted-lists/) |
| Remove Nth Node From End | Medium | Two-Pointer Gap | [LeetCode 19](https://leetcode.com/problems/remove-nth-node-from-end-of-list/) |
| Reorder List | Medium | Reverse + Merge | [LeetCode 143](https://leetcode.com/problems/reorder-list/) |
