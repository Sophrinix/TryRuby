require "spec_helper"

describe IrbController do
  describe "routing" do

    it "recognizes and generates #index" do
      { :get => "/irb" }.should route_to(:controller => "irb", :action => "index")
    end

    it "recognizes and generates #new" do
      { :get => "/irb/new" }.should route_to(:controller => "irb", :action => "new")
    end

    it "recognizes and generates #show" do
      { :get => "/irb/1" }.should route_to(:controller => "irb", :action => "show", :id => "1")
    end

    it "recognizes and generates #edit" do
      { :get => "/irb/1/edit" }.should route_to(:controller => "irb", :action => "edit", :id => "1")
    end

    it "recognizes and generates #create" do
      { :post => "/irb" }.should route_to(:controller => "irb", :action => "create")
    end

    it "recognizes and generates #update" do
      { :put => "/irb/1" }.should route_to(:controller => "irb", :action => "update", :id => "1")
    end

    it "recognizes and generates #destroy" do
      { :delete => "/irb/1" }.should route_to(:controller => "irb", :action => "destroy", :id => "1")
    end

  end
end
