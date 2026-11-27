# Arma el mensaje para compartir el resultado de una partida por WhatsApp.
# Nunca incluye la respuesta ni el enunciado: solo cómo le fue al jugador.
#
#   compartir = TextoParaCompartir.new(partida)
#   compartir.texto          # => "Resolví un críptico Medio en Rubípticos 🧩 ..."
#   compartir.url_whatsapp   # => "https://wa.me/?text=..."
class TextoParaCompartir
  def initialize(partida)
    @partida = partida
    @criptico = partida.criptico
  end

  def texto
    return "El críptico #{dificultad} de Rubípticos me ganó. ¿Vos podés? 🧩" if @partida.rendida?

    [ titulo, "⏱ #{tiempo} · 💡 #{pistas} · ⭐ #{@partida.puntos} puntos", racha ].compact.join("\n")
  end

  def url_whatsapp
    "https://wa.me/?text=#{ERB::Util.url_encode(texto)}"
  end

  private
    def titulo
      if CripticoDelDia.new(@partida.resuelto_at.to_date).es?(@criptico)
        "Resolví el críptico del día (#{dificultad}) en Rubípticos 🧩"
      else
        "Resolví un críptico #{dificultad} en Rubípticos 🧩"
      end
    end

    def dificultad
      I18n.t("cripticos.dificultades.#{@criptico.dificultad}")
    end

    # 245 segundos => "4:05"
    def tiempo
      minutos, segundos = @partida.segundos_jugados.divmod(60)
      format("%d:%02d", minutos, segundos)
    end

    def pistas
      case @partida.pistas_usadas
      when 0 then "sin pistas"
      when 1 then "1 pista"
      else "#{@partida.pistas_usadas} pistas"
      end
    end

    def racha
      dias = @partida.jugador.racha_actual
      "🔥 Racha de #{dias} días" if dias > 1
    end
end
