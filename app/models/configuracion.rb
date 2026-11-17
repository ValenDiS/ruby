class Configuracion < ApplicationRecord
  validates :url_fuente, presence: true, format: { with: %r{\Ahttps?://\S+\z}, message: "tiene que empezar con http:// o https://" }
  validates :texto_bienvenida, presence: true, length: { maximum: 1000 }

  def self.actual
    find_or_create_by!(id: 1)
  end
end
