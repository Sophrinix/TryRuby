require 'test_helper'    

# tests if the TryRubyOutput translation, for use with mouseapp_2.js and similar
# is working correctly
class OutputTest < Test::Unit::TestCase
  def test_simple_result
    t = TryRuby::Output.standard(result: [12,24])
    assert_equal("=> \033[1;20m[12, 24]", t.format)
  end
  
  def test_result_and_output
    t = TryRuby::Output.standard(result: 333, output: "hello")
    assert_equal("hello=> \033[1;20m333", t.format)
  end

  def test_error
    begin
      40.reverse
    rescue Exception => e
      t = TryRuby::Output.error(error: e)
    end
    assert_equal("\033[1;33mNoMethodError: undefined method `reverse' for 40:Fixnum",
                 t.format)
  end

  def test_error_with_output
    begin
      40.reverse
    rescue Exception => e
      t = TryRuby::Output.error(error: e, output: "hello\nworld")
    end
    assert_equal("hello\nworld\033[1;33mNoMethodError: undefined method `reverse' for 40:Fixnum",
                 t.format)
  end

  def test_illegal
    t = TryRuby::Output.illegal
    assert_equal("\033[1;33mYou aren't allowed to run that command!",
                 t.format)
  end
      


  def test_line_continuation
    t = TryRuby::Output.line_continuation(3)
    assert_equal(".." * 3, t.format)
  end

  def xtest_javascript
    t = TryRuby::Output.javascript(javascript: 'alert("hello")')
    # expected ends in a space to stop a visual problem in mouseapp
    assert_equal("\033[1;JSmalert(\"hello\")\033[m ", t.format)
  end

end