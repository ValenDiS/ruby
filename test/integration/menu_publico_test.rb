require "test_helper"

class MenuPublicoTest < ActionDispatch::IntegrationTest
  # El inicio todavía pide login hasta que el issue 4 lo haga público; por eso se entra logueado.
  test "el layout público muestra el menú con las cuatro secciones" do
    sign_in_as(users(:admin))

    get root_path

    assert_response :success
    assert_select "nav[aria-label='Menú del sitio']" do
      assert_select "a.navbar-brand[href=?]", root_path
      assert_select "a.nav-link[href=?]", new_partida_path, "Jugar"
      assert_select ".nav-link", "Mi racha"
      assert_select ".nav-link", "Tabla de posiciones"
      assert_select "a.nav-link[href=?]", chatbot_path, "Cómo se juega"
    end
  end
end
