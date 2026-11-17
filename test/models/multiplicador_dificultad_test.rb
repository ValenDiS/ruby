require "test_helper"

class MultiplicadorDificultadTest < ActiveSupport::TestCase
  test "el valor es mayor que 0 y como máximo 5" do
    multiplicador = multiplicadores_dificultad(:facil)

    assert multiplicador.update(valor: 0.5)
    assert multiplicador.update(valor: 5)
    assert_not multiplicador.update(valor: 0)
    assert_not multiplicador.update(valor: 5.01)
  end

  test "la dificultad tiene que ser facil, medio o avanzado" do
    assert_not MultiplicadorDificultad.new(dificultad: "experto", valor: 1).valid?
  end

  test "la base rechaza un valor fuera de rango" do
    assert_raises(ActiveRecord::StatementInvalid) do
      multiplicadores_dificultad(:facil).update_column(:valor, 0)
    end
  end
end
