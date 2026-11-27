require "test_helper"

class RespuestasYRendicionTest < ActionDispatch::IntegrationTest
  setup do
    post jugador_path, params: { jugador: { nombre: "Nueva" } }
    @jugador = Jugador.find_by!(nombre: "Nueva")
    post partidas_path, params: { dificultad: "facil" }
    @partida = @jugador.partidas.sole
    post iniciar_partida_path(@partida)
    @partida.reload
  end

  test "el formulario muestra los intentos restantes y un fallo no revela la solución" do
    get partida_path(@partida)
    assert_select "#intentos-restantes", text: "Intentos restantes: 5"
    assert_select "input[name='intento[intentos_previos]'][value='0']"
    assert_select "form[action=?]", rendirse_partida_path(@partida)

    responder("CASA", headers: { "Accept" => "text/vnd.turbo-stream.html, text/html" })

    assert_response :unprocessable_entity
    assert_equal "text/html", response.media_type
    assert_select "#intentos-restantes", text: "Intentos restantes: 4"
    assert_select "input[name='intento[intentos_previos]'][value='1']"
    assert_select "input[name='intento[respuesta]'][value='']"
    assert_no_solucion
    assert_equal 1, @partida.reload.intentos
  end

  test "respuestas vacías y contadores alterados no consumen intentos" do
    responder("?!123")
    assert_response :unprocessable_entity
    assert_equal 0, @partida.reload.intentos
    assert_select "[role=alert]", text: /No se consumió ningún intento/

    [ nil, "0falso", "-1", "99", "1" ].each do |contador|
      responder("CASA", contador: contador)
      assert_response :conflict
      assert_equal 0, @partida.reload.intentos
    end
  end

  test "un formulario repetido no consume dos intentos ni cambia el reloj" do
    inicio = @partida.iniciado_at
    responder("CASA", contador: "0")
    responder("CASA", contador: "0")

    assert_response :conflict
    assert_equal 1, @partida.reload.intentos
    assert_equal inicio, @partida.iniciado_at
    assert_select "input[name='intento[intentos_previos]'][value='1']"
    assert_no_solucion
  end

  test "cinco fallos dejan solo la rendición disponible y un sexto envío se rechaza" do
    5.times { |contador| responder("CASA", contador: contador.to_s) }

    assert_response :unprocessable_entity
    assert_select "#intentos-restantes", text: "Intentos restantes: 0"
    assert_select "form[action=?]", responder_partida_path(@partida), count: 0
    assert_select "form[action=?]", rendirse_partida_path(@partida)
    assert_no_solucion

    responder("MATE", contador: "5")
    assert_response :unprocessable_entity
    assert_equal 5, @partida.reload.intentos
    assert_not @partida.terminada?
    assert_no_solucion

    post rendirse_partida_path(@partida)
    assert_response :see_other
    follow_redirect!
    assert_select "h1", text: "Te rendiste"
    assert_select "strong", text: @partida.criptico.respuesta
    assert_equal 0, @partida.reload.puntos
  end

  test "un acierto usa el contrato de puntaje y conserva sus puntos al repetir operaciones" do
    llamadas = 0
    calculo = lambda do |partida|
      llamadas += 1
      assert Partida.find(partida.id).resuelta?
      144
    end

    con_calculador(calculo) do
      responder(" mÁ tE! ", extras: { puntos: 9000, resuelto_at: 10.days.ago.iso8601, intentos: 5 })
      assert_response :see_other
      assert_redirected_to partida_path(@partida)
      assert_equal 144, @partida.reload.puntos
      assert_equal 1, @partida.intentos
      originales = @partida.attributes
      follow_redirect!
      assert_select "h1", text: "Partida resuelta"
      assert_select "strong", text: @partida.criptico.respuesta
      assert_includes response.body, @partida.criptico.explicacion
      assert_select "form[action=?]", responder_partida_path(@partida), count: 0
      assert_select "form[action=?]", rendirse_partida_path(@partida), count: 0

      responder("MATE", contador: "0")
      assert_response :see_other
      post rendirse_partida_path(@partida)
      assert_response :see_other
      assert_equal 1, llamadas
      assert_equal originales, @partida.reload.attributes
    end
  end

  test "si el calculador falta o falla se revierte el cierre sin mostrar la solución" do
    originales = @partida.attributes
    stub_const(Object, :CalculadorDePuntaje, nil, exists: Object.const_defined?(:CalculadorDePuntaje)) do
      responder("MATE")
      assert_response :service_unavailable
      assert_equal originales, @partida.reload.attributes
      assert_no_solucion
      assert_select "input[name='intento[respuesta]'][value='']"
      assert_select "[role=alert]", text: /Tu intento no se consumió/
    end

    con_calculador(->(_) { raise "La dependencia falló" }) do
      responder("MATE")
      assert_response :service_unavailable
      assert_equal originales, @partida.reload.attributes
      assert_no_solucion
    end
  end

  test "rendirse no acepta puntos ni timestamps y no vuelve a cambiar el cierre" do
    responder("CASA")
    post rendirse_partida_path(@partida), params: { puntos: 9000, rendido_at: 10.days.ago.iso8601, intentos: 5 }

    assert_response :see_other
    assert @partida.reload.rendida?
    assert_equal 0, @partida.puntos
    assert_equal 1, @partida.intentos
    originales = @partida.attributes
    responder("MATE")
    assert_response :see_other
    post rendirse_partida_path(@partida)
    assert_equal originales, @partida.reload.attributes
  end

  test "no permite responder ni rendirse antes del inicio" do
    @partida.update!(iniciado_at: nil)

    responder("MATE")
    assert_response :conflict
    assert_no_solucion
    assert_not_includes response.body, @partida.criptico.enunciado
    post rendirse_partida_path(@partida)
    assert_response :conflict
    assert_no_solucion
    assert_not @partida.reload.terminada?
    assert_equal 0, @partida.intentos
  end

  test "otro navegador no puede responder ni rendirse por este jugador" do
    otra = open_session
    otra.post jugador_path, params: { jugador: { nombre: "Otra" } }
    otra.post responder_partida_path(@partida), params: { intento: { respuesta: "CASA", intentos_previos: "0" } }
    otra.assert_response :not_found
    otra.post rendirse_partida_path(@partida)
    otra.assert_response :not_found
    assert_equal 0, @partida.reload.intentos
    assert_not @partida.terminada?
  end

  test "un bloqueo impide responder y rendirse sin alterar la partida" do
    @jugador.update!(bloqueado: true)
    originales = @partida.attributes

    responder("CASA")
    assert_redirected_to root_path
    post rendirse_partida_path(@partida)
    assert_redirected_to root_path
    assert_equal originales, @partida.reload.attributes
  end

  private
    def responder(respuesta, contador: @partida.intentos.to_s, headers: {}, extras: {})
      post responder_partida_path(@partida), params: {
        intento: { respuesta: respuesta, intentos_previos: contador }.merge(extras)
      }, headers: headers
    end

    def con_calculador(calculo)
      falso = Class.new do
        define_method(:initialize) { |partida| @partida = partida }
        define_method(:calcular) { calculo.call(@partida) }
      end
      stub_const(Object, :CalculadorDePuntaje, falso, exists: Object.const_defined?(:CalculadorDePuntaje)) { yield }
    end

    def assert_no_solucion
      assert_not_includes response.body, @partida.criptico.respuesta
      assert_not_includes response.body, @partida.criptico.explicacion
      assert_not_includes response.body, @partida.criptico.ayuda
    end
end
