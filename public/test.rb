require 'pp'
require 'test/unit'
require 'rexml/document'
require 'test/unit/ui/console/testrunner'
require 'stringio'

load 'tryruby_runner.rb'

class TryRubyTestSession < TryRubyBaseSession
  def initialize
    reset
    @current_includes = []
  end
 
 
  attr_accessor :start_time, :current_statement
  attr_accessor :nesting_level, :past_commands, :current_includes
 
end

$session = nil

class TryRubyTest < Test::Unit::TestCase
  # a test helper that simplifies testing the tryruby interpretor. 
  # It takes one optional argument session, which is the session to use for
  # the test.
  # It then takes a block. In the block a method input is available which is used
  # to send a line to the interpretor and test the output.
  # 
  # input takes one mandatory argument, the line, and some optional args:
  # - output: The output of line should match this (defaults to "")
  # - javascript: The line generated a javascript function, and should match this
  # - error: The line generated an error and should match this
  # - result: The line didn't generate an error or javascript, and should match this
  #           (defaults to nil if not supplied)
  # - line_continuation: The line didn't complete, the current indent level
  #   should be equal to this (use true if you aren't interested in testing this)
  # output, error, javascript and result can take either a:
  # - Class: Tests if <value> is the given type
  # - Proc: Proc should take one param (the <value>) and run assertions with that value
  # - Regexp: Tests <value> (a string) against the regexp
  # - <other>: <value> should equal <other>
  def tryruby_session(session = TryRubyTestSession.new, &block)
    input_o = TryRubySession_Input.new
    input_o.session = session
    input_o.test = self
    input_o.instance_eval(&block)
    
  end


  def test_lesson1
    tryruby_session do
      input '2 + 6'           , result: 8
      input '"Jimmy"'         , result: "Jimmy"
      input '"Jimmy".reverse' , result: "ymmiJ"
      input '"Jimmy".length'  , result: 5
      input '"Jimmy" * 5'     , result: "JimmyJimmyJimmyJimmyJimmy"
    end
  end

  def test_lesson2
    tryruby_session do
      input '40.reverse',          error: NoMethodError
      input '40.to_s.reverse',     result: "04"
      input '[]',                  result: []
      input '[12,47,35]',          result: [12,47,35]
      input '[12,47,35].max',      result: 47
      input 'ticket = [12,47,35]', result: [12,47,35]
      input 'ticket',              result: [12,47,35]
      input 'ticket.sort!',        result: [12,35,47]
    end
  end

  def test_lesson3
    poem = <<-EOF
My toast has flown from my hand
And my toast has gone to the
moon.
But when I saw it on television,
Planting our flag on Halley's
comet,
More still did I want to eat it.
EOF
    
    tryruby_session do
      input 'print poem',                         output: poem
      input "poem['toast'] = 'honeydew'",         result: "honeydew"
      input 'print poem',                         output: (poem['toast'] = 'honeydew'; poem)
      input 'poem.reverse',                       result: poem.reverse
      input 'poem.lines.to_a.reverse',            result: poem.lines.to_a.reverse
      input 'print poem.lines.to_a.reverse.join', output: poem.lines.to_a.reverse.join
      end
  end

  def test_lesson4
    tryruby_session do
      input 'books = {}',                     result: {}

      input 'books["Gravity\'s Rainbow"] = :splendid',
            result: :splendid

      input 'books["a"] = :mediocre',         result: :mediocre
      input 'books["b"] = :mediocre',         result: :mediocre
      input 'books["c"] = :mediocre',         result: :mediocre
      input 'books.length',                   result: 4
      input 'books["Gravity\'s Rainbow"]',    result: :splendid
      input 'books.keys',                     result: ["Gravity's Rainbow", "a", "b", "c"]
      input 'ratings = Hash.new {0}',         result: {}

      input 'books.values.each { |rate| ratings[rate] += 1 }',
            result: [:splendid, :mediocre, :mediocre, :mediocre]  

      input '5.times {print "Odelay!" }',              
            result: 5,
            output: 'Odelay!Odelay!Odelay!Odelay!Odelay!'
      
    end
  end

    

  def test_lesson6_and_7
    $session = TryRubyTestSession.new
    tryruby_session $session do
      input 'Hash.new',              result: {}
      input 'class BlogEntry',       line_continuation: 1
      input 'attr_accessor :title, :time, :fulltext, :mood', line_continuation: 1
      input 'end',                   result: nil

      # can't test for BlogEntry directly, as it isn't defined in this scope
      input 'entry = BlogEntry.new', result: Proc.new {|v|
        assert_equal("BlogEntry", v.class.name, 
                     "line should result in a BlogEntry")
      }

      input 'entry.title = "Today Mt. Hood Was Stolen!"', result: "Today Mt. Hood Was Stolen!"

      input 'entry.time = Time.now', result: Time

      input 'entry.mood = :sick', result: :sick

      str = <<EOF
