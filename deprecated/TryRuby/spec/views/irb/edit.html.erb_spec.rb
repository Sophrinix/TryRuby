require 'spec_helper'

describe "irb/edit.html.erb" do
  before(:each) do
    @irb = assign(:irb, stub_model(Irb))
  end

  it "renders the edit irb form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => irb_path(@irb), :method => "post" do
    end
  end
end
