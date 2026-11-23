require "test_helper"

class CalculadorDePuntajeTest < ActiveSupport::TestCase
  setup do
    travel_to Time.zone.local(2026, 11, 20, 12, 0)
    @jugador = Jugador.create!(nombre: "Puntero")
  end

  # Partida resuelta en memoria: no hace falta guardarla para calcular.
  # Sin días jugados antes, la racha contando hoy es 1.
  def partida(dificultad:, segundos:, tipo: "anagrama", pistas: 0)
    inicio = Time.current - segundos
    Partida.new(jugador: @jugador, criptico: Criptico.new(tipo: tipo, dificultad: dificultad),
                iniciado_at: inicio, resuelto_at: Time.current, pistas_usadas: pistas)
  end

  # Guarda una partida resuelta en cada uno de los días anteriores a hoy.
  def jugar_dias_anteriores(cantidad)
    cantidad.times do |numero|
      criptico = cripticos(:mate).dup
      criptico.update!(id_fuente: "cr-puntaje-#{numero}")
      dia = (numero + 1).days.ago
      @jugador.partidas.create!(criptico: criptico, iniciado_at: dia - 1.minute, resuelto_at: dia)
    end
  end

  test "la base es puntos del tipo por multiplicador de la dificultad" do
    assert_equal 100, CalculadorDePuntaje.new(partida(dificultad: "facil", segundos: 10)).base
    assert_equal 200, CalculadorDePuntaje.new(partida(dificultad: "medio", segundos: 10)).base
    assert_equal 300, CalculadorDePuntaje.new(partida(dificultad: "avanzado", segundos: 10)).base
  end

  test "la base usa los valores configurados en el admin" do
    puntajes_por_tipo(:anagrama).update!(puntos: 150)
    multiplicadores_dificultad(:medio).update!(valor: 2.5)

    assert_equal 375, CalculadorDePuntaje.new(partida(dificultad: "medio", segundos: 10)).base
  end

  test "dentro del tiempo de referencia el factor es 1" do
    assert_equal 1, CalculadorDePuntaje.new(partida(dificultad: "facil", segundos: 60)).factor_de_tiempo
    assert_equal 1, CalculadorDePuntaje.new(partida(dificultad: "medio", segundos: 180)).factor_de_tiempo
    assert_equal 1, CalculadorDePuntaje.new(partida(dificultad: "avanzado", segundos: 300)).factor_de_tiempo
  end

  test "si tarda más, el factor es referencia dividido lo que tardó" do
    assert_equal 0.75, CalculadorDePuntaje.new(partida(dificultad: "medio", segundos: 240)).factor_de_tiempo
    assert_equal 0.5, CalculadorDePuntaje.new(partida(dificultad: "facil", segundos: 120)).factor_de_tiempo
  end

  test "el factor de tiempo nunca baja de 0,25" do
    assert_equal 0.25, CalculadorDePuntaje.new(partida(dificultad: "facil", segundos: 3.hours)).factor_de_tiempo
  end

  test "cada pista resta 0,20" do
    { 0 => 1, 1 => 0.8, 2 => 0.6, 3 => 0.4, 4 => 0.2 }.each do |pistas, factor|
      calculador = CalculadorDePuntaje.new(partida(dificultad: "facil", segundos: 10, pistas: pistas))
      assert_in_delta factor, calculador.factor_de_pistas, 0.001
    end
  end

  test "la racha cuenta el día de hoy" do
    assert_in_delta 1.05, CalculadorDePuntaje.new(partida(dificultad: "facil", segundos: 10)).factor_de_racha, 0.001

    jugar_dias_anteriores(1)
    assert_in_delta 1.10, CalculadorDePuntaje.new(partida(dificultad: "facil", segundos: 10)).factor_de_racha, 0.001
  end

  test "el factor de racha llega como máximo a 1,5" do
    jugar_dias_anteriores(12)

    assert_equal 1.5, CalculadorDePuntaje.new(partida(dificultad: "facil", segundos: 10)).factor_de_racha
  end

  test "ejemplo del enunciado: medio, 240 s, 1 pista y 4 días de racha da 144" do
    jugar_dias_anteriores(3)

    assert_equal 144, CalculadorDePuntaje.new(partida(dificultad: "medio", segundos: 240, pistas: 1)).calcular
  end

  test "redondea al entero más cercano" do
    # 100 × 0,75 × 1 × 1,05 = 78,75
    assert_equal 79, CalculadorDePuntaje.new(partida(dificultad: "facil", segundos: 80)).calcular
  end

  test "una partida resuelta da como mínimo 10 puntos" do
    # 100 × 0,25 × 0,2 × 1,05 = 5,25
    assert_equal 10, CalculadorDePuntaje.new(partida(dificultad: "facil", segundos: 3.hours, pistas: 4)).calcular
  end

  test "rendirse da 0 puntos" do
    rendida = Partida.new(jugador: @jugador, criptico: cripticos(:mate),
                          iniciado_at: 1.minute.ago, rendido_at: Time.current)

    assert_equal 0, CalculadorDePuntaje.new(rendida).calcular
  end
end
