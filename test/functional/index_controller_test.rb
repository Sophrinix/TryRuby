require 'test_helper'

class IndexControllerTest < ActionController::TestCase
  test "should get terminal" do
    get :terminal
    assert_response :success
  end

end
