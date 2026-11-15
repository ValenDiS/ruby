# Registro de cada vez que se sincronizó el catálogo de crípticos con la API.
class Sincronizacion < ApplicationRecord
  ESTADOS = %w[exitosa sin_cambios fallida].freeze

  # Admin que hizo la sincronización. Cuando se mergee el modelo User (issue 5)
  # se puede agregar:
  #   belongs_to :user, optional: true
  # Mientras tanto guardamos solo el id.

  enum :estado, ESTADOS.index_by(&:itself), validate: true

  validates :url, presence: true
  validates :creados, :actualizados, :desactivados, :rechazados,
            numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  scope :recientes, -> { order(created_at: :desc) }

  # La versión que se compara para decidir si hay cambios.
  def self.ultima_version_exitosa
    exitosa.order(created_at: :desc, id: :desc).pick(:version)
  end

  def fecha
    created_at
  end

  # Texto corto para mostrar en el admin o en consola.
  def resumen
    case estado
    when "fallida"     then "Error: #{mensaje_error}"
    when "sin_cambios" then "Sin cambios (versión #{version})"
    else
      "Versión #{version}: #{creados} creados, #{actualizados} actualizados, " \
        "#{desactivados} desactivados, #{rechazados} rechazados"
    end
  end
end
