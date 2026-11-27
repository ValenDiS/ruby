class Admin::DashboardController < Admin::BaseController
  permitir_roles :admin, :editor_puntajes

  def show
  end
end
