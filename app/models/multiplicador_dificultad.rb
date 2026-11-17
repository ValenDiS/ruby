class MultiplicadorDificultad < ApplicationRecord
  DIFICULTADES = %w[facil medio avanzado].freeze

  validates :dificultad, presence: true, inclusion: { in: DIFICULTADES }, uniqueness: true
  validates :valor, numericality: { greater_than: 0, less_than_or_equal_to: 5 }
end
