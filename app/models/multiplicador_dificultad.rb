class MultiplicadorDificultad < ApplicationRecord
  validates :dificultad, presence: true, inclusion: { in: Criptico::DIFICULTADES }, uniqueness: true
  validates :valor, numericality: { greater_than: 0, less_than_or_equal_to: 5 }
end
