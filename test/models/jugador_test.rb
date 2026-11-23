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
      Jugador.new(nombre: "pedrito", nombre_normalizado: "pedrito").save!(validate: false)
    end
  end

  test "se le genera un token al crearlo" do
    assert Jugador.create!(nombre: "Nuevo").token.present?
  end

  test "el nombre es único también con mayúsculas acentuadas y unicode equivalente" do
    Jugador.create!(nombre: "María")

    assert_not Jugador.new(nombre: "MARÍA").valid?
    assert_not Jugador.new(nombre: "Mari\u0301a").valid?
  end

  test "la base impide repetir la clave unicode normalizada" do
    jugador = Jugador.create!(nombre: "María")

    assert_raises(ActiveRecord::RecordNotUnique) do
      Jugador.insert_all!([ { nombre: "MARÍA", nombre_normalizado: jugador.nombre_normalizado,
                             token: "otro-token", bloqueado: false } ])
    end
  end

  test "la normalización del nombre conserva tildes y la diferencia entre eñe y ene" do
    Jugador.create!(nombre: "Peña")
    Jugador.create!(nombre: "María")

    assert Jugador.new(nombre: "Pena").valid?
    assert Jugador.new(nombre: "Maria").valid?
    assert_not Jugador.new(nombre: "PEÑA").valid?
  end

  test "visibles excluye a los bloqueados" do
    assert_includes Jugador.visibles, jugadores(:pedrito)
    assert_not_includes Jugador.visibles, jugadores(:ofensivo)
  end
end
