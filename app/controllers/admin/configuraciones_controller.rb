class Admin::ConfiguracionesController < Admin::BaseController
  before_action :set_configuracion

  def edit
  end

  def update
    if @configuracion.update(params.expect(configuracion: [ :url_fuente, :texto_bienvenida ]))
      redirect_to edit_admin_configuracion_path, notice: "Configuración guardada."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private
    def set_configuracion
      @configuracion = Configuracion.actual
    end
end
