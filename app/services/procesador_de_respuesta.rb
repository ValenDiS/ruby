class ProcesadorDeRespuesta
  class PuntajeNoDisponible < StandardError; end

  Resultado = Data.define(:partida, :estado)

  def self.call(...)
    new(...).call
  end

  def initialize(jugador:, partida:, respuesta:, intentos_previos:, calculador: nil)
    @jugador = jugador
    @token = jugador.token
    @partida = partida
    @respuesta = respuesta
    @intentos_previos = intentos_previos
    @calculador = calculador
  end

  def call
    @jugador.with_lock do
      if @jugador.token != @token
        resultado(:identidad_retirada)
      elsif @jugador.bloqueado?
        resultado(:jugador_bloqueado)
      else
        @partida.with_lock { procesar }
      end
    end
  end

  private
    def procesar
      return resultado(:partida_ajena) unless @partida.jugador_id == @jugador.id
      return resultado(:terminada, @partida) if @partida.terminada?
      return resultado(:sin_iniciar, @partida) unless @partida.iniciada?
      return resultado(:sin_intentos, @partida) if @partida.intentos_restantes.zero?
      return resultado(:desactualizada, @partida) unless @intentos_previos.is_a?(Integer) && @intentos_previos == @partida.intentos
      return resultado(:respuesta_invalida, @partida) unless @respuesta.is_a?(String) && @respuesta.valid_encoding?

      respuesta = NormalizadorDeTexto.normalizar(@respuesta)
      return resultado(:respuesta_invalida, @partida) if respuesta.empty?

      if respuesta == @partida.criptico.respuesta_normalizada
        resolver
      else
        @partida.update!(intentos: @partida.intentos + 1)
        resultado(:incorrecta, @partida)
      end
    end

    def resolver
      # El calculador puede consultar la resolución del día dentro de esta transacción.
      @partida.update!(intentos: @partida.intentos + 1, resuelto_at: Time.current)
      @partida.update!(puntos: calcular_puntos)
      resultado(:resuelta, @partida)
    end

    def calcular_puntos
      puntos = if @calculador
        @calculador.call(@partida)
      else
        raise PuntajeNoDisponible, "CalculadorDePuntaje todavía no integrado" unless defined?(CalculadorDePuntaje)

        CalculadorDePuntaje.new(@partida).calcular
      end
      unless puntos.is_a?(Integer) && puntos >= 10
        raise PuntajeNoDisponible, "El calculador debe devolver un entero mayor o igual a 10"
      end

      puntos
    rescue PuntajeNoDisponible
      raise
    rescue StandardError => error
      Rails.logger.error("[ProcesadorDeRespuesta] Falló el cálculo de puntaje (#{error.class})")
      raise PuntajeNoDisponible, "No se pudo calcular el puntaje"
    end

    def resultado(estado, partida = nil)
      Resultado.new(partida: partida, estado: estado)
    end
end
