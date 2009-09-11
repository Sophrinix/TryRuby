require 'pp'
require 'test/unit'
require 'tryruby_runner.rb'
require 'test/unit/ui/console/testrunner'
require 'stringio'

class TryRubyTest < Test::Unit::TestCase

  def tryruby_session(session = TryRubyTestSession.new, &block)
    input_o = Hash.new
    input_o[:session] = session
    input_o[:tests] = []
    def input_o.input(line, params = {})
      params[:output] ||= ""
      params[:result] ||= nil
      
      result = run_script(self[:session], line)
      self[:tests] << {:actual => result,
        :expected_result => params[:result],
        :expected_output => params[:output]}
      
    end
    input_o.instance_eval(&block)
    input_o[:tests].each do |test|
      assert_equal(test[:expected_result], test[:actual][:result])
      assert_equal(test[:expected_output], test[:actual][:output])
    end
    
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

  
  

  


    
end

Test::Unit::UI::Console::TestRunner.run(TryRubyTest)
