class AsignadorDePartidas
  Resultado = Data.define(:partida, :estado) do
    def exitoso?
      partida.present?
    end
  end

  def self.call(jugador:, dificultad:)
    new(jugador: jugador, dificultad: dificultad).call
  end

  def initialize(jugador:, dificultad:)
    @jugador = jugador
    @token = jugador.token
    @dificultad = dificultad
  end

  def call
    return resultado(:dificultad_invalida) unless Criptico::DIFICULTADES.include?(@dificultad)

    # Serializa las asignaciones del jugador y vuelve a leer su identidad y bloqueo.
    @jugador.with_lock { asignar }
  end

  private
    def asignar
      return resultado(:identidad_retirada) unless @jugador.token == @token
      return resultado(:jugador_bloqueado) if @jugador.bloqueado?

      abierta = @jugador.partida_abierta
      return resultado(:retomada, abierta) if abierta

      criptico = disponibles.order(Arel.sql("RANDOM()")).first
      return resultado(:sin_disponibles) unless criptico

      partida = @jugador.partidas.create!(criptico: criptico)
      resultado(:asignada, partida)
    end

    def disponibles
      Criptico.jugables.where(dificultad: @dificultad)
              .where.not(id: @jugador.partidas.select(:criptico_id))
    end

    def resultado(estado, partida = nil)
      Resultado.new(partida: partida, estado: estado)
    end
end
