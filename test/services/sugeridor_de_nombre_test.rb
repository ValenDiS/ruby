require "test_helper"

class SugeridorDeNombreTest < ActiveSupport::TestCase
  test "saltea variantes ocupadas sin distinguir mayúsculas" do
    Jugador.create!(nombre: "pedrito_2")
    Jugador.create!(nombre: "PEDRITO_3", bloqueado: true)

    assert_equal "Pedrito_4", SugeridorDeNombre.call("Pedrito")
  end

  test "mantiene el máximo de veinte caracteres incluso con sufijo de dos dígitos" do
    base = "abcdefghijklmnopqrst"
    (2..9).each { |numero| Jugador.create!(nombre: "#{base.first(18)}_#{numero}") }

    sugerencia = SugeridorDeNombre.call(base)

    assert_equal "abcdefghijklmnopq_10", sugerencia
    assert Jugador.new(nombre: sugerencia).valid?
  end

  test "saltea variantes con otras mayúsculas acentuadas" do
    Jugador.create!(nombre: "MARÍA_2")

    assert_equal "María_3", SugeridorDeNombre.call("María")
  end
end
