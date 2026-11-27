require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  setup { @user = users(:admin) }

  test "new" do
    get new_session_path
    assert_response :success
  end

  test "create con credenciales válidas" do
    post session_path, params: { email_address: @user.email_address, password: "password" }

    assert_redirected_to admin_root_path
    assert cookies[:session_id]
  end

  test "create con credenciales inválidas" do
    post session_path, params: { email_address: @user.email_address, password: "wrong" }

    assert_redirected_to new_session_path
    assert_nil cookies[:session_id]
  end

  test "un usuario desactivado no puede loguearse" do
    post session_path, params: { email_address: users(:inactivo).email_address, password: "password" }

    assert_redirected_to new_session_path
    assert_nil cookies[:session_id]
  end

  test "una sesión abierta deja de valer si el usuario se desactiva" do
    editor = users(:editor)
    sign_in_as(editor)
    editor.update!(activo: false)

    get admin_root_path

    assert_redirected_to new_session_path
  end

  test "destroy" do
    sign_in_as(@user)

    delete session_path

    assert_redirected_to new_session_path
    assert_empty cookies[:session_id]
  end
end
