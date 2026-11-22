# Calcula los puntos de una partida resuelta.
#
#   CalculadorDePuntaje.new(partida).calcular  # => 200
#
# puntos = base × tiempo
#   base:   puntos del tipo × multiplicador de la dificultad (se configuran en el admin)
#   tiempo: 1 si resolvió dentro del tiempo de referencia; si tardó más,
#           referencia ÷ segundos, sin bajar de 0,25
class CalculadorDePuntaje
  TIEMPOS_DE_REFERENCIA = { "facil" => 60, "medio" => 180, "avanzado" => 300 }.freeze
  FACTOR_DE_TIEMPO_MINIMO = 0.25

  def initialize(partida)
    @partida = partida
    @criptico = partida.criptico
  end

  def calcular
    (base * factor_de_tiempo).round
  end

  def base
    puntos_del_tipo = PuntajePorTipo.find_by!(tipo: @criptico.tipo).puntos
    multiplicador = MultiplicadorDificultad.find_by!(dificultad: @criptico.dificultad).valor

    puntos_del_tipo * multiplicador.to_f
  end

  def factor_de_tiempo
    referencia = TIEMPOS_DE_REFERENCIA.fetch(@criptico.dificultad)
    segundos = @partida.segundos_jugados
    return 1.0 if segundos <= referencia

    [ referencia.to_f / segundos, FACTOR_DE_TIEMPO_MINIMO ].max
  end
end
