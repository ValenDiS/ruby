require "net/http"

# Trae el catálogo de crípticos desde la API JSON de la cátedra y lo
# guarda en la base. Lo usan el botón «Sincronizar ahora» del admin,
# db:seed y la tarea rake cripticos:sincronizar.
#
#   sincronizacion = SincronizadorDeCripticos.new(usuario: Current.user).call
#   sincronizacion.resumen   # => "Versión 2026-10-26.1: 34 creados, ..."
#
# Reglas (enunciado, «Reglas de la sincronización»):
#   1. GET a la URL con timeout de 10 s. Error de red o JSON inválido → no se toca nada.
#   2. Misma versión que la última sincronización exitosa → «Sin cambios».
#   3. Se identifica por id de la fuente: si no existe se crea, si cambió se actualiza.
#   4. Un críptico inválido se saltea y se informa con su id y el motivo.
#   5. Los que ya no vienen no se borran: se desactivan (en_fuente = false).
#   6. Cada sincronización queda registrada (modelo Sincronizacion).
class SincronizadorDeCripticos
  TIMEOUT = 10 # segundos
  MAX_REDIRECCIONES = 3 # por ej. http:// → https:// en GitHub Pages

  # Errores de la fuente: red, HTTP o JSON. Ante cualquiera de estos no se toca la base.
  class ErrorDeFuente < StandardError; end

  ERRORES_DE_RED = [
    Net::OpenTimeout, Net::ReadTimeout, SocketError, SystemCallError,
    IOError, OpenSSL::SSL::SSLError, Net::HTTPBadResponse, Net::ProtocolError
  ].freeze

  # La variable de entorno pisa la URL guardada en la configuración del admin.
  def self.url_configurada
    ENV["CRIPTICOS_URL"].presence || Configuracion.actual.url_fuente
  end

  def self.call(...)
    new(...).call
  end

  # cliente_http: cualquier objeto que responda a call(url) y devuelva el cuerpo
  # de la respuesta como String. Se puede reemplazar en los tests.
  def initialize(url: self.class.url_configurada, usuario: nil, cliente_http: nil)
    @url = url.to_s.strip
    @usuario = usuario
    @cliente_http = cliente_http || method(:descargar)
  end

  def call
    catalogo = obtener_catalogo
    version = catalogo["version"].to_s

    if version == Sincronizacion.ultima_version_exitosa
      return registrar(estado: "sin_cambios", version: version)
    end

    procesar(catalogo, version)
  rescue ErrorDeFuente => e
    registrar(estado: "fallida", mensaje_error: e.message)
  rescue ActiveRecord::ActiveRecordError => e
    Rails.logger.error("[SincronizadorDeCripticos] #{e.class}: #{e.message}")
    registrar(estado: "fallida", version: version, mensaje_error: "Error al guardar en la base: #{e.message}")
  end

  private

  attr_reader :url, :usuario

  # ---------- 1. Obtener y validar el JSON ----------

  def obtener_catalogo
    cuerpo = @cliente_http.call(url)
    datos = JSON.parse(cuerpo.to_s)

    raise ErrorDeFuente, "El JSON no tiene el formato esperado (falta \"version\")" unless datos.is_a?(Hash) && datos["version"].present?
    raise ErrorDeFuente, "El JSON no tiene la lista \"cripticos\"" unless datos["cripticos"].is_a?(Array)

    datos
  rescue JSON::ParserError => e
    raise ErrorDeFuente, "La respuesta no es un JSON válido (#{e.message.truncate(80)})"
  rescue *ERRORES_DE_RED => e
    raise ErrorDeFuente, "No se pudo conectar con #{url}: #{mensaje_de_red(e)}"
  end

  # Net::HTTP no sigue redirecciones solo: si la fuente responde 301/302
  # (por ejemplo, GitHub Pages pasando de http a https), se sigue la nueva
  # dirección hasta MAX_REDIRECCIONES veces.
  def descargar(direccion, redirecciones_restantes = MAX_REDIRECCIONES)
    uri = URI.parse(direccion)
    raise ErrorDeFuente, "La URL de la fuente no es válida: #{direccion.inspect}" unless uri.is_a?(URI::HTTP) && uri.host.present?

    respuesta = Net::HTTP.start(uri.host, uri.port,
                                use_ssl: uri.scheme == "https",
                                open_timeout: TIMEOUT, read_timeout: TIMEOUT) do |http|
      http.get(uri.request_uri, "Accept" => "application/json")
    end

    if respuesta.is_a?(Net::HTTPRedirection) && respuesta["location"].present?
      raise ErrorDeFuente, "La fuente redirigió demasiadas veces" if redirecciones_restantes.zero?

      return descargar(URI.join(direccion, respuesta["location"]).to_s, redirecciones_restantes - 1)
    end

    raise ErrorDeFuente, "La fuente respondió HTTP #{respuesta.code}" unless respuesta.is_a?(Net::HTTPSuccess)

    respuesta.body.to_s.force_encoding(Encoding::UTF_8)
  rescue URI::InvalidURIError
    raise ErrorDeFuente, "La URL de la fuente no es válida: #{direccion.inspect}"
  end

  def mensaje_de_red(error)
    case error
    when Net::OpenTimeout, Net::ReadTimeout then "se superó el tiempo de espera de #{TIMEOUT} s"
    else error.message
    end
  end

  # ---------- 2 a 5. Procesar los crípticos ----------

  def procesar(catalogo, version)
    @contadores = { creados: 0, actualizados: 0, desactivados: 0 }
    @rechazos = []
    @origen = catalogo["fuente"].presence || url
    ids_en_fuente = []

    ActiveRecord::Base.transaction do
      catalogo["cripticos"].each_with_index do |item, posicion|
        id = procesar_item(item, posicion, ids_en_fuente)
        ids_en_fuente << id if id
      end

      @contadores[:desactivados] = desactivar_ausentes(ids_en_fuente)
    end

    registrar(estado: "exitosa", version: version, **@contadores,
              rechazados: @rechazos.size, detalle_rechazados: @rechazos)
  end

  # Devuelve el id de la fuente si el ítem lo tiene (aunque sea inválido),
  # para que no se desactive un críptico que sí vino en el catálogo.
  def procesar_item(item, posicion, ids_ya_vistos)
    unless item.is_a?(Hash)
      rechazar("posición #{posicion + 1}", "no es un objeto JSON")
      return
    end

    id = item["id"].to_s.strip
    if id.empty?
      rechazar("posición #{posicion + 1}", "no tiene id")
      return
    end

    if ids_ya_vistos.include?(id)
      rechazar(id, "id repetido en el catálogo (se usó el primero)")
      return
    end

    criptico = Criptico.find_or_initialize_by(id_fuente: id)
    nuevo = criptico.new_record?
    criptico.assign_attributes(atributos_desde(item))

    if criptico.invalid?
      rechazar(id, criptico.errors.full_messages.to_sentence)
    elsif nuevo
      criptico.save!
      @contadores[:creados] += 1
    elsif criptico.changed?
      criptico.save!
      @contadores[:actualizados] += 1
    end

    id
  end

  def atributos_desde(item)
    {
      enunciado: item["enunciado"],
      enumeracion: item["enumeracion"],
      respuesta: item["respuesta"],
      definiciones: item["definiciones"] || [],
      indicadores: item["indicadores"] || [],
      material: item["material"] || [],
      tipo: item["tipo"],
      dificultad: item["dificultad"],
      ayuda: item["ayuda"],
      explicacion: item["explicacion"],
      autor: item["autor"],
      origen: @origen,
      en_fuente: true
    }
  end

  def desactivar_ausentes(ids_en_fuente)
    Criptico.where(en_fuente: true)
            .where.not(id_fuente: ids_en_fuente)
            .update_all(en_fuente: false, updated_at: Time.current)
  end

  def rechazar(id, motivo)
    @rechazos << { "id" => id, "motivo" => motivo }
  end

  # ---------- 6. Registro ----------

  def registrar(**atributos)
    Sincronizacion.create!(url: url.presence || "(sin URL)", user_id: usuario&.id, **atributos)
  end
end
