class Publico::BaseController < ApplicationController
  # El login del backend se incorpora en la issue 5.
  allow_unauthenticated_access if respond_to?(:allow_unauthenticated_access)

  include IdentidadJugador
end
