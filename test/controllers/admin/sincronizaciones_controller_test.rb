require "test_helper"

class Admin::SincronizacionesControllerTest < ActionDispatch::IntegrationTest
  test "el admin ve el historial y el informe con los rechazados" do
    sincronizacion = Sincronizacion.create!(url: "https://ejemplo.test/v1/cryptics.json", estado: "exitosa",
                                            version: "1", creados: 1, rechazados: 1, user: users(:admin),
                                            detalle_rechazados: [ { "id" => "cr-104", "motivo" => "Respuesta no puede estar en blanco" } ])
    sign_in_as(users(:admin))

    get admin_sincronizaciones_path
    assert_response :success

    get admin_sincronizacion_path(sincronizacion)
    assert_response :success
    assert_includes response.body, "cr-104"
  end

  test "sincronizar ahora con la fuente caída informa el error y registra al admin" do
    Configuracion.actual.update!(url_fuente: "http://127.0.0.1:1/v1/cryptics.json")
    sign_in_as(users(:admin))

    assert_no_difference("Criptico.count") do
      post admin_sincronizaciones_path
    end

    sincronizacion = Sincronizacion.last
    assert sincronizacion.fallida?
    assert_equal users(:admin), sincronizacion.user
    assert_redirected_to admin_sincronizacion_path(sincronizacion)
  end

  test "el editor de puntajes no puede sincronizar" do
    sign_in_as(users(:editor))

    assert_no_difference("Sincronizacion.count") do
      post admin_sincronizaciones_path
    end
    assert_redirected_to admin_root_path
  end
end
