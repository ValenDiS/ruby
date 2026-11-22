require "test_helper"

class CalculadorDePuntajeTest < ActiveSupport::TestCase
  # Partida resuelta en memoria: no hace falta guardarla para calcular.
  def partida(dificultad:, segundos:, tipo: "anagrama")
    inicio = Time.current
    Partida.new(criptico: Criptico.new(tipo: tipo, dificultad: dificultad),
                iniciado_at: inicio, resuelto_at: inicio + segundos)
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

  test "calcula base por tiempo y redondea" do
    assert_equal 150, CalculadorDePuntaje.new(partida(dificultad: "medio", segundos: 240)).calcular
    assert_equal 43, CalculadorDePuntaje.new(partida(dificultad: "facil", segundos: 140)).calcular
  end
end
