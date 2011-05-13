class TryrubyController < ApplicationController
  layout 'tryruby'
  
  def run
    @cmd=params[:cmd]
  
 @a= run_script(@cmd)
@b = "handleJSON({\"type\": #{@a.type.to_json}, \"output\":#{@a.output.to_json},\"result\":#{@a.result.inspect.to_json}, \"error\": #{@a.error.inspect.to_json}})"
 
 render :json => @b
   end
  
  private 
  
  def run_script(command)
   # output =  begin
    #            eval(command)
     #         rescue StandardError => e
      #          e.message + ". On the "
       
        TryRuby.run_line(command)
   #           end

  #  return "=> #{output}" + ", says yoda"
  end
end
