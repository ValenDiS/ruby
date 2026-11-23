require "test_helper"

class ProcesadorDeRespuestaTest < ActiveSupport::TestCase
  setup do
    @jugador = Jugador.create!(nombre: "Nueva")
    @partida = AsignadorDePartidas.call(jugador: @jugador, dificultad: "facil").partida
    @partida.update!(iniciado_at: 2.minutes.ago)
  end

  test "una respuesta incorrecta consume un intento y conserva el inicio" do
    inicio = @partida.iniciado_at
    resultado = responder("CASA", calculador: ->(_) { flunk "No debe calcular puntos" })

    assert_equal :incorrecta, resultado.estado
    assert_equal 1, @partida.reload.intentos
    assert_equal 4, @partida.intentos_restantes
    assert_equal inicio, @partida.iniciado_at
    assert_nil @partida.resuelto_at
    assert_nil @partida.puntos
  end

  test "el acierto usa el calculador una vez y guarda el cierre y los puntos juntos" do
    inicio = Time.zone.local(2026, 11, 22, 15)
    @partida.update!(iniciado_at: inicio)
    llamadas = 0
    calculador = lambda do |partida|
      llamadas += 1
      assert_equal 240, partida.segundos_jugados
      assert Partida.find(partida.id).resuelta?
      assert_equal Time.current, partida.resuelto_at
      assert_equal 1, partida.intentos
      144
    end

    travel_to inicio + 240.seconds do
      assert_equal :resuelta, responder(" mÁ tE! ", calculador: calculador).estado
      assert_equal Time.current, @partida.reload.resuelto_at
    end

    assert_equal 144, @partida.puntos
    assert_equal 1, llamadas
    originales = @partida.attributes
    assert_equal :terminada, responder("MATE", previos: 0, calculador: calculador).estado
    assert_equal 1, llamadas
    assert_equal originales, @partida.reload.attributes
  end

  test "un formulario repetido o desactualizado no consume otro intento" do
    repetido = ProcesadorDeRespuesta.new(jugador: Jugador.find(@jugador.id), partida: Partida.find(@partida.id),
                                         respuesta: "CASA", intentos_previos: 0)
    responder("CASA")

    assert_equal :desactualizada, repetido.call.estado
    assert_equal 1, @partida.reload.intentos
    assert_equal :desactualizada, responder("OTRA", previos: nil).estado
    assert_equal 1, @partida.reload.intentos
    assert_equal :incorrecta, responder("OTRA").estado
    assert_equal 2, @partida.reload.intentos
  end

  test "respuestas vacías, sin letras o con tipo inválido no consumen intentos" do
    [ nil, "", " \t ", "?!123", [ "MATE" ], { respuesta: "MATE" } ].each do |respuesta|
      assert_equal :respuesta_invalida, responder(respuesta).estado
      assert_equal 0, @partida.reload.intentos
    end
  end

  test "el quinto intento puede ser correcto" do
    @partida.update!(intentos: 4)

    assert_equal :resuelta, responder("MATE").estado
    assert_equal 5, @partida.reload.intentos
    assert_equal 144, @partida.puntos
  end

  test "el quinto fallo deja de admitir respuestas y espera una rendición explícita" do
    5.times { assert_equal :incorrecta, responder("CASA").estado }

    assert_equal :sin_intentos, responder("MATE").estado
    assert_equal 5, @partida.reload.intentos
    assert_equal 0, @partida.intentos_restantes
    assert_not @partida.terminada?
    assert_nil @partida.puntos
  end

  test "el cálculo fallido revierte tanto la resolución como el intento" do
    originales = @partida.attributes
    error = assert_raises(ProcesadorDeRespuesta::PuntajeNoDisponible) do
      responder("MATE", calculador: ->(_) { raise "Falla de la dependencia" })
    end

    assert_instance_of RuntimeError, error.cause
    assert_equal originales, @partida.reload.attributes
  end

  test "no acepta valores de puntaje que incumplan el contrato de un acierto" do
    [ nil, 0, -1, 9, 10.5, "100" ].each do |puntos|
      assert_raises(ProcesadorDeRespuesta::PuntajeNoDisponible) do
        responder("MATE", calculador: ->(_) { puntos })
      end
      assert_equal 0, @partida.reload.intentos
      assert_not @partida.resuelta?
      assert_nil @partida.puntos
    end
  end

  test "distingue ene y eñe al comparar la respuesta real" do
    criptico = Criptico.create!(id_fuente: "test-enie", tipo: "doble_definicion", dificultad: "facil",
                               enunciado: "Tiempo de doce meses o edad de una persona", respuesta: "AÑO", enumeracion: "(3)",
                               definiciones: [ "Tiempo de doce meses", "edad de una persona" ])
    @partida.update!(criptico: criptico)

    assert_equal :incorrecta, responder("ANO").estado
    assert_equal :resuelta, responder("an\u0303o").estado
  end

  test "no responde antes de presionar Jugar" do
    @partida.update!(iniciado_at: nil)

    assert_equal :sin_iniciar, responder("MATE").estado
    assert_equal 0, @partida.reload.intentos
  end

  test "no responde por otro jugador ni con un bloqueo administrativo" do
    otro = Jugador.create!(nombre: "Otro")
    resultado = ProcesadorDeRespuesta.call(jugador: otro, partida: @partida, respuesta: "MATE", intentos_previos: 0)
    assert_equal :partida_ajena, resultado.estado
    assert_nil resultado.partida

    Jugador.find(@jugador.id).update!(bloqueado: true)
    assert_equal :jugador_bloqueado, responder("MATE").estado
    assert_equal 0, @partida.reload.intentos
  end

  test "una identidad retirada no puede seguir respondiendo" do
    pendiente = ProcesadorDeRespuesta.new(jugador: @jugador, partida: @partida, respuesta: "CASA", intentos_previos: 0)
    CambioDeJugador.call(jugador: Jugador.find(@jugador.id), nombre: "Otra", confirmado: true)

    assert_equal :identidad_retirada, pendiente.call.estado
    assert_equal 0, @partida.reload.intentos
  end

  test "una rendición que se confirma primero impide resolver después" do
    pendiente = ProcesadorDeRespuesta.new(jugador: @jugador, partida: Partida.find(@partida.id), respuesta: "MATE",
                                          intentos_previos: 0, calculador: ->(_) { flunk "No debe recalcular puntos" })
    RendicionDePartida.call(jugador: @jugador, partida: @partida)
    originales = @partida.reload.attributes

    assert_equal :terminada, pendiente.call.estado
    assert_equal originales, @partida.reload.attributes
  end

  private
    def responder(respuesta, previos: @partida.intentos, calculador: ->(_) { 144 })
      ProcesadorDeRespuesta.call(jugador: @jugador, partida: @partida, respuesta: respuesta,
                                intentos_previos: previos, calculador: calculador)
    end
end
