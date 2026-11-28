require "test_helper"

class RegistroDeJugadorTest < ActiveSupport::TestCase
  test "registra un jugador y genera su token" do
    resultado = nil
    assert_difference "Jugador.count", 1 do
      resultado = RegistroDeJugador.call(nombre: "Nuevo")
    end

    assert resultado.exitoso?
    assert resultado.jugador.token.present?
    assert_nil resultado.sugerencia
  end

  test "un nombre tomado sugiere una alternativa sin recuperar al dueño" do
    resultado = nil
    assert_no_difference "Jugador.count" do
      resultado = RegistroDeJugador.call(nombre: "PEDRITO")
    end

    assert_not resultado.exitoso?
    assert_nil resultado.jugador.id
    assert_equal "PEDRITO_2", resultado.sugerencia
  end

  test "un nombre inválido no se corrige silenciosamente ni genera sugerencia" do
    [ nil, "Al", " Ana", "Ana ", "a" * 21 ].each do |nombre|
      assert_no_difference "Jugador.count" do
        resultado = RegistroDeJugador.call(nombre: nombre)
        assert_not resultado.exitoso?
        assert resultado.jugador.errors[:nombre].any?
        assert_nil resultado.sugerencia
      end
    end
  end

  test "un nombre bloqueado sigue reservado" do
    resultado = RegistroDeJugador.call(nombre: jugadores(:ofensivo).nombre)

    assert_not resultado.exitoso?
    assert resultado.sugerencia.present?
  end
end
