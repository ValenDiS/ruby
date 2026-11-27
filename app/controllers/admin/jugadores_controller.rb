class Admin::JugadoresController < Admin::BaseController
  def index
    @jugadores = Jugador.order(:nombre)
    @tabla_reiniciada_at = Configuracion.actual.tabla_reiniciada_at
  end

  # Solo se usa para bloquear o desbloquear el nombre.
  def update
    jugador = Jugador.find(params[:id])
    jugador.update!(params.expect(jugador: [ :bloqueado ]))
    redirect_to admin_jugadores_path, notice: "#{jugador.nombre} #{jugador.bloqueado? ? "bloqueado" : "desbloqueado"}."
  end

  def reiniciar_tabla
    Configuracion.actual.reiniciar_tabla!
    redirect_to admin_jugadores_path, notice: "Tabla de posiciones reiniciada."
  end
end
