# Stub mínimo para el backend (issue 5). El resto (cookie, partidas, puntaje y racha)
# lo completan los issues 2 y 3.
class Jugador < ApplicationRecord
  has_secure_token :token

  # El historial queda aunque el jugador ya no se use («empezar como otro jugador»).
  has_many :partidas, dependent: :restrict_with_error

  validates :nombre, presence: true, length: { in: 3..20 }, uniqueness: { case_sensitive: false },
                     format: { with: /\A\S(.*\S)?\z/, message: "no puede empezar ni terminar con espacios" }
  validates :bloqueado, inclusion: { in: [ true, false ] }

  scope :visibles, -> { where(bloqueado: false) }

  # TODO issue 3: suma de los puntos de las partidas resueltas.
  def puntos_totales
    0
  end

  # TODO issue 3: días seguidos jugando, contando hoy.
  def racha_actual
    0
  end
end
