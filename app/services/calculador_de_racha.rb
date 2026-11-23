# Racha de días seguidos jugando. Un día cuenta si el jugador terminó al menos
# una partida ese día (la resolvió o se rindió). Las fechas son de Argentina
# (config.time_zone), así que jugar a las 23:30 cuenta para ese mismo día.
#
#   CalculadorDeRacha.new(jugador).actual        # => 4
#   CalculadorDeRacha.new(jugador).contando_hoy  # => 5 (si hoy todavía no jugó)
#   CalculadorDeRacha.new(jugador).mejor         # => 7
class CalculadorDeRacha
  def initialize(jugador, hoy: Date.current)
    @jugador = jugador
    @hoy = hoy
  end

  # Días seguidos hasta hoy. Si hoy todavía no jugó, la racha de ayer sigue viva
  # hasta que termine el día.
  def actual
    desde = dias_jugados.include?(@hoy) ? @hoy : @hoy.yesterday
    dias_seguidos_hasta(desde)
  end

  # La racha suponiendo que hoy juega: es la que usa el puntaje,
  # así todas las partidas del mismo día tienen el mismo bonus.
  def contando_hoy
    dias_seguidos_hasta(@hoy.yesterday) + 1
  end

  # La racha más larga que tuvo el jugador, aunque ya se haya cortado.
  # Se mide desde cada día que cierra una racha (el día siguiente no jugó).
  def mejor
    dias_jugados.reject { |dia| dias_jugados.include?(dia.tomorrow) }
                .map { |ultimo_dia| dias_seguidos_hasta(ultimo_dia) }
                .max || 0
  end

  private
    def dias_seguidos_hasta(dia)
      dias = 0
      while dias_jugados.include?(dia)
        dias += 1
        dia = dia.yesterday
      end
      dias
    end

    def dias_jugados
      @dias_jugados ||= @jugador.partidas.resueltas.or(@jugador.partidas.rendidas)
                                .pluck(:resuelto_at, :rendido_at)
                                .map { |resuelto, rendido| (resuelto || rendido).to_date }
                                .to_set
    end
end
