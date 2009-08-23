#!/usr/bin/env ruby

require 'cgi'
require 'cgi/session'
require 'cgi/session/pstore'
cgi = CGI.new("html4")

sess = CGI::Session.new( cgi, "session_key" => "a_test",
                              "prefix" => "rubysess.")
lastaccess = sess["lastaccess"].to_s
sess["lastaccess"] = Time.now
if cgi['bgcolor'][0] =~ /[a-z]/
  sess["bgcolor"] = cgi['bgcolor']
end

cgi.out{
  cgi.html {
    cgi.body ("bgcolor" => sess["bgcolor"]){
      "The background of this page"    +
      "changes based on the 'bgcolor'" +
      "each user has in session."      +
      "Last access time: #{lastaccess}"
    }
  }
}
