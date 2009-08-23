#!/usr/bin/env ruby


require 'cgi'
require 'stringio'
require 'cgi/session'
require 'cgi/session/pstore'     # provides CGI::Session::PStore
cgi = CGI.new("html5")


$session = CGI::Session.new(cgi,
    'database_manager' => CGI::Session::PStore,  # use PStore
    'session_key' => '_rb_sess_id',              # custom $session key
    'session_expires' => Time.now + 60 * 60,     # 30 minute timeout
    'prefix' => 'pstore_sid_')                   # PStore option

$session['current_statement'] ||= []
$session['nesting_level'] ||= 0
$session['nesting_level'] = 0 if $session['nesting_level'] < 0

$session['past_commands'] ||= []


print cgi.header

Dir = Class.new

class Dir
  def self.entries(path)
    case path
    when "/" then [".", "comics.txt"]
    end
  end
  def self.[](path)
    case path
    when "/*.txt" then ["comics.txt"]
    end
  end
    
end

class File
  def self.read(path)
    case path
    when "/comics.txt" then "Achewood fighting! action!"
    end
  end
end
    

class JavascriptResult
  attr_accessor :js
  def initialize(js)
    self.js = js
  end
end


def unfinished_statement?(line)
  line.match(/^\s*((def)|(class))/) || line.match(/.* do *\|.*\| *$/)

end

def finished_statement?(line)
  line == "end"
end

$common_code = <<EOF

poem = "My toast has flown from my hand\nAnd my toast has gone to the
moon.\nBut when I saw it on television,\nPlanting our flag on Halley's
comet,\nMore still did I want to eat it.\n"

EOF

$original_stdout = $stdout

def run_script(line)
  #puts "SESSION FOR LINE #{line}"
  $session
  #puts "########################\n\n"


  line_caused_error = false
  if unfinished_statement?(line) then
    $session['current_statement'] << line
    $session['nesting_level'] += 1
    return ".."
  end


  if finished_statement?(line) then
    $session['nesting_level'] -= 1
    $session['current_statement'] << line
    
    if $session['nesting_level'] <= 0 then
      new_line = $session['current_statement'].join("\n")
      $session['current_statement'] = []
      return run_line(new_line)
    else
      return ".."
    end
  end
  if $session['nesting_level'] > 0 then
    $session['current_statement'] << line
    return ".."
  end
  # finally ready to run a command
  run_line(line)
end

def run_line(line)
  #p $session
  begin
    previous_commands = $session['past_commands'].map do |cmd|
      cmd
      #"begin\n#{cmd}\nrescue Exception\nend"
    end.join("\n")
       
    eval_cmd = <<EOF
#{$common_code}
$stdout = StringIO.new("w")
#{previous_commands}
$stdout = $original_stdout
#{line}
EOF
    #puts eval_cmd

    output = eval(eval_cmd)
    if output.instance_of? JavascriptResult
      result = "\033[1;JSm#{output.js}\033[m"
    else
      result = "=> " + "\033[1;20m" + output.inspect
    end
  rescue Exception => e
    line_caused_error = true
    msg = e.message.sub(/.*:in `initialize': /, "")
    p msg
    error_s = "#{e.class}: #{msg}"
    result = "\033[1;33m#{error_s}"
    
  end
  unless line == "!INIT!IRB!" or line_caused_error
    $session['past_commands'] << line
  end
  return result
end



print run_script(cgi['cmd'])


  
