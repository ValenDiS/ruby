class RendicionDePartida
  Resultado = Data.define(:partida, :estado)

  def self.call(jugador:, partida:)
    new(jugador: jugador, partida: partida).call
  end

  def initialize(jugador:, partida:)
    @jugador = jugador
    @token = jugador.token
    @partida = partida
  end

  def call
    @jugador.with_lock do
      if @jugador.token != @token
        resultado(:identidad_retirada)
      elsif @jugador.bloqueado?
        resultado(:jugador_bloqueado)
      else
        @partida.with_lock { rendirse }
      end
    end
  end

  private
    def rendirse
      return resultado(:partida_ajena) unless @partida.jugador_id == @jugador.id
      return resultado(:terminada, @partida) if @partida.terminada?
      return resultado(:sin_iniciar, @partida) unless @partida.iniciada?

      @partida.update!(rendido_at: Time.current, puntos: 0)
      resultado(:rendida, @partida)
    end

    def resultado(estado, partida = nil)
      Resultado.new(partida: partida, estado: estado)
    end
end
