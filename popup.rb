module Popup
  def self.goto(url)
    JavascriptResult.new("window.irb.options.popup_goto(\"#{url}\")")
  end
end
