# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.
require './lib/tryruby'

class ApplicationController < ActionController::Base
#  attr_accessor :past_commands, :current_statement, :start_time
=begin  
   #attr_accessor :session
  TryRuby.session = session
     
    TryRuby.session['start_time'] ||= Time.now
    TryRuby.session['current_statement'] ||= ''
    TryRuby.session['past_commands'] ||= ''
    
  helper :all # include all helpers, all the time
  protect_from_forgery # See ActionController::RequestForgeryProtection for details

  # Scrub sensitive parameters from your log
  # filter_parameter_logging :password
  #class << self
=end
# not needed
  #end
end
