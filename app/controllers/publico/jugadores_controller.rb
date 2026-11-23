class Publico::JugadoresController < Publico::BaseController
  before_action :redirigir_jugador_identificado

  def new
    @jugador = Jugador.new
  end

  def create
    resultado = RegistroDeJugador.call(nombre: params.expect(jugador: [ :nombre ])[:nombre])
    @jugador = resultado.jugador

    if resultado.exitoso?
      identificar_jugador(@jugador)
      redirect_to root_path, status: :see_other
    else
      @sugerencia = resultado.sugerencia
      render :new, status: :unprocessable_entity
    end
  end

  private
    def redirigir_jugador_identificado
      redirect_to root_path if jugador_actual
    end
end
