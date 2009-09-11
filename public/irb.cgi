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
cgi = CGI.new("html5")
 
  
 
$session = CGI::Session.new(cgi,
    'database_manager' => CGI::Session::PStore, # use PStore
    'session_key' => '_rb_sess_id', # custom $session key
    'session_expires' => Time.now + 60 * 60, # 30 minute timeout
    'prefix' => 'pstore_sid_') # PStore option
 
$session['current_statement'] ||= []
$session['nesting_level'] ||= 0
$session['nesting_level'] = 0 if $session['nesting_level'] < 0
$session['start_time'] ||= Time.now
 
$session['past_commands'] ||= []
 
$session['current_includes'] ||= []
 
print cgi.header
 
$session['current_includes'].each do |inc|
  require inc
end
 
script_results = run_script($session, cgi['cmd'])
puts script_results[:output] unless script_results[:output].empty?
puts format_result(script_results[:result])
