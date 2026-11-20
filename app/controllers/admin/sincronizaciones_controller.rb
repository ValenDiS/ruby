class Admin::SincronizacionesController < Admin::BaseController
  def index
    @sincronizaciones = Sincronizacion.includes(:user).recientes.limit(50)
  end

  def show
    @sincronizacion = Sincronizacion.find(params[:id])
  end

  # Botón «Sincronizar ahora».
  def create
    sincronizacion = SincronizadorDeCripticos.new(usuario: Current.user).call
    redirect_to admin_sincronizacion_path(sincronizacion)
  end
end
