require "test_helper"

class IdentidadJugadorTest < ActionDispatch::IntegrationTest
  test "el visitante puede consultar inicio y guía sin elegir nombre" do
    get root_path
    assert_response :success
    assert_select "a[href=?]", new_jugador_path, text: "Elegir nombre"

    get chatbot_path
    assert_response :success
  end

  test "registra y recuerda al jugador sin exponer su token en el HTML" do
    get new_jugador_path
    assert_response :success

    assert_difference "Jugador.count", 1 do
      post jugador_path, params: { jugador: { nombre: "Nueva" } }
    end
    assert_redirected_to root_path
    assert_response :see_other
    jugador = Jugador.find_by!(nombre: "Nueva")
    assert_match(/httponly/i, response.headers["set-cookie"].to_s)
    assert_match(/samesite=lax/i, response.headers["set-cookie"].to_s)
    assert cookies[:jugador_token].present?
    assert_not_equal jugador.token, cookies[:jugador_token]

    follow_redirect!
    assert_select "strong", text: "Nueva"
    assert_not_includes response.body, jugador.token

    get new_jugador_path
    assert_redirected_to root_path
  end

  test "un nombre tomado muestra errores y una sugerencia sin identificar al visitante" do
    assert_no_difference "Jugador.count" do
      post jugador_path, params: { jugador: { nombre: "PEDRITO" } }
    end

    assert_response :unprocessable_entity
    assert_select "[role=status] strong", text: "PEDRITO_2"
    assert_nil cookies[:jugador_token]
  end

  test "ignora atributos que corresponden al servidor" do
    post jugador_path, params: { jugador: { nombre: "Segura", token: "elegido", bloqueado: true,
                                           nombre_normalizado: "nombre-ajeno" } }

    jugador = Jugador.find_by!(nombre: "Segura")
    assert_not jugador.bloqueado?
    assert_not_equal "elegido", jugador.token
    assert_equal "segura", jugador.nombre_normalizado
  end

  test "en HTTPS la cookie se transmite solo por conexiones seguras" do
    https!
    post jugador_path, params: { jugador: { nombre: "Segura" } }

    assert_match(/secure/i, response.headers["set-cookie"].to_s)
  end

  test "una cookie alterada o un token sin firma no recupera la identidad" do
    [ "cookie-alterada", jugadores(:pedrito).token ].each do |valor|
      cookies[:jugador_token] = valor
      get new_jugador_path

      assert_response :success
      assert_empty cookies[:jugador_token].to_s
    end
  end

  test "una cookie de un jugador inexistente permite volver a elegir nombre" do
    post jugador_path, params: { jugador: { nombre: "Temporal" } }
    Jugador.find_by!(nombre: "Temporal").destroy!

    get new_jugador_path

    assert_response :success
    assert_empty cookies[:jugador_token].to_s
  end

  test "repetir el alta con una identidad vigente no crea otro jugador" do
    post jugador_path, params: { jugador: { nombre: "Primera" } }
    cookie_original = cookies[:jugador_token]

    assert_no_difference "Jugador.count" do
      post jugador_path, params: { jugador: { nombre: "Segunda" } }
    end

    assert_redirected_to root_path
    assert_equal cookie_original, cookies[:jugador_token]
  end

  test "dos navegadores conservan jugadores diferentes" do
    post jugador_path, params: { jugador: { nombre: "Primera" } }
    otra_sesion = open_session
    otra_sesion.post jugador_path, params: { jugador: { nombre: "Segunda" } }

    get root_path
    assert_select "strong", text: "Primera"
    otra_sesion.get root_path
    otra_sesion.assert_select "strong", text: "Segunda"
  end
end
