require 'minitest/autorun'

# Module 1: Objects & Variables
# Instructions: Fill in the blanks (____) or replace TODOs to make the tests pass.

class VariablesTest < Minitest::Test

  # Exercise 1: Assignment
  # Ruby variables are snake_case by convention.
  def test_variable_assignment
    my_favorite_language = "Ruby"
    
    assert_equal "Ruby", my_favorite_language
  end

  # Exercise 2: String Interpolation
  # Use double quotes ("") for interpolation. Single quotes ('') are literal.
  def test_string_interpolation
    name = "Engineer"
    # Replace ____ with the correct interpolation syntax
    greeting = "Hello, #{name}!"
    
    assert_equal "Hello, Engineer!", greeting
  end

  # Exercise 3: Symbols vs Strings
  # Symbols are immutable and represent "names". Strings are data.
  # Two symbols with the same name are the SAME object.
  def test_symbols_are_unique
    str1 = "ruby"
    str2 = "ruby"
    sym1 = :ruby
    sym2 = :ruby

    # In Ruby, .object_id returns the unique memory address of the object.
    assert_equal true, sym1.object_id == sym2.object_id
    assert_equal false, str1.object_id == str2.object_id
  end

  # Exercise 4: Strong Typing
  # Ruby won't implicitly convert types. 
  # Use .to_s (to string) or .to_i (to integer).
  def test_type_conversion
    age = 20
    # Task: Convert 'age' to a string so it can be concatenated.
    result = "I am " + age.to_s + " years old."
    
    assert_equal "I am 20 years old.", result
  end

  # Exercise 5: Basic Collections (Array & Hash)
  def test_collections
    # Arrays are ordered lists.
    list = ["Ruby", "Go", "TypeScript"]
    # Task: Access the first element.
    first_item = list[0]

    # Hashes are key-value pairs.
    # We often use symbols as keys.
    profile = { name: "Manuel", role: "Architect" }
    # Task: Access the 'role' value.
    my_role = profile[:role]

    assert_equal "Ruby", first_item
    assert_equal "Architect", my_role
  end

end
