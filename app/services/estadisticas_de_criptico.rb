# Estadísticas de juego de cada críptico, para el listado del admin:
# veces jugado, porcentaje resuelto y tiempo promedio.
#
#   estadisticas = EstadisticasDeCriptico.new(@cripticos).call
#   estadisticas[criptico.id].veces_jugado        # => 3
#   estadisticas[criptico.id].porcentaje_resuelto # => 66.7
#   estadisticas[criptico.id].tiempo_promedio     # => 95 (segundos)
#
# Hace UNA sola consulta agrupada por críptico, así la tabla del admin no
# dispara una consulta por fila (N+1).
#
# Criterios:
#   - Veces jugado: partidas iniciadas (el jugador tocó «Jugar»). Una partida
#     asignada que nunca se inició no cuenta.
#   - Porcentaje resuelto: resueltas sobre iniciadas. Las rendidas y las que
#     siguen en curso cuentan como jugadas pero no resueltas.
#   - Tiempo promedio: solo de las resueltas, entre iniciado_at y resuelto_at,
#     calculado en la base, igual que el tiempo oficial del puntaje.
class EstadisticasDeCriptico
  Estadistica = Data.define(:veces_jugado, :resueltas, :porcentaje_resuelto, :tiempo_promedio)

  # Lo que devuelve un críptico que nadie jugó todavía.
  SIN_PARTIDAS = Estadistica.new(veces_jugado: 0, resueltas: 0, porcentaje_resuelto: nil, tiempo_promedio: nil)

  # Diferencia en segundos entre dos datetime en SQLite (julianday da días con decimales).
  SEGUNDOS_RESOLVIENDO = "(julianday(resuelto_at) - julianday(iniciado_at)) * 86400".freeze

  # cripticos: una relación o lista de crípticos (por ej. el resultado de los
  # filtros del admin). Si se omite, calcula para todos.
  def initialize(cripticos = nil)
    @cripticos = cripticos
  end

  # Devuelve un Hash { criptico_id => Estadistica }. Para un id sin partidas
  # devuelve SIN_PARTIDAS, así la vista no tiene que distinguir el caso.
  def call
    filas = partidas_iniciadas.group(:criptico_id).pluck(
      :criptico_id,
      Arel.sql("COUNT(*)"),
      Arel.sql("COUNT(resuelto_at)"),
      Arel.sql("AVG(CASE WHEN resuelto_at IS NOT NULL THEN #{SEGUNDOS_RESOLVIENDO} END)")
    )

    estadisticas = filas.to_h do |criptico_id, jugadas, resueltas, promedio|
      [ criptico_id, armar(jugadas, resueltas, promedio) ]
    end
    estadisticas.default = SIN_PARTIDAS
    estadisticas
  end

  private

  def partidas_iniciadas
    partidas = Partida.where.not(iniciado_at: nil)
    @cripticos.nil? ? partidas : partidas.where(criptico_id: ids_de_cripticos)
  end

  def ids_de_cripticos
    @cripticos.respond_to?(:ids) ? @cripticos.ids : Array(@cripticos).map(&:id)
  end

  def armar(jugadas, resueltas, promedio)
    Estadistica.new(
      veces_jugado: jugadas,
      resueltas: resueltas,
      porcentaje_resuelto: (100.0 * resueltas / jugadas).round(1),
      tiempo_promedio: promedio&.round
    )
  end
end
