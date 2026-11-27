require "test_helper"

class Admin::DashboardControllerTest < ActionDispatch::IntegrationTest
  test "sin login redirige al login" do
    get admin_root_path
    assert_redirected_to new_session_path
  end

  test "el admin entra al panel" do
    sign_in_as(users(:admin))
    get admin_root_path
    assert_response :success
  end

  test "el editor de puntajes entra al panel" do
    sign_in_as(users(:editor))
    get admin_root_path
    assert_response :success
  end
end
