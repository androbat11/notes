
### Stack

The stack stores values in the order it gets them and removes the values in the opposite order. This is referred to as _last in, first out (LIFO)_.

* All data stored on the ***stack must have a known***, fixed size. Data with an unknown size at compile time or a size that might change must be stored on the heap instead.
* ***Pushing to the stack is faster than allocating on the heap*** because the allocator never has to search for a place to store new data; that location is always at the top of the stack.

### Heap

The heap is less organized: When you put data on the heap, you request a certain amount of space. The memory allocator finds an empty spot in the heap that is big enough, marks it as being in use, and returns a **_pointer_**, **which is the address of that location**.
* This process is called _allocating on the heap_ and is sometimes abbreviated as just _allocating_ (pushing values onto the stack is not considered allocating).*
* Because the ***pointer to the heap is a known***, fixed size, ***you can store the pointer on the stack,*** but when you want the actual data, you must follow the pointer.
* Comparatively, allocating space on the heap requires more work because the allocator must first find a big enough space to hold the data and then perform bookkeeping to prepare for the next allocation.


### Conclusion

Keeping track of what parts of code are using what data on the heap, minimizing the amount of duplicate data on the heap, and cleaning up unused data on the heap so that you don’t run out of space are all problems that ownership addresses. Once you understand ownership, you won’t need to think about the stack and the heap very often. But knowing that the main purpose of ownership is to manage heap data can help explain why it works the way it does.