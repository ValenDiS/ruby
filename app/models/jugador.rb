# Identidad compartida por el juego público y el backend.
class Jugador < ApplicationRecord
  has_secure_token :token

  # El historial queda aunque el jugador ya no se use («empezar como otro jugador»).
  has_many :partidas, dependent: :restrict_with_error

  before_validation :normalizar_nombre

  validates :nombre, presence: true, length: { in: 3..20 },
                     format: { with: /\A\S(.*\S)?\z/, message: "no puede empezar ni terminar con espacios" }
  validates :bloqueado, inclusion: { in: [ true, false ] }
  validate :nombre_disponible

  scope :visibles, -> { where(bloqueado: false) }

  def self.normalizar_nombre(nombre)
    nombre.to_s.unicode_normalize(:nfc).downcase
  end

  def partida_abierta
    partidas.en_curso.order(:created_at, :id).first
  end

  # TODO issue 3: suma de los puntos de las partidas resueltas.
  def puntos_totales
    0
  end

  # TODO issue 3: días seguidos jugando, contando hoy.
  def racha_actual
    0
  end

  private
    def normalizar_nombre
      self.nombre_normalizado = self.class.normalizar_nombre(nombre)
    end

    def nombre_disponible
      return if nombre.blank?

      if self.class.where(nombre_normalizado: nombre_normalizado).where.not(id: id).exists?
        errors.add(:nombre, :taken)
      end
    end
end
