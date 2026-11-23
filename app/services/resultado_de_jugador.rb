ResultadoDeJugador = Data.define(:jugador, :sugerencia, :exitoso) do
  def exitoso?
    exitoso
  end
end
