class Admin::SincronizacionesController < Admin::BaseController
  def index
    @sincronizaciones = Sincronizacion.recientes.limit(50)
    @usuarios = User.where(id: @sincronizaciones.map(&:user_id)).index_by(&:id)
    @url_fuente = Configuracion.actual.url_fuente
  end

  def show
    @sincronizacion = Sincronizacion.find(params[:id])
    @usuario = User.find_by(id: @sincronizacion.user_id)
  end

  # Botón «Sincronizar ahora»: usa la URL guardada en Configuración.
  def create
    sincronizacion = SincronizadorDeCripticos.new(url: Configuracion.actual.url_fuente, usuario: Current.user).call
    redirect_to admin_sincronizacion_path(sincronizacion)
  end
end
