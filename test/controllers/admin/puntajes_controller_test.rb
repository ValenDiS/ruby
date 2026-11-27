require "test_helper"

class Admin::PuntajesControllerTest < ActionDispatch::IntegrationTest
  test "el editor de puntajes ve y edita los puntos y multiplicadores" do
    sign_in_as(users(:editor))

    get admin_puntajes_por_tipo_path
    assert_response :success

    patch admin_puntaje_por_tipo_path(puntajes_por_tipo(:anagrama)), params: { puntaje_por_tipo: { puntos: 150 } }
    assert_redirected_to admin_puntajes_por_tipo_path
    assert_equal 150, puntajes_por_tipo(:anagrama).reload.puntos

    patch admin_multiplicador_dificultad_path(multiplicadores_dificultad(:medio)), params: { multiplicador_dificultad: { valor: 2.5 } }
    assert_equal 2.5, multiplicadores_dificultad(:medio).reload.valor
  end

  test "un valor inválido no se guarda y se avisa" do
    sign_in_as(users(:admin))

    patch admin_puntaje_por_tipo_path(puntajes_por_tipo(:anagrama)), params: { puntaje_por_tipo: { puntos: 2000 } }

    assert_redirected_to admin_puntajes_por_tipo_path
    assert flash[:alert].present?
    assert_equal 100, puntajes_por_tipo(:anagrama).reload.puntos
  end

  test "sin login no se puede entrar" do
    get admin_puntajes_por_tipo_path
    assert_redirected_to new_session_path
  end
end
