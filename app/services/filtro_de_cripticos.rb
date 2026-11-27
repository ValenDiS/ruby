# Filtros del listado de crípticos del admin. Los filtros vacíos se ignoran.
#
#   FiltroDeCripticos.new(dificultad: "facil", estado: "jugable").call
class FiltroDeCripticos
  ESTADOS = %w[jugable desactivado fuera_de_fuente].freeze

  def initialize(dificultad: nil, tipo: nil, estado: nil, origen: nil)
    @dificultad = dificultad
    @tipo = tipo
    @estado = estado
    @origen = origen
  end

  def call
    cripticos = Criptico.all
    cripticos = cripticos.where(dificultad: @dificultad) if @dificultad.present?
    cripticos = cripticos.where(tipo: @tipo) if @tipo.present?
    cripticos = cripticos.where(origen: @origen) if @origen.present?

    case @estado
    when "jugable" then cripticos.jugables
    when "desactivado" then cripticos.where(activo: false)
    when "fuera_de_fuente" then cripticos.fuera_de_fuente
    else cripticos
    end
  end
end
