class Admin::MultiplicadoresDificultadController < Admin::BaseController
  permitir_roles :admin, :editor_puntajes

  def update
    multiplicador = MultiplicadorDificultad.find(params[:id])

    if multiplicador.update(params.expect(multiplicador_dificultad: [ :valor ]))
      redirect_to admin_puntajes_por_tipo_path, notice: "Multiplicador actualizado."
    else
      redirect_to admin_puntajes_por_tipo_path, alert: multiplicador.errors.full_messages.to_sentence
    end
  end
end
