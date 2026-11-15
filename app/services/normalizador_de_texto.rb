# Normaliza textos para comparar respuestas y letras de crípticos.
#
#   NormalizadorDeTexto.normalizar(" Jamón ")  # => "JAMON"
#   NormalizadorDeTexto.normalizar("Ñandú")    # => "ÑANDU"  (la Ñ se conserva)
#
# Saca tildes, espacios, signos y números, y pasa todo a mayúsculas.
# La Ñ NO se convierte en N, porque en castellano son letras distintas.
module NormalizadorDeTexto
  CON_TILDE = "ÁÉÍÓÚÜÀÈÌÒÙ".freeze
  SIN_TILDE = "AEIOUUAEIOU".freeze

  module_function

  def normalizar(texto)
    texto.to_s.upcase.tr(CON_TILDE, SIN_TILDE).gsub(/[^A-ZÑ]/, "")
  end

  # Palabras de un texto, sin signos de puntuación.
  #   palabras("álbum, casa y amor") # => ["álbum", "casa", "y", "amor"]
  def palabras(texto)
    texto.to_s.scan(/[[:alpha:]]+/)
  end
end
