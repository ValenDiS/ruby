require "test_helper"

class GestionDeJugadorTest < ActionDispatch::IntegrationTest
  test "un visitante sin identidad debe elegir nombre antes de gestionar un jugador" do
    get edit_jugador_path
    assert_redirected_to new_jugador_path

    get new_cambio_de_jugador_path
    assert_redirected_to new_jugador_path

    assert_no_difference "Jugador.count" do
      patch jugador_path, params: { jugador: { nombre: "Otro" } }
      assert_redirected_to new_jugador_path

      post cambio_de_jugador_path, params: { jugador: { nombre: "Otro" }, confirmacion: "1" }
      assert_redirected_to new_jugador_path
    end
  end

  test "cambia su nombre sin cambiar el jugador ni la cookie" do
    jugador = registrar_jugador
    cookie_original = cookies[:jugador_token]
    token_original = jugador.token
    get edit_jugador_path
    assert_response :success
    assert_select "form[action=?] input[name='jugador[nombre]'][value='Primera']", jugador_path

    assert_no_difference "Jugador.count" do
      patch jugador_path, params: { jugador: { nombre: "Renombrada" } }
    end

    assert_response :see_other
    assert_redirected_to root_path
    assert_equal "Renombrada", jugador.reload.nombre
    assert_equal token_original, jugador.token
    assert_equal cookie_original, cookies[:jugador_token]
    follow_redirect!
    assert_select "strong", text: "Renombrada"
    assert_select "[role=status]", text: "Tu nombre fue actualizado."
  end

  test "un nombre ocupado muestra sugerencia sin modificar a ninguno de los jugadores" do
    jugador = registrar_jugador
    cookie_original = cookies[:jugador_token]
    patch jugador_path, params: { jugador: { nombre: "PEDRITO" } }

    assert_response :unprocessable_entity
    assert_select "[role=status] strong", text: "PEDRITO_2"
    assert_equal "Primera", jugador.reload.nombre
    assert_equal "Pedrito", jugadores(:pedrito).reload.nombre
    assert_equal cookie_original, cookies[:jugador_token]
  end

  test "el cambio de nombre ignora identificadores, tokens y permisos enviados por el cliente" do
    jugador = registrar_jugador
    jugador.update!(bloqueado: true)
    token_original = jugador.token

    patch jugador_path, params: { id: jugadores(:pedrito).id, jugador: {
      id: jugadores(:pedrito).id, nombre: "Renombrada", token: "elegido", bloqueado: false,
      nombre_normalizado: "pedrito"
    } }

    assert_redirected_to root_path
    assert_equal "Renombrada", jugador.reload.nombre
    assert_equal "renombrada", jugador.nombre_normalizado
    assert_equal token_original, jugador.token
    assert jugador.bloqueado?
    assert_equal "Pedrito", jugadores(:pedrito).reload.nombre
  end

  test "abrir la confirmación y cancelarla no cambia la identidad" do
    jugador = registrar_jugador
    originales = jugador.attributes
    cookie_original = cookies[:jugador_token]

    assert_no_difference "Jugador.count" do
      get new_cambio_de_jugador_path
      assert_response :success
      assert_select "[role=alert]", text: /No vas a poder recuperar el acceso/
      assert_select "input[type=checkbox][name=confirmacion][required]"
      assert_select "a[href=?]", root_path, text: "Cancelar y seguir con mi jugador"
      get root_path
    end

    assert_equal originales, jugador.reload.attributes
    assert_equal cookie_original, cookies[:jugador_token]
    assert_select "strong", text: "Primera"
  end

  test "el servidor exige confirmar aunque se omita la validación del navegador" do
    jugador = registrar_jugador
    cookie_original = cookies[:jugador_token]
    token_original = jugador.token

    assert_no_difference "Jugador.count" do
      post cambio_de_jugador_path, params: { jugador: { nombre: "Segunda" }, jugador_anterior_id: jugador.id }
    end

    assert_response :unprocessable_entity
    assert_select "#errores-jugador", text: /Confirmá que querés empezar/
    assert_equal cookie_original, cookies[:jugador_token]
    assert_equal token_original, jugador.reload.token
  end

  test "un nombre ocupado durante el cambio conserva la identidad actual" do
    jugador = registrar_jugador
    cookie_original = cookies[:jugador_token]
    token_original = jugador.token

    assert_no_difference "Jugador.count" do
      post cambio_de_jugador_path, params: { jugador: { nombre: "Pedrito" }, confirmacion: "1",
                                            jugador_anterior_id: jugador.id }
    end

    assert_response :unprocessable_entity
    assert_select "[role=status] strong", text: "Pedrito_2"
    assert_equal cookie_original, cookies[:jugador_token]
    assert_equal token_original, jugador.reload.token
  end

  test "confirmar reemplaza la identidad y las cookies anteriores ya no dan acceso" do
    anterior = registrar_jugador
    token_anterior = anterior.token
    cookie_anterior = cookies[:jugador_token]
    otra_sesion = open_session
    otra_sesion.cookies[:jugador_token] = cookie_anterior

    assert_difference "Jugador.count", 1 do
      post cambio_de_jugador_path, params: { jugador: { nombre: "Segunda" }, confirmacion: "1",
                                            jugador_anterior_id: anterior.id }
    end

    assert_response :see_other
    assert_redirected_to root_path
    assert_equal "Primera", anterior.reload.nombre
    assert_not_equal token_anterior, anterior.token
    assert_not_equal cookie_anterior, cookies[:jugador_token]
    follow_redirect!
    assert_select "strong", text: "Segunda"

    otra_sesion.get root_path
    otra_sesion.assert_select "a[href=?]", new_jugador_path, text: "Elegir nombre"
    otra_sesion.assert_select "strong", text: "Primera", count: 0
  end

  test "una confirmación de otra identidad o de una pestaña anterior no retira el jugador actual" do
    anterior = registrar_jugador
    get new_cambio_de_jugador_path
    assert_select "input[type=hidden][name=jugador_anterior_id][value=?]", anterior.id.to_s

    post cambio_de_jugador_path, params: { jugador: { nombre: "Segunda" }, confirmacion: "1",
                                          jugador_anterior_id: anterior.id }
    assert_redirected_to root_path
    actual = Jugador.find_by!(nombre: "Segunda")
    cookie_actual = cookies[:jugador_token]
    token_actual = actual.token

    assert_no_difference "Jugador.count" do
      post cambio_de_jugador_path, params: { jugador: { nombre: "Tercera" }, confirmacion: "1",
                                            jugador_anterior_id: anterior.id }
    end

    assert_response :unprocessable_entity
    assert_equal cookie_actual, cookies[:jugador_token]
    assert_equal token_actual, actual.reload.token
    get root_path
    assert_select "strong", text: "Segunda"
  end

  private
    def registrar_jugador
      post jugador_path, params: { jugador: { nombre: "Primera" } }
      assert_redirected_to root_path
      Jugador.find_by!(nombre: "Primera")
    end
end
