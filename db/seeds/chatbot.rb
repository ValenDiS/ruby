# El recorrido se instala entero una sola vez. Después lo mantiene el administrador.
NodoChatbot.transaction do
  next if NodoChatbot.exists?(clave: "bienvenida")

  temas = YAML.safe_load_file(Rails.root.join("db/seeds/chatbot.yml"))
  enunciados_activos = NodoChatbot.enunciados_activos

  nodos = temas.to_h do |clave, tema|
    nodo = NodoChatbot.new(clave: clave, mensaje: tema.fetch("mensaje"), ejemplo: tema["ejemplo"])
    nodo.ejemplo = nodo.ejemplo_visible(enunciados_activos)
    nodo.save!
    [ clave, nodo ]
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
