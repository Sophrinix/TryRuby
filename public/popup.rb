class Symbol
  def to_proc
    Proc.new { |obj, *args| obj.send(self, *args) }
  end
end

module Popup
  def self.goto(url)
    url = url.gsub '"', '\"'
    TryRuby::Output.javascript "window.irb.options.popup_goto(\"#{url}\")"
  end
 
  class Header
    attr_accessor :level, :text
    def initialize(level, text)
      self.level, self.text = level, text
    end
    def generate_html
      "<h#{level}>#{self.text}</h#{level}>"
    end
 
  end
 
  class Link
    attr_accessor :text, :target
    def initialize(text, target)
      self.text, self.target = text, target
    end
    def generate_html
      "<a href=\"#{target}\">#{text}</a>"
    end
 
 
  end
 
  class List
    attr_accessor :elements
    def initialize(elements)
      self.elements = elements
    end
    
    def generate_html
      items = elements.map do |elem|
        text = elem.instance_of?(Paragraph) ? elem.text : elem.generate_html
        "<li>#{text}</li>"
      end.join(" ")
 
      "<ul>#{items}</ul>"
    end
  end
 
 
  class Paragraph
    attr_accessor :text
    def initialize(text)
      self.text = text
    end
 
    def generate_html
      "<p>#{self.text}</p>"
    end
  end
 
 
  class ComplexPopup
    attr_reader :elements
    def initialize
      @elements = []
    end

    (1..6).each do |n|
      define_method "h#{n}".to_sym do |text|
        @elements << Header.new(n, text)
      end
    end

    
    # def h1 text
    #   @elements << Header.new(1, text)
    # end
 
    def link(text, target)
      @elements << Link.new(text, target)
    end
 
    def p(text)
      @elements << Paragraph.new(text)
    end
 
    def list(&block)
      lst = ComplexPopup.new
      lst.instance_eval(&block)
      @elements << List.new(lst.elements)
    end
 
    def generate_html()
      @elements.map(&:generate_html).join(" ")
    end
        
              
      
  end
      
      
  def self.make(&block)
    result = ComplexPopup.new
    result.instance_eval(&block)
 
    html = result.generate_html.gsub('\\', '\\\\').gsub('"', '\"')
    command = "window.irb.options.popup_make(\"#{html}\")"
    TryRuby::Output.javascript command
  end
    
end
