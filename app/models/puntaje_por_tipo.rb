class PuntajePorTipo < ApplicationRecord
  validates :tipo, presence: true, inclusion: { in: Criptico::TIPOS }, uniqueness: true
  validates :puntos, numericality: { only_integer: true, in: 10..1000 }
end
