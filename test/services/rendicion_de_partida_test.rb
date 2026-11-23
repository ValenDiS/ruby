require "test_helper"

class RendicionDePartidaTest < ActiveSupport::TestCase
  setup do
    @jugador = Jugador.create!(nombre: "Nueva")
    @partida = AsignadorDePartidas.call(jugador: @jugador, dificultad: "facil").partida
    @partida.update!(iniciado_at: 2.minutes.ago, intentos: 2)
  end

  test "rendirse guarda cero puntos y conserva los intentos consumidos" do
    travel_to Time.zone.local(2026, 11, 22, 15, 30) do
      @partida.update!(iniciado_at: 2.minutes.ago)
      assert_equal :rendida, rendirse.estado
      assert_equal Time.current, @partida.reload.rendido_at
    end

    assert_nil @partida.resuelto_at
    assert_equal 0, @partida.puntos
    assert_equal 2, @partida.intentos
  end

  test "repetir la rendición no altera el cierre" do
    rendirse
    originales = @partida.reload.attributes

    travel_to 1.day.from_now do
      assert_equal :terminada, rendirse.estado
    end

    assert_equal originales, @partida.reload.attributes
  end

  test "permite rendirse con los cinco intentos agotados" do
    @partida.update!(intentos: 5)

    assert_equal :rendida, rendirse.estado
    assert_equal 0, @partida.reload.puntos
    assert_equal 5, @partida.intentos
  end

  test "una rendición preparada antes de un acierto no borra los puntos" do
    pendiente = RendicionDePartida.new(jugador: Jugador.find(@jugador.id), partida: Partida.find(@partida.id))
    ProcesadorDeRespuesta.call(jugador: @jugador, partida: @partida, respuesta: "MATE", intentos_previos: 2,
                               calculador: ->(_) { 144 })
    originales = @partida.reload.attributes

    assert_equal :terminada, pendiente.call.estado
    assert_equal originales, @partida.reload.attributes
    assert_equal 144, @partida.puntos
  end

  test "no revela la solución mediante rendición antes del inicio" do
    @partida.update!(iniciado_at: nil)

    assert_equal :sin_iniciar, rendirse.estado
    assert_not @partida.reload.terminada?
    assert_nil @partida.puntos
  end

  test "rechaza partidas ajenas, bloqueos e identidades retiradas" do
    otro = Jugador.create!(nombre: "Otro")
    resultado = RendicionDePartida.call(jugador: otro, partida: @partida)
    assert_equal :partida_ajena, resultado.estado
    assert_nil resultado.partida

    Jugador.find(@jugador.id).update!(bloqueado: true)
    assert_equal :jugador_bloqueado, rendirse.estado
    Jugador.find(@jugador.id).update!(bloqueado: false)
    pendiente = RendicionDePartida.new(jugador: @jugador.reload, partida: @partida)
    CambioDeJugador.call(jugador: Jugador.find(@jugador.id), nombre: "Otra", confirmado: true)
    assert_equal :identidad_retirada, pendiente.call.estado
    assert_not @partida.reload.terminada?
  end

  private
    def rendirse
      RendicionDePartida.call(jugador: @jugador, partida: @partida)
    end
end
