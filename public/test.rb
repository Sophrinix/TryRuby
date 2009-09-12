require 'pp'
require 'test/unit'
require 'test/unit/ui/console/testrunner'
require 'stringio'

load 'tryruby_runner.rb'

$session = nil

class TryRubyTest < Test::Unit::TestCase

  def tryruby_session(session = TryRubyTestSession.new, &block)
    input_o = Hash.new
    input_o[:session] = session
    input_o[:test] = self
    def input_o.input(line, params = {})
      params[:output] ||= ""
      params[:result] ||= nil
      params[:error] ||= nil
      
      o = Object.new
      session = self[:session]
      # store the initial constants of Object
      initial_constants = Object.constants
      result = o.instance_eval do
        run_script(session, line)
      end

      # next 4 lines will revert Object to the way it was before
      # run_script
      diff_constants = Object.constants - initial_constants
      diff_constants.each do |constant|
        Object.send(:remove_const, constant)
      end


      begin
        tester = self[:test]
        if params[:error] then
          tester.assert_equal(:error, result.type, 
                              "Testing if line `#{line}` resulted in an error")
          tester.assert_equal(params[:error], result.error.class,
                              "Testing if line `#{line}` result in the right error")
          return
        end
        if params[:js]
          tester.assert_equal(params[:js], result.js,
                              "Testing if line `#{line}' results in the correct javascript")
          return
        end
        if params[:line_continuation]
          tester.assert_equal(:line_continuation, result.type,
                              "Testing if line `#{line}' resulted in a line continuation")
          if params[:line_continuation] != true then
            tester.assert_equal(result.indent_level, params[:line_continuation],
                                "Testing if line `#{line}' triggered enough autoindent")
          end
          return
        end
        tester.assert_nil(result.error,
                          "Testing line `#{line}' to ensure there was no error")
        if params[:result].instance_of?(Proc) then
          tester.assert(params[:result].call(result.result),
                        "Testing line `#{line}': #{params[:message]}")
        else
          tester.assert_equal(params[:result],
                              result.result,
                              "Testing line `#{line}' for correct result")
        end

        tester.assert_equal(params[:output],
                            result.output,
                            "Testing line `#{line}' for correct output")
      rescue Test::Unit::AssertionFailedError => e
        new_bt = Test::Unit::Util::BacktraceFilter.filter_backtrace(e.backtrace)[1..1]
        e.set_backtrace(new_bt)
        raise e
        
      end


    end
    input_o.instance_eval(&block)
    
  end

  def test_lesson1
    tryruby_session do
      input '2 + 6', :result => 8
      input '"Jimmy"', :result => "Jimmy"
      input '"Jimmy".reverse', :result => "ymmiJ"
      input '"Jimmy".length', :result => 5
      input '"Jimmy" * 5', :result => "JimmyJimmyJimmyJimmyJimmy"
    end
  end

  def test_lesson2
    tryruby_session do
      input '40.reverse', :error => NoMethodError
      input '40.to_s.reverse', result: "04"
      input '[]', result: []
      input '[12,47,35]', result: [12,47,35]
      input '[12,47,35].max', result: 47
      input 'ticket = [12,47,35]', result: [12,47,35]
      input 'ticket', result: [12,47,35]
      input 'ticket.sort!', result: [12,35,47]
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
      input 'print poem', output: poem
      input "poem['toast'] = 'honeydew'", result: "honeydew"
      input 'print poem', output: (poem['toast'] = 'honeydew'; poem)
      input 'poem.reverse', result: poem.reverse
      input 'poem.lines.to_a.reverse', result: poem.lines.to_a.reverse
      input 'print poem.lines.to_a.reverse.join', output: poem.lines.to_a.reverse.join
      end
  end

  def test_lesson4
    tryruby_session do
      input 'books = {}', result: {}
      input 'books["Gravity\'s Rainbow"] = :splendid', result: :splendid
      input 'books["a"] = :mediocre', result: :mediocre
      input 'books["b"] = :mediocre', result: :mediocre
      input 'books["c"] = :mediocre', result: :mediocre
      input 'books.length', result: 4
      input 'books["Gravity\'s Rainbow"]', result: :splendid
      input 'books.keys', result: ["Gravity's Rainbow", "a", "b", "c"]
      input 'ratings = Hash.new {0}', result: {}
      input 'books.values.each { |rate| ratings[rate] += 1 }',
            result: [:splendid, :mediocre, :mediocre, :mediocre]  
      input '5.times {print "Odelay!" }', result: 5, output: 'Odelay!Odelay!Odelay!Odelay!Odelay!'
      
    end
  end

    

  def test_lesson6
    $session = TryRubyTestSession.new
    tryruby_session $session do
      input 'Hash.new', result: {}
      input 'class BlogEntry', line_continuation: 1
      input 'attr_accessor :title, :time, :fulltext, :mood', line_continuation: 1
      input 'end', result: nil
      input 'entry = BlogEntry.new', result: Proc.new {|v| v.class.name == "BlogEntry"},
             message: "result should be a class named BlogEntry"
      input 'entry.title = "Today Mt. Hood Was Stolen!"', result: "Today Mt. Hood Was Stolen!"
      input 'entry.time = Time.now', result: Proc.new {|v| v.class == Time },
             message: "result should be a Time object"
      input 'entry.mood = :sick', result: :sick
      input ('entry.fulltext = "I can\'t believe Mt. Hood was stolen! ' +
            'I am speechless! It was stolen by a giraffe who drove ' +
            'away in his Cadillac Seville very nonchalant!!"'),
            result: ("I can't believe Mt. Hood was stolen! " +
                     "I am speechless! It was stolen by a giraffe who " + 
                     "drove away in his Cadillac Seville very nonchalant!!")
      input 'entry', result: Proc.new {|v|
        v.mood == :sick and v.time.instance_of?(Time) and v.fulltext[0..5] = "I am "
      }, message: "result should be a correctly created BlogEntry"

      input 'class BlogEntry', line_continuation: 1
      input 'def initialize( title, mood, fulltext )', line_continuation: 2
      input '@time = Time.now', line_continuation: 2
      input '@title, @mood, @fulltext = title, mood, fulltext', line_continuation: 2
      input 'end', line_continuation: 1
      input 'end', result: nil
      
      input 'BlogEntry.new', error: ArgumentError



      input ('entry2 = BlogEntry.new("I Left my Hoodie on the Mountain!", ' + 
            ':confused, "I am never going back to that mountain and I ' + 
        'hope a giraffe steals it." )'),
        result: Proc.new {|v| v.class.name == "BlogEntry" },
        message: "Result should be a BlogEntry"

      # lesson 7 starts here (depends on lesson 6 to complete)
      input 'blog = [entry, entry2]', result: Proc.new { |v|
        v.is_a?(Array) and v.all? {|e| e.class.name == "BlogEntry" }
      }, message: "All elements of result should be a BlogEntry"


      input 'blog.map { |entry| entry.mood }', result: [:sick, :confused]
      input 'require "popup"', result: Proc.new {true} # don't care
      input 'Popup.make do', line_continuation: 1
      input "h1 'My Blog'", line_continuation: 1
      input "list do", line_continuation: 2
      input 'blog.each do |entry|', line_continuation: 3
      input 'h2 entry.title', line_continuation: 3
      input 'p entry.fulltext', line_continuation: 3
      input 'end', line_continuation: 2
      input 'end', line_continuation: 1
      input 'end', javascript: ""
      
        
    end
  end

    
  
  

  


    
end

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

end
    

Test::Unit::UI::Console::TestRunner.run(TryRubyOutputTest)
Test::Unit::UI::Console::TestRunner.run(TryRubyTest)
