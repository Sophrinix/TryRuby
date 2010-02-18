#!/usr/bin/env ruby

require 'tryruby.rb'
#require 'cgi'
#equire 'cgi/session'
#require 'cgi/session/pstore'


class TryRubyCGISession < TryRubyBaseSession
  def initialize
    @session ||= {}

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