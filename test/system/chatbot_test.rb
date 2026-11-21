require "application_system_test_case"

class ChatbotTest < ApplicationSystemTestCase
  def teardown
    # Chrome rechaza el borrado del origen "*" de Capybara 3.40. Cerrar el navegador descarta la sesión.
    page.driver.quit
    super
  end

  test "un visitante recorre la guía, retoma el tema en otra página y vuelve al menú" do
    load Rails.root.join("db/seeds/chatbot.rb")
    visit root_path
    click_link "Cómo se juega"

    within "dialog[open]" do
      click_link "Los tipos de crípticos"
      click_link "Anagrama"
      assert_text "Con las cuatro letras de SACO podés formar CAOS."
      click_button "Cerrar"
    end
    assert_no_selector "dialog[open]"
    assert_current_path root_path

    visit chatbot_path(nodo: "partes")
    within "main" do
      assert_text "Buscá la definición"
    end
    within "nav" do
      click_link "Cómo se juega"
    end
    within "dialog[open]" do
      assert_text "Con las cuatro letras de SACO podés formar CAOS."
      click_link "Volver al menú"
      assert_text "¿Qué querés aprender?"
      find_button("Cerrar").send_keys(:escape)
    end
    assert_no_selector "dialog[open]"
    assert_current_path chatbot_path(nodo: "partes")
  end
end
