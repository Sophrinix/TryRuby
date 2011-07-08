require 'test_helper'

class TutorialsControllerTest < ActionController::TestCase
  test "should get intro" do
    get :intro
    assert_response :success
  end

end
