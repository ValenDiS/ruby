require "test_helper"

class Admin::UsersControllerTest < ActionDispatch::IntegrationTest
  test "el admin ve el listado" do
    sign_in_as(users(:admin))
    get admin_users_path
    assert_response :success
  end

  test "el admin crea un usuario" do
    sign_in_as(users(:admin))

    assert_difference("User.count") do
      post admin_users_path, params: { user: { email_address: "nuevo@example.com", password: "password",
                                               password_confirmation: "password", rol: "editor_puntajes" } }
    end
    assert_redirected_to admin_users_path
  end

  test "el admin desactiva a otro usuario" do
    sign_in_as(users(:admin))

    patch admin_user_path(users(:editor)), params: { user: { activo: "0" } }

    assert_redirected_to admin_users_path
    assert_not users(:editor).reload.activo?
  end

  test "editar sin contraseña no la cambia" do
    sign_in_as(users(:admin))

    patch admin_user_path(users(:editor)), params: { user: { email_address: "editor2@example.com", password: "" } }

    assert_equal users(:editor), User.autenticar(email_address: "editor2@example.com", password: "password")
  end

  test "el editor que escribe la URL a mano es rechazado" do
    sign_in_as(users(:editor))

    get admin_users_path
    assert_redirected_to admin_root_path

    patch admin_user_path(users(:editor)), params: { user: { rol: "admin" } }
    assert_redirected_to admin_root_path
    assert users(:editor).reload.editor_puntajes?
  end
end
