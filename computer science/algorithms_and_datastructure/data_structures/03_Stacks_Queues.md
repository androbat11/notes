# Stacks and Queues: Temporal Ordering

> "A stack is a history of events where only the present is accessible. A queue is a line of events waiting for their turn in time." — *Tutor Lamport*

## 1. The Stack (LIFO: Last-In, First-Out)
A Stack is a restricted state machine. You can only interact with the `top`.
**Invariant:** The element at the top is the one most recently added.

### Metacognition: The "Undo" Logic
At Spotify, when you navigate through menus, each "Back" button press pops a state from the Navigation Stack.
**Mnemonic: "P-U-S-H"**
- **P**lace on top.
- **U**pdate the pointer.
- **S**ave the context.
- **H**old the state.

## 2. The Queue (FIFO: First-In, First-Out)
A Queue maintains the order of arrival.
**Invariant:** The element at the `front` has been in the system the longest.

### Metacognition: The "Buffer" Logic
When you stream a song, Spotify uses a **Circular Queue** as a buffer. While the player consumes data from the front, the network thread pushes new data to the back.

## 3. Implementation Examples

### The Stack (Using a List)
```python
class SpotifyHistoryStack:
    def __init__(self):
        self.stack = []

    def visit_page(self, page_name):
        # State Transition: S -> S + [page]
        self.stack.append(page_name)
        print(f"Visited: {page_name}")

    def back_button(self):
        # Invariant: Cannot pop from an empty history
        if not self.stack:
            return None
        return self.stack.pop()

# Usage
history = SpotifyHistoryStack()
history.visit_page("Home")
history.visit_page("Artist: Radiohead")
print(f"Back to: {history.back_button()}") # Returns "Artist: Radiohead"
```

### The Queue (Using collections.deque for O(1) ops)
```python
from collections import deque

class PlaybackQueue:
    def __init__(self):
        self.queue = deque()

    def add_to_queue(self, track_id):
        # State Transition: Q -> Q + [track]
        self.queue.append(track_id)

    def play_next(self):
        # Invariant: FIFO - First added is first played
        if not self.queue:
            return "No more tracks."
        return self.queue.popleft()

# Usage
pq = PlaybackQueue()
pq.add_to_queue("Track_001")
pq.add_to_queue("Track_002")
print(f"Playing: {pq.play_next()}") # "Track_001"
```

| Problem | Difficulty | Structure | Link |
| :--- | :--- | :--- | :--- |
| Valid Parentheses | Easy | Stack | [LeetCode 20](https://leetcode.com/problems/valid-parentheses/) |
| Implement Queue using Stacks | Easy | Two Stacks | [LeetCode 232](https://leetcode.com/problems/implement-queue-using-stacks/) |
| Min Stack | Medium | Auxiliary Stack | [LeetCode 155](https://leetcode.com/problems/min-stack/) |
| Daily Temperatures | Medium | Monotonic Stack | [LeetCode 739](https://leetcode.com/problems/daily-temperatures/) |
| Task Scheduler | Medium | Priority Queue | [LeetCode 621](https://leetcode.com/problems/task-scheduler/) |
