class Admin::BaseController < ApplicationController
  layout "admin"

  # Por defecto solo entra el admin. Cada controlador puede sumar roles con permitir_roles.
  class_attribute :roles_permitidos, default: %w[admin]
  before_action :autorizar_rol

  def self.permitir_roles(*roles)
    self.roles_permitidos = roles.map(&:to_s)
  end

  private
    def autorizar_rol
      unless roles_permitidos.include?(Current.user.rol)
        redirect_to admin_root_path, alert: "No tenés permiso para entrar ahí."
      end
    end
end
