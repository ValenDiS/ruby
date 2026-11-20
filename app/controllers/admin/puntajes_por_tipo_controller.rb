class Admin::PuntajesPorTipoController < Admin::BaseController
  permitir_roles :admin, :editor_puntajes

  # Muestra en una sola pantalla los puntos por tipo y los multiplicadores por dificultad.
  def index
    @puntajes = PuntajePorTipo.order(:tipo)
    @multiplicadores = MultiplicadorDificultad.all.sort_by { |m| Criptico::DIFICULTADES.index(m.dificultad) }
  end

  def update
    puntaje = PuntajePorTipo.find(params[:id])

    if puntaje.update(params.expect(puntaje_por_tipo: [ :puntos ]))
      redirect_to admin_puntajes_por_tipo_path, notice: "Puntos actualizados."
    else
      redirect_to admin_puntajes_por_tipo_path, alert: puntaje.errors.full_messages.to_sentence
    end
  end
end
