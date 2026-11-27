require "test_helper"

class PuntajePorTipoTest < ActiveSupport::TestCase
  test "los puntos son un entero entre 10 y 1000" do
    puntaje = puntajes_por_tipo(:anagrama)

    assert puntaje.update(puntos: 10)
    assert puntaje.update(puntos: 1000)
    assert_not puntaje.update(puntos: 9)
    assert_not puntaje.update(puntos: 1001)
    assert_not puntaje.update(puntos: 50.5)
  end

  test "el tipo tiene que ser uno de los 13 y no repetirse" do
    assert_not PuntajePorTipo.new(tipo: "inventado", puntos: 100).valid?
    assert_not PuntajePorTipo.new(tipo: "anagrama", puntos: 100).valid?
  end

  test "la base rechaza puntos fuera de rango" do
    assert_raises(ActiveRecord::StatementInvalid) do
      puntajes_por_tipo(:anagrama).update_column(:puntos, 5)
    end
  end
end
