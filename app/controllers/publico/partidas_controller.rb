class Publico::PartidasController < Publico::BaseController
  before_action :evitar_cache
  before_action :requerir_jugador
  before_action :requerir_jugador_habilitado
  before_action :buscar_partida, only: %i[ show iniciar responder rendirse ]

  def new
    abierta = jugador_actual.partida_abierta
    return redirect_to partida_path(abierta) if abierta

    respond_to { |formato| formato.html }
  end

  def create
    resultado = AsignadorDePartidas.call(jugador: jugador_actual, dificultad: params[:dificultad])

    if resultado.exitoso?
      redirect_to partida_path(resultado.partida), status: :see_other
    elsif resultado.estado == :identidad_retirada
      redirect_to new_jugador_path, status: :see_other
    elsif resultado.estado == :jugador_bloqueado
      redirect_to root_path, status: :see_other
    else
      @error = t("juego.errores.#{resultado.estado}")
      render :new, status: :unprocessable_entity
    end
  end

  def show
    respond_to { |formato| formato.html }
  end

  def iniciar
    resultado = IniciadorDePartidas.call(jugador: jugador_actual, partida: @partida)
    mostrar_resultado(resultado)
  end

  def responder
    intento = params.expect(intento: [ :respuesta, :intentos_previos ])
    contador = intento[:intentos_previos]
    previos = contador.to_i if contador.is_a?(String) && contador.match?(/\A[0-5]\z/)
    resultado = ProcesadorDeRespuesta.call(jugador: jugador_actual, partida: @partida,
                                          respuesta: intento[:respuesta], intentos_previos: previos)
    mostrar_resultado(resultado)
  rescue ProcesadorDeRespuesta::PuntajeNoDisponible
    # El rollback de la base no limpia los atributos que quedaron en memoria.
    @partida.reload
    @error = t("juego.errores.puntaje_no_disponible")
    render :show, status: :service_unavailable
  end

  def rendirse
    resultado = RendicionDePartida.call(jugador: jugador_actual, partida: @partida)
    mostrar_resultado(resultado)
  end

  private
    def mostrar_resultado(resultado)
      case resultado.estado
      when :iniciada, :retomada, :terminada, :resuelta, :rendida
        redirect_to partida_path(@partida), status: :see_other
      when :identidad_retirada
        redirect_to new_jugador_path, status: :see_other
      when :jugador_bloqueado
        redirect_to root_path, status: :see_other
      when :partida_ajena
        head :not_found
      when :sin_intentos
        render :show, status: :unprocessable_entity
      when :sin_iniciar, :desactualizada
        @error = t("juego.errores.#{resultado.estado}")
        render :show, status: :conflict
      when :incorrecta, :respuesta_invalida
        @error = t("juego.errores.#{resultado.estado}")
        render :show, status: :unprocessable_entity
      end
    end

    def buscar_partida
      @partida = jugador_actual.partidas.includes(:criptico).find(params[:id])
    end

    def requerir_jugador_habilitado
      redirect_to root_path, status: :see_other if jugador_actual.bloqueado?
    end

    def evitar_cache
      response.headers["Cache-Control"] = "no-store"
    end
end