I can't believe Mt. Hood was stolen!
I am speechless! It was stolen by a giraffe who drove
away in his Cadillac Seville very nonchalant!!
EOF
      input "entry.fulltext = #{str.inspect}",  result: str
                    
                   

      input 'entry', result: Proc.new {|v|
        assert_equal(:sick,  v.instance_variable_get("@mood"))
        assert_equal(Time,    v.instance_variable_get("@time").class)
        assert_equal("I can'",v.instance_variable_get("@fulltext")[0..5])
        
      }, message: "result should be a correctly created BlogEntry"

      input 'class BlogEntry',                                  line_continuation: 1
      input 'def initialize( title, mood, fulltext )',          line_continuation: 2
      input '@time = Time.now',                                 line_continuation: 2
      input '@title, @mood, @fulltext = title, mood, fulltext', line_continuation: 2
      input 'end',                                              line_continuation: 1
      input 'end',                                              result: nil
      
      input 'BlogEntry.new',                                    error: ArgumentError


      line = <<-EOF
        entry2 = BlogEntry.new("I Left my Hoodie on the Mountain!",
          :confused,
          "I am never going back to that mountain and I hope a giraffe steals it.")
      EOF

      input line.tr("\n", ' '),
        result: Proc.new {|v| assert_equal("BlogEntry", v.class.name) }

      # ######################################################
      # lesson 7 starts here (depends on lesson 6 to complete)
      # ######################################################

      input 'blog = [entry, entry2]', result: Proc.new { |v|
        assert_kind_of(Array, v)
        assert(v.all? {|e| e.class.name == "BlogEntry" },
               "All elements of result should be a BlogEntry")
      }


      input 'blog.map { |entry| entry.mood }', result: [:sick, :confused]
      input 'require "popup"',                 result: Proc.new {} # don't care
      input 'Popup.make do',                   line_continuation: 1
      input "h1 'My Blog'",                    line_continuation: 1
      input "list do",                         line_continuation: 2
      input 'blog.each do |entry|',            line_continuation: 3
      input 'h2 entry.title',                  line_continuation: 3
      input 'p entry.fulltext',                line_continuation: 3
      input 'end',                             line_continuation: 2
      input 'end',                             line_continuation: 1

      
      
      input 'end', javascript: Proc.new {|v|
        # v = v.gsub(/\s+/,"") # remove all spaces
        expected_str = <<-EOF
          <xml><h1>My Blog</h1>
          <ul>
            <li><h2>Today Mt. Hood Was Stolen!</h2></li>
            <li>I can't believe Mt. Hood was stolen! I am speechless! 
                It was stolen by a giraffe who drove away in his
                Cadillac Seville very nonchalant!!</li>
            <li><h2>I Left my Hoodie on the Mountain!</h2></li>
            <li>I am never going back to that mountain and
              I hope a giraffe steals it.</li>
          </ul></xml>
          EOF
        expected_xml = REXML::Document.new(expected_str.strip)
        assert_match(/^window.irb.options.popup_make\(".*"\)?/m,
                     v,
                     "testing that Popup calls the correct javascript function")
        actual_str = v.match(/^window.irb.options.popup_make\("(.*)"\);?/m)[1]
        actual_str = "<xml>#{actual_str}</xml>"
        actual_xml = REXML::Document.new(actual_str.strip)
        assert_equal(expected_xml.write(StringIO.new).to_s,
                     actual_xml.write(StringIO.new).to_s,
                     "testing that html used with the javascript popup " +
                     "function is correct")
      }
        
    end # tryruby_session

  end # lesson6_and_7


    
  # class that performs the tests with the input sections of the 
  # tryrubysession test helper
  class TryRubySession_Input
    attr_accessor :session, :test

    # performs an assertion
    # actual is the value being tested 
    # expected should either be a 
    # - Class: the class of actual should be expected
    # - Regexp: actual (a string) should match the expected Regexp
    # - Proc: A proc that takes one argument, actual. Assertions can
    # be used inside that proc, eg assert_equal, assert.
    # - <other>: actual should equal expected
    # name is the name of the input (result, output, javascript, error),
    # used in messages
    # line is the line being tested
    def do_assert(actual, expected, name, line)
      case expected
      when Class
        @test.assert_kind_of(expected, actual,
                           "Testing line `#{line}': #{name} should be a #{expected}")
      when Regexp
        @test.assert_match(expected, actual, 
                              "Testing line `#{line}': #{name} should match #{expected}")
      when Proc
        @backtrace_pos = 0
        @test.instance_exec(actual, &expected)
          
          # @test.assert(expected.call(actual),
          #              "Testing line `#{line}': #{message} \n[#{actual}]")
      else
          @test.assert_equal(expected,actual,
                             "Testing line `#{line}' for correct #{name}")
      end
    end

    # runs the line using this objects session. 
    def do_test(line)
      o = Object.new
      # store the initial constants of Object
      initial_constants = Object.constants
      session = @session
      
      thread = Thread.new do
        o.instance_eval do
          run_script(session, line)
        end
      end
        
      result = thread.value
      # restores require to its old functionality
      def Object.require(str)
        old_require(str)
      end

      # next 4 lines will revert Object to the way it was before
      # run_script
      diff_constants = Object.constants - initial_constants
      diff_constants.each do |constant|
        Object.send(:remove_const, constant)
      end
      result
    end


    # The input function, used with the tryruby_session test helper
    # see tryruby_session for more details
    def input(line, params = {})
      @backtrace_pos = 1
      params[:output] ||= ""
      params[:result] ||= nil
      params[:error] ||= nil
      
      result = do_test(line)
      begin
        if params[:error] then
          @test.assert_equal(:error, result.type, 
                              "Testing if line `#{line}` resulted in an error")
          do_assert(result.error, params[:error], "error", line)
        elsif params[:javascript] then
          do_assert(result.javascript, params[:javascript], "javascript", line)
          do_assert(result.output, params[:output], "output", line)
        elsif params[:line_continuation]
          @test.assert_equal(:line_continuation, result.type,
                              "Testing if line `#{line}' resulted in a line continuation")
          if params[:line_continuation] != true then
            @test.assert_equal(result.indent_level, params[:line_continuation],
                                "Testing if line `#{line}' triggered enough autoindent")
          end
        else
          @test.assert_nil(result.error,
                            "Testing line `#{line}' to ensure there was no error")
          do_assert(result.result, params[:result], "result" , line)
          do_assert(result.output, params[:output], "output", line)
        end
        
      rescue Test::Unit::AssertionFailedError => e
        
        new_bt = Test::Unit::Util::BacktraceFilter.filter_backtrace(e.backtrace)
        new_bt = new_bt[@backtrace_pos..@backtrace_pos]
        e.set_backtrace(new_bt)
        raise e
        
      end
    end
  end
