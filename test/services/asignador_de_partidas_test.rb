require "test_helper"

class AsignadorDePartidasTest < ActiveSupport::TestCase
  setup do
    @jugador = Jugador.create!(nombre: "Nueva")
  end

  test "asigna un críptico de la dificultad elegida sin iniciar el reloj" do
    criptico = crear_criptico(dificultad: "medio")
    resultado = nil

    assert_difference "Partida.count", 1 do
      resultado = asignar("medio")
    end

    assert resultado.exitoso?
    assert_equal :asignada, resultado.estado
    assert_equal criptico, resultado.partida.criptico
    assert_equal @jugador, resultado.partida.jugador
    assert_nil resultado.partida.iniciado_at
    assert_nil resultado.partida.resuelto_at
    assert_nil resultado.partida.rendido_at
    assert_nil resultado.partida.puntos
    assert_equal 0, resultado.partida.intentos
    assert_equal 0, resultado.partida.pistas_usadas
  end

  test "admite las tres dificultades definidas en el catálogo" do
    Criptico::DIFICULTADES.each do |dificultad|
      jugador = Jugador.create!(nombre: "Jugador_#{dificultad}")
      crear_criptico(dificultad: dificultad)

      resultado = AsignadorDePartidas.call(jugador: jugador, dificultad: dificultad)

      assert resultado.exitoso?
      assert_equal dificultad, resultado.partida.criptico.dificultad
    end
  end

  test "rechaza dificultades desconocidas sin crear una partida" do
    [ nil, "", "experto", "FACIL", [ "facil" ] ].each do |dificultad|
      assert_no_difference "Partida.count" do
        resultado = asignar(dificultad)
        assert_not resultado.exitoso?
        assert_equal :dificultad_invalida, resultado.estado
        assert_nil resultado.partida
      end
    end
  end

  test "no asigna crípticos desactivados, fuera de fuente ni de otra dificultad" do
    crear_criptico(dificultad: "medio", activo: false)
    crear_criptico(dificultad: "medio", en_fuente: false)
    crear_criptico(dificultad: "avanzado")

    assert_no_difference "Partida.count" do
      resultado = asignar("medio")
      assert_not resultado.exitoso?
      assert_equal :sin_disponibles, resultado.estado
    end
  end

  test "excluye los resueltos y rendidos y elige entre los que quedan" do
    resuelto = crear_criptico(dificultad: "medio")
    rendido = crear_criptico(dificultad: "medio")
    disponible = crear_criptico(dificultad: "medio")
    @jugador.partidas.create!(criptico: resuelto, iniciado_at: 2.minutes.ago, resuelto_at: 1.minute.ago, puntos: 100)
    @jugador.partidas.create!(criptico: rendido, iniciado_at: 2.minutes.ago, rendido_at: 1.minute.ago, puntos: 0)

    assert_equal disponible, asignar("medio").partida.criptico
  end

  test "informa cuando el jugador ya agotó todos los crípticos de esa dificultad" do
    @jugador.partidas.create!(criptico: cripticos(:mate), iniciado_at: 2.minutes.ago, resuelto_at: 1.minute.ago, puntos: 100)

    assert_no_difference "Partida.count" do
      resultado = asignar("facil")
      assert_not resultado.exitoso?
      assert_equal :sin_disponibles, resultado.estado
    end
  end

  test "lo jugado por otra persona sigue disponible para este jugador" do
    assert_equal cripticos(:mate), partidas(:resuelta).criptico

    assert_equal cripticos(:mate), asignar("facil").partida.criptico
  end

  test "repetir la asignación retoma la partida sin crear otra" do
    crear_criptico(dificultad: "medio")
    primera = asignar("facil").partida

    assert_no_difference "Partida.count" do
      repetida = AsignadorDePartidas.call(jugador: Jugador.find(@jugador.id), dificultad: "medio")
      assert repetida.exitoso?
      assert_equal :retomada, repetida.estado
      assert_equal primera.id, repetida.partida.id
    end

    assert_nil primera.reload.iniciado_at
  end

  test "retoma una partida ya iniciada sin alterar el reloj ni sus datos" do
    inicio = 10.minutes.ago.change(usec: 0)
    partida = @jugador.partidas.create!(criptico: cripticos(:mate), iniciado_at: inicio, intentos: 2, pistas_usadas: 1)

    assert_no_difference "Partida.count" do
      resultado = asignar("avanzado")
      assert_equal :retomada, resultado.estado
      assert_equal partida.id, resultado.partida.id
    end

    assert_equal inicio, partida.reload.iniciado_at
    assert_equal 2, partida.intentos
    assert_equal 1, partida.pistas_usadas
  end

  test "una partida abierta se conserva aunque el catálogo la desactive después" do
    primera = asignar("facil").partida
    primera.criptico.update!(activo: false, en_fuente: false)

    assert_equal primera.id, asignar("facil").partida.id
  end

  test "un jugador bloqueado no puede obtener ni retomar partidas" do
    abierta = asignar("facil").partida
    Jugador.find(@jugador.id).update!(bloqueado: true)

    assert_no_difference "Partida.count" do
      resultado = asignar("facil")
      assert_not resultado.exitoso?
      assert_equal :jugador_bloqueado, resultado.estado
      assert_nil resultado.partida
    end

    assert abierta.reload.persisted?
  end

  test "una solicitud de una identidad retirada no asigna partidas" do
    pendiente = AsignadorDePartidas.new(jugador: @jugador, dificultad: "facil")
    CambioDeJugador.call(jugador: Jugador.find(@jugador.id), nombre: "Segunda", confirmado: true)

    assert_no_difference "Partida.count" do
      resultado = pendiente.call
      assert_not resultado.exitoso?
      assert_equal :identidad_retirada, resultado.estado
    end
  end

  test "elige un candidato del conjunto disponible" do
    candidatos = 3.times.map { crear_criptico(dificultad: "medio") }

    resultado = asignar("medio")

    assert_includes candidatos, resultado.partida.criptico
  end

  private
    def asignar(dificultad)
      AsignadorDePartidas.call(jugador: @jugador, dificultad: dificultad)
    end

    def crear_criptico(**atributos)
      @secuencia = (@secuencia || 0) + 1
      datos = cripticos(:mate).attributes.except("id", "created_at", "updated_at")
      Criptico.create!(datos.merge(id_fuente: "asignacion-#{@secuencia}").merge(atributos))
    end
end
