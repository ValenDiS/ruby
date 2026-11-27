require "test_helper"

class Admin::ConfiguracionesControllerTest < ActionDispatch::IntegrationTest
  test "el admin edita la configuración" do
    sign_in_as(users(:admin))

    get edit_admin_configuracion_path
    assert_response :success

    patch admin_configuracion_path, params: { configuracion: { texto_bienvenida: "Hola!" } }
    assert_redirected_to edit_admin_configuracion_path
    assert_equal "Hola!", Configuracion.actual.texto_bienvenida
  end

  test "una URL inválida no se guarda" do
    sign_in_as(users(:admin))

    patch admin_configuracion_path, params: { configuracion: { url_fuente: "no es una url" } }

    assert_response :unprocessable_entity
  end

  test "el editor de puntajes no puede entrar" do
    sign_in_as(users(:editor))

    get edit_admin_configuracion_path

    assert_redirected_to admin_root_path
  end
end
