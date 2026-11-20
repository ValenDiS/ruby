require "test_helper"
require "socket"

class SincronizadorDeCripticosTest < ActiveSupport::TestCase
  URL = "https://ejemplo.test/v1/cryptics.json".freeze

  setup do
    Criptico.delete_all # arrancamos con la base vacía, sin fixtures
  end

  # Cliente HTTP falso: devuelve el contenido de un archivo de test/fixtures/files.
  def cliente_con(archivo)
    contenido = file_fixture(archivo).read
    ->(_url) { contenido }
  end

  def cliente_con_json(hash)
    ->(_url) { hash.to_json }
  end

  def sincronizar(cliente)
    SincronizadorDeCripticos.new(url: URL, cliente_http: cliente).call
  end

  def catalogo
    JSON.parse(file_fixture("cryptics.json").read)
  end

  test "carga el catálogo completo de la cátedra" do
    sinc = sincronizar(cliente_con("cryptics.json"))

    assert sinc.exitosa?, sinc.resumen
    assert_equal 34, sinc.creados
    assert_equal 0, sinc.rechazados
    assert_equal 34, Criptico.jugables.count
    assert_equal({ "facil" => 12, "medio" => 13, "avanzado" => 9 }, Criptico.group(:dificultad).count)
  end

  test "es idempotente: sincronizar dos veces no duplica nada" do
    sincronizar(cliente_con("cryptics.json"))
    segunda = sincronizar(cliente_con("cryptics.json"))

    assert segunda.sin_cambios?
    assert_equal 34, Criptico.count
  end

  test "con otra versión pero el mismo contenido no crea ni actualiza nada" do
    sincronizar(cliente_con("cryptics.json"))
    otra = sincronizar(cliente_con_json(catalogo.merge("version" => "otra-version")))

    assert otra.exitosa?
    assert_equal [ 0, 0, 0 ], [ otra.creados, otra.actualizados, otra.desactivados ]
    assert_equal 34, Criptico.count
  end

  test "actualiza un críptico que cambió" do
    sincronizar(cliente_con("cryptics.json"))
    datos = catalogo.merge("version" => "v2")
    datos["cripticos"].first["ayuda"] = "Una ayuda nueva"

    sinc = sincronizar(cliente_con_json(datos))

    assert_equal 1, sinc.actualizados
    assert_equal "Una ayuda nueva", Criptico.find_by!(id_fuente: "cr-001").ayuda
  end

  test "desactiva (no borra) los que ya no vienen y los reactiva si vuelven" do
    sincronizar(cliente_con("cryptics.json"))
    datos = catalogo.merge("version" => "v2")
    datos["cripticos"].reject! { |c| c["id"] == "cr-034" }

    sinc = sincronizar(cliente_con_json(datos))
    assert_equal 1, sinc.desactivados
    assert_not Criptico.find_by!(id_fuente: "cr-034").jugable?
    assert_equal 34, Criptico.count

    vuelta = sincronizar(cliente_con_json(catalogo.merge("version" => "v3")))
    assert_equal 1, vuelta.actualizados
    assert Criptico.find_by!(id_fuente: "cr-034").jugable?
  end

  test "no reactiva un críptico que el admin desactivó a mano" do
    sincronizar(cliente_con("cryptics.json"))
    Criptico.find_by!(id_fuente: "cr-001").update!(activo: false)

    sincronizar(cliente_con_json(catalogo.merge("version" => "v2")))

    assert_not Criptico.find_by!(id_fuente: "cr-001").activo?
  end

  test "el catálogo con errores carga los válidos y reporta los rechazados con id y motivo" do
    sinc = sincronizar(cliente_con("cryptics_with_errors.json"))

    # Solo el primer cr-101 es válido. Los demás tienen un error cada uno:
    # cr-102 enumeración, cr-103 anagrama, cr-104 sin respuesta,
    # cr-105 tipo/dificultad, cr-101 repetido, cr-107 definición fuera del enunciado.
    assert sinc.exitosa?
    assert_equal 1, sinc.creados
    assert_equal 6, sinc.rechazados
    assert_equal %w[cr-102 cr-103 cr-104 cr-105 cr-101 cr-107], sinc.detalle_rechazados.map { |r| r["id"] }
    assert sinc.detalle_rechazados.all? { |r| r["motivo"].present? }
    assert_match(/repetido/, sinc.detalle_rechazados[4]["motivo"])
    assert_equal [ "cr-101" ], Criptico.pluck(:id_fuente)
  end

  test "error de red: no toca nada e informa el error" do
    sincronizar(cliente_con("cryptics.json"))
    caido = ->(_url) { raise Net::OpenTimeout }

    sinc = sincronizar(caido)

    assert sinc.fallida?
    assert_match(/tiempo de espera/, sinc.mensaje_error)
    assert_equal 34, Criptico.jugables.count
  end

  test "JSON inválido: no toca nada e informa el error" do
    sinc = sincronizar(->(_url) { "<html>no es json</html>" })

    assert sinc.fallida?
    assert_match(/JSON/, sinc.mensaje_error)
    assert_equal 0, Criptico.count
  end

  test "JSON sin la lista de crípticos se informa como error" do
    sinc = sincronizar(cliente_con_json({ "version" => "x" }))

    assert sinc.fallida?
    assert_equal 0, Criptico.count
  end

  test "una sincronización fallida no cuenta como última versión" do
    sincronizar(->(_url) { raise SocketError, "sin conexión" })
    sinc = sincronizar(cliente_con("cryptics.json"))

    assert sinc.exitosa?
  end

  test "registra el usuario que la hizo" do
    admin = Struct.new(:id).new(7)
    sinc = SincronizadorDeCripticos.new(url: URL, usuario: admin, cliente_http: cliente_con("cryptics.json")).call

    assert_equal 7, sinc.user_id
  end

  # ---------- Descarga real por HTTP (servidor local, sin internet) ----------

  # Levanta un servidor HTTP mínimo en 127.0.0.1 (puerto libre) que responde
  # según la ruta pedida. rutas: { "/ruta" => [ código, encabezados, cuerpo ] }.
  # Así se prueba el Net::HTTP de verdad sin depender de la API de la cátedra.
  def con_servidor(rutas)
    servidor = TCPServer.new("127.0.0.1", 0)
    hilo = Thread.new do
      loop do
        conexion = servidor.accept
        ruta = conexion.gets.to_s.split[1]
        loop { break if conexion.gets.to_s.chomp.empty? } # saltea los encabezados del pedido

        codigo, encabezados, cuerpo = rutas.fetch(ruta, [ 404, {}, "" ])
        conexion.write "HTTP/1.1 #{codigo} X\r\n"
        encabezados.merge("Content-Length" => cuerpo.bytesize, "Connection" => "close").each do |nombre, valor|
          conexion.write "#{nombre}: #{valor}\r\n"
        end
        conexion.write "\r\n#{cuerpo}"
        conexion.close
      end
    end

    yield "http://127.0.0.1:#{servidor.addr[1]}"
  ensure
    hilo&.kill
    servidor&.close
  end

  test "descarga por HTTP y sigue una redirección" do
    json = file_fixture("cryptics.json").read
    rutas = {
      "/viejo" => [ 301, { "Location" => "/v1/cryptics.json" }, "" ],
      "/v1/cryptics.json" => [ 200, { "Content-Type" => "application/json" }, json ]
    }

    con_servidor(rutas) do |base|
      sinc = SincronizadorDeCripticos.new(url: "#{base}/viejo").call

      assert sinc.exitosa?, sinc.resumen
      assert_equal 34, sinc.creados
    end
  end

  test "una respuesta HTTP de error se informa y no toca nada" do
    con_servidor({}) do |base|
      sinc = SincronizadorDeCripticos.new(url: "#{base}/no-existe").call

      assert sinc.fallida?
      assert_match(/HTTP 404/, sinc.mensaje_error)
      assert_equal 0, Criptico.count
    end
  end

  test "corta si la fuente redirige en bucle" do
    con_servidor("/bucle" => [ 302, { "Location" => "/bucle" }, "" ]) do |base|
      sinc = SincronizadorDeCripticos.new(url: "#{base}/bucle").call

      assert sinc.fallida?
      assert_match(/demasiadas veces/, sinc.mensaje_error)
    end
  end
end
