
class TryrubyController < ApplicationController
 
  layout 'tryruby'
  def index
  end

  def run
  eval(params[:cmd])
 
    #@cmd=params[:cmd]
   # @a= run_script(@cmd)
   # @b = "handleJSON({\"type\": #{@a.type.to_json}, \"output\":#{@a.output.to_json},\"result\":#{@a.result.inspect.to_json}, \"error\": #{@a.error.inspect.to_json}})"

begin
  render :json => @b 
   rescue
   end
  end
    

  def run_script(command)
    #output =  begin
                eval(command)
     #         rescue StandardError => e
      #          e.message + ". On the "
     begin
    #   Tryrubyengine.session ||= TRSession.new
       #TryRuby.run_line(TryRuby.session.cgi['cmd']).format
       #Tryrubyengine.new
     #  @c= Tryrubyengine.session
      # @c.inspect
       # Tryrubyengine.run_line(command)
      rescue
         
      end
   #           end

  #  return "=> #{output}" + ", says yoda"
  end

end
