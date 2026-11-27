class IniciadorDePartidas
  Resultado = Data.define(:partida, :estado) do
    def exitoso?
      %i[ iniciada retomada ].include?(estado)
    end
  end

  def self.call(jugador:, partida:)
    new(jugador: jugador, partida: partida).call
  end

  def initialize(jugador:, partida:)
    @jugador = jugador
    @token = jugador.token
    @partida = partida
  end

  def call
    # El orden de bloqueo coincide con la asignación y el cambio de identidad.
    @jugador.with_lock { iniciar }
  end

  private
    def iniciar
      return resultado(:identidad_retirada) unless @jugador.token == @token
      return resultado(:jugador_bloqueado) if @jugador.bloqueado?
      @partida.with_lock do
        if @partida.jugador_id != @jugador.id
          resultado(:partida_ajena)
        elsif @partida.terminada?
          resultado(:terminada, @partida)
        elsif @partida.iniciada?
          resultado(:retomada, @partida)
        else
          @partida.update!(iniciado_at: Time.current)
          resultado(:iniciada, @partida)
        end
      end
    end

    def resultado(estado, partida = nil)
      Resultado.new(partida: partida, estado: estado)
    end
end
