require "test_helper"

class ConfiguracionTest < ActiveSupport::TestCase
  test "actual devuelve siempre la misma fila" do
    assert_equal configuraciones(:actual), Configuracion.actual
    assert_no_difference("Configuracion.count") { Configuracion.actual }
  end

  test "la URL tiene que ser http o https" do
    configuracion = Configuracion.actual

    assert_not configuracion.update(url_fuente: "ftp://algo.com/cryptics.json")
    assert_not configuracion.update(url_fuente: "")
    assert configuracion.update(url_fuente: "http://localhost:8000/v1/cryptics_with_errors.json")
  end

  test "el texto de bienvenida es obligatorio" do
    assert_not Configuracion.actual.update(texto_bienvenida: "")
  end

  test "la base no permite una segunda fila" do
    assert_raises(ActiveRecord::StatementInvalid) { Configuracion.create!(id: 2) }
  end
end
