class CambioDeJugador
  def self.call(jugador:, nombre:, confirmado:)
    new(jugador: jugador, nombre: nombre, confirmado: confirmado).call
  end

  def initialize(jugador:, nombre:, confirmado:)
    @anterior = jugador
    @token_anterior = jugador.token
    @nombre = nombre
    @confirmado = confirmado
  end

  def call
    return rechazar("Confirmá que querés empezar como otro jugador.") unless @confirmado == true

    @anterior.with_lock do
      if @anterior.token != @token_anterior
        rechazar("La identidad ya cambió. Volvé al inicio antes de continuar.")
      else
        resultado = RegistroDeJugador.call(nombre: @nombre)
        # El jugador anterior conserva sus datos, pero su token deja de dar acceso.
        @anterior.regenerate_token if resultado.exitoso?
        resultado
      end
    end
  end

  private
    def rechazar(mensaje)
      jugador = Jugador.new(nombre: @nombre)
      jugador.errors.add(:base, mensaje)
      ResultadoDeJugador.new(jugador: jugador, sugerencia: nil, exitoso: false)
    end
end
