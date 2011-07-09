
require 'stringio'
#require '../lib/popup.rb'
#require '../lib/setup.rb'

class TryrubyController < ApplicationController
 
  layout 'tryruby'
  def index
  end

  def run
    cmd = params[:cmd]
 result = Thread.new { eval cmd  }.value
  
    #@cmd=params[:cmd]
   # @a= run_script(@cmd)
   # @b = "handleJSON({\"type\": #{@a.type.to_json}, \"output\":#{@a.output.to_json},\"result\":#{@a.result.inspect.to_json}, \"error\": #{@a.error.inspect.to_json}})"

begin
  render :json => result 
   rescue
   end
  end
    

  def run_script(command)
    #output =  begin
           #     eval(command)
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
private
module Tryrubyengine
SetupCode = <<SETUP_EOF

# create the basic filesystem
FakeFS::FileSystem.clear

["Home", "Libraries", "MouseHole", "Programs", "Tutorials"].each {|dir| Dir.mkdir dir }

comic_txt_text = <<-COMIC_EOF
Achewood: http://achewood.com/
Dinosaur Comics: http://qwantz.com/
Perry Bible Fellowship: http://cheston.com/pbf/archive.html
Get Your War On: http://mnftiu.cc/
COMIC_EOF

flickrpedia_user_rb_text = <<-FLICK_EOF
MouseHole.script do                                                   
  name 'FlickrPedia'                                                  
  namespace 'mail@robertbrook.com'                                    
  description "Inserts Wikipedia links for Flickr tags"               
  version '0.1'                                                       
                                                                      
  include_match %r{^HTTP://www.flickr.com/photos/.*?$}                
                                                                      
  rewrite do |req, res|                                               
    document.elements.each('//a[@class="globe"]') do |link|           
      href = link.attributes['href']                                  
      clipped = href[13 ..-11] # who needs regex?                     
      span = REXML::Element.new 'a'                                   
      span.attributes['class'] = 'Grey'                               
      span.attributes['href'] = 'HTTP://www.wikipedia.org/wiki/' + clipp
ed                                                                    
      span.text = 'W ' # this is pretty crappy...                     
      link.parent.insert_after link, span                             
    end                                                               
  end                                                                 
end  
FLICK_EOF

popup_rb_text = <<-POPUP_EOF
module Popup
  # ...
end
POPUP_EOF

File.open('/comics.txt', "w") {|f| f.write(comic_txt_text) }
File.open('/MouseHole/flickrpedia.user.rb', "w") {|f| f.write(flickrpedia_user_rb_text) }
File.open('/Libraries/popup.rb', "w") {|f| f.write(popup_rb_text) }


# require
module Kernel
  def require(path)
    result = true
    case path
    when 'popup'
      include LoadPopup
      extend LoadPopup
      true
    else
      result = false
    end
    result
  end
end

SETUP_EOF
end
end
