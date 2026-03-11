require 'minitest/autorun'

# Module 4: Blocks, Procs, and Lambdas
# The core of Ruby's functional power.

class BlocksTest < Minitest::Test

  # Exercise 1: Yielding to a block
  # 'yield' executes the block passed to the method.
  def do_something_twice
    yield
    yield
  end

  def test_yield
    count = 0
    # Task: Call 'do_something_twice' with a block that increments 'count'
    do_something_twice do
      count += 1
    end
    
    assert_equal 2, count
  end

  # Exercise 2: block_given?
  # Always check if a block exists before yielding!
  def run_safely
    if block_given?
      yield
    else
      "No block provided"
    end
  end

  def test_block_given
    # Task 1: Call 'run_safely' without a block.
    result1 = run_safely
    # Task 2: Call 'run_safely' with a block that returns "Success"
    result2 = run_safely { "Success" }

    assert_equal "No block provided", result1
    assert_equal "Success", result2
  end

  # Exercise 3: Passing arguments to blocks
  def repeat_with_index(times)
    times.times do |i|
      yield(i)
    end
  end

  def test_yield_with_arguments
    collected = []
    # Task: Pass 3 times and collect the index 'i' in the 'collected' array.
    repeat_with_index(3) do |i|
      collected << i
    end

    assert_equal [0, 1, 2], collected
  end

  # Exercise 4: Enumerable - Map
  # Map transforms every element in a collection.
  def test_map_transformation
    names = ["manuel", "ruby", "rust"]
    # Task: Transform 'names' to be capitalized using .map and .capitalize
    upcased = names.map { |name| name.capitalize }

    assert_equal ["Manuel", "Ruby", "Rust"], upcased
  end

  # Exercise 5: Procs vs Lambdas
  # Procs are "loose", Lambdas are "strict" (about arguments and return).
  def test_proc_and_lambda
    # A Proc (Procedure)
    my_proc = Proc.new { "I am a Proc" }
    
    # A Lambda (The "Stricter" cousin)
    my_lambda = -> { "I am a Lambda" }

    # Task: Execute both.
    proc_result = my_proc.call
    lambda_result = my_lambda.call

    assert_equal "I am a Proc", proc_result
    assert_equal "I am a Lambda", lambda_result
  end

end
