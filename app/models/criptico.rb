class Criptico < ApplicationRecord
  TIPOS = %w[anagrama oculta charada contenedor inversion supresion homofono
             doble_definicion iniciales finales sustitucion simbolos combinada].freeze
  DIFICULTADES = %w[facil medio avanzado].freeze

  # Enums guardados como texto (más legible en la base que un entero).
  # validate: true → un valor desconocido ("palindromo") es un error de
  # validación en vez de levantar ArgumentError.
  enum :tipo, TIPOS.index_by(&:itself), validate: { allow_nil: true }
  enum :dificultad, DIFICULTADES.index_by(&:itself), validate: { allow_nil: true }, prefix: :dificultad

  # Un críptico se puede jugar si el admin no lo desactivó
  # y sigue viniendo en la fuente.
  scope :jugables, -> { where(activo: true, en_fuente: true) }
  scope :fuera_de_fuente, -> { where(en_fuente: false) }

  ESTADOS_FILTRO = %w[jugable desactivado fuera_de_fuente].freeze

  # Filtros del listado del admin. Los filtros vacíos se ignoran.
  def self.filtrar(dificultad: nil, tipo: nil, estado: nil, origen: nil)
    cripticos = all
    cripticos = cripticos.where(dificultad: dificultad) if dificultad.present?
    cripticos = cripticos.where(tipo: tipo) if tipo.present?
    cripticos = cripticos.where(origen: origen) if origen.present?

    case estado
    when "jugable" then cripticos.jugables
    when "desactivado" then cripticos.where(activo: false)
    when "fuera_de_fuente" then cripticos.fuera_de_fuente
    else cripticos
    end
  end

  validates :id_fuente, presence: true, uniqueness: true
  validates :enunciado, :respuesta, :enumeracion, presence: true
  validates :tipo, :dificultad, presence: true
  validates :activo, :en_fuente, inclusion: { in: [ true, false ] }

  validate :enumeracion_coincide_con_respuesta
  validate :fragmentos_aparecen_en_enunciado
  validate :al_menos_una_definicion
  validate :reglas_del_tipo

  def jugable?
    activo? && en_fuente?
  end

  # Respuesta lista para comparar con lo que escribe el jugador.
  def respuesta_normalizada
    NormalizadorDeTexto.normalizar(respuesta)
  end

  private

  def enumeracion_coincide_con_respuesta
    return if enumeracion.blank? || respuesta.blank?

    if VerificadorDeCriptico.letras_de_enumeracion(enumeracion).nil?
      errors.add(:enumeracion, "tiene un formato inválido (se espera algo como \"(6)\")")
    elsif !VerificadorDeCriptico.enumeracion_coincide?(enumeracion, respuesta)
      errors.add(:enumeracion, "#{enumeracion} no coincide con el largo de la respuesta " \
                               "(#{respuesta_normalizada.length} letras)")
    end
  end

  def fragmentos_aparecen_en_enunciado
    return if enunciado.blank?

    { definiciones: definiciones, indicadores: indicadores, material: material }.each do |campo, fragmentos|
      unless fragmentos.is_a?(Array)
        errors.add(campo, "debe ser una lista")
        next
      end

      fragmentos.each do |fragmento|
        next if VerificadorDeCriptico.aparece_en?(fragmento, enunciado)

        errors.add(campo, "\"#{fragmento}\" no aparece en el enunciado")
      end
    end
  end

  def al_menos_una_definicion
    errors.add(:definiciones, "debe tener al menos una") if Array(definiciones).empty?
  end

  def reglas_del_tipo
    return if respuesta.blank? || !Array(material).all?(String)

    case tipo
    when "doble_definicion"
      errors.add(:definiciones, "de una doble definición deben ser exactamente 2") unless Array(definiciones).size == 2
    when "oculta"
      errors.add(:respuesta, "no está escondida en el material") unless VerificadorDeCriptico.oculta_valida?(material, respuesta)
    when "anagrama"
      errors.add(:material, "no tiene las mismas letras que la respuesta") unless VerificadorDeCriptico.anagrama_valido?(material, respuesta)
    when "iniciales"
      errors.add(:respuesta, "no se forma con las iniciales del material") unless VerificadorDeCriptico.iniciales_validas?(material, respuesta)
    when "finales"
      errors.add(:respuesta, "no se forma con las letras finales del material") unless VerificadorDeCriptico.finales_validas?(material, respuesta)
    end
  end
end
