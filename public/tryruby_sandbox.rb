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

module TryRuby
Line, Past_commands, current_includes = ARGV
def current_includes
current_includes
end
def current_includes<<(item)
current_includes << item
end
end
ARGV = []

poem = <<POEM_EOF
My toast has flown from my hand
And my toast has gone to the
moon.
But when I saw it on television,
Planting our flag on Halley's
comet,
More still did I want to eat it.
POEM_EOF

#def require(path)
#  result = ''
#  path = path.sub(/\.rb$/, "")
#  return false unless ['popup'].include?(path)
#  if Object.tryruby_current_includes.include?(path)
#    Thread.new do
#      
#    end.join
#  else
#    Thread.new do
#      result = File.read(path)
#      Object.tryruby_current_includes << path
#    end.join
#  end
#  true
#end
def require(require_path)
  result = false
  Thread.new do
    path = require_path.sub(/\.rb$/, "")
    if ['popup'].include?(path) and !TryRuby::Current_includes.include?(path)
      TryRuby::Current_includes << path
      result = true
    end
  end.join
  result
end

$stdout = FakeStdout.new

eval( <<EOF
$SAFE=3