require "test_helper"

class FiltroDeCripticosTest < ActiveSupport::TestCase
  setup do
    @mate = cripticos(:mate)
    @gato = Criptico.create!(id_fuente: "prueba-gato", enunciado: "Felino o herramienta para cambiar la rueda",
                             enumeracion: "(4)", respuesta: "GATO", tipo: "doble_definicion", dificultad: "medio",
                             definiciones: [ "Felino", "herramienta para cambiar la rueda" ], indicadores: [], material: [],
                             origen: "Propio", activo: false)
  end

  def filtrar(**filtros)
    FiltroDeCripticos.new(**filtros).call.to_a
  end

  test "filtra por dificultad, tipo y origen" do
    assert_equal [ @mate ], filtrar(dificultad: "facil")
    assert_equal [ @gato ], filtrar(tipo: "doble_definicion", origen: "Propio")
  end

  test "filtra por estado" do
    assert_equal [ @gato ], filtrar(estado: "desactivado")
    assert_equal [ @mate ], filtrar(estado: "jugable")

    @mate.update!(en_fuente: false)
    assert_equal [ @mate ], filtrar(estado: "fuera_de_fuente")
  end

  test "ignora los filtros vacíos" do
    assert_equal 2, filtrar(dificultad: "", tipo: nil).size
  end
end
