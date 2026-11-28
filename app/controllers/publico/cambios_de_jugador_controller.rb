class Publico::CambiosDeJugadorController < Publico::BaseController
  before_action :requerir_jugador

  def new
    @jugador = Jugador.new
  end

  def create
    resultado = CambioDeJugador.call(
      jugador: jugador_actual,
      nombre: params.expect(jugador: [ :nombre ])[:nombre],
      confirmado: confirmacion_valida?
    )
    @jugador = resultado.jugador

    if resultado.exitoso?
      identificar_jugador(@jugador)
      redirect_to root_path, notice: "Empezaste como un nuevo jugador.", status: :see_other
    else
      @sugerencia = resultado.sugerencia
      render :new, status: :unprocessable_entity
    end
  end

  private
    def confirmacion_valida?
      params[:confirmacion] == "1" && params[:jugador_anterior_id] == jugador_actual.id.to_s
    end
end
