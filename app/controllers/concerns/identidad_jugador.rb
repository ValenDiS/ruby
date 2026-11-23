module IdentidadJugador
  extend ActiveSupport::Concern

  included do
    helper_method :jugador_actual
  end

  private
    def jugador_actual
      return @jugador_actual if defined?(@jugador_actual)

      token = cookies.signed[:jugador_token]
      @jugador_actual = Jugador.find_by(token: token) if token.present?
      cookies.delete(:jugador_token) if cookies[:jugador_token].present? && @jugador_actual.nil?
      @jugador_actual
    end

    def identificar_jugador(jugador)
      cookies.signed.permanent[:jugador_token] = {
        value: jugador.token,
        httponly: true,
        same_site: :lax,
        secure: request.ssl?
      }
      @jugador_actual = jugador
    end
end
