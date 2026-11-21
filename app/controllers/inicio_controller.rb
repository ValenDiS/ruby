class InicioController < ApplicationController
  allow_unauthenticated_access only: :show if respond_to?(:allow_unauthenticated_access)

  def show
  end
end
