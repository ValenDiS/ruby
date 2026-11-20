require "test_helper"

class Admin::JugadoresControllerTest < ActionDispatch::IntegrationTest
  test "el admin ve el listado y bloquea un nombre" do
    sign_in_as(users(:admin))

    get admin_jugadores_path
    assert_response :success

    patch admin_jugador_path(jugadores(:pedrito)), params: { jugador: { bloqueado: true } }
    assert_redirected_to admin_jugadores_path
    assert jugadores(:pedrito).reload.bloqueado?
  end

  test "el admin reinicia la tabla de posiciones sin borrar jugadores" do
    sign_in_as(users(:admin))

    assert_no_difference("Jugador.count") do
      post reiniciar_tabla_admin_jugadores_path
    end
    assert_redirected_to admin_jugadores_path
    assert Configuracion.actual.tabla_reiniciada_at.present?
  end

  test "el editor de puntajes no ve jugadores ni puede reiniciar la tabla" do
    sign_in_as(users(:editor))

    get admin_jugadores_path
    assert_redirected_to admin_root_path

    post reiniciar_tabla_admin_jugadores_path
    assert_nil Configuracion.actual.tabla_reiniciada_at
  end
end
