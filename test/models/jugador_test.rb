require "test_helper"

class JugadorTest < ActiveSupport::TestCase
  test "el nombre tiene entre 3 y 20 caracteres y sin espacios en las puntas" do
    assert Jugador.new(nombre: "Ana").valid?
    assert_not Jugador.new(nombre: "Al").valid?
    assert_not Jugador.new(nombre: "a" * 21).valid?
    assert_not Jugador.new(nombre: " Ana").valid?
    assert_not Jugador.new(nombre: "Ana ").valid?
  end

  test "el nombre es único sin distinguir mayúsculas" do
    assert_not Jugador.new(nombre: "PEDRITO").valid?
  end

  test "la base también rechaza el nombre repetido con otras mayúsculas" do
    assert_raises(ActiveRecord::RecordNotUnique) do
      Jugador.new(nombre: "pedrito").save!(validate: false)
    end
  end

  test "se le genera un token al crearlo" do
    assert Jugador.create!(nombre: "Nuevo").token.present?
  end

  test "visibles excluye a los bloqueados" do
    assert_includes Jugador.visibles, jugadores(:pedrito)
    assert_not_includes Jugador.visibles, jugadores(:ofensivo)
  end

  test "los puntos totales suman las partidas resueltas" do
    assert_equal 80, jugadores(:pedrito).puntos_totales
  end

  test "sin partidas resueltas los puntos totales son 0" do
    assert_equal 0, jugadores(:ofensivo).puntos_totales
    assert_equal 0, Jugador.create!(nombre: "Novato").puntos_totales
  end

  test "la racha actual y la mejor salen del historial de partidas" do
    travel_to Time.zone.local(2026, 11, 20, 12, 0)
    jugador = Jugador.create!(nombre: "Constante")
    [ 5.days.ago, 4.days.ago, 1.day.ago ].each_with_index do |dia, numero|
      criptico = cripticos(:mate).dup
      criptico.update!(id_fuente: "cr-jugador-#{numero}")
      jugador.partidas.create!(criptico: criptico, iniciado_at: dia - 1.minute, resuelto_at: dia)
    end

    assert_equal 1, jugador.racha_actual
    assert_equal 2, jugador.mejor_racha
  end
end
