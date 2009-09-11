class TryRubyTestSession
  def initialize()
    @current_statement = []
    @nesting_level = 0
    @start_time = Time.now
    @past_commands = []
    @current_includes = []
  end

  attr_accessor :start_time, :current_statement
  attr_accessor :nesting_level, :past_commands, :current_includes

end

    
  
  
  



def special_require(require_path)
  path = require_path.sub(/\.rb$/, "")
  return false unless ['popup'].include? path
  return false if $session.current_includes.include? path
  $session.current_includes << path
  true
end
  
def time
  seconds = (Time.now - $session.start_time).ceil
  return "#{seconds} seconds" if seconds < 60 
  return "#{seconds / 60} minutes" if seconds > 60
    
end
    
    
 
class JavascriptResult
  attr_accessor :js
  def initialize(js)
    self.js = js
  end
end
 
 
def unfinished_statement?(line)
  [/^\s*((def)|(class))/,
   /.* do *\|.*\| *$/,
   /((do)|(\{))\s*$/].any? {|regexp| line.match(regexp) }
end
 
def finished_statement?(line)
  [/^\s*end\s*$/,
   /^\s*}\s*$/].any? {|regexp| line.match(regexp)};
end
 
$common_code = <<EOF
poem = "My toast has flown from my hand\nAnd my toast has gone to the
moon.\nBut when I saw it on television,\nPlanting our flag on Halley's
comet,\nMore still did I want to eat it.\n"

def require(str)
  special_require(str)
end

EOF
 
$original_stdout = $stdout
 
def run_script(session, line)

  if line == "!INIT!IRB!" then
    session.start_time = Time.now
    session.current_statement = []
    session.nesting_level = 0
    session.past_commands = []
    return " "
  end
 
  if /^\s*reset\s*$/ === line then
    session.current_statement = []
    session.nesting_level = 0
    return " "
  end
 
  line_caused_error = false
  if unfinished_statement?(line) then
    session.current_statement << line
    session.nesting_level += 1
    return ".." * session.nesting_level
  end
 
 
  if finished_statement?(line) then
    session.nesting_level -= 1
    session.current_statement << line
    
    if session.nesting_level <= 0 then
      new_line = session.current_statement.join("\n")
      session.current_statement = []
      return run_line(session, new_line)
    else
      return ".." * session.nesting_level
    end
  end
  if session.nesting_level > 0 then
    session.current_statement << line
    return ".." * session.nesting_level
  end
  # finally ready to run a command
  run_line(session, line)
end
 
def run_line(session, line)
#Sandbox.new()  
  
#p session
  begin
    outputIO = StringIO.new
    previous_commands = session.past_commands.map do |cmd|
      cmd
      #"begin\n#{cmd}\nrescue Exception\nend"
    end.join("\n")
       
    eval_cmd = <<EOF
# $SAFE = 3
# an idea to try ##line == "require 'popup.rb' " ? $SAFE = 0 : $SAFE = 3 
#{$common_code}
$stdout = StringIO.new()
#{previous_commands}
$stdout = outputIO

#{line}
EOF
    #puts eval_cmd
 
    result = eval(eval_cmd)
    $stdout = $original_stdout

  rescue Exception => e
    $stdout = $original_stdout
    line_caused_error = true
    msg = e.message.sub(/.*:in `initialize': /, "")
    p msg
    error_s = "#{e.class}: #{msg}"
    result = "\033[1;33m#{error_s}"
    
  end
  unless line == "!INIT!IRB!" or line_caused_error
    session.past_commands << line
  end
  {:output => outputIO.string, :result => result}
end
 
def format_result(str)
  if str.instance_of? JavascriptResult
    result = "\033[1;JSm#{str.js}\033[m"
  else
    result = "=> " + "\033[1;20m" + str.inspect
  end
end
 
