require "test_helper"

class FlujoDePartidasTest < ActionDispatch::IntegrationTest
  test "jugar desde cualquier página pide nombre si todavía no hay identidad" do
    get chatbot_path
    assert_select "nav a[href=?]", new_partida_path, text: "Jugar"

    get new_partida_path
    assert_redirected_to new_jugador_path

    assert_no_difference "Partida.count" do
      post partidas_path, params: { dificultad: "facil" }
      assert_redirected_to new_jugador_path
      post iniciar_partida_path(partidas(:resuelta))
      assert_redirected_to new_jugador_path
    end
  end

  test "elige dificultad y confirma Jugar antes de recibir el enunciado" do
    jugador = registrar_jugador
    criptico = cripticos(:mate)
    get new_partida_path
    assert_response :success
    assert_select "input[type=radio][name=dificultad]", count: 3
    assert_select "label", text: "Fácil"
    assert_select "label", text: "Medio"
    assert_select "label", text: "Avanzado"

    assert_difference "Partida.count", 1 do
      post partidas_path, params: { dificultad: "facil", jugador_id: jugadores(:pedrito).id,
                                   iniciado_at: 2.days.ago.iso8601, puntos: 9000 }
    end

    partida = jugador.partidas.sole
    assert_response :see_other
    assert_redirected_to partida_path(partida)
    follow_redirect!
    assert_response :success
    assert_select "form[action=?] button", iniciar_partida_path(partida), text: "Jugar"
    assert_not_includes response.body, criptico.enunciado
    assert_not_includes response.body, criptico.enumeracion
    assert_no_solucion(criptico)
    assert_nil partida.reload.iniciado_at
    assert_nil partida.puntos
    assert_equal jugador.id, partida.jugador_id

    travel_to Time.zone.local(2026, 11, 22, 15, 30) do
      post iniciar_partida_path(partida), params: { iniciado_at: 10.days.ago.iso8601, puntos: 9000, intentos: 4 }
      assert_response :see_other
      assert_redirected_to partida_path(partida)
      assert_equal Time.current, partida.reload.iniciado_at
      assert_equal 0, partida.intentos
      assert_nil partida.puntos
      follow_redirect!
      assert_select "#enunciado-criptico", text: "#{criptico.enunciado} #{criptico.enumeracion}"
      assert_select "[data-controller=cronometro][data-cronometro-transcurrido-value='0']"
      assert_no_solucion(criptico)
    end
  end

  test "volver retoma la partida pendiente sin revelar el enunciado ni iniciar el reloj" do
    jugador = registrar_jugador
    post partidas_path, params: { dificultad: "facil" }
    partida = jugador.partidas.sole

    assert_no_difference "Partida.count" do
      get new_partida_path
      assert_redirected_to partida_path(partida)
      follow_redirect!
      get partida_path(partida)
    end

    assert_nil partida.reload.iniciado_at
    assert_not_includes response.body, partida.criptico.enunciado
  end

  test "volver a jugar y repetir el botón no reinicia el tiempo" do
    jugador = registrar_jugador
    post partidas_path, params: { dificultad: "facil" }
    partida = jugador.partidas.sole
    inicio = Time.zone.local(2026, 11, 22, 15, 30)
    travel_to(inicio) { post iniciar_partida_path(partida) }

    travel_to inicio + 125.seconds do
      assert_no_difference "Partida.count" do
        get new_partida_path
        assert_redirected_to partida_path(partida)
        follow_redirect!
        assert_select "[data-cronometro-transcurrido-value='125'] [data-cronometro-target=reloj]", text: "00:02:05"
        post partidas_path, params: { dificultad: "avanzado" }
        assert_redirected_to partida_path(partida)
        post iniciar_partida_path(partida)
      end

      assert_equal inicio, partida.reload.iniciado_at
      get partida_path(partida)
      assert_no_solucion(partida.criptico)
    end
  end

  test "una dificultad inválida o agotada informa el error sin crear partidas" do
    registrar_jugador

    [ nil, "experto", "medio" ].each do |dificultad|
      assert_no_difference "Partida.count" do
        post partidas_path, params: { dificultad: dificultad }
      end

      assert_response :unprocessable_entity
      assert_select "[role=alert]", text: dificultad == "medio" ? /No hay crípticos disponibles/ : /Elegí una dificultad válida/
      assert_select "input[type=radio][name=dificultad]", count: 3
    end
  end

  test "otro navegador no puede consultar ni iniciar una partida ajena" do
    jugador = registrar_jugador
    post partidas_path, params: { dificultad: "facil" }
    partida = jugador.partidas.sole
    otra_sesion = open_session
    otra_sesion.post jugador_path, params: { jugador: { nombre: "Otra" } }

    otra_sesion.get partida_path(partida)
    otra_sesion.assert_response :not_found
    otra_sesion.post iniciar_partida_path(partida)
    otra_sesion.assert_response :not_found
    assert_nil partida.reload.iniciado_at
  end

  test "el bloqueo impide elegir dificultad, consultar o iniciar una partida" do
    jugador = registrar_jugador
    post partidas_path, params: { dificultad: "facil" }
    partida = jugador.partidas.sole
    jugador.update!(bloqueado: true)

    get new_partida_path
    assert_redirected_to root_path
    get partida_path(partida)
    assert_redirected_to root_path
    post iniciar_partida_path(partida)
    assert_redirected_to root_path
    assert_nil partida.reload.iniciado_at
  end

  test "las páginas de juego no se guardan en caché ni ofrecen JSON con datos del críptico" do
    jugador = registrar_jugador
    get new_partida_path
    assert_equal "no-store", response.headers["Cache-Control"]
    assert_select "meta[name=turbo-cache-control][content=no-cache]"
    post partidas_path, params: { dificultad: "facil" }
    partida = jugador.partidas.sole
    get partida_path(partida)
    assert_equal "no-store", response.headers["Cache-Control"]
    assert_select "meta[name=turbo-cache-control][content=no-cache]"

    get partida_path(partida, format: :json)
    assert_response :not_acceptable
    assert_not_includes response.body, partida.criptico.respuesta
  end

  test "solo una partida terminada revela su solución y no se puede reiniciar" do
    jugador = registrar_jugador
    post partidas_path, params: { dificultad: "facil" }
    partida = jugador.partidas.sole
    partida.update!(iniciado_at: 2.minutes.ago, resuelto_at: 1.minute.ago, puntos: 100)
    originales = partida.attributes

    get partida_path(partida)
    assert_select "strong", text: partida.criptico.respuesta
    assert_includes response.body, partida.criptico.explicacion
    assert_select "[data-controller=cronometro]", count: 0
    post iniciar_partida_path(partida)
    assert_redirected_to partida_path(partida)
    assert_equal originales, partida.reload.attributes
  end

  private
    def registrar_jugador
      post jugador_path, params: { jugador: { nombre: "Nueva" } }
      Jugador.find_by!(nombre: "Nueva")
    end

    def assert_no_solucion(criptico)
      assert_not_includes response.body, criptico.respuesta
      assert_not_includes response.body, criptico.explicacion
      assert_not_includes response.body, criptico.ayuda
    end
end
