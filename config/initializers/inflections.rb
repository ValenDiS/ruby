# Be sure to restart your server when you modify this file.

# Rails pluraliza en inglés: se definen los plurales de los modelos en español.
ActiveSupport::Inflector.inflections(:en) do |inflect|
  inflect.irregular "criptico", "cripticos"
  inflect.irregular "jugador", "jugadores"
  inflect.irregular "partida", "partidas"
  inflect.irregular "puntaje_por_tipo", "puntajes_por_tipo"
  inflect.irregular "multiplicador_dificultad", "multiplicadores_dificultad"
  inflect.irregular "configuracion", "configuraciones"
  inflect.irregular "sincronizacion", "sincronizaciones"
  inflect.irregular "nodo_chatbot", "nodos_chatbot"
end
