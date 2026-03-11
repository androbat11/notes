# Ruby Fundamentals: The Architect's Guide

Welcome, Engineer. After 20 years of seeing languages come and go, Ruby remains one of the most intellectually satisfying environments to work in. Why? Because it treats you like a human who wants to express *intent*, not a machine that needs instructions.

## The Mental Model: "Everything is an Object"
In Ruby, even the number `1` or the class `String` itself is an object. 
**Metacognition:** Why does this matter? Because it means there is a universal interface. If you want to know what a "thing" can do, you ask it: `object.methods`.

### 1. Variables & Basic Types
Ruby is **Dynamically Typed** (like Python/JS) but **Strongly Typed** (it won't let you add a String and an Integer without an explicit conversion).
-   `String`: "I'm a string"
-   `Symbol`: `:i_am_a_symbol` (Immutable, efficient, used for keys)
-   `Integer/Float`: `42`, `3.14`
-   `Array`: `[1, 2, 3]`
-   `Hash`: `{ key: "value" }`

### 2. Control Flow: The "Unless" & "Until"
Ruby values readability above all. Instead of `if !condition`, we use `unless condition`. It's about reducing the cognitive load of "Not" logic.

### 3. Methods: Message Passing
When you call `user.name`, you aren't "accessing a property." You are **sending a message** called `:name` to the `user` object. The object decides how to respond.

### 4. Blocks: The Soul of Ruby
This is where Ruby shines. A **Block** is a chunk of code you pass into a method to be executed.
```ruby
[1, 2, 3].each do |num|
  puts num * 2
end
```
Think of a block as a "plugin" for a method's behavior.

---

## How to use these exercises
1.  Navigate to the `exercises/` folder.
2.  Open an exercise file (e.g., `01_variables.rb`).
3.  Read the instructions and fill in the missing code (look for `____` or TODOs).
4.  Run the exercise using the Ruby interpreter:
    ```bash
    ruby 01_variables.rb
    ```
5.  The output will tell you which tests passed or failed.

---
## The Roadmap
-   [ ] Module 1: Objects & Variables (5 Exercises)
-   [ ] Module 2: Control Flow (5 Exercises)
-   [ ] Module 3: Methods & Scope (5 Exercises)
-   [ ] Module 4: Blocks, Procs, & Lambdas (5 Exercises)
-   [ ] Module 5: Classes & Modules (5 Exercises)
