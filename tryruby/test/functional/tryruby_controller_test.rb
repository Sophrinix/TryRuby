require 'test_helper'

class TryrubyControllerTest < ActionController::TestCase
  test "run" do
    get :run, :cmd => "2 + 6"
    assert_response :success
  end
end
