# Reglas "de juego de palabras" que permiten que el sistema verifique
# un críptico por sí mismo. Son funciones puras (no tocan la base),
# y las usa el modelo Criptico en sus validaciones.
module VerificadorDeCriptico
  # Palabras de unión que se ignoran en iniciales/finales.
  # Ej: «Colas de álbum, casa y amor» → la «y» solo une: álbuM casA amoR = MAR.
  CONECTORES = %w[y e o u ni de del la el los las a al con].freeze

  module_function

  # "(6)" => 6 ; "(4,5)" => 9 ; "(4 5)" => 9
  def letras_de_enumeracion(enumeracion)
    return nil unless enumeracion.to_s.strip.match?(/\A\(\s*\d+(\s*[,\s-]\s*\d+)*\s*\)\z/)

    enumeracion.scan(/\d+/).sum(&:to_i)
  end

  # La enumeración coincide con el largo de la respuesta (sin tildes ni espacios).
  def enumeracion_coincide?(enumeracion, respuesta)
    letras_de_enumeracion(enumeracion) == NormalizadorDeTexto.normalizar(respuesta).length
  end

  # El fragmento aparece textualmente en el enunciado
  # (sin distinguir mayúsculas: «Al principio» puede venir en minúscula en otro lado).
  def aparece_en?(fragmento, enunciado)
    enunciado.to_s.downcase.include?(fragmento.to_s.downcase)
  end

  # Oculta: la respuesta está escrita de corrido dentro del material, sin espacios.
  #   «cama tejida» → CAMATEJIDA contiene MATE
  def oculta_valida?(material, respuesta)
    NormalizadorDeTexto.normalizar(Array(material).join).include?(NormalizadorDeTexto.normalizar(respuesta))
  end

  # Anagrama: el material tiene exactamente las mismas letras que la respuesta.
  #   «Monja» → AJMNO == JAMÓN → AJMNO
  def anagrama_valido?(material, respuesta)
    letras_ordenadas(Array(material).join) == letras_ordenadas(respuesta)
  end

  # Iniciales: las primeras letras de las palabras del material forman la respuesta.
  def iniciales_validas?(material, respuesta)
    extremos_forman_respuesta?(material, respuesta) { |palabra| palabra[0] }
  end

  # Finales: las últimas letras de las palabras del material forman la respuesta.
  def finales_validas?(material, respuesta)
    extremos_forman_respuesta?(material, respuesta) { |palabra| palabra[-1] }
  end

  def letras_ordenadas(texto)
    NormalizadorDeTexto.normalizar(texto).chars.sort
  end

  # Prueba primero con todas las palabras y, si no da, sin los conectores.
  def extremos_forman_respuesta?(material, respuesta, &letra_de)
    objetivo = NormalizadorDeTexto.normalizar(respuesta)
    palabras = NormalizadorDeTexto.palabras(Array(material).join(" "))
    sin_conectores = palabras.reject { |p| CONECTORES.include?(p.downcase) }

    [ palabras, sin_conectores ].any? do |lista|
      NormalizadorDeTexto.normalizar(lista.map(&letra_de).join) == objetivo
    end
  end
end
