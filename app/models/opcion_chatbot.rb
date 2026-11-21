class OpcionChatbot < ApplicationRecord
  belongs_to :origen, class_name: "NodoChatbot", inverse_of: :opciones
  belongs_to :destino, class_name: "NodoChatbot", inverse_of: :opciones_entrantes

  validates :texto, presence: true
  validates :destino_id, uniqueness: { scope: :origen_id }
end
