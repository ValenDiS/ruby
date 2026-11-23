class Publico::PartidasController < Publico::BaseController
  before_action :evitar_cache
  before_action :requerir_jugador
  before_action :requerir_jugador_habilitado
  before_action :buscar_partida, only: %i[ show iniciar ]

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

    case resultado.estado
    when :iniciada, :retomada, :terminada
      redirect_to partida_path(@partida), status: :see_other
    when :identidad_retirada
      redirect_to new_jugador_path, status: :see_other
    when :jugador_bloqueado
      redirect_to root_path, status: :see_other
    when :partida_ajena
      head :not_found
    end
  end

  private
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
