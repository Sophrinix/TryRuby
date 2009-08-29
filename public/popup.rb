module Popup
  def self.goto(url)
    JavascriptResult.new("window.irb.options.popup_goto(\"#{url}\")")
  end

  class Header
    attr_accessor :level, :text
    def initialize(level, text)
      self.level, self.text = level, text
    end
  end

  class Link
    attr_accessor :text, :target
    def initialize(text, target)
      self.text, self.target = text, target
    end
  end

  class ComplexPopup
    def initialize
      @elements = []
    end
    
    def h1 text
      @elements << Header.new(1, text)
    end

    def link(text, target)
      @elements << Link.new(text, target)
    end
  end
      
      
  def self.make(&block)
    result = ComplexPopup.new
    result.instance_eval(&block)

    result
  end
    
end
