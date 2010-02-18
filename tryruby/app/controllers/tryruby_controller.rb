class TryrubyController < ApplicationController
  layout 'tryruby'
  
  def run
    render :text => run_script(params[:cmd])
  end
  
  private 
  
  def run_script(command)
    output =  begin
                eval(command)
              rescue StandardError => e
                e.message
              end

    return "=> #{output}"
  end
end
