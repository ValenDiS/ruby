require "test_helper"

class RecorridoChatbotTest < ActiveSupport::TestCase
  def cargar_recorrido
    load Rails.root.join("db/seeds/chatbot.rb")
  end

  test "todos los temas se alcanzan desde la bienvenida y ofrecen volver al menú" do
    cargar_recorrido
    menu = NodoChatbot.find_by!(clave: "bienvenida")
    pendientes = [ menu ]
    visitados = Set.new

    until pendientes.empty?
      nodo = pendientes.shift
      next unless visitados.add?(nodo.clave)

      opciones = nodo.opciones.includes(:destino)
      unless nodo == menu
        assert opciones.any? { |opcion| opcion.texto == "Volver al menú" && opcion.destino == menu }, nodo.clave
      end
      pendientes.concat(opciones.map(&:destino))
    end

    esperados = %w[bienvenida que_es partes tipos puntaje pistas rachas] + Criptico::TIPOS
    assert_equal esperados.to_set, visitados
    assert_equal NodoChatbot.count, visitados.size
  end

  test "cada tipo tiene un ejemplo propio distinto de los enunciados del catálogo completo" do
    cargar_recorrido
    catalogo = JSON.parse(File.read(Rails.root.join("test/fixtures/files/cryptics.json")))
    enunciados = catalogo.fetch("cripticos").map { |dato| NormalizadorDeTexto.normalizar(dato.fetch("enunciado")) }

    Criptico::TIPOS.each do |tipo|
      ejemplo = NodoChatbot.find_by!(clave: tipo).ejemplo
      assert_predicate ejemplo, :present?, tipo
      texto = NormalizadorDeTexto.normalizar(ejemplo)
      assert enunciados.none? { |enunciado| texto.include?(enunciado) }, tipo
    end
  end

  test "si un ejemplo ya está en el catálogo activo se carga la regla sin revelar la solución" do
    Criptico.create!(id_fuente: "ejemplo-oculto", enunciado: "El mapa nuevo esconde un alimento",
                     respuesta: "PAN", enumeracion: "(3)", tipo: "oculta", dificultad: "facil",
                     definiciones: [ "un alimento" ], indicadores: [ "esconde" ], material: [ "mapa nuevo" ])
    cargar_recorrido

    nodo = NodoChatbot.find_by!(clave: "oculta")
    assert_nil nodo.ejemplo
    assert_predicate nodo.mensaje, :present?
  end

  test "repetir los seeds conserva el contenido y los enlaces editados" do
    cargar_recorrido
    menu = NodoChatbot.find_by!(clave: "bienvenida")
    menu.update!(mensaje: "Elegí un tema")
    opcion = menu.opciones.first
    destino = NodoChatbot.find_by!(clave: "inversion")
    opcion.update!(texto: "Practicar inversión", destino: destino)

    assert_no_difference [ "NodoChatbot.count", "OpcionChatbot.count" ] do
      cargar_recorrido
    end
    assert_equal "Elegí un tema", menu.reload.mensaje
    assert_equal "Practicar inversión", opcion.reload.texto
    assert_equal destino, opcion.destino
  end
end
