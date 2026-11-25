class Jugador < ApplicationRecord
  has_secure_token :token

  # El historial queda aunque el jugador ya no se use («empezar como otro jugador»).
  has_many :partidas, dependent: :restrict_with_error

  validates :nombre, presence: true, length: { in: 3..20 }, uniqueness: { case_sensitive: false },
                     format: { with: /\A\S(.*\S)?\z/, message: "no puede empezar ni terminar con espacios" }
  validates :bloqueado, inclusion: { in: [ true, false ] }

  scope :visibles, -> { where(bloqueado: false) }

  # Los puntos ya quedan guardados en cada partida al resolverla;
  # las rendidas valen 0, así que no suman.
  def puntos_totales
    partidas.resueltas.sum(:puntos)
  end

  def racha_actual
    CalculadorDeRacha.new(self).actual
  end

  def mejor_racha
    CalculadorDeRacha.new(self).mejor
  end
end
