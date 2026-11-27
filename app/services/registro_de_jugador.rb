class RegistroDeJugador
  def self.call(nombre:)
    new(nombre: nombre).call
  end

  def initialize(nombre:)
    @nombre = nombre
  end

  def call
    AsignacionDeNombre.call(jugador: Jugador.new, nombre: @nombre)
  end
end
