class Publico::JugadoresController < Publico::BaseController
  before_action :redirigir_jugador_identificado, only: %i[ new create ]
  before_action :requerir_jugador, only: %i[ edit update ]

  def new
    @jugador = Jugador.new
  end

  def create
    resultado = RegistroDeJugador.call(nombre: nombre_del_formulario)
    @jugador = resultado.jugador

    if resultado.exitoso?
      identificar_jugador(@jugador)
      redirect_to root_path, status: :see_other
    else
      @sugerencia = resultado.sugerencia
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @jugador = jugador_actual
  end

  def update
    resultado = AsignacionDeNombre.call(jugador: jugador_actual, nombre: nombre_del_formulario)
    @jugador = resultado.jugador

    if resultado.exitoso?
      redirect_to root_path, notice: "Tu nombre fue actualizado.", status: :see_other
    else
      @sugerencia = resultado.sugerencia
      render :edit, status: :unprocessable_entity
    end
  end

  private
    def nombre_del_formulario
      params.expect(jugador: [ :nombre ])[:nombre]
    end

    def redirigir_jugador_identificado
      redirect_to root_path if jugador_actual
    end
end
