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
end
