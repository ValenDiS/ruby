require "test_helper"

class NormalizadorDeTextoTest < ActiveSupport::TestCase
  test "compara respuestas ignorando tildes, mayúsculas, espacios y signos" do
    [ "jamon", "Jamón", " JAMÓN! ", "jaMo\u0301n" ].each do |respuesta|
      assert_equal "JAMON", NormalizadorDeTexto.normalizar(respuesta)
    end
  end

  test "conserva la eñe incluso en unicode descompuesto" do
    [ "Ñandú", "N\u0303andu\u0301", " ñANdU " ].each do |respuesta|
      assert_equal "ÑANDU", NormalizadorDeTexto.normalizar(respuesta)
    end

    assert_not_equal NormalizadorDeTexto.normalizar("AÑO"), NormalizadorDeTexto.normalizar("ANO")
  end
end