end

# tests if the TryRubyOutput translation, for use with mouseapp_2.js and similar
# is working correctly
class TryRubyOutputTest < Test::Unit::TestCase
  def test_simple_result
    t = TryRubyOutput.standard(result: [12,24])
    assert_equal("=> \033[1;20m[12, 24]", t.format_output)
  end
  
  def test_result_and_output
    t = TryRubyOutput.standard(result: 333, output: "hello")
    assert_equal("hello\n=> \033[1;20m333", t.format_output)
  end

  def test_error
    begin
      40.reverse
    rescue Exception => e
      t = TryRubyOutput.error(error: e)
    end
    assert_equal("\033[1;33mNoMethodError: undefined method `reverse' for 40:Fixnum",
                 t.format_output)
  end

  def test_line_continuation
    t = TryRubyOutput.line_continuation(3)
    assert_equal(".." * 3, t.format_output)
  end

  def test_javascript
    t = TryRubyOutput.javascript(javascript: 'alert("hello")')
    # expected ends in a space to stop a visual problem in mouseapp
    assert_equal("\033[1;JSmalert(\"hello\")\033[m ", t.format_output)
  end

end
    

Test::Unit::UI::Console::TestRunner.run(TryRubyOutputTest)
Test::Unit::UI::Console::TestRunner.run(TryRubyTest)
