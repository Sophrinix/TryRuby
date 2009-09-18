#!/usr/bin/env ruby

# yes i put ruby1.9 instead of ruby because of debian, i know
#i need to fix that, i'll do it later
 
#require "sandbox" 
require 'cgi'
require 'popup.rb'
require 'stringio'
require 'cgi/session'
require 'cgi/session/pstore' # provides CGI::Session::PStore
require 'tryruby_runner.rb'
 
class TryRubyCGISession < TryRubyBaseSession
  def initialize
    @session = CGI::Session.new(@cgi = CGI.new,
                                    'database_manager' => CGI::Session::PStore, # use PStore
                                    'session_key' => '_rb_sess_id', # custom $session key
                                    'session_expires' => Time.now + 60 * 60, # 30 minute timeout
                                    'prefix' => 'pstore_sid_', #Pstore option
                                    'tmpdir' => 'tmp'       # Temp Directory for sessions
    )
    
 
    @session['current_statement'] ||= []
    @session['nesting_level'] ||= 0
    @session['nesting_level'] = 0 if @session['nesting_level'] < 0
    @session['start_time'] ||= Time.now
    
    @session['past_commands'] ||= []
    
    @session['current_includes'] ||= []
    print cgi.header('text/plain')
  end

  def self.make_session_accessor(name)
    define_method(name.to_sym) do
      @session[name]
    end

    define_method("#{name}=".to_sym) do |new_val|
      @session[name] = new_val
    end
  end

  make_session_accessor 'current_statement'
  make_session_accessor 'past_commands'
  make_session_accessor 'nesting_level'
  make_session_accessor 'start_time'
  make_session_accessor 'current_includes'

  attr_accessor :cgi, :session

end
  
$session = TryRubyCGISession.new 

 
 
# $session.current_includes.each do |inc|
#   require inc
# end
 
print run_script($session, $session.cgi['cmd']).format_output
# puts script_results[:output] unless script_results[:output].empty?
