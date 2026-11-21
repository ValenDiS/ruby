class Admin::CripticosController < Admin::BaseController
  def index
    @filtros = params.permit(:dificultad, :tipo, :estado, :origen)
    @cripticos = FiltroDeCripticos.new(**@filtros.to_h.symbolize_keys).call.order(:id_fuente)
    @origenes = Criptico.distinct.order(:origen).pluck(:origen).compact
  end

  # Solo se usa para activar o desactivar.
  def update
    criptico = Criptico.find(params[:id])

    if criptico.update(params.expect(criptico: [ :activo ]))
      redirect_back_or_to admin_cripticos_path, notice: "Críptico #{criptico.id_fuente} #{criptico.activo? ? "activado" : "desactivado"}."
    else
      redirect_back_or_to admin_cripticos_path, alert: criptico.errors.full_messages.to_sentence
    end
  end
end
