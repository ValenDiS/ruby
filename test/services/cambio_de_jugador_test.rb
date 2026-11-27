require "test_helper"

class CambioDeJugadorTest < ActiveSupport::TestCase
  test "requiere confirmación explícita antes de crear otra identidad" do
    [ false, nil, "1" ].each do |confirmado|
      anterior = jugadores(:pedrito)
      originales = anterior.attributes

      assert_no_difference "Jugador.count" do
        resultado = CambioDeJugador.call(jugador: anterior, nombre: "Nueva", confirmado: confirmado)
        assert_not resultado.exitoso?
        assert resultado.jugador.errors[:base].any?
      end

      assert_equal originales, anterior.reload.attributes
    end
  end

  test "conserva el jugador anterior y retira su token al crear uno nuevo" do
    anterior = jugadores(:pedrito)
    token_anterior = anterior.token
    originales = anterior.attributes.except("token", "updated_at")
    resultado = nil

    assert_difference "Jugador.count", 1 do
      resultado = CambioDeJugador.call(jugador: anterior, nombre: "Nueva", confirmado: true)
    end

    assert resultado.exitoso?
    assert_not_equal anterior.id, resultado.jugador.id
    assert_equal "Nueva", resultado.jugador.nombre
    assert_not resultado.jugador.bloqueado?
    assert_equal originales, anterior.reload.attributes.except("token", "updated_at")
    assert_not_equal token_anterior, anterior.token
    assert_nil Jugador.find_by(token: token_anterior)
  end

  test "empezar de cero mantiene el historial anterior y no lo transfiere al nuevo jugador" do
    anterior = jugadores(:pedrito)
    partida = partidas(:resuelta)
    originales = partida.attributes

    resultado = CambioDeJugador.call(jugador: anterior, nombre: "Nueva", confirmado: true)

    assert resultado.exitoso?
    assert_equal originales, partida.reload.attributes
    assert_includes anterior.partidas, partida
    assert_empty resultado.jugador.partidas
  end

  test "un nombre ocupado conserva el acceso al jugador anterior" do
    anterior = jugadores(:pedrito)
    originales = anterior.attributes

    assert_no_difference "Jugador.count" do
      resultado = CambioDeJugador.call(jugador: anterior, nombre: "NOMBREFEO", confirmado: true)
      assert_not resultado.exitoso?
      assert_equal "NOMBREFEO_2", resultado.sugerencia
    end

    assert_equal originales, anterior.reload.attributes
  end

  test "un nombre inválido conserva el acceso al jugador anterior" do
    anterior = jugadores(:pedrito)
    originales = anterior.attributes

    assert_no_difference "Jugador.count" do
      resultado = CambioDeJugador.call(jugador: anterior, nombre: " Ana ", confirmado: true)
      assert_not resultado.exitoso?
    end

    assert_equal originales, anterior.reload.attributes
  end

  test "una solicitud que conserva el token anterior no vuelve a crear jugadores" do
    anterior = jugadores(:pedrito)
    solicitud_atrasada = CambioDeJugador.new(jugador: Jugador.find(anterior.id), nombre: "Segunda", confirmado: true)
    assert CambioDeJugador.call(jugador: anterior, nombre: "Primera", confirmado: true).exitoso?

    assert_no_difference "Jugador.count" do
      resultado = solicitud_atrasada.call
      assert_not resultado.exitoso?
      assert resultado.jugador.errors[:base].any?
    end
  end
end
