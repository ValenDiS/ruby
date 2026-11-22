class Partida < ApplicationRecord
  MAXIMO_INTENTOS = 5
  MAXIMO_PISTAS = 4

  belongs_to :jugador
  belongs_to :criptico

  validates :criptico_id, uniqueness: { scope: :jugador_id, message: "ya fue jugado por este jugador" }
  validates :intentos, numericality: { only_integer: true, in: 0..MAXIMO_INTENTOS }
  validates :pistas_usadas, numericality: { only_integer: true, in: 0..MAXIMO_PISTAS }
  validates :puntos, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true
  validate :no_puede_estar_resuelta_y_rendida
  validate :terminada_necesita_inicio

  scope :resueltas, -> { where.not(resuelto_at: nil) }
  scope :rendidas, -> { where.not(rendido_at: nil) }
  scope :en_curso, -> { where(resuelto_at: nil, rendido_at: nil) }

  def iniciada?
    iniciado_at.present?
  end

  def resuelta?
    resuelto_at.present?
  end

  def rendida?
    rendido_at.present?
  end

  def terminada?
    resuelta? || rendida?
  end

  # Tiempo oficial: lo calcula el servidor con los dos timestamps, nunca el navegador.
  def segundos_jugados
    return unless iniciada? && resuelta?

    (resuelto_at - iniciado_at).round
  end

  private
    def no_puede_estar_resuelta_y_rendida
      errors.add(:base, "Una partida no puede estar resuelta y rendida a la vez.") if resuelta? && rendida?
    end

    def terminada_necesita_inicio
      errors.add(:iniciado_at, "no puede estar vacío en una partida terminada") if terminada? && !iniciada?
    end
end
