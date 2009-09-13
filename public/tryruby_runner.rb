class TryRubyBaseSession
  def reset
    self.start_time = Time.now
    self.current_statement = []
    self.nesting_level = 0
    self.past_commands = []
  end
end


class TryRubyTestSession < TryRubyBaseSession
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

alias :old_require :require

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

def debug_define_all
eval <<RUBY_EOF
  Object.send(:remove_const, :BlogEntry) if Object.constants.include? :BlogEntry
  class BlogEntry
    attr_accessor :title, :time, :fulltext, :mood
  end

  entry = BlogEntry.new
  entry.title = "Today Mt. Hood Was Stolen!"
  entry.time = Time.now
  entry.mood = :sick

  str = <<EOF
I can't believe Mt. Hood was stolen!
I am speechless! It was stolen by a giraffe who drove
away in his Cadillac Seville very nonchalant!!
EOF
  entry.fulltext = str.tr("\n", " ")
  
  class BlogEntry
    def initialize( title, mood, fulltext)
      @time = Time.now
      @title, @mood, @fulltext = title, mood, fulltext
    end
  end

  entry2 = BlogEntry.new("I Left my Hoodie on the Mountain!",
            :confused, "I am never going back to that mountain and I " + 
                       "hope a giraffe steals it." )

  blog = [entry, entry2]

  require 'popup'
  $blog_popup = Popup.make do
    h1 'My Blog'
    list do
      blog.each do |entry|
        h2 entry.title
        p entry.fulltext
      end
    end
  end

  nil

RUBY_EOF
end

    
class JavascriptResult
  attr_accessor :javascript
  def initialize(javascript)
    self.javascript = javascript
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

class TryRubyOutput
  attr_reader :type, :result, :output, :error, :indent_level, :javascript

  def self.standard(params)
    new_params = { type: :standard, result: params[:result],
      output: params[:output]}
    new_params[:output] ||= ""
    TryRubyOutput.new(new_params)
  end

  def self.javascript(params)
    new_params = { type: :javascript, javascript: params[:javascript],
      output: params[:output]}
    new_params[:output] ||= ""
    TryRubyOutput.new(new_params)
  end

  def self.no_output
    params = { type: :standard, result: nil, output: "" }
    TryRubyOutput.new(params)
  end

  def self.line_continuation(level)
    params = { type: :line_continuation, indent_level: level}
    TryRubyOutput.new(params)
  end

  def self.error(params = {})
    new_params = { type: :error, error: params[:error],
      output: params[:output]}
    new_params[:output] ||= ""
    TryRubyOutput.new(new_params)
  end

  def format_output
    if self.type == :line_continuation then
      return ".." * self.indent_level
    end
    return format_error if self.type == :error

    result = ""
    result += "#{self.output}\n" unless self.output.empty?

    if self.type == :javascript
      result += "\033[1;JSm#{self.javascript}\033[m"
    else
      result += "=> \033[1;20m#{self.result.inspect}"
    end
    result
  end

  def format_error
    e = @error
    msg = e.message.sub(/.*:in `initialize': /, "")
    error_s = "#{e.class}: #{msg}"
    
    errorOutput = "\033[1;33m#{error_s}"
    if output.empty? then
      result = errorOutput
    else
      result = output + "\n" + errorOutput
    end
    result
  end

  protected
  def initialize(values)
    values.each do |variable, value|
      instance_variable_set("@#{variable}", value)
    end
  end


  
end
 
$original_stdout = $stdout
 
def run_script(session, line)

  if line == "!INIT!IRB!" then
    session.reset
    return TryRubyOutput.no_output
  end
 
  if /^\s*reset\s*$/ === line then
    session.current_statement = []
    session.nesting_level = 0
    return TryRubyOutput.no_output
  end
 
  if unfinished_statement?(line) then
    session.current_statement << line
    session.nesting_level += 1
    return TryRubyOutput.line_continuation(session.nesting_level)
  end
 
 
  if finished_statement?(line) then
    session.nesting_level -= 1
    session.current_statement << line
    
    if session.nesting_level <= 0 then
      new_line = session.current_statement.join("\n")
      session.current_statement = []
      return run_line(session, new_line)
    else
      return TryRubyOutput.line_continuation(session.nesting_level)
    end
  end
  if session.nesting_level > 0 then
    session.current_statement << line
    return TryRubyOutput.line_continuation(session.nesting_level)
  end
  # finally ready to run a command
  run_line(session, line)
end

class FakeStdout
  attr_accessor :calls
  def initialize
    @calls = []
    @string = ""
  end
  def method_missing(method, *args)
    @calls << {method: method, args: args}
  end

  def write(str)
    @string += str
    
    method_missing(:write, strs)
  end

  def to_s
    return "" if @calls.empty?
    @string
    # @calls.join("\n")
  end
end
 
def run_line(session, line)
  begin
    # outputIO = StringIO.new
    previous_commands = session.past_commands.join("\n")
    $outputIO = nil

    include_cmd = session.current_includes.map do |inc|
      "old_require '#{inc}'"
    end.join("\n")
       
    eval_cmd = <<EOF
#{include_cmd}

$SAFE = 3
$outputIO = StringIO.new
outputIO = StringIO.new
#{$common_code}
$stdout = FakeStdout.new
#{previous_commands}
begin
  $stdout = FakeStdout.new
  result = instance_eval do
    #{line}
  end
  {:result => result, :output => $stdout.to_s}
  
rescue SecurityError => e
  TryRubyOutput.standard(result: "SECURITY ERROR: " + e.inspect + e.backtrace.inspect)
rescue Exception => e
  TryRubyOutput.error(error: e, output: outputIO.string)
end
EOF
    line_count = 0
    
    # res = eval_cmd.lines.map do |line| 
    #   line_count += 1
    #   line_count.to_s.ljust(4) + line
    # end.join
    # puts res
      
 
    # o = Object.new
    # thread = Thread.new { o.instance_eval(eval_cmd) }
    # result = thread.value
    eval_result = eval(eval_cmd)
    $stdout = $original_stdout
    return eval_result if eval_result.is_a?(TryRubyOutput) # exception occurred
    output = eval_result[:output]
    result = eval_result[:result]


    # result = eval(eval_cmd)
    session.past_commands << line
    if result.is_a?(JavascriptResult) then
      return TryRubyOutput.javascript(javascript: result.javascript, output: output)
    else
      return TryRubyOutput.standard(result: result, output: output)
    end

  end
  
end

 

