# Calcula los puntos de una partida.
#
#   CalculadorDePuntaje.new(partida).calcular  # => 144
#
# puntos = base × tiempo × pistas × racha
#   base:   puntos del tipo × multiplicador de la dificultad (se configuran en el admin)
#   tiempo: 1 si resolvió dentro del tiempo de referencia; si tardó más,
#           referencia ÷ segundos, sin bajar de 0,25
#   pistas: cada pista resta 0,20
#   racha:  cada día de racha (contando hoy) suma 0,05, hasta 1,5
#
# Si el críptico era el críptico del día (el día en que se resolvió), vale el doble.
# Se redondea al entero más cercano. Una partida resuelta da como mínimo 10 puntos
# y una rendida da 0.
class CalculadorDePuntaje
  TIEMPOS_DE_REFERENCIA = { "facil" => 60, "medio" => 180, "avanzado" => 300 }.freeze
  FACTOR_DE_TIEMPO_MINIMO = 0.25
  DESCUENTO_POR_PISTA = 0.20
  BONUS_POR_DIA_DE_RACHA = 0.05
  FACTOR_DE_RACHA_MAXIMO = 1.5
  PUNTOS_MINIMOS = 10
  MULTIPLICADOR_CRIPTICO_DEL_DIA = 2

  def initialize(partida)
    @partida = partida
    @criptico = partida.criptico
  end

  def calcular
    return 0 if @partida.rendida?

    puntos = (base * factor_de_tiempo * factor_de_pistas * factor_de_racha * factor_del_dia).round
    [ puntos, PUNTOS_MINIMOS ].max
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

  def factor_de_pistas
    1 - DESCUENTO_POR_PISTA * @partida.pistas_usadas
  end

  def factor_de_racha
    dias = CalculadorDeRacha.new(@partida.jugador).contando_hoy
    [ 1 + BONUS_POR_DIA_DE_RACHA * dias, FACTOR_DE_RACHA_MAXIMO ].min
  end

  def factor_del_dia
    del_dia = CripticoDelDia.new(@partida.resuelto_at.to_date).es?(@criptico)
    del_dia ? MULTIPLICADOR_CRIPTICO_DEL_DIA : 1
  end
end
