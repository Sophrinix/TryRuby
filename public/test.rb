require 'pp'
require 'test/unit'
require 'tryruby_runner.rb'
require 'test/unit/ui/console/testrunner'
require 'stringio'

class TryRubyTest < Test::Unit::TestCase

  def tryruby_session(session = TryRubyTestSession.new, &block)
    input_o = Hash.new
    input_o[:session] = session
    input_o[:test] = self
    def input_o.input(line, params = {})
      params[:output] ||= ""
      params[:result] ||= nil
      params[:error] ||= nil
      
      result = run_script(self[:session], line)

      begin
        tester = self[:test]
        if params[:error] then
          tester.assert_equal(:error, result.type, 
                              "Testing if line `#{line}` resulted in an error")
          tester.assert_equal(params[:error], result.error.class,
                              "Testing if line `#{line}` result in the right error")
          return
        end
        if params[:line_continuation]
          tester.assert_equal(:line_continuation, result.type,
                              "Testing if line `#{line}' resulted in a line continuation")
          return
        end
        tester.assert_equal(params[:result],
                            result.result,
                            "Testing line `#{line}' for correct result")

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
    end
  end
  
  

  


    
end

Test::Unit::UI::Console::TestRunner.run(TryRubyTest)
