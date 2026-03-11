require 'minitest/autorun'

# Module 5: Classes & Modules
# In Ruby, everything is an object. Classes are the blueprints.

# Exercise 1 & 2: Defining a Class & Accessors
# Metacognition: Writing getters/setters manually is tedious. 
# Ruby provides 'attr_accessor' to do it for you.
class Book
  attr_accessor :title, :author

  def initialize(title, author)
    @title = title
    @author = author
  end
end

# Exercise 3: Inheritance
class EBook < Book
  # Task: Initialize with title, author, and file_size.
  attr_accessor :file_size

  def initialize(title, author, file_size)
    super(title, author) # 'super' calls the parent method.
    @file_size = file_size
  end
end

# Exercise 4: Modules (Mixins)
# Ruby doesn't support multiple inheritance. 
# Instead, we "mix in" modules to share behavior.
module Playable
  def play
    "Playing..."
  end
end

class VideoGame
  include Playable # Task: Mix in the Playable module.
end

class ClassesTest < Minitest::Test

  def test_class_instantiation
    # Task: Create a new Book instance "Ruby for Beginners" by "Matz"
    book = Book.new("Ruby for Beginners", "Matz")

    assert_equal "Ruby for Beginners", book.title
    assert_equal "Matz", book.author
  end

  def test_inheritance
    # Task: Create an EBook with title "Learn Ruby", author "Manuel", size 5
    ebook = EBook.new("Learn Ruby", "Manuel", 5)

    assert_equal "Learn Ruby", ebook.title
    assert_equal 5, ebook.file_size
    # Task: Verify inheritance works.
    assert_kind_of Book, ebook
  end

  def test_mixins
    # Task: Instantiate VideoGame and call 'play'
    game = VideoGame.new
    
    assert_equal "Playing...", game.play
  end

  def test_private_methods
    # Task: Private methods cannot be called from outside.
    class Secretive
      def reveal
        internal_secret
      end

      private

      def internal_secret
        "Shh!"
      end
    end

    s = Secretive.new
    # This should work.
    assert_equal "Shh!", s.reveal
    # This should fail if uncommented:
    # s.internal_secret 
  end

  def test_self_keyword
    # 'self' refers to the current object.
    class Speaker
      def who_am_i
        self
      end
    end

    s = Speaker.new
    assert_equal s, s.who_am_i
  end

end
