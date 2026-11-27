require "test_helper"

class TextoParaCompartirTest < ActiveSupport::TestCase
  setup do
    travel_to Time.zone.local(2026, 11, 20, 12, 0)
    @jugador = Jugador.create!(nombre: "Compartidor")
    @criptico = cripticos(:mate).dup
    @criptico.update!(id_fuente: "cr-compartir", dificultad: "medio", elegible_dia: false)
  end

  def resolver(criptico: @criptico, segundos: 245, pistas: 1, puntos: 144)
    @jugador.partidas.create!(criptico: criptico, iniciado_at: segundos.seconds.ago,
                              resuelto_at: Time.current, pistas_usadas: pistas, puntos: puntos)
  end

  test "muestra dificultad, tiempo, pistas y puntos" do
    texto = TextoParaCompartir.new(resolver).texto

    assert_includes texto, "Resolví un críptico Medio"
    assert_includes texto, "⏱ 4:05"
    assert_includes texto, "1 pista"
    assert_includes texto, "144 puntos"
  end

  test "no revela la respuesta ni el enunciado" do
    texto = TextoParaCompartir.new(resolver).texto

    assert_not_includes texto.upcase, @criptico.respuesta
    assert_not_includes texto, @criptico.enunciado
  end

  test "sin pistas lo dice" do
    assert_includes TextoParaCompartir.new(resolver(pistas: 0)).texto, "sin pistas"
  end

  test "muestra la racha si lleva más de un día" do
    assert_not_includes TextoParaCompartir.new(resolver).texto, "Racha"

    otro = cripticos(:mate).dup
    otro.update!(id_fuente: "cr-compartir-ayer")
    @jugador.partidas.create!(criptico: otro, iniciado_at: 1.day.ago - 1.minute, resuelto_at: 1.day.ago)
    partida = @jugador.partidas.find_by!(criptico: @criptico)

    assert_includes TextoParaCompartir.new(partida).texto, "🔥 Racha de 2 días"
  end

  test "avisa si era el críptico del día" do
    texto = TextoParaCompartir.new(resolver(criptico: CripticoDelDia.new.criptico)).texto

    assert_includes texto, "Resolví el críptico del día"
  end

  test "si se rindió, no muestra puntos" do
    rendida = @jugador.partidas.create!(criptico: @criptico, iniciado_at: 1.minute.ago,
                                         rendido_at: Time.current, puntos: 0)
    texto = TextoParaCompartir.new(rendida).texto

    assert_includes texto, "me ganó"
    assert_not_includes texto, "puntos"
  end

  test "el link de WhatsApp lleva el texto codificado" do
    compartir = TextoParaCompartir.new(resolver)

    assert compartir.url_whatsapp.start_with?("https://wa.me/?text=")
    assert_equal compartir.texto, CGI.unescape(compartir.url_whatsapp.delete_prefix("https://wa.me/?text="))
  end
end
