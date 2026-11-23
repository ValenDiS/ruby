class RegistroDeJugador
  Resultado = Data.define(:jugador, :sugerencia) do
    def exitoso?
      jugador.persisted?
    end
  end

  def self.call(nombre:)
    new(nombre: nombre).call
  end

  def initialize(nombre:)
    @jugador = Jugador.new(nombre: nombre)
  end

  def call
    guardar
    sugerencia = SugeridorDeNombre.call(@jugador.nombre) if @jugador.errors.of_kind?(:nombre, :taken)
    Resultado.new(jugador: @jugador, sugerencia: sugerencia)
  end

  private
    def guardar
      @jugador.save
    rescue ActiveRecord::RecordNotUnique
      # Otro registro pudo tomar el nombre después de validarlo.
      # Los conflictos ajenos al nombre conservan su error original.
      raise if @jugador.valid?
    end
end
