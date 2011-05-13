require 'test_helper'

# This tests the TryRubyBaseSession#calculate_nesting_level function
class NestingLevelTest < Test::Unit::TestCase
  def test_finished_statement_should_return_0
    assert_equal(0, TryRuby.calculate_nesting_level("42"))
  end

  def test_missing_end_should_return_1
    assert_equal(1, TryRuby.calculate_nesting_level("3.times do"))
  end

  def test_missing_close_brace_should_return_1
    assert_equal(1, TryRuby.calculate_nesting_level("3.times {"))
  end

  def test_open_class_should_return_1
    assert_equal(1, TryRuby.calculate_nesting_level("class BlogEntry"))
  end

  def test_closed_class_should_return_0
    assert_equal(0, TryRuby.calculate_nesting_level("class BlogEntry\nend"))
  end

  def test_2_unclosed_dos_should_return_2
    assert_equal(2, TryRuby.calculate_nesting_level("3.times do\n4.times do"))
  end

  def test_mix_of_opened_statements
    test_str = <<-EOF
    class MyClass
      def mymethod
        3.times do
          8.times {
    EOF
    assert_equal(4, TryRuby.calculate_nesting_level(test_str))
  end

  def test_open_and_close_on_same_line_should_return_0
    assert_equal(0, TryRuby.calculate_nesting_level("3.times { puts 'lol' }"))
    assert_equal(0, TryRuby.calculate_nesting_level("3.times do |v| puts 'lol'; end"))
  end

  def test_half_statement
    assert_equal(1, TryRuby.calculate_nesting_level('true and'))
    assert_equal(1, TryRuby.calculate_nesting_level('amethod('))
  end
                                                                   
end
