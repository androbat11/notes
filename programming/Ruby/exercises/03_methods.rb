require 'minitest/autorun'

# Module 3: Methods & Scope
# Instructions: Replace the '____' or TODOs to make the tests pass.

# Exercise 1 & 3: Basic Methods & Implicit Returns
# Senior Tip: Rubyists avoid 'return' if it's the last line. 
# It keeps the code "DRY" and focuses on the result.
def greet(name)
  "Hello, #{name}!"
end

# Exercise 2: Default Arguments
def say_hi(name = "World")
  "Hi, #{name}!"
end

# Exercise 4: Variable Scope
# Task: Methods create their own local scope. They cannot see variables from outside.
# But Instance Variables (@name) are accessible within any method of the class.
class Engineer
  def initialize(name)
    @name = name
  end

  def identify
    @name
  end
end

# Exercise 5: Keyword Arguments (Named Arguments)
# These are safer and more readable for methods with many parameters.
def build_config(env: "dev", debug: true)
  { environment: env, debug: debug }
end

class MethodsTest < Minitest::Test

  def test_implicit_return
    # Task: Call 'greet' with "Manuel"
    result = greet("Manuel")
    assert_equal "Hello, Manuel!", result
  end

  def test_default_args
    # Task: Call 'say_hi' without arguments
    result_default = say_hi()
    # Task: Call 'say_hi' with "Ruby"
    result_named = say_hi("Ruby")

    assert_equal "Hi, World!", result_default
    assert_equal "Hi, Ruby!", result_named
  end

  def test_scope
    # Task: Create a new Engineer instance with "Manuel"
    eng = Engineer.new("Manuel")
    assert_equal "Manuel", eng.identify
  end

  def test_keyword_arguments
    # Task: Call 'build_config' with env: "prod"
    config = build_config(env: "prod")
    
    assert_equal "prod", config[:environment]
    assert_equal true, config[:debug]
  end

  def test_splat_operator
    # The 'splat' (*) operator collects multiple arguments into an array.
    def list_tools(*tools)
      tools
    end

    # Task: Call list_tools with "Git", "Ruby", "Docker"
    result = list_tools("Git", "Ruby", "Docker")

    assert_equal ["Git", "Ruby", "Docker"], result
  end

end
