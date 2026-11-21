# El recorrido se instala entero una sola vez. Después lo mantiene el administrador.
NodoChatbot.transaction do
  next if NodoChatbot.exists?(clave: "bienvenida")

  temas = YAML.safe_load_file(Rails.root.join("db/seeds/chatbot.yml"))
  enunciados_activos = Criptico.where(activo: true).pluck(:enunciado).map { |texto| NormalizadorDeTexto.normalizar(texto) }

  nodos = temas.to_h do |clave, tema|
    ejemplo = tema["ejemplo"]
    if ejemplo
      texto = NormalizadorDeTexto.normalizar(ejemplo)
      ejemplo = nil if enunciados_activos.any? { |enunciado| texto.include?(enunciado) }
    end
    [ clave, NodoChatbot.create!(clave: clave, mensaje: tema.fetch("mensaje"), ejemplo: ejemplo) ]
  end

  temas.each do |clave, tema|
    origen = nodos.fetch(clave)
    tema.fetch("opciones", {}).each do |destino, texto|
      origen.opciones.create!(texto: texto, destino: nodos.fetch(destino))
    end
    unless clave == "bienvenida"
      origen.opciones.create!(texto: "Volver al menú", destino: nodos.fetch("bienvenida"))
    end
  end
end
