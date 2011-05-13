require 'spec_helper'

describe "irb/show.html.erb" do
  before(:each) do
    @irb = assign(:irb, stub_model(Irb))
  end

  it "renders attributes in <p>" do
    render
  end
end
