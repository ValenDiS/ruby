require "test_helper"

class IniciadorDePartidasTest < ActiveSupport::TestCase
  setup do
    @jugador = Jugador.create!(nombre: "Nueva")
    @partida = AsignadorDePartidas.call(jugador: @jugador, dificultad: "facil").partida
  end

  test "inicia con la hora del servidor y conserva el resto de la partida" do
    originales = @partida.attributes.except("iniciado_at", "updated_at")

    travel_to Time.zone.local(2026, 11, 22, 15, 30) do
      resultado = iniciar

      assert resultado.exitoso?
      assert_equal :iniciada, resultado.estado
      assert_equal Time.current, @partida.reload.iniciado_at
    end

    assert_equal originales, @partida.attributes.except("iniciado_at", "updated_at")
  end

  test "dos solicitudes preparadas antes del inicio conservan un único timestamp" do
    atrasada = IniciadorDePartidas.new(jugador: Jugador.find(@jugador.id), partida: Partida.find(@partida.id))
    inicio = nil

    travel_to Time.zone.local(2026, 11, 22, 15, 30) do
      iniciar
      inicio = @partida.reload.iniciado_at
    end

    travel_to inicio + 2.minutes do
      resultado = atrasada.call

      assert resultado.exitoso?
      assert_equal :retomada, resultado.estado
      assert_equal inicio, resultado.partida.reload.iniciado_at
    end
  end

  test "no permite iniciar la partida de otro jugador" do
    otro = Jugador.create!(nombre: "Otro")

    resultado = IniciadorDePartidas.call(jugador: otro, partida: @partida)

    assert_not resultado.exitoso?
    assert_equal :partida_ajena, resultado.estado
    assert_nil resultado.partida
    assert_nil @partida.reload.iniciado_at
  end

  test "comprueba el dueño con los datos actualizados de la partida" do
    otro = Jugador.create!(nombre: "Otro")
    Partida.find(@partida.id).update!(jugador: otro)

    resultado = iniciar

    assert_equal :partida_ajena, resultado.estado
    assert_nil @partida.reload.iniciado_at
  end

  test "un bloqueo posterior a la asignación impide iniciar" do
    Jugador.find(@jugador.id).update!(bloqueado: true)

    resultado = iniciar

    assert_not resultado.exitoso?
    assert_equal :jugador_bloqueado, resultado.estado
    assert_nil @partida.reload.iniciado_at
  end

  test "una identidad retirada no inicia la partida que tenía asignada" do
    pendiente = IniciadorDePartidas.new(jugador: @jugador, partida: @partida)
    CambioDeJugador.call(jugador: Jugador.find(@jugador.id), nombre: "Otra", confirmado: true)

    resultado = pendiente.call

    assert_not resultado.exitoso?
    assert_equal :identidad_retirada, resultado.estado
    assert_nil @partida.reload.iniciado_at
  end

  test "no reinicia partidas resueltas ni rendidas" do
    [ :resuelta, :rendida ].each do |nombre|
      partida = partidas(nombre)
      originales = partida.attributes

      # La fixture rendida pertenece a un jugador bloqueado: se habilita para probar el cierre.
      jugador = partida.jugador
      jugador.update!(bloqueado: false)
      resultado = IniciadorDePartidas.call(jugador: jugador, partida: partida)

      assert_not resultado.exitoso?
      assert_equal :terminada, resultado.estado
      assert_equal originales, partida.reload.attributes
    end
  end

  private
    def iniciar
      IniciadorDePartidas.call(jugador: @jugador, partida: @partida)
    end
end
