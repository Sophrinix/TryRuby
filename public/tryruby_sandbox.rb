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

class Object
  attr_reader :tryruby_line, :tryruby_past_commands, :tryruby_current_includes
  @tryruby_line, @tryruby_past_commands, @tryruby_current_includes = ARGV
end
ARGV = []

poem = <<POEM_EOF
blah blah blah
POEM_EOF

def require(path)
  result = ''
  path = path.sub(/\.rb$/, "")
  return false unless ['popup'].include?(path)
  if Object.tryruby_current_includes.include?(path)
    
  else
    Thread.new do
      result = File.read(path)
      Object.tryruby_current_includes << path
    end
  end
  true
end

$stdout = FakeStdout.new

eval( <<EOF
$SAFE=3