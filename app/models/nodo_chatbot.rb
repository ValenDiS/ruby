class NodoChatbot < ApplicationRecord
  has_many :opciones_entrantes, class_name: "OpcionChatbot", foreign_key: :destino_id,
           inverse_of: :destino, dependent: :restrict_with_error
  has_many :opciones, -> { order(:id) }, class_name: "OpcionChatbot", foreign_key: :origen_id,
           inverse_of: :origen, dependent: :destroy

  validates :clave, presence: true, uniqueness: true
  validates :mensaje, presence: true

  def self.enunciados_activos
    Criptico.where(activo: true).pluck(:enunciado).map { |texto| NormalizadorDeTexto.normalizar(texto) }
  end

  def ejemplo_visible(enunciados = nil)
    return if ejemplo.blank?

    texto = NormalizadorDeTexto.normalizar(ejemplo)
    ejemplo unless (enunciados || self.class.enunciados_activos).any? { |enunciado| texto.include?(enunciado) }
  end
end
