require 'minitest/autorun'

# Module 2: Control Flow
# Instructions: Fill in the blanks (____) or replace TODOs to make the tests pass.

class ControlFlowTest < Minitest::Test

  # Exercise 1: If/Else
  def test_if_else
    status = "senior"
    experience = 20

    # Task: If experience is greater than 10, set status to "senior".
    if experience > 10
      status = "senior"
    else
      status = "junior"
    end
    
    assert_equal "senior", status
  end

  # Exercise 2: Unless (The "Not" If)
  # Metacognition: Ruby wants you to think "positive". 
  # Use unless for things that should happen IF NOT condition.
  def test_unless_logic
    is_weekend = false
    activity = "coding"

    # Task: Set activity to "resting" unless it's the weekend.
    # Actually, let's say "Unless it's the weekend, I'm working"
    unless is_weekend
      activity = "working"
    end
    
    assert_equal "working", activity
  end

  # Exercise 3: Case (Ruby's Switch/Match)
  # Ruby's 'case' uses the === operator (relationship operator).
  def test_case_statement
    language = "Ruby"
    category = "unknown"

    case language
    when "Ruby", "Python", "JS"
      category = "scripting"
    when "Rust", "Go", "C++"
      category = "systems"
    else
      category = "other"
    end
    
    assert_equal "scripting", category
  end

  # Exercise 4: Ternary & Inline If
  # Senior tip: Ruby methods return the LAST expression automatically.
  def test_shorthand_if
    score = 85
    # Task: Assign 'pass' if score > 70, 'fail' otherwise using ternary.
    result = score > 70 ? "pass" : "fail"

    # Task: Append '!!' to message ONLY if result is 'pass' using inline 'if'
    message = "Success"
    message += "!!" if result == "pass"
    
    assert_equal "Success!!", message
  end

  # Exercise 5: Each (The Ruby Loop)
  # We almost never use 'for' loops in Ruby. We use iterators.
  def test_basic_iterator
    numbers = [1, 2, 3]
    doubled = []

    # Task: Use .each to double every number in the array.
    numbers.each do |n|
      doubled << n * 2 # << is the shovel operator, it appends to the array.
    end
    
    assert_equal [2, 4, 6], doubled
  end

end
