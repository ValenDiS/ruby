require "test_helper"

class ChatbotPublicoTest < ActionDispatch::IntegrationTest
  test "un nodo recordado que ya no existe vuelve a la bienvenida dentro del frame" do
    load Rails.root.join("db/seeds/chatbot.rb")
    get chatbot_path(nodo: "eliminado"), headers: { "Turbo-Frame" => "chatbot_nodo" }

    assert_response :success
    assert_select "turbo-frame#chatbot_nodo [data-chatbot-clave=bienvenida]"
    assert_select "dialog", count: 0
  end

  test "si la guía todavía no está cargada el visitante recibe un mensaje" do
    get chatbot_path

    assert_response :success
    assert_select "main p", "La guía todavía no está disponible."
  end

  test "un ejemplo deja de mostrarse si su enunciado pasa a ser jugable" do
    load Rails.root.join("db/seeds/chatbot.rb")
    Criptico.create!(id_fuente: "nueva-oculta", enunciado: "El mapa nuevo esconde un alimento",
                     respuesta: "PAN", enumeracion: "(3)", tipo: "oculta", dificultad: "facil",
                     definiciones: [ "un alimento" ], indicadores: [ "esconde" ], material: [ "mapa nuevo" ])
    get chatbot_path(nodo: "oculta"), headers: { "Turbo-Frame" => "chatbot_nodo" }

    assert_response :success
    assert_select "[data-chatbot-clave=oculta] p", text: /Leé el material de corrido/
    assert_no_match(/El mapa nuevo|se lee PAN/, response.body)
  end
end
