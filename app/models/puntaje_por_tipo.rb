class PuntajePorTipo < ApplicationRecord
  TIPOS = %w[anagrama oculta charada contenedor inversion supresion homofono
             doble_definicion iniciales finales sustitucion simbolos combinada].freeze

  validates :tipo, presence: true, inclusion: { in: TIPOS }, uniqueness: true
  validates :puntos, numericality: { only_integer: true, in: 10..1000 }
end
