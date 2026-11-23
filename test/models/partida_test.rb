require "test_helper"

class PartidaTest < ActiveSupport::TestCase
  setup do
    @nueva = Partida.new(jugador: Jugador.create!(nombre: "Nueva"), criptico: cripticos(:mate))
  end

  test "requiere jugador y críptico" do
    partida = Partida.new
    assert_not partida.valid?
    assert_includes partida.errors.attribute_names, :jugador
    assert_includes partida.errors.attribute_names, :criptico
  end

  test "arranca sin iniciar, con 0 intentos y 0 pistas" do
    assert @nueva.valid?
    assert_not @nueva.iniciada?
    assert_equal 0, @nueva.intentos
    assert_equal 0, @nueva.pistas_usadas
  end

  test "un jugador juega cada críptico una sola vez" do
    repetida = Partida.new(jugador: jugadores(:pedrito), criptico: cripticos(:mate))
    assert_not repetida.valid?
    assert_includes repetida.errors.attribute_names, :criptico_id
  end

  test "la base también impide repetir jugador y críptico" do
    assert_raises(ActiveRecord::RecordNotUnique) do
      Partida.new(jugador: jugadores(:pedrito), criptico: cripticos(:mate)).save!(validate: false)
    end
  end

  test "hasta 5 intentos y 4 pistas" do
    @nueva.intentos = 6
    @nueva.pistas_usadas = 5
    assert_not @nueva.valid?
    assert_includes @nueva.errors.attribute_names, :intentos
    assert_includes @nueva.errors.attribute_names, :pistas_usadas
  end

  test "la base rechaza más pistas de las permitidas" do
    assert_raises(ActiveRecord::StatementInvalid) do
      partidas(:resuelta).update_column(:pistas_usadas, 5)
    end
  end

  test "no puede estar resuelta y rendida a la vez" do
    partida = partidas(:resuelta)
    partida.rendido_at = Time.current
    assert_not partida.valid?
  end

  test "una partida terminada tiene que haber empezado" do
    @nueva.resuelto_at = Time.current
    assert_not @nueva.valid?
    assert_includes @nueva.errors.attribute_names, :iniciado_at
  end

  test "los segundos jugados salen de los timestamps de inicio y resolución" do
    @nueva.iniciado_at = Time.current
    assert_nil @nueva.segundos_jugados

    @nueva.resuelto_at = @nueva.iniciado_at + 95.seconds
    assert_equal 95, @nueva.segundos_jugados
  end

  test "scopes por estado" do
    assert_includes Partida.resueltas, partidas(:resuelta)
    assert_includes Partida.rendidas, partidas(:rendida)
    assert_empty Partida.en_curso
  end

  test "no se puede borrar un jugador con partidas" do
    assert_not jugadores(:pedrito).destroy
    assert Jugador.exists?(jugadores(:pedrito).id)
  end
end
