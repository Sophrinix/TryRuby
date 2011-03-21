require 'spec_helper'

describe "irb/index.html.erb" do
  before(:each) do
    assign(:irb, [
      stub_model(Irb),
      stub_model(Irb)
    ])
  end

  it "renders a list of irb" do
    render
  end
end
