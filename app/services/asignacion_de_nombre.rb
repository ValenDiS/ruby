class AsignacionDeNombre
  def self.call(jugador:, nombre:)
    new(jugador: jugador, nombre: nombre).call
  end

  def initialize(jugador:, nombre:)
    @jugador = jugador
    @jugador.nombre = nombre
  end

  def call
    exitoso = guardar
    sugerencia = SugeridorDeNombre.call(@jugador.nombre) if @jugador.errors.of_kind?(:nombre, :taken)
    ResultadoDeJugador.new(jugador: @jugador, sugerencia: sugerencia, exitoso: exitoso)
  end

  private
    def guardar
      @jugador.save
    rescue ActiveRecord::RecordNotUnique
      # El índice único también protege cuando dos solicitudes compiten por un nombre.
      raise if @jugador.valid?

      false
    end
end
