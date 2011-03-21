require 'spec_helper'

describe "irb/new.html.erb" do
  before(:each) do
    assign(:irb, stub_model(Irb).as_new_record)
  end

  it "renders new irb form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => irb_path, :method => "post" do
    end
  end
end
