require "test_helper"

class EstadisticasDeCripticoTest < ActiveSupport::TestCase
  setup do
    Partida.delete_all # arrancamos sin las partidas de los fixtures
    @mate = cripticos(:mate)
    @mora = Criptico.create!(
      id_fuente: "test-mora", enunciado: "Amor loco da una fruta del bosque", enumeracion: "(4)",
      respuesta: "MORA", definiciones: [ "una fruta del bosque" ], indicadores: [ "loco" ],
      material: [ "Amor" ], tipo: "anagrama", dificultad: "facil"
    )
    @ahora = Time.current.change(usec: 0)
  end

  # Crea una partida con un jugador nuevo (cada jugador juega un críptico una sola vez).
  def partida(criptico, iniciada_hace: nil, duracion: nil, rendida: false)
    @jugadores = (@jugadores || 0) + 1
    jugador = Jugador.create!(nombre: "Jugador#{@jugadores}")
    iniciado_at = iniciada_hace && @ahora - iniciada_hace
    fin = iniciado_at && duracion && iniciado_at + duracion

    Partida.create!(jugador: jugador, criptico: criptico, iniciado_at: iniciado_at,
                    resuelto_at: (fin unless rendida), rendido_at: (fin if rendida))
  end

  test "calcula veces jugado, porcentaje resuelto y tiempo promedio" do
    partida(@mate, iniciada_hace: 1.hour, duracion: 60)
    partida(@mate, iniciada_hace: 1.hour, duracion: 120)
    partida(@mate, iniciada_hace: 1.hour, duracion: 300, rendida: true)

    estadistica = EstadisticasDeCriptico.new.call[@mate.id]

    assert_equal 3, estadistica.veces_jugado
    assert_equal 2, estadistica.resueltas
    assert_equal 66.7, estadistica.porcentaje_resuelto
    assert_equal 90, estadistica.tiempo_promedio # (60 + 120) / 2: la rendida no cuenta
  end

  test "las partidas asignadas que nunca se iniciaron no cuentan como jugadas" do
    partida(@mate) # asignada, sin tocar «Jugar»
    partida(@mate, iniciada_hace: 5.minutes) # en curso

    estadistica = EstadisticasDeCriptico.new.call[@mate.id]

    assert_equal 1, estadistica.veces_jugado
    assert_equal 0.0, estadistica.porcentaje_resuelto
    assert_nil estadistica.tiempo_promedio
  end

  test "un críptico sin partidas devuelve ceros y nil, sin romper la vista" do
    estadistica = EstadisticasDeCriptico.new.call[@mora.id]

    assert_equal EstadisticasDeCriptico::SIN_PARTIDAS, estadistica
    assert_equal 0, estadistica.veces_jugado
    assert_nil estadistica.porcentaje_resuelto
  end

  test "separa las estadísticas por críptico" do
    partida(@mate, iniciada_hace: 1.hour, duracion: 30)
    partida(@mora, iniciada_hace: 1.hour, duracion: 200, rendida: true)

    estadisticas = EstadisticasDeCriptico.new.call

    assert_equal 100.0, estadisticas[@mate.id].porcentaje_resuelto
    assert_equal 30, estadisticas[@mate.id].tiempo_promedio
    assert_equal 0.0, estadisticas[@mora.id].porcentaje_resuelto
  end

  test "se puede limitar a algunos crípticos, por ejemplo los del filtro del admin" do
    partida(@mate, iniciada_hace: 1.hour, duracion: 30)
    partida(@mora, iniciada_hace: 1.hour, duracion: 30)

    estadisticas = EstadisticasDeCriptico.new(Criptico.where(id: @mora.id)).call

    assert_equal [ @mora.id ], estadisticas.keys
  end

  test "hace una sola consulta para todos los crípticos (sin N+1)" do
    partida(@mate, iniciada_hace: 1.hour, duracion: 30)
    partida(@mora, iniciada_hace: 1.hour, duracion: 30)

    consultas = 0
    contar = ->(*, payload) { consultas += 1 unless payload[:name] == "SCHEMA" }
    ActiveSupport::Notifications.subscribed(contar, "sql.active_record") do
      EstadisticasDeCriptico.new.call
    end

    assert_equal 1, consultas
  end
end
