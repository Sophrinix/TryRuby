require 'ruby_parser'

class TryRubyBaseSession
  def reset
    self.start_time = Time.now
    self.current_statement = []
    self.nesting_level = 0
    self.past_commands = []
  end

  def calculate_nesting_level(statement)
    begin
      RubyParser.new.parse(statement)
      0
    rescue Racc::ParseError => e
      case e.message
      when /parse error on value \"\$end\" \(\$end\)/ then
        new_statement = statement + "\n end"
        begin
          RubyParser.new.parse(new_statement)
          return 1
        rescue Racc::ParseError => e
          if e.message =~ /parse error on value \"end\" \(kEND\)/ then
            new_statement = statement + "\n }"
          end
        end
        1 + calculate_nesting_level(new_statement)
      else
        raise e
      end
    end
  end
  
  def <<(line)
    if line == "!INIT!IRB!" then
      self.reset
      return TryRubyOutput.no_output
    end
    
    if line =~ /^\s*reset\s*$/ then
      self.current_statement = []
      self.nesting_level = 0
      return TryRubyOutput.no_output
    end
    
    if line =~ /^\s*time\s*$/
      seconds = (Time.now - $session.start_time).ceil
      if seconds < 60; time = "#{seconds} seconds"
      else; time = "#{seconds / 60} minutes"
      end # if
      return TryRubyOutput.standard({result: time})
    end

    self.current_statement << line
    begin
      self.nesting_level = calculate_nesting_level(current_statement.join("\n"))
    rescue Exception => e
      #syntax error.
      begin
        eval(line)
      rescue Exception => e
        self << 'reset' #run this method to calm down the interpreter kind of.
        return TryRubyOutput.error(error: e)
      end
    end

    run_session
    

  end

  # This method is executed after a line is added to this Session. If indent_level is not 0,
  # then a line continuation will be returned. Otherwise the command in self.current_statement
  # will be run, cleared and the result returned.
  def run_session
    return TryRubyOutput.line_continuation(nesting_level) if nesting_level > 0

    
    line = current_statement.join("\n")
    
    include_cmd = self.current_includes.map do |inc|
      File.read("#{inc}.rb")
      # "old_require '#{inc}'"
    end.join("\n")

    
    eval_cmd = <<EOF
#{include_cmd}
 
#{$common_code}
$SAFE = 3
$stdout = FakeStdout.new
#{past_commands.join("\n")}
begin
$stdout = FakeStdout.new
result = #{line}
{:result => result, :output => $stdout.to_s}
rescue SecurityError => e
TryRubyOutput.illegal
rescue Exception => e
TryRubyOutput.error(error: e, output: $stdout.to_s)
end
EOF

    
    # puts eval_cmd
    # thread = Thread.new { o.instance_eval(eval_cmd) }
    # result = thread.value
    eval_result = eval(eval_cmd, TOPLEVEL_BINDING)
    self.current_statement = []
    $stdout = $original_stdout
    return eval_result if eval_result.is_a?(TryRubyOutput) # exception occurred
    output = eval_result[:output]
    result = eval_result[:result]
    
    
    
    # result = eval(eval_cmd)
    self.past_commands << line
    if result.is_a?(JavascriptResult) then
      return TryRubyOutput.javascript(javascript: result.javascript, output: output)
    else
      return TryRubyOutput.standard(result: result, output: output)
    end
  end




    
end
 
alias :old_require :require
 
def special_require(require_path)
  path = require_path.sub(/\.rb$/, "")
  return false unless ['popup'].include? path
  return false if $session.current_includes.include? path
  $session.current_includes << path
  true
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

class Regexp
  def +(regex)
    return false if regex.class != Regexp
    Regexp.new(self.source + regex.source)
  end
end

 
$common_code = <<EOF
poem = <<POEM_EOF
My toast has flown from my hand
And my toast has gone to the
moon.
But when I saw it on television,
Planting our flag on Halley's
comet,
More still did I want to eat it.
POEM_EOF
 
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

  def self.illegal
    new_params = { type: :illegal }
    TryRubyOutput.new(new_params)
  end
 
  def self.javascript(params)
    new_params = { type: :javascript, javascript: params[:javascript],
      output: params[:output]}
    new_params[:output] ||= ""
    TryRubyOutput.new(new_params)
  end
 
  def self.no_output
    params = { type: :no_output, result: nil, output: "" }
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
    return "\033[1;33mYou aren't allowed to run that command!" if self.type == :illegal
    
    result = ""
    result += "#{self.output}\n" unless self.output.empty?
 

    if self.type == :javascript then
      result += "\033[1;JSm#{self.javascript}\033[m "
    else
      result += "=> \033[1;20m#{self.result.inspect}" unless self.type == :no_output
    end
    result
  end
 
  def format_error
    e = @error
    msg = e.message.sub(/.*:in `initialize': /, "")
    error_s = "#{e.class}: #{msg}"
    
    error_output = "\033[1;33m#{error_s}"
    if output.empty? then
      result = error_output
    else
      result = output + "\n" + error_output
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
  session << line

 
end #run_script
 
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