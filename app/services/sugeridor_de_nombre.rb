class SugeridorDeNombre
  def self.call(nombre)
    base = nombre.to_s.strip
    numero = 2

    loop do
      sufijo = "_#{numero}"
      candidato = "#{base.first(20 - sufijo.length)}#{sufijo}"
      return candidato unless Jugador.exists?(nombre_normalizado: Jugador.normalizar_nombre(candidato))

      numero += 1
    end
  end
end
