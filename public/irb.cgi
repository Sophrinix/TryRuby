#!/usr/bin/env ruby


require 'cgi'
require 'stringio'
require 'cgi/session'
require 'cgi/session/pstore'     # provides CGI::Session::PStore

##Good Catch Ruby Community
# This is a psa Go Here to find out what this means:
# http://www.rubycentral.com/pickaxe/taint.html
$SAFE = 4
cgi = CGI.new("html5")


# Init the sessions, plus initialize the $session variables
# if necessary
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

# customized Dir to get one of the tutorial steps working
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

# customized File to get one of the tutorial steps working
class File
  def self.read(path)
    case path
    when "/comics.txt" then "Achewood fighting! action!"
    end
  end
end
    

# Used for when a function needs to return a javascript script.
# See popup.rb for an example of it being used.
class JavascriptResult
  attr_accessor :js
  def initialize(js)
    self.js = js
  end
end


# matches against def x, class x and test.asdf do |dfdf| style statements
# Not that robust
def unfinished_statement?(line)
  line.match(/^\s*((def)|(class))/) || line.match(/.* do *\|.*\| *$/)

end

# matches against end, to finish a statement (or reduce the
# indent_level by one
def finished_statement?(line)
  line == "end"
end

# This code is used to initialize any predefined variables used
# by the tutorials
$common_code = <<EOF

poem = "My toast has flown from my hand\nAnd my toast has gone to the
moon.\nBut when I saw it on television,\nPlanting our flag on Halley's
comet,\nMore still did I want to eat it.\n"

EOF

# backup the original $stdout
$original_stdout = $stdout

# Accepts line (which is the line passed by GET cmd), and
# returns the output for that line.
def run_script(line)


  # unfinished statement (eg def myfunc). 
  if unfinished_statement?(line) then
    $session['current_statement'] << line
    $session['nesting_level'] += 1
    return ".."
  end


  # finishing statement (eg "end")
  if finished_statement?(line) then
    $session['nesting_level'] -= 1
    $session['current_statement'] << line
    
    # indent is now zero, run all code stored in
    # current_statement
    if $session['nesting_level'] <= 0 then
      new_line = $session['current_statement'].join("\n")
      $session['current_statement'] = []
      return run_line(new_line)
    else
      return ".."
    end
  end
  # normal statement, but indent is not zero
  if $session['nesting_level'] > 0 then
    $session['current_statement'] << line
    return ".."
  end
  # normal statement with 0 indent (ready to run code)
  run_line(line)
end

# Runs the line (using eval). Will run all past_commands first.
def run_line(line)
  line_caused_error = false
  begin
    previous_commands = $session['past_commands'].join("\n")

    stdout_captured = StringIO.new()
       
    # This script will
    # firstly runs the $common_code. Then it disables stdout 
    # and runs all previous commands.
    # Finally it will redirect all stdout to stdout_captured
    # and runs line
		# For temporary security-reasons, undefine unsafe methods on Kernel - which should prevent all 
		# calls to them - regardless of how it's passed to the script!
    eval_cmd = <<EOF

		module Kernel
			UNSAFE_METHODS = ["system", "exit", "abort", "exit!", "`", "eval", "exec", "syscall"]
			
			UNSAFE_METHODS.each do |m_name|
				undef_method m_name
			end
			
			def system(cmd)
				return "Kernel.system is not allowed for security-reasons."
			end
			
			def self.system(cmd)
				return "Kernel.system is not allowed for security-reasons!"		
			end
			
			def method_missing(method_name, *args, &block)
				if UNSAFE_METHODS.include?(method_name.to_s)
					return "Calls to unsafe methods in Kernel is disabled."
				else
					super
				end
			end
			
		end
		
		
#{$common_code}
$stdout = StringIO.new() #disable stdout
	#{previous_commands}
$stdout = stdout_captured

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
    puts "here#{e.inspect}"
    line_caused_error = true
    # format the message so that it maches what is expected
    # in the help files
    msg = e.message.sub(/.*:in `initialize': /, "")
    error_s = "#{e.class}: #{msg}"
    result = "\033[1;33m#{error_s}"

  ensure
    # make sure we can print again
    $stdout = $original_stdout
    print stdout_captured.string
    print "\n" unless stdout_captured.string.empty?

    
  end
  unless line == "!INIT!IRB!" or line_caused_error
    $session['past_commands'] << line
  end
  return result
end


print run_script(cgi['cmd'])


  
