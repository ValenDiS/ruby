require "test_helper"

class Admin::CripticosControllerTest < ActionDispatch::IntegrationTest
  test "el admin ve el listado filtrado" do
    sign_in_as(users(:admin))

    get admin_cripticos_path, params: { dificultad: "medio" }

    assert_response :success
    assert_includes response.body, cripticos(:gato).id_fuente
    assert_not_includes response.body, cripticos(:mate).id_fuente
  end

  test "el admin desactiva y activa un críptico" do
    sign_in_as(users(:admin))

    patch admin_criptico_path(cripticos(:mate)), params: { criptico: { activo: false } }
    assert_redirected_to admin_cripticos_path
    assert_not cripticos(:mate).reload.activo?

    patch admin_criptico_path(cripticos(:mate)), params: { criptico: { activo: true } }
    assert cripticos(:mate).reload.activo?
  end

  test "el editor de puntajes no puede entrar" do
    sign_in_as(users(:editor))

    get admin_cripticos_path
    assert_redirected_to admin_root_path

    patch admin_criptico_path(cripticos(:mate)), params: { criptico: { activo: false } }
    assert cripticos(:mate).reload.activo?
  end
end
