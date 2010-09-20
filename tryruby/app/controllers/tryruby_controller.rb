require './lib/tryruby'
class TryrubyController < ApplicationController
  layout 'tryruby'
  attr_accessor :past_commands, :current_statement, :start_time
  
  def run
    render :text => run_script(params[:cmd])
  end
  
  private 
  
  def run_script(command)
   # output =  begin
    #            eval(command)
     #         rescue StandardError => e
      #          e.message + ". On the "
       
        TryRuby.run_line(command).format
   #           end

  #  return "=> #{output}" + ", says yoda"
  end
end
