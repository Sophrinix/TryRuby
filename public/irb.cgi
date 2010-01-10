#!/usr/bin/env ruby

require 'tryruby.rb'
require 'cgi'
require 'cgi/session'
require 'cgi/session/pstore'

class TryRubyCGISession# < TryRuby::Session
  attr_accessor :cgi, :session
  
  def initialize
    @session = CGI::Session.new @cgi = CGI.new,
      'database_manager' => CGI::Session::PStore, # use PStore
      'session_key' => 'trb_sess_id', # custom $session key
      'session_expires' => Time.now + 60 * 60, # 60 minute timeout
      'prefix' => 'pstore_sid_', #Pstore option
      'tmpdir' => 'tmp' # Temp Directory for sessions
    
    
    @session['start_time'] ||= Time.now
    @session['current_statement'] ||= ''
    @session['past_commands'] ||= ''
  end
  
  def header
    @cgi.header 'text/plain'
  end
  
  [:current_statement, :past_commands, :start_time].each do |accessor|
    define_method(accessor) { @session[accessor.to_s] }
    define_method(:"#{accessor.to_s}=") { |new_val| @session[accessor.to_s] = new_val }
  end
end
  
TryRuby.session = TryRubyCGISession.new

print TryRuby.session.header + TryRuby.run_line(TryRuby.session.cgi['cmd']).format