require 'ruby_parser'
require 'fakefs/safe'

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
        begin
          1 + calculate_nesting_level(new_statement)
        rescue Racc::ParseError => e
          return 1
        end
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
      seconds = (Time.now - self.start_time).ceil
      if seconds < 60; time = "#{seconds} seconds"
      else; time = "#{seconds / 60} minutes"
      end # if
      return TryRubyOutput.standard(result: time)
    end

    self.current_statement << line
    begin
      self.nesting_level = calculate_nesting_level(current_statement.join("\n"))
    rescue Exception => e
      # syntax error.
      begin
        #RubyParser.new.parse(line)
        eval(line)
      rescue Exception => e
        self << 'reset'
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

    return TryRubyOutput.no_output if RubyParser.new.parse(line) == nil
    
    include_cmd = self.current_includes.map do |inc|
      File.read("#{inc}.rb")
    end.join("\n")


    original_stdout = $stdout
    eval_cmd = <<EOF
#{include_cmd}

poem = <<POEM_EOF
My toast has flown from my hand
And my toast has gone to the
moon.
But when I saw it on television,
Planting our flag on Halley's
comet,
More still did I want to eat it.
POEM_EOF
def require(require_path)
  result = false
  Thread.new do
    #require_path.untaint
    path = require_path.sub(/\.rb$/, "")
    if ['popup'].include?(path) and !$session.current_includes.include?(path)
      $session.current_includes << path
      result = true
    end
  end.join
  result
end

FakeFS.activate!
FakeFS::FileSystem.clear
#{self.past_commands.join("\n")}
# $SAFE = 3
$stdout = FakeStdout.new
begin
$stdout = FakeStdout.new
{result:(
#{line}
), output: $stdout.to_s}
rescue SecurityError => e
TryRubyOutput.illegal
rescue Exception => e
TryRubyOutput.error(error: e, output: $stdout.to_s)
end
EOF

    eval_result = eval(eval_cmd, TOPLEVEL_BINDING)
    self.current_statement = []
    $stdout = original_stdout
    return eval_result if eval_result.is_a?(TryRubyOutput) # exception occurred
    output = eval_result[:output]
    result = eval_result[:result]
    
    self.past_commands << line
    if result.is_a? JavascriptResult
      return TryRubyOutput.javascript(javascript: result.javascript, output: output)
    else
      return TryRubyOutput.standard(result: result, output: output)
    end
  end

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
 
class TryRubyOutput
  attr_reader :type, :result, :output, :error, :indent_level, :javascript
 
  def self.standard(params)
    params = { type: :standard, result: params[:result],
      output: params[:output]}
    params[:output] ||= ""
    TryRubyOutput.new(params)
  end

  def self.illegal
    params = { type: :illegal }
    TryRubyOutput.new(params)
  end
 
  def self.javascript(params)
    params = { type: :javascript, javascript: params[:javascript],
      output: params[:output]}
    params[:output] ||= ""
    TryRubyOutput.new(params)
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
    params = { type: :error, error: params[:error],
      output: params[:output]}
    params[:output] ||= ""
    TryRubyOutput.new(params)
  end
 

  def format_output
    case self.type
    when :line_continuation
      ".." * self.indent_level
    when :error
      format_error
    when :illegal
      "\033[1;33mYou aren't allowed to run that command!" if self.type == :illegal
    when :no_output
      ''
    else
      result = ''
      result += "#{self.output}" unless self.output.empty?
      if self.type == :javascript; result += "\033[1;JSm#{self.javascript}\033[m "
      else; result += "=> \033[1;20m#{self.result.inspect}"
      end
      result
    end
  end
 
  def format_error
    e = @error
    msg = e.message.sub(/.*:in `initialize': |\(eval\):1: /, "")
    # RegEx explination: (regular error|syntax error)
    
    error_output = "\033[1;33m#{e.class}: #{msg}"
    if self.output.empty?
      error_output
    else
      self.output + error_output
    end
  end
 
  protected
  def initialize(values)
    values.each do |variable, value|
      instance_variable_set("@#{variable}", value)
    end
  end
 
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
    @string += str.to_s
    
    method_missing(:write, strs)
  end
 
  def to_s
    return "" if @calls.empty?
    @string
    # @calls.join("\n")
  end
end
